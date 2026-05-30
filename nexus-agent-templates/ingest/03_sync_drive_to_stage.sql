-- ═══════════════════════════════════════════════════════════════════
-- SYNC_CLIENT_ASSETS — Google Drive → @CLIENT_DOCS/{client}/asset/
-- Requires: GOOGLE_DRIVE_EAI, GOOGLE_DRIVE_SERVICE_ACCOUNT secret
-- Packages: requests, PyJWT, cryptography
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE PROCEDURE SYNC_CLIENT_ASSETS(CLIENT_NAME_INPUT VARCHAR)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'requests', 'PyJWT', 'cryptography')
HANDLER = 'sync_client_assets'
EXECUTE AS CALLER
EXTERNAL_ACCESS_INTEGRATIONS = (GOOGLE_DRIVE_EAI)
SECRETS = ('cred' = GOOGLE_DRIVE_SERVICE_ACCOUNT)
AS
$$
import json
import io
import time
import jwt
import requests
import _snowflake

DB = "SPS_BUSINESS_INSIGHT"
SCHEMA = "NEXUS"


def _drive_token(sa):
    now = int(time.time())
    claim = {
        "iss": sa["client_email"],
        "scope": "https://www.googleapis.com/auth/drive.readonly",
        "aud": "https://oauth2.googleapis.com/token",
        "iat": now,
        "exp": now + 3600,
    }
    assertion = jwt.encode(claim, sa["private_key"], algorithm="RS256")
    r = requests.post(
        "https://oauth2.googleapis.com/token",
        data={"grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer", "assertion": assertion},
        timeout=30,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def sync_client_assets(session, client_name_input):
    try:
        rows = session.sql(f"""
            SELECT DRIVE_FOLDER_ID FROM {DB}.{SCHEMA}.CLIENTS
            WHERE CLIENT_NAME = ? AND ACTIVE = TRUE
        """, params=[client_name_input]).collect()
        if not rows or not rows[0]["DRIVE_FOLDER_ID"]:
            return {"status": "ERROR", "error": f"No DRIVE_FOLDER_ID for client '{client_name_input}'"}

        sa = json.loads(_snowflake.get_generic_secret_string("cred"))
        token = _drive_token(sa)
        headers = {"Authorization": f"Bearer {token}"}
        folder_id = rows[0]["DRIVE_FOLDER_ID"]

        resp = requests.get(
            "https://www.googleapis.com/drive/v3/files",
            headers=headers,
            params={
                "q": f"'{folder_id}' in parents and trashed = false",
                "fields": "files(id,name,mimeType,modifiedTime,size)",
                "pageSize": 100,
            },
            timeout=60,
        )
        resp.raise_for_status()
        files = resp.json().get("files", [])
        synced = []

        for f in files:
            name = f["name"]
            if not name.lower().endswith((".pdf", ".docx", ".doc", ".md", ".txt")):
                continue
            stage_rel = f"{client_name_input}/asset/{name}"
            dl = requests.get(
                f"https://www.googleapis.com/drive/v3/files/{f['id']}?alt=media",
                headers=headers,
                timeout=120,
            )
            dl.raise_for_status()
            session.file.put_stream(
                io.BytesIO(dl.content),
                f"@{DB}.{SCHEMA}.CLIENT_DOCS/{stage_rel}",
                auto_compress=False,
                overwrite=True,
            )
            session.sql(f"""
                MERGE INTO {DB}.{SCHEMA}.CLIENT_FILES t
                USING (SELECT ? AS CLIENT_NAME, ? AS FILE_NAME) s
                ON t.CLIENT_NAME = s.CLIENT_NAME AND t.FILE_NAME = s.FILE_NAME
                WHEN MATCHED THEN UPDATE SET
                    STAGE_PATH = ?, DRIVE_FILE_ID = ?, FILE_SIZE = ?,
                    CONTENT_TYPE = ?, SYNCED_AT = CURRENT_TIMESTAMP()
                WHEN NOT MATCHED THEN INSERT
                    (CLIENT_NAME, FILE_NAME, STAGE_PATH, DRIVE_FILE_ID, FILE_SIZE, CONTENT_TYPE)
                VALUES (?, ?, ?, ?, ?, ?)
            """, params=[
                client_name_input, name,
                stage_rel, f["id"], int(f.get("size") or 0), f.get("mimeType", ""),
                client_name_input, name, stage_rel, f["id"], int(f.get("size") or 0), f.get("mimeType", ""),
            ]).collect()
            synced.append(name)

        return {"status": "SUCCESS", "client_name": client_name_input, "files_synced": len(synced), "file_names": synced}
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}
$$;

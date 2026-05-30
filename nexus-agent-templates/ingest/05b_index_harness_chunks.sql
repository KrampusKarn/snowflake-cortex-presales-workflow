CREATE OR REPLACE PROCEDURE "INDEX_HARNESS_CHUNKS"("RUN_ID" VARCHAR, "CHUNK_KIND" VARCHAR, "SKILL_NAME" VARCHAR DEFAULT null, "STAGE_NUMBER" NUMBER(38,0) DEFAULT null)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'index_harness_chunks'
EXECUTE AS CALLER
AS '
import json

DB = "DEMO_SPS_CORTEX"
SCHEMA = "NEXUS"
SEARCH_FQN = f"{DB}.{SCHEMA}.SOURCE_DOCUMENTS_SEARCH"


def _config(session):
    rows = session.sql(f"""
        SELECT CONFIG_KEY, CONFIG_VALUE FROM {DB}.{SCHEMA}.PIPELINE_CONFIG
        WHERE CONFIG_KEY IN (
            ''HARNESS_SEARCH_ENABLED'', ''HARNESS_CHUNK_SIZE'', ''HARNESS_CHUNK_OVERLAP'',
            ''SOURCE_DOCUMENTS_SEARCH_FQN''
        )
    """).collect()
    cfg = {r["CONFIG_KEY"]: r["CONFIG_VALUE"] for r in rows}
    return {
        "enabled": str(cfg.get("HARNESS_SEARCH_ENABLED", "true")).lower() == "true",
        "chunk_size": int(cfg.get("HARNESS_CHUNK_SIZE", "1500") or 1500),
        "overlap": int(cfg.get("HARNESS_CHUNK_OVERLAP", "100") or 100),
        "search_fqn": (cfg.get("SOURCE_DOCUMENTS_SEARCH_FQN") or SEARCH_FQN).strip(),
    }


def _chunk_text(text, chunk_size, overlap):
    text = (text or "").strip()
    if not text:
        return []
    chunks, start, n = [], 0, len(text)
    while start < n:
        end = min(start + chunk_size, n)
        if end < n:
            para = text.rfind("\\n\\n", start, end)
            if para > start + chunk_size // 2:
                end = para
        piece = text[start:end].strip()
        if len(piece) >= 20:
            chunks.append(piece)
        if end >= n:
            break
        start = max(end - overlap, start + 1)
    return chunks


def _refresh_search(session, search_fqn):
    try:
        session.sql(f"ALTER CORTEX SEARCH SERVICE {search_fqn} REFRESH").collect()
        return True
    except Exception:
        return False


def index_harness_chunks(session, run_id, chunk_kind, skill_name, stage_number):
    try:
        cfg = _config(session)
        if not cfg["enabled"]:
            return {"status": "SKIPPED", "reason": "HARNESS_SEARCH_ENABLED=false"}

        state = session.sql(f"""
            SELECT CLIENT_NAME, PROJECT_NAME, BRIEF_CONTENT
            FROM {DB}.{SCHEMA}.ORCHESTRATOR_STATE WHERE RUN_ID = ?
        """, params=[run_id]).collect()
        if not state:
            return {"status": "ERROR", "error": f"Run ''{run_id}'' not found"}

        client = state[0]["CLIENT_NAME"] or state[0]["PROJECT_NAME"].lower().replace(" ", "-")
        kind = (chunk_kind or "").strip().lower()

        content = None
        doc_type = None
        title = None
        parent_id = None
        skill = skill_name
        stage = int(stage_number) if stage_number is not None else None

        if kind == "brief":
            content = state[0]["BRIEF_CONTENT"] or ""
            doc_type = "brief"
            title = "Project Brief (SSOT)"
            parent_id = run_id
            session.sql(f"""
                DELETE FROM {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
                WHERE CLIENT_NAME = ? AND RUN_ID = ? AND DOC_TYPE = ''brief''
            """, params=[client, run_id]).collect()
        elif kind == "skill_output":
            if not skill_name or stage_number is None:
                return {"status": "ERROR", "error": "skill_output requires SKILL_NAME and STAGE_NUMBER"}
            out = session.sql(f"""
                SELECT OUTPUT_ID, OUTPUT_CONTENT
                FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
                WHERE RUN_ID = ? AND SKILL_NAME = ? AND STAGE_NUMBER = ?
                ORDER BY CREATED_AT DESC LIMIT 1
            """, params=[run_id, skill_name, int(stage_number)]).collect()
            if not out:
                return {"status": "ERROR", "error": "No STAGE_OUTPUTS row to index"}
            content = out[0]["OUTPUT_CONTENT"] or ""
            parent_id = out[0]["OUTPUT_ID"]
            doc_type = "skill_output"
            title = f"{skill_name} (Stage {int(stage_number)})"
            session.sql(f"""
                DELETE FROM {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
                WHERE CLIENT_NAME = ? AND RUN_ID = ? AND DOC_TYPE = ''skill_output''
                  AND SKILL_NAME = ? AND STAGE_NUMBER = ?
            """, params=[client, run_id, skill_name, int(stage_number)]).collect()
        else:
            return {"status": "ERROR", "error": f"Unknown CHUNK_KIND ''{chunk_kind}''. Use brief or skill_output."}

        pieces = _chunk_text(content, cfg["chunk_size"], cfg["overlap"])
        if not pieces:
            return {"status": "SKIPPED", "reason": "empty content", "chunk_kind": kind}

        for idx, piece in enumerate(pieces):
            session.sql(f"""
                INSERT INTO {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
                    (CLIENT_NAME, RUN_ID, DOC_TYPE, SOURCE_KIND, SKILL_NAME, STAGE_NUMBER,
                     TITLE, CHUNK_INDEX, CONTENT, PARENT_DOC_ID)
                VALUES (?, ?, ?, ''workflow'', ?, ?, ?, ?, ?, ?)
            """, params=[
                client, run_id, doc_type, skill, stage,
                title, idx, piece, parent_id,
            ]).collect()

        refreshed = _refresh_search(session, cfg["search_fqn"])
        return {
            "status": "SUCCESS",
            "chunk_kind": kind,
            "chunks_indexed": len(pieces),
            "search_refreshed": refreshed,
            "client_name": client,
        }
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}
';

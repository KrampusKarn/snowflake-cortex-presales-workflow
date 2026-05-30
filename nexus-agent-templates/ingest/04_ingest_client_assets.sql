CREATE OR REPLACE PROCEDURE "INGEST_CLIENT_ASSETS"("CLIENT_NAME" VARCHAR, "RUN_ID" VARCHAR DEFAULT null)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'ingest_client_assets'
EXECUTE AS CALLER
AS '
import json

DB = "DEMO_SPS_CORTEX"
SCHEMA = "NEXUS"
STAGE = f"@{DB}.{SCHEMA}.CLIENT_DOCS"
SEARCH_FQN = f"{DB}.{SCHEMA}.SOURCE_DOCUMENTS_SEARCH"


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


def _search_config(session):
    rows = session.sql(f"""
        SELECT CONFIG_KEY, CONFIG_VALUE FROM {DB}.{SCHEMA}.PIPELINE_CONFIG
        WHERE CONFIG_KEY IN (
            ''HARNESS_SEARCH_ENABLED'', ''HARNESS_CHUNK_SIZE'', ''HARNESS_CHUNK_OVERLAP'',
            ''HARNESS_SEARCH_TOP_K'', ''SOURCE_DOCUMENTS_SEARCH_FQN''
        )
    """).collect()
    cfg = {r["CONFIG_KEY"]: r["CONFIG_VALUE"] for r in rows}
    return {
        "enabled": str(cfg.get("HARNESS_SEARCH_ENABLED", "true")).lower() == "true",
        "chunk_size": int(cfg.get("HARNESS_CHUNK_SIZE", "1500") or 1500),
        "overlap": int(cfg.get("HARNESS_CHUNK_OVERLAP", "100") or 100),
        "top_k": int(cfg.get("HARNESS_SEARCH_TOP_K", "8") or 8),
        "search_fqn": (cfg.get("SOURCE_DOCUMENTS_SEARCH_FQN") or SEARCH_FQN).strip(),
    }


def _refresh_search(session, search_fqn):
    try:
        session.sql(f"ALTER CORTEX SEARCH SERVICE {search_fqn} REFRESH").collect()
        return True
    except Exception:
        return False


def _index_ingest_chunks(session, client_name, fname, doc_type, title, content, doc_id, run_id, cfg):
    session.sql(f"""
        DELETE FROM {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
        WHERE CLIENT_NAME = ? AND FILE_NAME = ? AND SOURCE_KIND = ''ingest''
    """, params=[client_name, fname]).collect()

    pieces = _chunk_text(content, cfg["chunk_size"], cfg["overlap"])
    for idx, piece in enumerate(pieces):
        session.sql(f"""
            INSERT INTO {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
                (CLIENT_NAME, RUN_ID, DOC_TYPE, SOURCE_KIND, FILE_NAME, TITLE,
                 CHUNK_INDEX, CONTENT, PARENT_DOC_ID)
            VALUES (?, ?, ?, ''ingest'', ?, ?, ?, ?, ?)
        """, params=[
            client_name, run_id, doc_type, fname, title, idx, piece, doc_id,
        ]).collect()
    return len(pieces)


def _doc_type(name):
    n = name.lower()
    if "brief" in n:
        return "brief"
    if "sow" in n:
        return "sow"
    if "rfp" in n:
        return "rfp"
    return "notes"


def _is_missing(value):
    if value is None:
        return True
    text = str(value).strip()
    if not text:
        return True
    return text.lower() in ("null", "none", "undefined", "n/a")


def ingest_client_assets(session, client_name, run_id):
    try:
        if _is_missing(run_id):
            run_id = None

        files = session.sql(f"""
            SELECT FILE_NAME, STAGE_PATH FROM {DB}.{SCHEMA}.CLIENT_FILES
            WHERE CLIENT_NAME = ?
        """, params=[client_name]).collect()

        if not files:
            return {"status": "ERROR", "error": f"No files in CLIENT_FILES for ''{client_name}''. Run SYNC_CLIENT_ASSETS first."}

        ingested, skipped_empty = [], []
        chunks_indexed = 0
        cfg = _search_config(session)
        for row in files:
            fname = row["FILE_NAME"]
            stage_path = row["STAGE_PATH"]
            full_stage = f"{STAGE}/{stage_path}"
            ext = fname.lower().split(".")[-1]

            if ext in ("md", "txt"):
                text_rows = session.sql(f"""
                    SELECT $1 AS content FROM {full_stage}
                    (FILE_FORMAT => (TYPE => ''CSV'', FIELD_DELIMITER => ''NONE'', RECORD_DELIMITER => ''\\\\n''))
                """).collect()
                content = "\\n".join(r["CONTENT"] for r in text_rows) if text_rows else ""
            elif ext in ("pdf", "docx", "doc"):
                parse_rows = session.sql(f"""
                    SELECT SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
                        ''{STAGE}'',
                        ''{stage_path}'',
                        OBJECT_CONSTRUCT(''mode'', ''LAYOUT'')
                    ) AS parsed
                """).collect()
                parsed = parse_rows[0]["PARSED"] if parse_rows else None
                if parsed:
                    try:
                        p = json.loads(parsed) if isinstance(parsed, str) else parsed
                        content = p.get("content", str(parsed))
                    except Exception:
                        content = str(parsed)
                else:
                    content = ""
            else:
                continue

            if not content or len(content.strip()) < 10:
                skipped_empty.append(fname)
                continue

            doc_type = _doc_type(fname)
            title = fname.rsplit(".", 1)[0]

            session.sql(f"""
                MERGE INTO {DB}.{SCHEMA}.SOURCE_DOCUMENTS t
                USING (SELECT
                    ? AS CLIENT_NAME, ? AS FILE_NAME, ? AS RUN_ID,
                    ? AS DOC_TYPE, ? AS TITLE, ? AS CONTENT, ? AS STAGE_PATH
                ) s
                ON t.CLIENT_NAME = s.CLIENT_NAME AND t.FILE_NAME = s.FILE_NAME
                WHEN MATCHED THEN UPDATE SET
                    RUN_ID = s.RUN_ID,
                    DOC_TYPE = s.DOC_TYPE,
                    TITLE = s.TITLE,
                    CONTENT = s.CONTENT,
                    STAGE_PATH = s.STAGE_PATH
                WHEN NOT MATCHED THEN INSERT
                    (PROJECT_ID, CLIENT_NAME, RUN_ID, DOC_TYPE, TITLE, CONTENT, FILE_NAME, STAGE_PATH)
                VALUES
                    (s.CLIENT_NAME, s.CLIENT_NAME, s.RUN_ID, s.DOC_TYPE, s.TITLE, s.CONTENT, s.FILE_NAME, s.STAGE_PATH)
            """, params=[
                client_name, fname, run_id,
                doc_type, title, content, stage_path,
            ]).collect()

            doc_id_rows = session.sql(f"""
                SELECT DOC_ID FROM {DB}.{SCHEMA}.SOURCE_DOCUMENTS
                WHERE CLIENT_NAME = ? AND FILE_NAME = ?
            """, params=[client_name, fname]).collect()
            doc_id = doc_id_rows[0]["DOC_ID"] if doc_id_rows else None

            if cfg["enabled"] and doc_id:
                chunks_indexed += _index_ingest_chunks(
                    session, client_name, fname, doc_type, title, content, doc_id, run_id, cfg
                )

            ingested.append(fname)

        # ── Orphan cleanup: SOURCE_DOCUMENTS rows whose FILE_NAME is no longer in CLIENT_FILES ──
        del_result = session.sql(f"""
            DELETE FROM {DB}.{SCHEMA}.SOURCE_DOCUMENTS
            WHERE CLIENT_NAME = ?
              AND FILE_NAME IS NOT NULL
              AND FILE_NAME NOT IN (
                  SELECT FILE_NAME FROM {DB}.{SCHEMA}.CLIENT_FILES WHERE CLIENT_NAME = ?
              )
        """, params=[client_name, client_name]).collect()
        session.sql(f"""
            DELETE FROM {DB}.{SCHEMA}.SOURCE_DOCUMENT_CHUNKS
            WHERE CLIENT_NAME = ? AND SOURCE_KIND = ''ingest''
              AND (FILE_NAME IS NULL OR FILE_NAME NOT IN (
                  SELECT FILE_NAME FROM {DB}.{SCHEMA}.CLIENT_FILES WHERE CLIENT_NAME = ?
              ))
        """, params=[client_name, client_name]).collect()

        search_refreshed = False
        if cfg["enabled"] and chunks_indexed > 0:
            search_refreshed = _refresh_search(session, cfg["search_fqn"])
        removed_count = 0
        if del_result and del_result[0]:
            try:
                removed_count = int(del_result[0][0])
            except Exception:
                removed_count = 0

        return {
            "status": "SUCCESS",
            "client_name": client_name,
            "documents_ingested": len(ingested),
            "chunks_indexed": chunks_indexed,
            "search_refreshed": search_refreshed,
            "documents_skipped_empty": len(skipped_empty),
            "documents_removed_orphan": removed_count,
            "file_names": ingested,
            "skipped_empty": skipped_empty,
        }
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}
';

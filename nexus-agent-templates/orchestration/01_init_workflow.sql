-- ============================================================
-- INIT_WORKFLOW — Create a new pre-sales workflow run
-- ============================================================
-- Supports inline RFP text OR ingested SOURCE_DOCUMENTS for a client.
--
-- Usage:
--   CALL SPS_BUSINESS_INSIGHT.NEXUS.INIT_WORKFLOW(
--     'Easia Hub 2026',
--     'easia-hub',
--     NULL  -- uses SOURCE_DOCUMENTS when NULL
--   );
-- ============================================================

CREATE OR REPLACE PROCEDURE SPS_BUSINESS_INSIGHT.NEXUS.INIT_WORKFLOW(
    PROJECT_NAME VARCHAR,
    CLIENT_NAME VARCHAR,
    RFP_CONTENT VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'init_workflow'
EXECUTE AS CALLER
AS
$$
def init_workflow(session, project_name, client_name, rfp_content):
    """Initialize a new workflow run. Loads RFP from SOURCE_DOCUMENTS when rfp_content is null."""
    try:
        run_id_row = session.sql("SELECT UUID_STRING() AS rid").collect()
        run_id = run_id_row[0]['RID']

        user_rfp = rfp_content
        if not user_rfp or not str(user_rfp).strip():
            doc_rows = session.sql("""
                SELECT TITLE, DOC_TYPE, CONTENT
                FROM SPS_BUSINESS_INSIGHT.NEXUS.SOURCE_DOCUMENTS
                WHERE CLIENT_NAME = ?
                ORDER BY CASE DOC_TYPE
                    WHEN 'rfp' THEN 1 WHEN 'brief' THEN 2 WHEN 'sow' THEN 3 ELSE 4 END,
                    CREATED_AT
            """, params=[client_name]).collect()

            if not doc_rows:
                return {
                    'status': 'ERROR',
                    'error': f'No RFP content provided and no SOURCE_DOCUMENTS for client "{client_name}". Run INGEST_CLIENT_ASSETS first or pass rfp_content.'
                }

            parts = []
            for d in doc_rows:
                parts.append(f"## {d['TITLE']} ({d['DOC_TYPE']})\n{d['CONTENT']}")
            user_rfp = "\n\n---\n\n".join(parts)

        session.sql("""
            INSERT INTO SPS_BUSINESS_INSIGHT.NEXUS.ORCHESTRATOR_STATE
                (RUN_ID, PROJECT_NAME, CLIENT_NAME, USER_RFP_INPUT, CURRENT_STAGE, STAGE_STATUS)
            VALUES (?, ?, ?, ?, 1, 'NOT_STARTED')
        """, params=[run_id, project_name, client_name, user_rfp]).collect()

        return {
            'status': 'SUCCESS',
            'run_id': run_id,
            'project_name': project_name,
            'client_name': client_name,
            'current_stage': 1,
            'rfp_source': 'inline' if rfp_content else 'source_documents',
            'message': f'Workflow initialized for "{project_name}" (client: {client_name}). Use this RUN_ID for all subsequent operations.'
        }

    except Exception as e:
        return {
            'status': 'ERROR',
            'error': 'Failed to initialize workflow',
            'detail': str(e)
        }
$$;

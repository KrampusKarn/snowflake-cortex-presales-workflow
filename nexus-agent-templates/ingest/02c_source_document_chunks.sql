-- ═══════════════════════════════════════════════════════════════════
-- SOURCE_DOCUMENT_CHUNKS — chunked text for Cortex Search retrieval
-- Populated by INGEST_CLIENT_ASSETS (Drive PDFs) and harness indexing
-- (brief + skill outputs). Powers SOURCE_DOCUMENTS_SEARCH for Worker/Eval.
-- ═══════════════════════════════════════════════════════════════════

USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

CREATE TABLE IF NOT EXISTS SOURCE_DOCUMENT_CHUNKS (
    CHUNK_ID        STRING DEFAULT UUID_STRING(),
    CLIENT_NAME     STRING NOT NULL,
    RUN_ID          STRING COMMENT 'Workflow run when chunk is brief/skill_output; NULL for ingested assets',
    DOC_TYPE        STRING NOT NULL COMMENT 'rfp | brief | sow | notes | skill_output',
    SOURCE_KIND     STRING NOT NULL COMMENT 'ingest | workflow',
    FILE_NAME       STRING,
    SKILL_NAME      STRING,
    STAGE_NUMBER    NUMBER,
    TITLE           STRING NOT NULL,
    CHUNK_INDEX     NUMBER NOT NULL,
    CONTENT         STRING NOT NULL,
    PARENT_DOC_ID   STRING COMMENT 'SOURCE_DOCUMENTS.DOC_ID or STAGE_OUTPUTS.OUTPUT_ID',
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

MERGE INTO PIPELINE_CONFIG t
USING (
    SELECT column1 AS CONFIG_KEY, column2 AS CONFIG_VALUE FROM VALUES
        ('HARNESS_SEARCH_ENABLED', 'true'),
        ('HARNESS_SEARCH_TOP_K', '8'),
        ('HARNESS_CHUNK_SIZE', '1500'),
        ('HARNESS_CHUNK_OVERLAP', '100'),
        ('SOURCE_DOCUMENTS_SEARCH_FQN', 'DEMO_SPS_CORTEX.NEXUS.SOURCE_DOCUMENTS_SEARCH')
) s
ON t.CONFIG_KEY = s.CONFIG_KEY
WHEN NOT MATCHED THEN INSERT (CONFIG_KEY, CONFIG_VALUE) VALUES (s.CONFIG_KEY, s.CONFIG_VALUE);

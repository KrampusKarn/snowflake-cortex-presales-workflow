-- ═══════════════════════════════════════════════════════════════════
-- Cortex Search services — harness + deck Q&A
--
--   SOURCE_DOCUMENTS_SEARCH → Worker/Evaluator retrieval (ingest + workflow chunks)
--   SKILLS_SEARCH_SERVICE   → Legacy SKILLS table audit (optional)
--   PROPOSAL_DECK_SEARCH    → DECK_RESEARCH_AGENT (post-export deck Q&A)
-- ═══════════════════════════════════════════════════════════════════

USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);
USE WAREHOUSE IDENTIFIER($DEPLOY_WAREHOUSE);

-- ── Client source + workflow chunks (harness retrieval) ───────────
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS SOURCE_DOCUMENTS_SEARCH
  ON CONTENT
  ATTRIBUTES CLIENT_NAME, DOC_TYPE, RUN_ID, SKILL_NAME, STAGE_NUMBER, TITLE, FILE_NAME, CHUNK_INDEX, SOURCE_KIND
  WAREHOUSE = IDENTIFIER($DEPLOY_WAREHOUSE)
  TARGET_LAG = '1 hour'
  AS (
    SELECT CHUNK_ID AS DOC_ID,
           TITLE,
           CONTENT,
           CLIENT_NAME,
           DOC_TYPE,
           RUN_ID,
           SKILL_NAME,
           STAGE_NUMBER,
           FILE_NAME,
           CHUNK_INDEX,
           SOURCE_KIND
    FROM SOURCE_DOCUMENT_CHUNKS
  );

-- ── Skills from Git (optional audit table) ────────────────────────
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS SKILLS_SEARCH_SERVICE
  ON CONTENT
  ATTRIBUTES SKILL_NAME, FOLDER_NAME, DESCRIPTION
  WAREHOUSE = IDENTIFIER($DEPLOY_WAREHOUSE)
  TARGET_LAG = '1 hour'
  AS (
    SELECT SKILL_ID::STRING AS DOC_ID,
           SKILL_NAME || ': ' || COALESCE(DESCRIPTION, '') AS TITLE,
           CONTENT,
           SKILL_NAME,
           FOLDER_NAME,
           DESCRIPTION
    FROM SKILLS
  );

-- ── Deck + workflow outputs (DECK_RESEARCH_AGENT only) ─────────────
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS PROPOSAL_DECK_SEARCH
  ON CONTENT
  ATTRIBUTES TITLE, SECTION, CLIENT_NAME, PROJECT_ID, CONTENT_SOURCE
  WAREHOUSE = IDENTIFIER($DEPLOY_WAREHOUSE)
  TARGET_LAG = '1 hour'
  AS (
    SELECT DOC_ID,
           TITLE,
           CONTENT,
           SLIDE_OR_SECTION AS SECTION,
           CLIENT_NAME,
           PROJECT_ID,
           'proposal_deck' AS CONTENT_SOURCE
    FROM PROPOSAL_DECK
    UNION ALL
    SELECT DOC_ID,
           TITLE,
           CONTENT,
           STAGE AS SECTION,
           CLIENT_NAME,
           PROJECT_ID,
           'workflow_output' AS CONTENT_SOURCE
    FROM WORKFLOW_OUTPUTS
  );

SHOW CORTEX SEARCH SERVICES IN SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

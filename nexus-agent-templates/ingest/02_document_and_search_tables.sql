-- ═══════════════════════════════════════════════════════════════════
-- Document + Cortex Search source tables (unified under NEXUS schema)
-- ═══════════════════════════════════════════════════════════════════

USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

-- ── Source documents (RFP, brief, SOW, notes) ─────────────────────
CREATE TABLE IF NOT EXISTS SOURCE_DOCUMENTS (
    DOC_ID          STRING DEFAULT UUID_STRING(),
    PROJECT_ID      STRING,
    CLIENT_NAME     STRING,
    RUN_ID          STRING,
    DOC_TYPE        STRING COMMENT 'rfp | brief | sow | notes',
    TITLE           STRING NOT NULL,
    CONTENT         STRING NOT NULL,
    FILE_NAME       STRING,
    STAGE_PATH      STRING,
    SOURCE_PATH     STRING,
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ── Workflow outputs (skill deliverables) ─────────────────────────
CREATE TABLE IF NOT EXISTS WORKFLOW_OUTPUTS (
    DOC_ID          STRING DEFAULT UUID_STRING(),
    PROJECT_ID      STRING,
    CLIENT_NAME     STRING,
    RUN_ID          STRING,
    STAGE           STRING COMMENT '01_research … 06_final',
    SKILL_NAME      STRING,
    TITLE           STRING NOT NULL,
    CONTENT         STRING NOT NULL,
    SOURCE_PATH     STRING,
    CREATED_AT      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ── Proposal deck + final packaging ───────────────────────────────
CREATE TABLE IF NOT EXISTS PROPOSAL_DECK (
    DOC_ID              STRING DEFAULT UUID_STRING(),
    PROJECT_ID          STRING,
    CLIENT_NAME         STRING,
    RUN_ID              STRING,
    SLIDE_OR_SECTION    STRING,
    TITLE               STRING NOT NULL,
    CONTENT             STRING NOT NULL,
    SOURCE_PATH         STRING,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ── Skills library (synced from Git) ──────────────────────────────
CREATE TABLE IF NOT EXISTS SKILLS (
    SKILL_ID        NUMBER AUTOINCREMENT,
    SKILL_NAME      VARCHAR NOT NULL COMMENT 'Frontmatter name, e.g. sales-rfp-analyzer',
    FOLDER_NAME     VARCHAR COMMENT 'Repo folder, e.g. rfp-analyzer',
    DESCRIPTION     VARCHAR,
    CONTENT         VARCHAR NOT NULL COMMENT 'Full SKILL.md body',
    GIT_PATH        VARCHAR,
    SYNCED_AT       TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UNIQUE (SKILL_NAME)
);

-- ── Runtime config (Git path, PDF endpoint, etc.) ─────────────────
CREATE TABLE IF NOT EXISTS PIPELINE_CONFIG (
    CONFIG_KEY   VARCHAR PRIMARY KEY,
    CONFIG_VALUE VARCHAR,
    UPDATED_AT   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

MERGE INTO PIPELINE_CONFIG t
USING (SELECT 'SKILLS_GIT_PATH' AS CONFIG_KEY, 'branches/DEMO/skills/pre-sales' AS CONFIG_VALUE) s
ON t.CONFIG_KEY = s.CONFIG_KEY
WHEN NOT MATCHED THEN INSERT (CONFIG_KEY, CONFIG_VALUE) VALUES (s.CONFIG_KEY, s.CONFIG_VALUE);

-- ═══════════════════════════════════════════════════════════════════
-- Deployment configuration — set these before running ingest/orchestration
-- Copy to deploy_config.sql and customize for your account.
-- ═══════════════════════════════════════════════════════════════════

SET DEPLOY_DATABASE = 'DEMO_SPS_CORTEX';
SET DEPLOY_SCHEMA   = 'NEXUS';
SET DEPLOY_WAREHOUSE = 'DEMO_WH';
SET DEPLOY_ROLE     = 'SYSADMIN';

-- Git repository (Snowflake Git integration) for skills sync
SET SKILLS_GIT_REPO   = '@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO';
SET SKILLS_GIT_BRANCH = 'DEMO';
SET SKILLS_GIT_PATH   = 'branches/DEMO/skills/pre-sales';

-- Google Drive (External Access — configure in 00_network_rule_and_secrets.sql)
SET DRIVE_ROOT_FOLDER_ID = 'YOUR_GOOGLE_DRIVE_FOLDER_ID';
SET DRIVE_EAI_NAME       = 'GOOGLE_DRIVE_EAI';

-- PDF export via Snowpark Container Services (Gotenberg) — see ingest/spcs-gotenberg/
SET PDF_COMPUTE_POOL    = 'PDF_COMPUTE_POOL';
SET PDF_SERVICE_NAME    = 'GOTENBERG_PDF_SERVICE';
SET PDF_IMAGE_REPO      = 'GOTENBERG_REPO';
SET PDF_EAI_NAME        = 'PDF_API_EAI';

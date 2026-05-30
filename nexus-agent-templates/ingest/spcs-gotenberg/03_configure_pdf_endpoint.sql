-- ═══════════════════════════════════════════════════════════════════
-- SPCS → PDF External Access Integration (run AFTER service is READY)
-- Run as ACCOUNTADMIN (network rule + EAI) then deploy role for PIPELINE_CONFIG.
--
-- Prerequisites:
--   SHOW ENDPOINTS IN SERVICE GOTENBERG_PDF_SERVICE;
--   Copy ingress_url from the pdfapi endpoint row.
-- ═══════════════════════════════════════════════════════════════════

USE ROLE ACCOUNTADMIN;

-- ── EDIT THESE TWO VALUES from SHOW ENDPOINTS ─────────────────────
-- Example ingress_url: https://abc123xyz.svc.sfc-aws.snowflakecomputing.app
SET PDF_SPCS_ENDPOINT = 'https://YOUR-ENDPOINT.svc.sfc-aws.snowflakecomputing.app';
SET PDF_SPCS_HOST     = 'YOUR-ENDPOINT.svc.sfc-aws.snowflakecomputing.app';

-- ── Create PDF API network rule + EAI (real SPCS host) ────────────
CREATE OR REPLACE NETWORK RULE PDF_API_NETWORK_RULE
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('YOUR-ENDPOINT.svc.sfc-aws.snowflakecomputing.app:443');

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION PDF_API_EAI
  ALLOWED_NETWORK_RULES = (PDF_API_NETWORK_RULE)
  ENABLED = TRUE
  COMMENT = 'Egress to Gotenberg PDF service on SPCS';

-- Grant to your deploy role (adjust role name if not SYSADMIN)
GRANT USAGE ON INTEGRATION PDF_API_EAI TO ROLE SYSADMIN;

-- ── Wire PIPELINE_CONFIG for EXPORT_PROPOSAL ──────────────────────
USE ROLE IDENTIFIER($DEPLOY_ROLE);
USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

UPDATE PIPELINE_CONFIG
SET CONFIG_VALUE = $PDF_SPCS_ENDPOINT,
    UPDATED_AT = CURRENT_TIMESTAMP()
WHERE CONFIG_KEY = 'PDF_API_BASE_URL';

UPDATE PIPELINE_CONFIG
SET CONFIG_VALUE = 'true',
    UPDATED_AT = CURRENT_TIMESTAMP()
WHERE CONFIG_KEY = 'PDF_API_ENABLED';

SELECT CONFIG_KEY, CONFIG_VALUE, UPDATED_AT
FROM PIPELINE_CONFIG
WHERE CONFIG_KEY IN ('PDF_API_BASE_URL', 'PDF_API_ENABLED');

-- Verify
DESCRIBE NETWORK RULE PDF_API_NETWORK_RULE;
DESCRIBE INTEGRATION PDF_API_EAI;

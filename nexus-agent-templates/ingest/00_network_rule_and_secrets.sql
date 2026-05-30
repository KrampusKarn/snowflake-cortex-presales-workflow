-- ═══════════════════════════════════════════════════════════════════
-- External Access: Google Drive + PDF API
-- Run as ACCOUNTADMIN or role with CREATE INTEGRATION privilege.
-- Replace host/port values before executing.
-- ═══════════════════════════════════════════════════════════════════

-- ── Google Drive API ─────────────────────────────────────────────
CREATE NETWORK RULE IF NOT EXISTS GOOGLE_DRIVE_NETWORK_RULE
  TYPE = HOST_PORT
  MODE = EGRESS
  VALUE_LIST = ('www.googleapis.com:443', 'oauth2.googleapis.com:443');

CREATE EXTERNAL ACCESS INTEGRATION IF NOT EXISTS GOOGLE_DRIVE_EAI
  ALLOWED_NETWORK_RULES = (GOOGLE_DRIVE_NETWORK_RULE)
  ENABLED = TRUE;

-- Store service account JSON in a secret (run once, replace placeholder):
-- CREATE OR REPLACE SECRET GOOGLE_DRIVE_SERVICE_ACCOUNT
--   TYPE = GENERIC_STRING
--   SECRET_STRING = '<paste service account JSON>';

-- GRANT USAGE ON INTEGRATION GOOGLE_DRIVE_EAI TO ROLE SYSADMIN;
-- GRANT READ ON SECRET GOOGLE_DRIVE_SERVICE_ACCOUNT TO ROLE SYSADMIN;

-- ── PDF API (Gotenberg on SPCS) ──────────────────────────────────
-- Do NOT create PDF EAI here. Deploy SPCS first, then run:
--   ingest/spcs-gotenberg/03_configure_pdf_endpoint.sql
-- with the real ingress_url from SHOW ENDPOINTS IN SERVICE GOTENBERG_PDF_SERVICE;

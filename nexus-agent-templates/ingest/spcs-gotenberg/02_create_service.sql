-- ═══════════════════════════════════════════════════════════════════
-- SPCS: Deploy Gotenberg as a long-running service
-- Prerequisites:
--   1. push_gotenberg_image.sh completed (gotenberg:8 in repo)
--   2. PUT gotenberg_service_spec.yaml to @SPCS_SPECS/spcs-gotenberg/
--      SnowSQL: PUT file://gotenberg_service_spec.yaml @SPCS_SPECS/spcs-gotenberg/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
-- ═══════════════════════════════════════════════════════════════════

USE ROLE IDENTIFIER($DEPLOY_ROLE);
USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

CREATE SERVICE IF NOT EXISTS GOTENBERG_PDF_SERVICE
  IN COMPUTE POOL PDF_COMPUTE_POOL
  FROM @SPCS_SPECS/spcs-gotenberg
  SPECIFICATION_TEMPLATE_FILE = 'gotenberg_service_spec.yaml'
  USING (
    DEPLOY_DATABASE => $DEPLOY_DATABASE,
    DEPLOY_SCHEMA   => $DEPLOY_SCHEMA,
    IMAGE_REPO_NAME => 'GOTENBERG_REPO'
  )
  MIN_INSTANCES = 1
  MAX_INSTANCES = 1
  AUTO_RESUME = TRUE
  COMMENT = 'Gotenberg HTML→PDF for pre-sales export';

-- Wait until service is READY, then run 03_configure_pdf_endpoint.sql
SHOW SERVICES LIKE 'GOTENBERG_PDF_SERVICE';
SHOW ENDPOINTS IN SERVICE GOTENBERG_PDF_SERVICE;

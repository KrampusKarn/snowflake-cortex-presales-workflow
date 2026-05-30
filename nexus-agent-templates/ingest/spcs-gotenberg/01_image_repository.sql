-- ═══════════════════════════════════════════════════════════════════
-- SPCS: Image repository for Gotenberg container
-- After this script: run push_gotenberg_image.sh (see README)
-- ═══════════════════════════════════════════════════════════════════

USE ROLE IDENTIFIER($DEPLOY_ROLE);
USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);

CREATE IMAGE REPOSITORY IF NOT EXISTS GOTENBERG_REPO
  COMMENT = 'Gotenberg PDF converter image for EXPORT_PROPOSAL';

SHOW IMAGE REPOSITORIES LIKE 'GOTENBERG_REPO';

-- Copy repository_url from output, then run:
--   ./push_gotenberg_image.sh <repository_url>

-- ═══════════════════════════════════════════════════════════════════
-- Client document stage + registry tables
-- Layout on stage:
--   @CLIENT_DOCS/{client_name}/asset/     ← synced from Google Drive
--   @CLIENT_DOCS/{client_name}/working/   ← per-run markdown intermediates
--   @CLIENT_DOCS/{client_name}/final/     ← client-ready PDFs + exports
-- ═══════════════════════════════════════════════════════════════════

USE ROLE IDENTIFIER($DEPLOY_ROLE);
USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);
USE WAREHOUSE IDENTIFIER($DEPLOY_WAREHOUSE);

CREATE STAGE IF NOT EXISTS CLIENT_DOCS
  DIRECTORY = (ENABLE = TRUE)
  COMMENT = 'Client assets: asset/, working/{run_id}/, final/';

-- Active clients for scheduled Drive sync
CREATE TABLE IF NOT EXISTS CLIENTS (
    CLIENT_NAME         VARCHAR PRIMARY KEY COMMENT 'Slug, e.g. easia-hub — matches Drive folder name',
    DISPLAY_NAME        VARCHAR,
    DRIVE_FOLDER_ID     VARCHAR COMMENT 'Google Drive folder ID for {client}/asset/',
    ACTIVE              BOOLEAN DEFAULT TRUE,
    CREATED_AT          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Tracks synced files to avoid re-download
CREATE TABLE IF NOT EXISTS CLIENT_FILES (
    FILE_ID             VARCHAR DEFAULT UUID_STRING(),
    CLIENT_NAME         VARCHAR NOT NULL,
    FILE_NAME           VARCHAR NOT NULL,
    STAGE_PATH          VARCHAR NOT NULL COMMENT 'Full stage path relative to CLIENT_DOCS',
    DRIVE_FILE_ID       VARCHAR,
    DRIVE_MODIFIED_TIME TIMESTAMP_NTZ,
    FILE_SIZE           NUMBER,
    CONTENT_TYPE        VARCHAR,
    SYNCED_AT           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UNIQUE (CLIENT_NAME, FILE_NAME)
);

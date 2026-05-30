-- ═══════════════════════════════════════════════════════════════════
-- Scheduled Drive sync — loops active clients daily
-- ═══════════════════════════════════════════════════════════════════

USE DATABASE IDENTIFIER($DEPLOY_DATABASE);
USE SCHEMA IDENTIFIER($DEPLOY_SCHEMA);
USE WAREHOUSE IDENTIFIER($DEPLOY_WAREHOUSE);

CREATE OR REPLACE PROCEDURE SYNC_ALL_ACTIVE_CLIENTS()
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
DECLARE
    results VARIANT DEFAULT ARRAY_CONSTRUCT();
    client_name VARCHAR;
    sync_result VARIANT;
    c CURSOR FOR SELECT CLIENT_NAME FROM CLIENTS WHERE ACTIVE = TRUE;
BEGIN
    FOR rec IN c DO
        client_name := rec.CLIENT_NAME;
        CALL SYNC_CLIENT_ASSETS(:client_name) INTO :sync_result;
        results := ARRAY_APPEND(results, OBJECT_CONSTRUCT('client', client_name, 'result', sync_result));
    END FOR;
    RETURN OBJECT_CONSTRUCT('status', 'SUCCESS', 'clients_synced', ARRAY_SIZE(results), 'details', results);
END;
$$;

CREATE TASK IF NOT EXISTS TASK_SYNC_CLIENT_ASSETS
  WAREHOUSE = IDENTIFIER($DEPLOY_WAREHOUSE)
  SCHEDULE = 'USING CRON 0 6 * * * UTC'
  COMMENT = 'Daily Google Drive → CLIENT_DOCS sync for active clients'
AS
  CALL SYNC_ALL_ACTIVE_CLIENTS();

-- ALTER TASK TASK_SYNC_CLIENT_ASSETS RESUME;

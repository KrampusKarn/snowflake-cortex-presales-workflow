-- ============================================================
-- RUN_SKILL — backward-compatible alias for EXECUTE_SKILL_TASK
-- ============================================================
-- Prefer 03_execute_skill_task.sql (WORKER_AGENT + native Git skills).
-- ============================================================

CREATE OR REPLACE PROCEDURE SPS_BUSINESS_INSIGHT.NEXUS.RUN_SKILL(
    RUN_ID_INPUT VARCHAR,
    SKILL_NAME_INPUT VARCHAR,
    TASK_DESCRIPTION VARCHAR,
    ADDITIONAL_CONTEXT VARCHAR DEFAULT NULL
)
RETURNS VARIANT
LANGUAGE SQL
EXECUTE AS CALLER
AS
$$
    CALL SPS_BUSINESS_INSIGHT.NEXUS.EXECUTE_SKILL_TASK(
        :RUN_ID_INPUT,
        :SKILL_NAME_INPUT,
        :TASK_DESCRIPTION,
        :ADDITIONAL_CONTEXT
    )
$$;

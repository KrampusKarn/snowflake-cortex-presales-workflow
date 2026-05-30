-- ============================================================
-- GET_WORKFLOW_STATE — Read the current state of a workflow run
-- ============================================================
-- Called by the Master Orchestrator at the start of every turn
-- to understand where the workflow is and what has been completed.
--
-- Usage:
--   CALL SPS_BUSINESS_INSIGHT.NEXUS.GET_WORKFLOW_STATE('<run_id>');
-- ============================================================

CREATE OR REPLACE PROCEDURE SPS_BUSINESS_INSIGHT.NEXUS.GET_WORKFLOW_STATE(
    RUN_ID_INPUT VARCHAR
)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'get_workflow_state'
EXECUTE AS CALLER
AS
$$
def get_workflow_state(session, run_id_input):
    """Read the full state of a workflow run including all completed outputs."""
    try:
        # 1. Read the main state row
        state_rows = session.sql("""
            SELECT RUN_ID, PROJECT_NAME, CLIENT_NAME, CURRENT_STAGE, STAGE_STATUS,
                   REVIEW_GATE_PENDING, RETRY_COUNT, MAX_RETRIES,
                   EXPORT_STATUS, SEARCH_INDEXED, FINAL_STAGE_PATH,
                   CASE WHEN BRIEF_CONTENT IS NOT NULL THEN TRUE ELSE FALSE END AS HAS_BRIEF,
                   CREATED_AT, UPDATED_AT
            FROM SPS_BUSINESS_INSIGHT.NEXUS.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        if not state_rows:
            return {'status': 'ERROR', 'error': f'Run ID "{run_id_input}" not found'}

        row = state_rows[0]

        # 2. Get summary of all stage outputs
        output_rows = session.sql("""
            SELECT STAGE_NUMBER, AGENT_NAME, EVALUATION_STATUS, EXECUTION_ORDER
            FROM SPS_BUSINESS_INSIGHT.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ?
            ORDER BY STAGE_NUMBER, EXECUTION_ORDER
        """, params=[run_id_input]).collect()

        outputs_summary = []
        for o in output_rows:
            outputs_summary.append({
                'stage': o['STAGE_NUMBER'],
                'agent': o['AGENT_NAME'],
                'status': o['EVALUATION_STATUS'],
                'order': o['EXECUTION_ORDER']
            })

        # 3. Get stages that are fully completed (all outputs PASS)
        completed_stages = session.sql("""
            SELECT DISTINCT STAGE_NUMBER
            FROM SPS_BUSINESS_INSIGHT.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ?
              AND EVALUATION_STATUS = 'PASS'
            ORDER BY STAGE_NUMBER
        """, params=[run_id_input]).collect()

        completed_list = [r['STAGE_NUMBER'] for r in completed_stages]

        return {
            'status': 'SUCCESS',
            'run_id': row['RUN_ID'],
            'project_name': row['PROJECT_NAME'],
            'client_name': row['CLIENT_NAME'],
            'export_status': row['EXPORT_STATUS'],
            'search_indexed': row['SEARCH_INDEXED'],
            'final_stage_path': row['FINAL_STAGE_PATH'],
            'current_stage': row['CURRENT_STAGE'],
            'stage_status': row['STAGE_STATUS'],
            'review_gate_pending': row['REVIEW_GATE_PENDING'],
            'retry_count': row['RETRY_COUNT'],
            'max_retries': row['MAX_RETRIES'],
            'has_brief': row['HAS_BRIEF'],
            'completed_stages': completed_list,
            'outputs': outputs_summary
        }

    except Exception as e:
        return {
            'status': 'ERROR',
            'error': 'Failed to read workflow state',
            'detail': str(e)
        }
$$;

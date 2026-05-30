CREATE OR REPLACE PROCEDURE "ADVANCE_STAGE"("RUN_ID" VARCHAR, "USER_APPROVED" BOOLEAN DEFAULT FALSE)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'advance_stage'
EXECUTE AS CALLER
AS '
def advance_stage(session, run_id_input, user_approved):
    """Advance the workflow to the next stage, enforcing review gates."""

    # Review gates: stages where user must approve before proceeding
    REVIEW_GATES = {1, 3, 6, 7}

    # Stage names for user-friendly messaging
    STAGE_NAMES = {
        1: ''RFP Analysis (Brief Generation)'',
        2: ''Research & Discovery'',
        3: ''Product Definition (Scope Lock)'',
        4: ''Design Direction'',
        5: ''Technical Strategy'',
        6: ''Estimation & Pricing (Commercial)'',
        7: ''Quality Gate & Review'',
        8: ''Final Packaging''
    }

    try:
        # 1. Read current state
        state_rows = session.sql("""
            SELECT CURRENT_STAGE, STAGE_STATUS, REVIEW_GATE_PENDING
            FROM DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        if not state_rows:
            return {''status'': ''ERROR'', ''error'': f''Run "{run_id_input}" not found''}

        current_stage = state_rows[0][''CURRENT_STAGE'']
        stage_status = state_rows[0][''STAGE_STATUS'']
        gate_pending = state_rows[0][''REVIEW_GATE_PENDING'']

        # 2. Verify all outputs for this stage have passed evaluation
        pending_outputs = session.sql("""
            SELECT COUNT(*) AS CNT
            FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND STAGE_NUMBER = ? AND EVALUATION_STATUS != ''PASS''
        """, params=[run_id_input, current_stage]).collect()

        if pending_outputs[0][''CNT''] > 0 and not gate_pending:
            return {
                ''status'': ''BLOCKED'',
                ''stage'': current_stage,
                ''message'': f''Cannot advance: {pending_outputs[0]["CNT"]} output(s) in Stage {current_stage} have not passed evaluation yet.''
            }

        # 3. Review gate logic
        if current_stage in REVIEW_GATES and not user_approved:
            # Set the review gate flag
            session.sql("""
                UPDATE DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
                SET REVIEW_GATE_PENDING = TRUE,
                    STAGE_STATUS = ''AWAITING_REVIEW'',
                    UPDATED_AT = CURRENT_TIMESTAMP()
                WHERE RUN_ID = ?
            """, params=[run_id_input]).collect()

            stage_name = STAGE_NAMES.get(current_stage, f''Stage {current_stage}'')
            return {
                ''status'': ''REVIEW_GATE'',
                ''stage'': current_stage,
                ''stage_name'': stage_name,
                ''message'': f''Stage {current_stage} ({stage_name}) is complete. User approval is required before advancing to Stage {current_stage + 1}.''
            }

        # 4. Check if workflow is complete (Stage 8 done)
        if current_stage >= 8:
            session.sql("""
                UPDATE DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
                SET STAGE_STATUS = ''COMPLETED'',
                    REVIEW_GATE_PENDING = FALSE,
                    EXPORT_STATUS = CASE
                        WHEN EXPORT_STATUS IN (''COMPLETED'', ''COMPLETED_MD_ONLY'') THEN EXPORT_STATUS
                        ELSE ''PENDING''
                    END,
                    UPDATED_AT = CURRENT_TIMESTAMP()
                WHERE RUN_ID = ?
            """, params=[run_id_input]).collect()

            return {
                ''status'': ''WORKFLOW_COMPLETE'',
                ''export_status'': ''PENDING'',
                ''message'': ''All 8 stages completed. Call export_proposal(run_id) to generate client-ready PDFs, then ask the user if they want to index final assets for Cortex Search.''
            }

        # 5. Advance to next stage
        next_stage = current_stage + 1
        next_name = STAGE_NAMES.get(next_stage, f''Stage {next_stage}'')

        session.sql("""
            UPDATE DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
            SET CURRENT_STAGE = ?,
                STAGE_STATUS = ''NOT_STARTED'',
                REVIEW_GATE_PENDING = FALSE,
                RETRY_COUNT = 0,
                UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[next_stage, run_id_input]).collect()

        return {
            ''status'': ''ADVANCED'',
            ''previous_stage'': current_stage,
            ''new_stage'': next_stage,
            ''new_stage_name'': next_name,
            ''message'': f''Advanced to Stage {next_stage}: {next_name}.''
        }

    except Exception as e:
        return {
            ''status'': ''ERROR'',
            ''error'': ''Failed to advance stage'',
            ''detail'': str(e)
        }
';

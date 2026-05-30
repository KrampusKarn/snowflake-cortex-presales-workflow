-- ═══════════════════════════════════════════════════════════════════
-- INDEX_FINAL_ASSETS — Populate Cortex Search tables after user confirms
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE PROCEDURE INDEX_FINAL_ASSETS(RUN_ID_INPUT VARCHAR)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'index_final_assets'
EXECUTE AS CALLER
AS
$$
DB = "SPS_BUSINESS_INSIGHT"
SCHEMA = "NEXUS"


def index_final_assets(session, run_id_input):
    try:
        state = session.sql(f"""
            SELECT CLIENT_NAME, PROJECT_NAME FROM {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()
        if not state:
            return {"status": "ERROR", "error": f"Run '{run_id_input}' not found"}
        client = state[0]["CLIENT_NAME"] or state[0]["PROJECT_NAME"].lower().replace(" ", "-")
        project = state[0]["PROJECT_NAME"]

        outputs = session.sql(f"""
            SELECT STAGE_NUMBER, SKILL_NAME, OUTPUT_CONTENT, STAGE_FILE_PATH
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = 'PASS'
            ORDER BY STAGE_NUMBER, EXECUTION_ORDER
        """, params=[run_id_input]).collect()

        indexed_outputs = 0
        indexed_deck = 0

        for o in outputs:
            stage_label = f"stage_{o['STAGE_NUMBER']:02d}"
            title = f"{o['SKILL_NAME']} (Stage {o['STAGE_NUMBER']})"
            session.sql(f"""
                INSERT INTO {DB}.{SCHEMA}.WORKFLOW_OUTPUTS
                    (PROJECT_ID, CLIENT_NAME, RUN_ID, STAGE, SKILL_NAME, TITLE, CONTENT, SOURCE_PATH)
                SELECT ?, ?, ?, ?, ?, ?, ?, ?
            """, params=[
                project, client, run_id_input, stage_label,
                o["SKILL_NAME"], title, o["OUTPUT_CONTENT"], o.get("STAGE_FILE_PATH"),
            ]).collect()
            indexed_outputs += 1

            if o["SKILL_NAME"] in ("generating-proposal-deck-outline", "generating-executive-summary"):
                section = "executive-summary" if "executive" in o["SKILL_NAME"] else "deck-outline"
                session.sql(f"""
                    INSERT INTO {DB}.{SCHEMA}.PROPOSAL_DECK
                        (PROJECT_ID, CLIENT_NAME, RUN_ID, SLIDE_OR_SECTION, TITLE, CONTENT)
                    SELECT ?, ?, ?, ?, ?, ?
                """, params=[
                    project, client, run_id_input, section, title, o["OUTPUT_CONTENT"],
                ]).collect()
                indexed_deck += 1

        session.sql(f"""
            UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            SET SEARCH_INDEXED = TRUE, UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        session.sql(f"ALTER CORTEX SEARCH SERVICE {DB}.{SCHEMA}.WORKFLOW_OUTPUTS_SEARCH REFRESH").collect()
        session.sql(f"ALTER CORTEX SEARCH SERVICE {DB}.{SCHEMA}.PROPOSAL_DECK_SEARCH REFRESH").collect()
        session.sql(f"ALTER CORTEX SEARCH SERVICE {DB}.{SCHEMA}.SOURCE_DOCUMENTS_SEARCH REFRESH").collect()

        return {
            "status": "SUCCESS",
            "run_id": run_id_input,
            "workflow_outputs_indexed": indexed_outputs,
            "deck_sections_indexed": indexed_deck,
            "search_indexed": True,
        }
    except Exception as e:
        return {"status": "ERROR", "error": str(e)}
$$;

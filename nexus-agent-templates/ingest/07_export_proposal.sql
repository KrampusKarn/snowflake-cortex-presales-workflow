-- ═══════════════════════════════════════════════════════════════════
-- EXPORT_PROPOSAL — Assemble markdown → PDF via External Access (Gotenberg)
-- Fallback: writes markdown bundle to @CLIENT_DOCS/{client}/final/
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE PROCEDURE EXPORT_PROPOSAL(RUN_ID_INPUT VARCHAR)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python', 'requests')
HANDLER = 'export_proposal'
EXECUTE AS CALLER
EXTERNAL_ACCESS_INTEGRATIONS = (PDF_API_EAI)
AS
$$
import io
import json
import requests

DB = "SPS_BUSINESS_INSIGHT"
SCHEMA = "NEXUS"
STAGE = f"@{DB}.{SCHEMA}.CLIENT_DOCS"


def export_proposal(session, run_id_input):
    try:
        state = session.sql(f"""
            SELECT CLIENT_NAME, PROJECT_NAME FROM {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()
        if not state:
            return {"status": "ERROR", "error": f"Run '{run_id_input}' not found"}
        client = state[0]["CLIENT_NAME"] or state[0]["PROJECT_NAME"].lower().replace(" ", "-")
        project = state[0]["PROJECT_NAME"]

        session.sql(f"""
            UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            SET EXPORT_STATUS = 'IN_PROGRESS', UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        outputs = session.sql(f"""
            SELECT STAGE_NUMBER, SKILL_NAME, OUTPUT_CONTENT
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = 'PASS'
            ORDER BY STAGE_NUMBER, EXECUTION_ORDER
        """, params=[run_id_input]).collect()

        sections = [f"# Proposal: {project}\n\n**Run ID:** {run_id_input}\n"]
        for o in outputs:
            sections.append(f"\n\n---\n\n## Stage {o['STAGE_NUMBER']}: {o['SKILL_NAME']}\n\n{o['OUTPUT_CONTENT']}")
        bundle = "\n".join(sections)

        md_rel = f"{client}/working/{run_id_input}/proposal-bundle.md"
        final_md_rel = f"{client}/final/proposal-{run_id_input}.md"
        final_pdf_rel = f"{client}/final/proposal-{run_id_input}.pdf"

        session.file.put_stream(
            io.BytesIO(bundle.encode("utf-8")),
            f"{STAGE}/{md_rel}",
            auto_compress=False,
            overwrite=True,
        )
        session.file.put_stream(
            io.BytesIO(bundle.encode("utf-8")),
            f"{STAGE}/{final_md_rel}",
            auto_compress=False,
            overwrite=True,
        )

        pdf_created = False
        pdf_api_base = None
        pdf_enabled = False

        config_rows = session.sql(f"""
            SELECT CONFIG_KEY, CONFIG_VALUE FROM {DB}.{SCHEMA}.PIPELINE_CONFIG
            WHERE CONFIG_KEY IN ('PDF_API_BASE_URL', 'PDF_API_ENABLED')
        """).collect()
        config = {r['CONFIG_KEY']: r['CONFIG_VALUE'] for r in config_rows}
        pdf_enabled = str(config.get('PDF_API_ENABLED', '')).lower() == 'true'
        pdf_api_base = (config.get('PDF_API_BASE_URL') or '').strip().rstrip('/')

        if pdf_enabled and pdf_api_base and 'your-gotenberg' not in pdf_api_base:
            try:
                html = (
                    "<!DOCTYPE html><html><head><meta charset='utf-8'>"
                    "<style>body{font-family:sans-serif;max-width:900px;margin:2em auto;padding:0 1em;}"
                    "pre{white-space:pre-wrap;}</style></head><body><pre>"
                    + bundle.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                    + "</pre></body></html>"
                )
                resp = requests.post(
                    f"{pdf_api_base}/forms/chromium/convert/html",
                    files={"index.html": ("index.html", html.encode("utf-8"), "text/html")},
                    timeout=120,
                )
                if resp.status_code == 200:
                    session.file.put_stream(
                        io.BytesIO(resp.content),
                        f"{STAGE}/{final_pdf_rel}",
                        auto_compress=False,
                        overwrite=True,
                    )
                    pdf_created = True
            except Exception:
                pdf_created = False

        export_status = "COMPLETED" if pdf_created else "COMPLETED_MD_ONLY"
        session.sql(f"""
            UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            SET EXPORT_STATUS = ?, FINAL_STAGE_PATH = ?,
                UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[export_status, f"{STAGE}/{client}/final/", run_id_input]).collect()

        return {
            "status": "SUCCESS",
            "export_status": export_status,
            "client_name": client,
            "markdown_path": f"{STAGE}/{final_md_rel}",
            "pdf_path": f"{STAGE}/{final_pdf_rel}" if pdf_created else None,
            "pdf_created": pdf_created,
            "message": "PDF exported." if pdf_created else (
                "Markdown exported to final/. Enable PDF via SPCS Gotenberg (see ingest/spcs-gotenberg/README.md)."
                if not pdf_enabled else
                "Markdown exported. PDF call failed — check PIPELINE_CONFIG and PDF_API_EAI network rule."
            ),
        }
    except Exception as e:
        session.sql(f"""
            UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            SET EXPORT_STATUS = 'FAILED', UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()
        return {"status": "ERROR", "error": str(e)}
$$;

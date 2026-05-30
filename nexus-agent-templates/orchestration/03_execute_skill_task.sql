CREATE OR REPLACE PROCEDURE "EXECUTE_SKILL_TASK"("RUN_ID" VARCHAR, "SKILL_NAME" VARCHAR, "TASK_DESCRIPTION" VARCHAR, "ADDITIONAL_CONTEXT" VARCHAR DEFAULT null)
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'execute_skill_task'
EXECUTE AS CALLER
AS '
import json
import io
import re
import _snowflake

DB = "DEMO_SPS_CORTEX"
SCHEMA = "NEXUS"
STAGE = f"@{DB}.{SCHEMA}.CLIENT_DOCS"
API_TIMEOUT = 600000
WORKER_ENDPOINT = f"/api/v2/databases/{DB}/schemas/{SCHEMA}/agents/WORKER_AGENT:run"

# Context shrink caps (prompt only — full output still stored in STAGE_OUTPUTS)
RFP_CAP = 12000
BRIEF_CAP_EARLY = 6000
BRIEF_CAP_LATE = 8000
PRIOR_OUTPUT_CAP = 1500
FEEDBACK_CAP = 2000
SEARCH_FQN = f"{DB}.{SCHEMA}.SOURCE_DOCUMENTS_SEARCH"
SEARCH_CHUNK_PROMPT_CAP = 1200


def _search_config(session):
    rows = session.sql(f"""
        SELECT CONFIG_KEY, CONFIG_VALUE FROM {DB}.{SCHEMA}.PIPELINE_CONFIG
        WHERE CONFIG_KEY IN (''HARNESS_SEARCH_ENABLED'', ''HARNESS_SEARCH_TOP_K'', ''SOURCE_DOCUMENTS_SEARCH_FQN'')
    """).collect()
    cfg = {r["CONFIG_KEY"]: r["CONFIG_VALUE"] for r in rows}
    return {
        "enabled": str(cfg.get("HARNESS_SEARCH_ENABLED", "true")).lower() == "true",
        "top_k": int(cfg.get("HARNESS_SEARCH_TOP_K", "8") or 8),
        "search_fqn": (cfg.get("SOURCE_DOCUMENTS_SEARCH_FQN") or SEARCH_FQN).strip(),
    }


def _parse_search_results(raw):
    if raw is None:
        return []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return []
    if isinstance(raw, list):
        return raw
    if isinstance(raw, dict):
        for key in ("results", "data", "response", "chunks"):
            val = raw.get(key)
            if isinstance(val, list):
                return val
    return []


def _search_filter(client_name, run_id, current_stage):
    stage = int(current_stage)
    base = {"@eq": {"CLIENT_NAME": client_name}}
    if stage == 1:
        return {"@and": [base, {"@eq": {"SOURCE_KIND": "ingest"}}]}
    return {
        "@and": [
            base,
            {"@or": [
                {"@and": [
                    {"@eq": {"RUN_ID": run_id}},
                    {"@or": [
                        {"@eq": {"DOC_TYPE": "brief"}},
                        {"@eq": {"DOC_TYPE": "skill_output"}},
                    ]},
                ]},
                {"@and": [
                    {"@eq": {"SOURCE_KIND": "ingest"}},
                    {"@eq": {"DOC_TYPE": "rfp"}},
                ]},
            ]},
        ]
    }


def _search_harness_context(session, cfg, client_name, run_id, current_stage, skill_name, task_description):
    query = f"{skill_name}: {task_description}".strip()
    params = json.dumps({
        "query": query,
        "limit": cfg["top_k"],
        "columns": ["CONTENT", "TITLE", "DOC_TYPE", "FILE_NAME", "CHUNK_INDEX", "SKILL_NAME"],
        "filter": _search_filter(client_name, run_id, current_stage),
    })
    rows = session.sql(
        "SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(?, ?) AS RESULTS",
        params=[cfg["search_fqn"], params],
    ).collect()
    if not rows:
        return [], query
    raw = rows[0]["RESULTS"]
    hits = _parse_search_results(raw)
    parts = []
    for hit in hits:
        if not isinstance(hit, dict):
            continue
        content = hit.get("CONTENT") or hit.get("content") or ""
        if not content:
            continue
        title = hit.get("TITLE") or hit.get("title") or "chunk"
        doc_type = hit.get("DOC_TYPE") or hit.get("doc_type") or ""
        parts.append(_truncate(content, SEARCH_CHUNK_PROMPT_CAP, "search chunk truncated"))
    return parts, query


def _truncate(text, limit, label="truncated for context window"):
    if not text:
        return ""
    text = str(text)
    if limit <= 0 or len(text) <= limit:
        return text
    return text[:limit] + f"\\n\\n[... {label} ...]"


def _brief_cap(stage):
    return BRIEF_CAP_LATE if int(stage) >= 6 else BRIEF_CAP_EARLY


def _load_prior_outputs(session, run_id_input, current_stage):
    """Stage-aware prior outputs — avoids sending entire workflow history to Worker."""
    stage = int(current_stage)
    if stage == 1:
        return []

    if stage <= 5:
        return session.sql(f"""
            SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = ''PASS'' AND STAGE_NUMBER = ?
            ORDER BY EXECUTION_ORDER
        """, params=[run_id_input, stage]).collect()

    if stage == 6:
        return session.sql(f"""
            SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = ''PASS'' AND STAGE_NUMBER IN (4, 5, 6)
            ORDER BY STAGE_NUMBER, EXECUTION_ORDER
        """, params=[run_id_input]).collect()

    if stage == 7:
        return session.sql(f"""
            SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = ''PASS'' AND STAGE_NUMBER < 7
            ORDER BY STAGE_NUMBER DESC, EXECUTION_ORDER DESC
            LIMIT 5
        """, params=[run_id_input]).collect()

    return session.sql(f"""
        SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
        FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
        WHERE RUN_ID = ? AND EVALUATION_STATUS = ''PASS'' AND STAGE_NUMBER IN (6, 7)
        ORDER BY STAGE_NUMBER, EXECUTION_ORDER
    """, params=[run_id_input]).collect()


def _is_missing_rfp(value):
    if value is None:
        return True
    text = str(value).strip()
    if not text:
        return True
    return text.lower() in ("null", "none", "undefined", "n/a")


def _load_source_documents(session, client_name):
    doc_rows = session.sql(f"""
        SELECT TITLE, DOC_TYPE, CONTENT
        FROM {DB}.{SCHEMA}.SOURCE_DOCUMENTS
        WHERE CLIENT_NAME = ?
        ORDER BY CASE DOC_TYPE
            WHEN ''rfp'' THEN 1 WHEN ''brief'' THEN 2 WHEN ''sow'' THEN 3 ELSE 4 END,
            CREATED_AT
    """, params=[client_name]).collect()

    if not doc_rows:
        return None

    parts = []
    for d in doc_rows:
        parts.append(f"## {d[''TITLE'']} ({d[''DOC_TYPE'']})\\n{d[''CONTENT'']}")
    return "\\n\\n---\\n\\n".join(parts)


def _resolve_rfp_input(session, run_id_input, client_name, rfp_input, brief):
    if not _is_missing_rfp(rfp_input) or brief:
        return rfp_input or ""

    loaded = _load_source_documents(session, client_name)
    if not loaded:
        return rfp_input or ""

    session.sql(f"""
        UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
        SET USER_RFP_INPUT = ?, UPDATED_AT = CURRENT_TIMESTAMP()
        WHERE RUN_ID = ?
    """, params=[loaded, run_id_input]).collect()
    return loaded


def _extract_agent_text(response_body):
    """Best-effort text extraction from Cortex Agent :run response."""
    if response_body is None:
        return ""
    if isinstance(response_body, bytes):
        response_body = response_body.decode("utf-8")
    if isinstance(response_body, dict):
        data = response_body
    else:
        try:
            data = json.loads(response_body)
        except (json.JSONDecodeError, TypeError):
            return str(response_body)

    if isinstance(data, str):
        return data

    for key in ("message", "final_message", "response"):
        if key in data and isinstance(data[key], str):
            return data[key]

    msg = data.get("message") or data.get("final_message")
    if isinstance(msg, dict):
        content = msg.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts = []
            for block in content:
                if isinstance(block, dict):
                    if block.get("type") == "text" and block.get("text"):
                        parts.append(block["text"])
                    elif block.get("content"):
                        parts.append(str(block["content"]))
            if parts:
                return "\\n".join(parts)

    choices = data.get("choices")
    if isinstance(choices, list) and choices:
        c0 = choices[0]
        if isinstance(c0, dict):
            messages = c0.get("messages") or c0.get("message")
            if isinstance(messages, dict) and messages.get("content"):
                return messages["content"]
            if isinstance(messages, str):
                return messages

    return json.dumps(data) if data else ""


def execute_skill_task(session, run_id_input, skill_name_input, task_description, additional_context):
    try:
        state_rows = session.sql(f"""
            SELECT BRIEF_CONTENT, CURRENT_STAGE, STAGE_STATUS, REVIEW_GATE_PENDING,
                   USER_RFP_INPUT, CLIENT_NAME, PROJECT_NAME
            FROM {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        if not state_rows:
            return {"status": "ERROR", "error": f''Run "{run_id_input}" not found''}

        brief = state_rows[0]["BRIEF_CONTENT"] or ""
        current_stage = int(state_rows[0]["CURRENT_STAGE"])
        review_gate_pending = bool(state_rows[0]["REVIEW_GATE_PENDING"])
        rfp_input = state_rows[0]["USER_RFP_INPUT"] or ""
        client_name = state_rows[0]["CLIENT_NAME"] or state_rows[0]["PROJECT_NAME"].lower().replace(" ", "-")

        if review_gate_pending:
            return {
                "status": "ERROR",
                "skill_name": skill_name_input,
                "error": f"Stage {current_stage} is complete and awaiting user review.",
                "current_stage": current_stage,
                "hint": (
                    "Do not execute more skills. Present the Stage summary to the user, then call "
                    "advance_stage(run_id, user_approved=''true'') after they approve."
                ),
            }

        if current_stage == 1:
            rfp_input = _resolve_rfp_input(session, run_id_input, client_name, rfp_input, brief)

        session.sql(f"""
            UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
            SET STAGE_STATUS = ''IN_PROGRESS'', UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        context_parts = [
            f"## Required skill\\nExecute the configured skill named exactly: `{skill_name_input}`",
        ]

        search_cfg = _search_config(session)
        search_hits = []
        search_query = None
        if search_cfg["enabled"]:
            try:
                search_hits, search_query = _search_harness_context(
                    session, search_cfg, client_name, run_id_input,
                    current_stage, skill_name_input, task_description,
                )
            except Exception:
                search_hits, search_query = [], None

        if search_hits:
            context_parts.append(
                "## Relevant Context (Cortex Search — top matches from client documents & workflow)\\n"
                + "\\n\\n---\\n\\n".join(
                    f"### Match {i + 1}\\n{chunk}" for i, chunk in enumerate(search_hits)
                )
            )
        elif current_stage == 1 and rfp_input and not _is_missing_rfp(rfp_input):
            context_parts.append(
                f"## Raw RFP / Client Input\\n{_truncate(rfp_input, RFP_CAP, ''RFP truncated'')}"
            )

        if brief and (current_stage > 1 or not search_hits):
            context_parts.append(
                f"## Project Brief (Single Source of Truth)\\n"
                f"{_truncate(brief, _brief_cap(current_stage), ''brief truncated'')}"
            )

        prior_outputs = _load_prior_outputs(session, run_id_input, current_stage)
        for row in prior_outputs:
            content = _truncate(row["OUTPUT_CONTENT"], PRIOR_OUTPUT_CAP, "prior output truncated")
            context_parts.append(
                f"## Prior Output: {row[''SKILL_NAME'']} (Stage {row[''STAGE_NUMBER'']})\\n{content}"
            )

        if additional_context:
            context_parts.append(
                f"## Evaluator Feedback (Address These Issues)\\n"
                f"{_truncate(additional_context, FEEDBACK_CAP, ''feedback truncated'')}"
            )

        context_parts.append(f"## Your Task\\n{task_description}")
        worker_prompt = "\\n\\n---\\n\\n".join(context_parts)
        prompt_chars = len(worker_prompt)

        request_body = {
            "stream": False,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": worker_prompt}],
                }
            ],
        }
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        resp = _snowflake.send_snow_api_request(
            "POST",
            WORKER_ENDPOINT,
            headers,
            {},
            request_body,
            None,
            API_TIMEOUT,
        )

        raw = resp.get("content", resp.get("body", resp))
        response_text = _extract_agent_text(raw).strip()

        if not response_text:
            return {
                "status": "ERROR",
                "skill_name": skill_name_input,
                "error": "WORKER_AGENT returned empty response",
                "detail": str(raw)[:2000],
            }

        order_row = session.sql(f"""
            SELECT COALESCE(MAX(EXECUTION_ORDER), 0) + 1 AS NEXT_ORDER
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND STAGE_NUMBER = ?
        """, params=[run_id_input, current_stage]).collect()
        next_order = order_row[0]["NEXT_ORDER"]

        existing_rows = session.sql(f"""
            SELECT OUTPUT_ID, EXECUTION_ORDER
            FROM {DB}.{SCHEMA}.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND STAGE_NUMBER = ? AND SKILL_NAME = ?
            ORDER BY CREATED_AT DESC, EXECUTION_ORDER DESC
            LIMIT 1
        """, params=[run_id_input, current_stage, skill_name_input]).collect()

        stage_file_path = None
        safe_name = skill_name_input.replace("/", "-")
        stage_rel = f"{client_name}/working/{run_id_input}/{safe_name}.md"
        try:
            session.file.put_stream(
                io.BytesIO(response_text.encode("utf-8")),
                f"{STAGE}/{stage_rel}",
                auto_compress=False,
                overwrite=True,
            )
            stage_file_path = stage_rel
        except Exception:
            pass

        if existing_rows:
            output_id = existing_rows[0]["OUTPUT_ID"]
            next_order = existing_rows[0]["EXECUTION_ORDER"]
            session.sql(f"""
                UPDATE {DB}.{SCHEMA}.STAGE_OUTPUTS
                SET OUTPUT_CONTENT = ?,
                    EVALUATION_STATUS = ''PENDING'',
                    EVALUATION_FEEDBACK = NULL,
                    STAGE_FILE_PATH = ?,
                    CREATED_AT = CURRENT_TIMESTAMP()
                WHERE OUTPUT_ID = ?
            """, params=[response_text, stage_file_path, output_id]).collect()
        else:
            session.sql(f"""
                INSERT INTO {DB}.{SCHEMA}.STAGE_OUTPUTS
                    (RUN_ID, STAGE_NUMBER, AGENT_NAME, SKILL_NAME, OUTPUT_CONTENT, EXECUTION_ORDER, STAGE_FILE_PATH)
                VALUES (?, ?, ''WORKER_AGENT'', ?, ?, ?, ?)
            """, params=[
                run_id_input, current_stage, skill_name_input,
                response_text, next_order, stage_file_path,
            ]).collect()

        if current_stage == 1 and "rfp-analyzer" in skill_name_input:
            session.sql(f"""
                UPDATE {DB}.{SCHEMA}.ORCHESTRATOR_STATE
                SET BRIEF_CONTENT = ?, UPDATED_AT = CURRENT_TIMESTAMP()
                WHERE RUN_ID = ?
            """, params=[response_text, run_id_input]).collect()
            if search_cfg["enabled"]:
                try:
                    session.sql(
                        f"CALL {DB}.{SCHEMA}.INDEX_HARNESS_CHUNKS(?, ?)",
                        params=[run_id_input, "brief"],
                    ).collect()
                except Exception:
                    pass

        return {
            "status": "SUCCESS",
            "skill_name": skill_name_input,
            "resolved_via": "worker_agent_git",
            "stage": current_stage,
            "response_preview": response_text[:1500],
            "full_length": len(response_text),
            "stage_file_path": stage_file_path,
            "prompt_chars": prompt_chars,
            "prior_outputs_included": len(prior_outputs),
            "search_hits": len(search_hits),
            "search_query": search_query,
            "message": (
                f''Skill "{skill_name_input}" executed via WORKER_AGENT at Stage {current_stage}. ''
                f''Call evaluate_output(run_id, skill_name, stage_number={current_stage}) before the next skill.''
            ),
        }

    except Exception as e:
        return {
            "status": "ERROR",
            "skill_name": skill_name_input,
            "error": f''Failed to execute skill "{skill_name_input}"'',
            "detail": str(e),
        }
';

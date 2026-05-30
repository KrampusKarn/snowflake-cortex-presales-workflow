CREATE OR REPLACE PROCEDURE "PLAN_STAGE"("RUN_ID" VARCHAR, "STAGE_NUMBER" NUMBER(38,0))
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'plan_stage'
EXECUTE AS CALLER
AS '
import json
import re
import _snowflake

API_TIMEOUT = 300000
AGENT_ENDPOINT = "/api/v2/databases/DEMO_SPS_CORTEX/schemas/NEXUS/agents/PLANNER_AGENT:run"

STAGE_NAMES = {
    1: ''RFP Analysis'',
    2: ''Research & Discovery'',
    3: ''Product Definition'',
    4: ''Design Direction'',
    5: ''Technical Strategy'',
    6: ''Estimation & Pricing'',
    7: ''Quality Gate & Review'',
    8: ''Final Packaging''
}


def _is_missing_rfp(value):
    if value is None:
        return True
    text = str(value).strip()
    if not text:
        return True
    return text.lower() in ("null", "none", "undefined", "n/a")


def _load_source_documents(session, client_name):
    doc_rows = session.sql("""
        SELECT TITLE, DOC_TYPE, CONTENT
        FROM DEMO_SPS_CORTEX.NEXUS.SOURCE_DOCUMENTS
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
    """Backfill USER_RFP_INPUT from SOURCE_DOCUMENTS when agent passed null literal."""
    if not _is_missing_rfp(rfp_input) or brief:
        return rfp_input or ""

    loaded = _load_source_documents(session, client_name)
    if not loaded:
        return rfp_input or ""

    session.sql("""
        UPDATE DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
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
                if isinstance(block, dict) and block.get("type") == "text" and block.get("text"):
                    parts.append(block["text"])
            if parts:
                return "\\n".join(parts)

    content = data.get("content")
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text" and block.get("text"):
                parts.append(block["text"])
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


def _count_tasks(plan_data):
    total = 0
    for step in plan_data.get("sub_steps", []):
        total += len(step.get("tasks", []))
    if not total and plan_data.get("tasks"):
        total = len(plan_data["tasks"])
    return total


def _normalize_plan(plan_data):
    if not isinstance(plan_data, dict):
        return None
    if "sub_steps" not in plan_data and plan_data.get("tasks"):
        return {
            "sub_steps": [{
                "name": "Main",
                "execution": "sequential",
                "tasks": plan_data["tasks"],
            }],
            "sprint_contract": plan_data.get("sprint_contract", ""),
            "has_review_gate": plan_data.get("has_review_gate", False),
        }
    return plan_data


def _parse_plan_json(response_body):
    """Extract a task plan JSON object from a Cortex Agent response."""
    sources = [_extract_agent_text(response_body), response_body]
    if isinstance(response_body, (dict, list)):
        sources.append(json.dumps(response_body))

    for source in sources:
        if source is None or source == "":
            continue

        candidates = []
        if isinstance(source, dict):
            candidates.append(source)
        else:
            src = str(source)
            try:
                candidates.append(json.loads(src))
            except (json.JSONDecodeError, TypeError):
                pass
            for match in re.finditer(r''\\{[\\s\\S]*\\}'', src):
                try:
                    candidates.append(json.loads(match.group()))
                except json.JSONDecodeError:
                    continue

        for candidate in candidates:
            if not isinstance(candidate, dict):
                continue
            if "content" in candidate and isinstance(candidate["content"], list):
                for block in candidate["content"]:
                    if isinstance(block, dict) and block.get("type") == "text" and block.get("text"):
                        nested = _parse_plan_json(block["text"])
                        if nested:
                            return nested
                continue
            normalized = _normalize_plan(candidate)
            if normalized and ("sub_steps" in normalized or normalized.get("tasks")):
                return normalized
    return None


STAGE_DEFAULT_PLANS = {
    1: {
        "sub_steps": [{
            "name": "RFP Analysis",
            "execution": "sequential",
            "tasks": [{
                "skill_name": "sales-rfp-analyzer",
                "description": "Analyze the ingested RFP and produce the Project Brief (Single Source of Truth).",
                "done_criteria": "Structured brief covering scope, objectives, timeline, budget, and constraints.",
            }],
        }],
        "sprint_contract": "Project Brief (SSOT) fully captures the RFP in structured markdown.",
        "has_review_gate": True,
    },
    7: {
        "sub_steps": [{
            "name": "Quality Gate",
            "execution": "sequential",
            "tasks": [{
                "skill_name": "proposal-quality-gate",
                "description": "Run the proposal quality gate against all prior stage outputs.",
                "done_criteria": "Quality gate report with pass/fail and remediation items.",
            }],
        }],
        "sprint_contract": "Quality gate validates completeness and consistency across all proposal sections.",
        "has_review_gate": True,
    },
}


def _default_plan_for_stage(stage_number):
    return STAGE_DEFAULT_PLANS.get(stage_number)


def plan_stage(session, run_id_input, stage_number_input):
    """Call PLANNER_AGENT to decompose a stage into tasks."""
    try:
        # ─────────────────────────────────────────────
        # 1. Read workflow state
        # ─────────────────────────────────────────────
        state_rows = session.sql("""
            SELECT BRIEF_CONTENT, USER_RFP_INPUT, CURRENT_STAGE, CLIENT_NAME
            FROM DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        if not state_rows:
            return {''status'': ''ERROR'', ''error'': f''Run "{run_id_input}" not found''}

        brief = state_rows[0][''BRIEF_CONTENT''] or ''''
        rfp_input = state_rows[0][''USER_RFP_INPUT''] or ''''
        client_name = state_rows[0][''CLIENT_NAME''] or ''''

        if stage_number_input == 1:
            rfp_input = _resolve_rfp_input(session, run_id_input, client_name, rfp_input, brief)
            if _is_missing_rfp(rfp_input) and not brief:
                return {
                    ''status'': ''ERROR'',
                    ''error'': ''No RFP or brief content available for Stage 1 planning.'',
                    ''hint'': ''Call ingest_client_assets for this client, then init_workflow again — or paste RFP text into rfp_content.''
                }

        # ─────────────────────────────────────────────
        # 2. Gather prior outputs summary for context
        # ─────────────────────────────────────────────
        prior_rows = session.sql("""
            SELECT SKILL_NAME, STAGE_NUMBER
            FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND EVALUATION_STATUS = ''PASS''
            ORDER BY STAGE_NUMBER
        """, params=[run_id_input]).collect()

        completed_skills = [f"- Stage {r[''STAGE_NUMBER'']}: {r[''SKILL_NAME'']}" for r in prior_rows]
        completed_summary = "\\n".join(completed_skills) if completed_skills else "None yet."

        # ─────────────────────────────────────────────
        # 3. Build the planning prompt
        # ─────────────────────────────────────────────
        stage_name = STAGE_NAMES.get(stage_number_input, f''Stage {stage_number_input}'')

        prompt = f"""Plan Stage {stage_number_input}: {stage_name}

## Project Brief
{brief if brief else rfp_input[:3000]}

## Already Completed
{completed_summary}

## Instructions
Create a detailed task plan for Stage {stage_number_input} ({stage_name}).
Return the plan as a JSON object with sub_steps, tasks, skill assignments, execution order, and sprint contract."""

        # ─────────────────────────────────────────────
        # 4. Call PLANNER_AGENT via :run API
        # ─────────────────────────────────────────────
        request_body = {
            "stream": False,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": prompt}],
                }
            ],
        }
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        resp = _snowflake.send_snow_api_request(
            "POST",
            AGENT_ENDPOINT,
            headers,
            {},
            request_body,
            None,
            API_TIMEOUT,
        )

        raw_response = resp.get("content", resp.get("body", resp))

        # ─────────────────────────────────────────────
        # 5. Parse the task plan from the response
        # ─────────────────────────────────────────────
        plan_data = _parse_plan_json(raw_response)
        plan_source = "planner_agent"

        if not plan_data or _count_tasks(plan_data) == 0:
            plan_data = _default_plan_for_stage(stage_number_input)
            if plan_data:
                plan_source = "stage_routing_default"

        if not plan_data or _count_tasks(plan_data) == 0:
            response_preview = _extract_agent_text(raw_response)[:3000]
            return {
                ''status'': ''ERROR'',
                ''error'': f''Planner returned no tasks for stage {stage_number_input}.'',
                ''raw_plan'': response_preview,
                ''hint'': ''Verify PLANNER_AGENT is deployed and returning JSON with sub_steps/tasks.''
            }

        # ─────────────────────────────────────────────
        # 6. Store the plan in ORCHESTRATOR_STATE metadata
        # ─────────────────────────────────────────────
        session.sql("""
            UPDATE DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
            SET METADATA = PARSE_JSON(?),
                STAGE_STATUS = ''IN_PROGRESS'',
                UPDATED_AT = CURRENT_TIMESTAMP()
            WHERE RUN_ID = ?
        """, params=[json.dumps(plan_data), run_id_input]).collect()

        # Count total tasks
        total_tasks = 0
        sub_steps = plan_data.get(''sub_steps'', [])
        for step in sub_steps:
            total_tasks += len(step.get(''tasks'', []))

        return {
            ''status'': ''SUCCESS'',
            ''stage'': stage_number_input,
            ''stage_name'': stage_name,
            ''sprint_contract'': plan_data.get(''sprint_contract'', ''''),
            ''sub_steps'': sub_steps,
            ''total_tasks'': total_tasks,
            ''has_review_gate'': plan_data.get(''has_review_gate'', False),
            ''parsed'': True,
            ''plan_source'': plan_source,
            ''message'': f''Stage {stage_number_input} planned: {total_tasks} tasks across {len(sub_steps)} sub-steps ({plan_source}).''
        }

    except Exception as e:
        return {
            ''status'': ''ERROR'',
            ''error'': f''Failed to plan stage {stage_number_input}'',
            ''detail'': str(e)
        }
';

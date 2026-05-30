CREATE OR REPLACE PROCEDURE "EVALUATE_OUTPUT"("RUN_ID" VARCHAR, "SKILL_NAME" VARCHAR, "STAGE_NUMBER" NUMBER(38,0))
RETURNS VARIANT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'evaluate_output'
EXECUTE AS CALLER
AS '
import json
import re
import _snowflake

API_TIMEOUT = 300000
EVALUATOR_ENDPOINT = "/api/v2/databases/DEMO_SPS_CORTEX/schemas/NEXUS/agents/EVALUATOR_AGENT:run"

# Review gates get fuller eval context; other stages use lite caps (prompt only)
REVIEW_GATE_STAGES = {1, 3, 6, 7}
EVAL_LITE = {"ref": 2500, "output": 6000, "cross_ref": 800, "max_cross": 3}
EVAL_FULL = {"ref": 5000, "output": 10000, "cross_ref": 1500, "max_cross": 5}
SPRINT_CONTRACT_CAP = 2000
SEARCH_FQN = "DEMO_SPS_CORTEX.NEXUS.SOURCE_DOCUMENTS_SEARCH"
SEARCH_REF_CHUNK_CAP = 800


def _search_config(session):
    rows = session.sql("""
        SELECT CONFIG_KEY, CONFIG_VALUE FROM DEMO_SPS_CORTEX.NEXUS.PIPELINE_CONFIG
        WHERE CONFIG_KEY IN (''HARNESS_SEARCH_ENABLED'', ''HARNESS_SEARCH_TOP_K'', ''SOURCE_DOCUMENTS_SEARCH_FQN'')
    """).collect()
    cfg = {r["CONFIG_KEY"]: r["CONFIG_VALUE"] for r in rows}
    return {
        "enabled": str(cfg.get("HARNESS_SEARCH_ENABLED", "true")).lower() == "true",
        "top_k": int(cfg.get("HARNESS_SEARCH_TOP_K", "5") or 5),
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


def _search_reference_context(session, cfg, client_name, run_id, stage_number, skill_name, reference_doc, ref_cap):
    fallback = _truncate(reference_doc, ref_cap, "reference truncated")
    if not cfg["enabled"]:
        return fallback, 0

    stage = int(stage_number)
    if stage == 1:
        filt = {"@and": [{"@eq": {"CLIENT_NAME": client_name}}, {"@eq": {"SOURCE_KIND": "ingest"}}]}
    else:
        filt = {
            "@and": [
                {"@eq": {"CLIENT_NAME": client_name}},
                {"@or": [
                    {"@and": [{"@eq": {"RUN_ID": run_id}}, {"@eq": {"DOC_TYPE": "brief"}}]},
                    {"@eq": {"SOURCE_KIND": "ingest"}},
                ]},
            ]
        }

    params = json.dumps({
        "query": f"{skill_name} requirements alignment brief",
        "limit": cfg["top_k"],
        "columns": ["CONTENT", "TITLE", "DOC_TYPE"],
        "filter": filt,
    })
    try:
        rows = session.sql(
            "SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(?, ?) AS RESULTS",
            params=[cfg["search_fqn"], params],
        ).collect()
        hits = _parse_search_results(rows[0]["RESULTS"] if rows else None)
        parts = []
        for hit in hits:
            if isinstance(hit, dict):
                content = hit.get("CONTENT") or hit.get("content") or ""
                if content:
                    parts.append(_truncate(content, SEARCH_REF_CHUNK_CAP, "ref chunk truncated"))
        if parts:
            return "\\n\\n---\\n\\n".join(parts), len(parts)
    except Exception:
        pass
    return fallback, 0


def _truncate(text, limit, label="truncated"):
    if not text:
        return ""
    text = str(text)
    if limit <= 0 or len(text) <= limit:
        return text
    return text[:limit] + f"\\n[... {label} ...]"


def _eval_limits(stage_number):
    return EVAL_FULL if int(stage_number) in REVIEW_GATE_STAGES else EVAL_LITE


def _load_cross_refs(session, run_id_input, output_id, stage_number_input, limits):
    stage = int(stage_number_input)
    if stage in REVIEW_GATE_STAGES:
        return session.sql("""
            SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
            FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND OUTPUT_ID != ? AND EVALUATION_STATUS = ''PASS''
            ORDER BY STAGE_NUMBER DESC, EXECUTION_ORDER DESC
            LIMIT ?
        """, params=[run_id_input, output_id, limits["max_cross"]]).collect()

    return session.sql("""
        SELECT SKILL_NAME, STAGE_NUMBER, OUTPUT_CONTENT
        FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
        WHERE RUN_ID = ? AND OUTPUT_ID != ? AND STAGE_NUMBER = ? AND EVALUATION_STATUS = ''PASS''
        ORDER BY EXECUTION_ORDER DESC
        LIMIT ?
    """, params=[run_id_input, output_id, stage, limits["max_cross"]]).collect()


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


def _parse_evaluation_json(response_body):
    """Extract evaluation rubric JSON from a Cortex Agent response."""
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
                        nested = _parse_evaluation_json(block["text"])
                        if nested:
                            return nested
                continue
            if "alignment_score" in candidate or "verdict" in candidate:
                return candidate

    text = _extract_agent_text(response_body)
    score_match = re.search(r''"alignment_score"\\s*:\\s*(\\d+(?:\\.\\d+)?)'', text)
    verdict_match = re.search(r''"verdict"\\s*:\\s*"(PASS|FAIL)"'', text, re.IGNORECASE)
    if score_match or verdict_match:
        return {
            "alignment_score": float(score_match.group(1)) if score_match else 0,
            "verdict": verdict_match.group(1).upper() if verdict_match else "FAIL",
            "feedback": text,
        }
    return None


def evaluate_output(session, run_id_input, skill_name_input, stage_number_input):
    """Call EVALUATOR_AGENT to score an output against the brief."""
    try:
        # ─────────────────────────────────────────────
        # 1. Read the brief (SSOT) and sprint contract
        # ─────────────────────────────────────────────
        state_rows = session.sql("""
            SELECT BRIEF_CONTENT, USER_RFP_INPUT, METADATA, CLIENT_NAME, PROJECT_NAME
            FROM DEMO_SPS_CORTEX.NEXUS.ORCHESTRATOR_STATE
            WHERE RUN_ID = ?
        """, params=[run_id_input]).collect()

        if not state_rows:
            return {''status'': ''ERROR'', ''error'': f''Run "{run_id_input}" not found''}

        brief = state_rows[0][''BRIEF_CONTENT''] or ''''
        rfp_input = state_rows[0][''USER_RFP_INPUT''] or ''''
        metadata = state_rows[0][''METADATA'']
        client_name = state_rows[0][''CLIENT_NAME''] or state_rows[0][''PROJECT_NAME'']
        if client_name:
            client_name = str(client_name).lower().replace(" ", "-")

        # For Stage 1, evaluate against raw RFP
        reference_doc = brief if stage_number_input > 1 else rfp_input

        # Extract sprint contract from metadata if available
        sprint_contract = ''''
        if metadata:
            try:
                meta = json.loads(str(metadata)) if isinstance(metadata, str) else metadata
                sprint_contract = meta.get(''sprint_contract'', '''')
            except (json.JSONDecodeError, TypeError):
                pass

        # ─────────────────────────────────────────────
        # 2. Read the output to evaluate
        # ─────────────────────────────────────────────
        output_rows = session.sql("""
            SELECT OUTPUT_ID, OUTPUT_CONTENT
            FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
            WHERE RUN_ID = ? AND SKILL_NAME = ? AND STAGE_NUMBER = ?
            ORDER BY CREATED_AT DESC
            LIMIT 1
        """, params=[run_id_input, skill_name_input, stage_number_input]).collect()

        if not output_rows:
            mismatch_rows = session.sql("""
                SELECT STAGE_NUMBER
                FROM DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
                WHERE RUN_ID = ? AND SKILL_NAME = ?
                ORDER BY CREATED_AT DESC
                LIMIT 1
            """, params=[run_id_input, skill_name_input]).collect()

            if mismatch_rows and int(mismatch_rows[0][''STAGE_NUMBER'']) != int(stage_number_input):
                stored_stage = int(mismatch_rows[0][''STAGE_NUMBER''])
                return {
                    ''status'': ''ERROR'',
                    ''error'': (
                        f''No output found for "{skill_name_input}" at Stage {stage_number_input}.''
                    ),
                    ''stored_stage'': stored_stage,
                    ''hint'': (
                        f''Output exists at Stage {stored_stage}. execute_skill_task always writes to ''
                        f''current_stage — call evaluate_output with stage_number={stored_stage}, or ''
                        f''call advance_stage before running Stage {stage_number_input} skills.''
                    ),
                }

            return {''status'': ''ERROR'', ''error'': f''No output found for "{skill_name_input}" at stage {stage_number_input}''}

        output_id = output_rows[0][''OUTPUT_ID'']
        output_content = output_rows[0][''OUTPUT_CONTENT'']
        stage_number_input = int(stage_number_input)
        limits = _eval_limits(stage_number_input)
        eval_mode = "full" if stage_number_input in REVIEW_GATE_STAGES else "lite"

        # ─────────────────────────────────────────────
        # 3. Read cross-reference outputs (stage-aware)
        # ─────────────────────────────────────────────
        cross_ref_rows = _load_cross_refs(
            session, run_id_input, output_id, stage_number_input, limits
        )

        cross_parts = []
        for r in cross_ref_rows:
            content = _truncate(r[''OUTPUT_CONTENT''], limits["cross_ref"], "cross-ref truncated")
            cross_parts.append(f"### {r[''SKILL_NAME'']} (Stage {r[''STAGE_NUMBER'']})\\n{content}")

        cross_ref_text = "\\n\\n".join(cross_parts) if cross_parts else "No other outputs yet."

        search_cfg = _search_config(session)
        reference_for_prompt, ref_search_hits = _search_reference_context(
            session, search_cfg, client_name, run_id_input,
            stage_number_input, skill_name_input, reference_doc, limits["ref"],
        )
        output_for_prompt = _truncate(output_content, limits["output"], "output truncated for evaluation")
        contract_for_prompt = _truncate(
            sprint_contract if sprint_contract else "No sprint contract specified.",
            SPRINT_CONTRACT_CAP,
            "sprint contract truncated",
        )

        # ─────────────────────────────────────────────
        # 4. Get attempt number
        # ─────────────────────────────────────────────
        attempt_rows = session.sql("""
            SELECT COUNT(*) AS CNT
            FROM DEMO_SPS_CORTEX.NEXUS.EVALUATION_LOG
            WHERE RUN_ID = ? AND AGENT_NAME = ? AND STAGE_NUMBER = ?
        """, params=[run_id_input, skill_name_input, stage_number_input]).collect()

        attempt_number = attempt_rows[0][''CNT''] + 1

        # ─────────────────────────────────────────────
        # 5. Build evaluation prompt
        # ─────────────────────────────────────────────
        eval_prompt = f"""## Reference Document ({"Brief SSOT" if stage_number_input > 1 else "Raw RFP Input"})
{reference_for_prompt}

---

## Sprint Contract
{contract_for_prompt}

---

## Output to Evaluate
- **Skill**: {skill_name_input}
- **Stage**: {stage_number_input}
- **Attempt**: {attempt_number}
- **Note**: Output may be truncated for evaluation; full text is stored in STAGE_OUTPUTS.

{output_for_prompt}

---

## Cross-Reference Outputs (for consistency checks)
{cross_ref_text}

---

Evaluate the output above using your 100-point rubric. Verify the sprint contract is met. Return your evaluation as a JSON object."""

        prompt_chars = len(eval_prompt)

        # ─────────────────────────────────────────────
        # 6. Call EVALUATOR_AGENT via :run API
        # ─────────────────────────────────────────────
        request_body = {
            "stream": False,
            "messages": [
                {
                    "role": "user",
                    "content": [{"type": "text", "text": eval_prompt}],
                }
            ],
        }
        headers = {
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

        resp = _snowflake.send_snow_api_request(
            "POST",
            EVALUATOR_ENDPOINT,
            headers,
            {},
            request_body,
            None,
            API_TIMEOUT,
        )

        raw_response = resp.get("content", resp.get("body", resp))

        # ─────────────────────────────────────────────
        # 7. Parse the evaluation response
        # ─────────────────────────────────────────────
        score = 0
        verdict = ''FAIL''
        breakdown = {}
        issues = []
        feedback = _extract_agent_text(raw_response)
        contract_met = False

        parsed = _parse_evaluation_json(raw_response)
        if parsed:
            score = parsed.get(''alignment_score'', 0)
            verdict = str(parsed.get(''verdict'', ''FAIL'')).upper()
            breakdown = parsed.get(''breakdown'', {})
            issues = parsed.get(''issues'', [])
            feedback = parsed.get(''feedback'', feedback)
            contract_met = parsed.get(''contract_met'', False)

            if score >= 80 and verdict != ''PASS'':
                verdict = ''PASS''
            elif score < 80 and verdict != ''FAIL'':
                verdict = ''FAIL''

        # ─────────────────────────────────────────────
        # 8. Update STAGE_OUTPUTS with evaluation result
        # ─────────────────────────────────────────────
        session.sql("""
            UPDATE DEMO_SPS_CORTEX.NEXUS.STAGE_OUTPUTS
            SET EVALUATION_STATUS = ?,
                EVALUATION_FEEDBACK = ?
            WHERE OUTPUT_ID = ?
        """, params=[verdict, feedback if isinstance(feedback, str) else json.dumps(feedback), output_id]).collect()

        if verdict == ''PASS'' and search_cfg["enabled"]:
            try:
                session.sql(
                    "CALL DEMO_SPS_CORTEX.NEXUS.INDEX_HARNESS_CHUNKS(?, ?, ?, ?)",
                    params=[run_id_input, "skill_output", skill_name_input, stage_number_input],
                ).collect()
            except Exception:
                pass

        # ─────────────────────────────────────────────
        # 9. Log to EVALUATION_LOG
        # ─────────────────────────────────────────────
        breakdown_json = json.dumps(breakdown) if breakdown else ''{}''
        issues_json = json.dumps(issues) if issues else ''[]''

        session.sql("""
            INSERT INTO DEMO_SPS_CORTEX.NEXUS.EVALUATION_LOG
                (RUN_ID, STAGE_NUMBER, AGENT_NAME, ALIGNMENT_SCORE, VERDICT,
                 BREAKDOWN, ISSUES_FOUND, FEEDBACK, ATTEMPT_NUMBER)
            SELECT ?, ?, ?, ?, ?, PARSE_JSON(?), PARSE_JSON(?), ?, ?
        """, params=[
            run_id_input, stage_number_input, skill_name_input,
            score, verdict, breakdown_json, issues_json,
            feedback if isinstance(feedback, str) else json.dumps(feedback),
            attempt_number
        ]).collect()

        return {
            ''status'': ''SUCCESS'',
            ''verdict'': verdict,
            ''alignment_score'': score,
            ''breakdown'': breakdown,
            ''contract_met'': contract_met,
            ''issues_count'': len(issues),
            ''attempt'': attempt_number,
            ''eval_mode'': eval_mode,
            ''prompt_chars'': prompt_chars,
            ''cross_refs_included'': len(cross_ref_rows),
            ''ref_search_hits'': ref_search_hits,
            ''feedback_preview'': (feedback[:500] if isinstance(feedback, str) else ''''),
            ''message'': f''{skill_name_input}: {verdict} (score: {score}/100, attempt #{attempt_number})''
        }

    except Exception as e:
        return {
            ''status'': ''ERROR'',
            ''error'': f''Failed to evaluate output from "{skill_name_input}"'',
            ''detail'': str(e)
        }
';

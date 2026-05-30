# Multi-Agent Orchestration System

A 4-agent harness for the Pre-Sales workflow using Snowflake Cortex Agents, inspired by [Anthropic's harness design](https://www.anthropic.com/engineering/harness-design-long-running-apps) and [Snowflake Intelligence multi-agent pattern](https://www.snowflake.com/en/developers/guides/multi-agent-orchestration-snowflake-intelligence/).

## Architecture

```
User → ORCHESTRATOR_AGENT (Master, 10 tools)
         │
         ├── sync_client_assets()   → Google Drive → @CLIENT_DOCS
         ├── ingest_client_assets() → Parse stage → SOURCE_DOCUMENTS
         ├── init_workflow()        → Creates run (inline RFP or ingested docs)
         ├── plan_stage()           → PLANNER_AGENT (via :run API)
         ├── run_skill()            → SKILLS → CORTEX.COMPLETE() + stage write
         ├── evaluate_output()      → EVALUATOR_AGENT
         ├── get_workflow_state()   → ORCHESTRATOR_STATE
         ├── advance_stage()        → Review gates + WORKFLOW_COMPLETE
         ├── export_proposal()      → PDF/markdown to final/
         └── index_final_assets()   → Cortex Search (user-confirmed)
```

### The Harness Loop (per stage)

```
plan_stage() → Planner returns task list with sprint contract
    │
    ▼
For each task:
    run_skill() → Worker fetches skill, calls COMPLETE()
    evaluate_output() → Evaluator scores against brief
        ├── PASS → next task
        └── FAIL → retry with feedback (max 2)
    │
    ▼
advance_stage() → review gate or next stage
```

### Key Design: No Pre-Created Sub-Agents

The Worker does NOT call pre-created agents. Instead:
1. Reads skill instructions from `NEXUS.SKILLS` table (synced from Git)
2. Uses them as the `system` prompt for `CORTEX.COMPLETE()`
3. Skills are always fresh — any Git push updates them immediately

## Components

| Type | Name | Purpose |
|------|------|---------|
| Cortex Agent | `ORCHESTRATOR_AGENT` | User-facing master, manages workflow |
| Cortex Agent | `PLANNER_AGENT` | Decomposes stages into tasks |
| Cortex Agent | `EVALUATOR_AGENT` | Quality scoring (GAN-inspired separation) |
| Stored Proc | `INIT_WORKFLOW` | Create a new workflow run |
| Stored Proc | `GET_WORKFLOW_STATE` | Read current state and outputs |
| Stored Proc | `RUN_SKILL` | Worker: SKILLS table → CORTEX.COMPLETE() |
| Stored Proc | `PLAN_STAGE` | Calls PLANNER_AGENT via :run API |
| Stored Proc | `EVALUATE_OUTPUT` | Calls EVALUATOR_AGENT via :run API |
| Stored Proc | `ADVANCE_STAGE` | Stage progression with review gates |
| Table | `ORCHESTRATOR_STATE` | Workflow run state and brief |
| Table | `STAGE_OUTPUTS` | Agent outputs with evaluation status |
| Table | `EVALUATION_LOG` | Audit trail of all evaluations |

## Prerequisites

1. Database and schema: `SPS_BUSINESS_INSIGHT.NEXUS` (or your `deploy_config.sql` values)
2. **Ingest layer deployed** — see [../ingest/README.md](../ingest/README.md) for `SKILLS`, stages, and search services
3. Warehouse: `SPS_MAIN_WH_XS`
4. Role: `SPS-SF-SYNC`

Deploy ingest scripts **before** orchestration when setting up E2E for the first time.

## Deployment Order

Run SQL files in this exact order (agents must exist before procedures that call them):

```bash
# Phase 1: Foundation
snowsql -f 00_state_tables.sql
snowsql -f 01_init_workflow.sql
snowsql -f 02_get_workflow_state.sql
snowsql -f 03_execute_skill_task.sql
snowsql -f 03_run_skill.sql
snowsql -f 06_advance_stage.sql

# Phase 2: Sub-agents (must exist before procedures that call them)
snowsql -f 08_planner_agent.sql
snowsql -f 08b_worker_agent.sql
snowsql -f 09_evaluator_agent.sql

# Phase 3: Procedures that call sub-agents
snowsql -f 04_plan_stage.sql
snowsql -f 05_evaluate_output.sql

# Phase 4: Master orchestrator (needs all SPs)
snowsql -f 07_orchestrator_agent.sql

# Phase 5: Permissions
snowsql -f 10_permissions.sql
```

## Verification

```sql
-- 1. Tables exist
SHOW TABLES LIKE '%ORCHESTRATOR%' IN SCHEMA SPS_BUSINESS_INSIGHT.NEXUS;
SHOW TABLES LIKE '%STAGE%' IN SCHEMA SPS_BUSINESS_INSIGHT.NEXUS;
SHOW TABLES LIKE '%EVALUATION%' IN SCHEMA SPS_BUSINESS_INSIGHT.NEXUS;

-- 2. Agents exist (should show 3)
SHOW AGENTS IN SCHEMA SPS_BUSINESS_INSIGHT.NEXUS;

-- 3. Test workflow init
CALL SPS_BUSINESS_INSIGHT.NEXUS.INIT_WORKFLOW('Test Project', 'test-client', 'Sample RFP for mobile app');

-- 4. Test planning (use run_id from step 3)
CALL SPS_BUSINESS_INSIGHT.NEXUS.PLAN_STAGE('<run_id>', 1);

-- 5. Test skill execution
CALL SPS_BUSINESS_INSIGHT.NEXUS.RUN_SKILL('<run_id>', 'sales-rfp-analyzer', 'Analyze this RFP', NULL);

-- 6. Test evaluation
CALL SPS_BUSINESS_INSIGHT.NEXUS.EVALUATE_OUTPUT('<run_id>', 'sales-rfp-analyzer', 1);

-- 7. Test advance (should trigger review gate)
CALL SPS_BUSINESS_INSIGHT.NEXUS.ADVANCE_STAGE('<run_id>', FALSE);

-- 8. End-to-end: chat with orchestrator
-- In Snowflake Intelligence or Nexus app:
-- "I have an RFP for a mobile e-commerce platform..."
```

## File Reference

| File | Type | Description |
|------|------|-------------|
| `00_state_tables.sql` | DDL | 3 state tables |
| `01_init_workflow.sql` | SP | Initialize workflow run |
| `02_get_workflow_state.sql` | SP | Read workflow state |
| `03_execute_skill_task.sql` | SP | Worker: WORKER_AGENT + Git skills |
| `03_run_skill.sql` | SP | Alias → EXECUTE_SKILL_TASK |
| `04_plan_stage.sql` | SP | Calls PLANNER_AGENT |
| `05_evaluate_output.sql` | SP | Calls EVALUATOR_AGENT |
| `06_advance_stage.sql` | SP | Stage progression + review gates |
| `07_orchestrator_agent.sql` | Agent | Master orchestrator (10 tools) |
| `08_planner_agent.sql` | Agent | Stage planner |
| `08b_worker_agent.sql` | Agent | Worker with native Git skills |
| `09_evaluator_agent.sql` | Agent | Quality evaluator (100-pt rubric) |
| `10_permissions.sql` | Grants | Access control |
| `11_stage_routing.md` | Docs | Stage-to-skill reference map |

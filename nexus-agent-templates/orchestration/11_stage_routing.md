# Stage-to-Skill Routing Map

This document defines which **skills** run at each stage, their execution order, dependencies, and review gate behavior. The Master Orchestrator uses `plan_stage` → `run_skill` → `evaluate_output` → `advance_stage` (not per-agent Cortex Agents).

---

## Stage Routing Table

| Stage | Sub-step | Skill(s) | Execution | Depends On | Review Gate |
|-------|----------|----------|-----------|------------|-------------|
| 1 | — | `sales-rfp-analyzer` | Single | Ingested RFP / user input | **YES** |
| 2 | 2a | `user-personas-generator`, `analyzing-market-research`, `conducting-competitor-analysis`, `mapping-stakeholders` | Parallel | Stage 1 brief | — |
| 2 | 2b | `mapping-customer-journeys` | Sequential | 2a (personas) | — |
| 2 | 2c | `defining-problem-statements` | Sequential | 2a + 2b | — |
| 3 | 3a | `extracting-features` | Single | Stage 2 outputs | — |
| 3 | 3b | `generating-prds`, `mapping-information-architecture` | Parallel | 3a | — |
| 3 | 3c | `user-flows-generator`, `generating-phased-roadmaps`, `defining-success-metrics` | Parallel | 3b | **YES** |
| 4 | — | `generating-brand-guidelines`, `generating-prototype-screens` | Parallel | Stage 3 outputs | — |
| 5 | — | `analyzing-tech-stack`, `generating-technical-assumptions`, `generating-design-assumptions` | Parallel | Brief + Stage 3 | — |
| 6 | 6a | `estimating-design-effort`, `estimating-dev-effort` | Parallel | Stages 4 + 5 | — |
| 6 | 6b | `consolidating-effort-summary` | Sequential | 6a | — |
| 6 | 6c | `sales-conditions-assumptions`, `pricing-packaging` | Parallel | 6b | **YES** |
| 7 | — | `proposal-quality-gate` | Single | ALL prior outputs | **YES** |
| 8 | — | `generating-executive-summary`, `generating-proposal-deck-outline` | Parallel | ALL prior + QG | — |

---

## Review Gates

| Gate | Stage | What User Reviews | Why |
|------|-------|-------------------|-----|
| 1 | Stage 1 | Project Brief (SSOT) | All subsequent work is based on this |
| 2 | Stage 3 | Feature List + Roadmap | Locks project scope |
| 3 | Stage 6 | Effort Summary + Pricing | Commercial commitment |
| 4 | Stage 7 | Quality Gate Report | Final assurance before packaging |

---

## Execution Flow per Stage

```
For each stage:
  1. Orchestrator calls get_workflow_state(run_id)
  2. Orchestrator calls plan_stage(run_id, stage_number)
  3. For each sub-step in the plan:
     - parallel: call run_skill for each task
     - sequential: call run_skill one at a time (respect depends_on)
  4. After EACH run_skill: call evaluate_output
     - PASS: continue
     - FAIL: retry run_skill with additional_context (max 2 retries)
  5. When all tasks PASS: call advance_stage
     - Review gates (1, 3, 6, 7): REVIEW_GATE → wait for user approval
     - Stage 8 complete: WORKFLOW_COMPLETE → export_proposal → optional index_final_assets
```

---

## E2E Pipeline Hooks

| Step | Tool / SP | When |
|------|-----------|------|
| Drive sync | `sync_client_assets(client_name)` | Before ingest (optional scheduled daily) |
| Ingest | `ingest_client_assets(client_name)` | Before init_workflow when RFP is on stage |
| Init | `init_workflow(project, client, rfp?)` | Start of workflow |
| Export | `export_proposal(run_id)` | After Stage 8 complete |
| Search index | `index_final_assets(run_id)` | After user confirms post-export |

---

## Skill Count

| Category | Count |
|----------|-------|
| Pre-sales skills | 26 |
| Orchestration agents | 3 (Orchestrator, Planner, Evaluator) |
| Optional deck Q&A | 1 (DECK_RESEARCH_AGENT) |

Skill names must match the `name:` frontmatter in `skills/pre-sales/*/SKILL.md`. Folder names (e.g. `rfp-analyzer`) are for Git paths only.

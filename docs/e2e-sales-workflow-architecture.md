# E2E Sales Document Prep — Architecture

End-to-end pipeline for transforming client RFP materials into a client-ready proposal using Snowflake Cortex Agents, Internal Stages, External Access, and Cortex Search.

## Overview

This repository implements a **unified Snowflake runtime** that connects:

| Layer | Components | Repo path |
|-------|------------|-----------|
| Ingest | Google Drive sync, stage layout, document parsing | `nexus-agent-templates/ingest/` |
| Skills | 26 pre-sales skills synced from Git | `skills/pre-sales/` |
| Orchestration | Planner → Worker → Evaluator harness | `nexus-agent-templates/orchestration/` |
| Export | Markdown bundle + PDF via External Access | `ingest/07_export_proposal.sql` |
| Search | Optional post-completion indexing + deck Q&A | `ingest/08_index_final_assets.sql`, `DECK_RESEARCH_AGENT` |

Standalone Cortex Search templates in `templates/cortex-search/` remain as a reference; the **Nexus schema** is the canonical deploy target for E2E.

## Data flow

```mermaid
flowchart LR
    A[Google Drive client/asset/] --> B[SYNC_CLIENT_ASSETS]
    B --> C["@CLIENT_DOCS/client/asset/"]
    C --> D[INGEST_CLIENT_ASSETS]
    D --> E[SOURCE_DOCUMENTS]
    E --> F[INIT_WORKFLOW]
    F --> G[8-stage harness]
    G --> H[STAGE_OUTPUTS + working/]
    H --> I[EXPORT_PROPOSAL]
    I --> J["@CLIENT_DOCS/client/final/"]
    J --> K[INDEX_FINAL_ASSETS]
    K --> L[Cortex Search services]
```

## Stage layout

All client files live on a single internal stage with a predictable hierarchy:

```
@CLIENT_DOCS/
  {client_slug}/
    asset/                 # Input PDFs, DOCX from Drive
    working/{run_id}/      # Per-skill markdown from RUN_SKILL
    final/                 # proposal-{run_id}.pdf and .md
```

Client slugs (e.g. `easia-hub`) must match:

- `CLIENTS.CLIENT_NAME` registry row
- Google Drive folder name convention
- `ORCHESTRATOR_STATE.CLIENT_NAME` on workflow runs

## Orchestration harness

The **Nexus harness** uses one Orchestrator agent and stored procedures — not 26 separate Cortex Agents per skill:

| SP / Agent | Role |
|------------|------|
| `ORCHESTRATOR_AGENT` | User-facing coordinator |
| `PLANNER_AGENT` | Stage decomposition (via `PLAN_STAGE`) |
| `RUN_SKILL` | Loads skill from `SKILLS` + `SKILLS_SEARCH_SERVICE`, calls `CORTEX.COMPLETE` |
| `EVALUATE_OUTPUT` | Quality gate (via `EVALUATOR_AGENT`) |
| `ADVANCE_STAGE` | Progression + review gates at stages 1, 3, 6, 7 |

After Stage 8, `ADVANCE_STAGE` returns `WORKFLOW_COMPLETE` with `export_status: PENDING`. The Orchestrator then calls `export_proposal` and optionally `index_final_assets` after user confirmation.

## Skills pipeline

Skills are authored in Git at `skills/pre-sales/{folder}/SKILL.md`. The **frontmatter `name:`** (e.g. `sales-rfp-analyzer`) is the identifier used by `RUN_SKILL` and the Planner — not the folder name.

`SYNC_SKILLS_FROM_GIT()` reads the Snowflake Git repo stage, upserts into `SKILLS`, and refreshes `SKILLS_SEARCH_SERVICE`.

## External Access integrations

| Integration | Purpose | Network hosts |
|-------------|---------|---------------|
| `GOOGLE_DRIVE_EAI` | Download client assets | `www.googleapis.com`, `oauth2.googleapis.com` |
| `PDF_API_EAI` | Gotenberg PDF via SPCS | SPCS service ingress host (see `spcs-gotenberg/`) |

Service account JSON for Drive is stored in secret `GOOGLE_DRIVE_SERVICE_ACCOUNT`.

### PDF export (SPCS + Gotenberg)

Gotenberg runs as a Snowpark Container Service (`GOTENBERG_PDF_SERVICE`). Deploy guide: [`nexus-agent-templates/ingest/spcs-gotenberg/README.md`](../nexus-agent-templates/ingest/spcs-gotenberg/README.md).

`EXPORT_PROPOSAL` reads `PIPELINE_CONFIG.PDF_API_BASE_URL` (set after `SHOW ENDPOINTS`) and calls the SPCS ingress URL via `PDF_API_EAI`.

## Cortex Search services

| Service | Source table | Use case |
|---------|--------------|----------|
| `SOURCE_DOCUMENTS_SEARCH` | `SOURCE_DOCUMENTS` | RFP / brief retrieval |
| `WORKFLOW_OUTPUTS_SEARCH` | `WORKFLOW_OUTPUTS` | PRDs, estimates, research |
| `PROPOSAL_DECK_SEARCH` | `PROPOSAL_DECK` | Deck Q&A |
| `SKILLS_SEARCH_SERVICE` | `SKILLS` | Fuzzy skill lookup in `RUN_SKILL` |

`INDEX_FINAL_ASSETS` populates search tables from approved `STAGE_OUTPUTS` and refreshes services. It runs **only after explicit user confirmation** post-export.

## Deploy runbook

1. Copy `nexus-agent-templates/deploy_config.example.sql` → `deploy_config.sql`
2. Run ingest scripts in order — see [nexus-agent-templates/ingest/README.md](../nexus-agent-templates/ingest/README.md)
3. Run orchestration scripts — see [nexus-agent-templates/orchestration/README.md](../nexus-agent-templates/orchestration/README.md)
4. Register client: `INSERT INTO CLIENTS ...`
5. `CALL SYNC_SKILLS_FROM_GIT();`
6. Resume tasks: `ALTER TASK TASK_SYNC_CLIENT_ASSETS RESUME;`

## Example session

```
User: Start proposal for easia-hub

Orchestrator:
  1. sync_client_assets('easia-hub')
  2. ingest_client_assets('easia-hub')
  3. init_workflow('Easia Hub 2026', 'easia-hub', NULL)
  4. [Stages 1–8 harness loop with review gates]
  5. export_proposal(run_id)
  6. "Index final assets for Cortex Search?" → index_final_assets(run_id) if yes
```

## Parameterization

Templates default to `SPS_BUSINESS_INSIGHT.NEXUS`. For forked deployments:

1. Set `DEPLOY_*` variables in `deploy_config.sql`
2. Search/replace schema names in Python SP bodies (`DB` / `SCHEMA` constants)
3. Update agent `tool_resources` warehouse and search service identifiers

## Security notes

- Client PDFs and proposals stay on `@CLIENT_DOCS` — never commit to Git (see root `.gitignore`)
- External Access secrets require ACCOUNTADMIN setup
- `INDEX_FINAL_ASSETS` is gated by Orchestrator instructions + user confirmation

## Related documentation

- [Pre-sales workflow guide](examples/pre-sales-workflow-guide.md) — 8-stage business process
- [Nexus templates README](../nexus-agent-templates/README.md) — deploy entry point
- [Skills README](../skills/README.md) — skill naming conventions

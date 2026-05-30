# Ingest Layer — Deploy Guide

SQL templates for the E2E sales document prep **ingest, skills sync, export, and search** layers. Run against the same `DATABASE.SCHEMA` as [orchestration](../orchestration/README.md).

## Prerequisites

1. Copy [`deploy_config.example.sql`](../deploy_config.example.sql) → `deploy_config.sql` and set account-specific values.
2. Run orchestration `00_state_tables.sql` first (or use `02b_alter_orchestrator_state.sql` on existing deployments).
3. **ACCOUNTADMIN:** Configure External Access in `00_network_rule_and_secrets.sql` and store `GOOGLE_DRIVE_SERVICE_ACCOUNT` secret.
4. Register clients: `INSERT INTO CLIENTS (CLIENT_NAME, DRIVE_FOLDER_ID) VALUES ('easia-hub', '<folder_id>');`
5. Snowflake Git repo stage `SKILLS_GIT_REPO` pointing at this repository.

## Deploy order

Execute in Snowsight/SnowSQL after sourcing `deploy_config.sql`:

| # | File | Purpose |
|---|------|---------|
| 1 | `00_network_rule_and_secrets.sql` | EAI for Drive + PDF API (ACCOUNTADMIN) |
| 2 | `01_client_stage.sql` | `@CLIENT_DOCS` stage, `CLIENTS`, `CLIENT_FILES` |
| 3 | `02_document_and_search_tables.sql` | `SOURCE_DOCUMENTS`, `WORKFLOW_OUTPUTS`, `PROPOSAL_DECK`, `SKILLS` |
| 4 | `02b_alter_orchestrator_state.sql` | Idempotent ALTERs if orchestration already deployed |
| 4b | `02c_source_document_chunks.sql` | `SOURCE_DOCUMENT_CHUNKS` table + harness search config |
| 5 | `03_sync_drive_to_stage.sql` | `SYNC_CLIENT_ASSETS` Python SP |
| 6 | `03_scheduled_task.sql` | Daily Drive sync task |
| 7 | `04_ingest_client_assets.sql` | `INGEST_CLIENT_ASSETS` — parse stage → `SOURCE_DOCUMENTS` |
| 8 | `06_skills_git_sync.sql` | `SYNC_SKILLS_FROM_GIT` + daily task |
| 9 | `05_search_services.sql` | Cortex Search services (run after first skills sync) |
| 9b | `05b_index_harness_chunks.sql` | `INDEX_HARNESS_CHUNKS` — brief/skill output → search chunks |
| 10 | `07_export_proposal.sql` | Markdown/PDF export (reads `PIPELINE_CONFIG`; SPCS Gotenberg) |
| 10b | `spcs-gotenberg/` | **Optional:** deploy Gotenberg on Snowpark Container Services |
| 11 | `08_index_final_assets.sql` | Post-completion search indexing |
| 12 | `09_deck_research_agent.sql` | Deck Q&A agent |
| 13 | `10_permissions.sql` | Role grants |

Then deploy [orchestration](../orchestration/) scripts `01`–`09` and `10_permissions.sql`.

## Stage layout

```
@CLIENT_DOCS/
  {client_name}/
    asset/              ← synced from Google Drive (PDF, DOCX, MD)
    working/{run_id}/   ← per-skill markdown from RUN_SKILL
    final/              ← proposal-{run_id}.pdf / .md
```

## Manual smoke test

```sql
-- 1. Sync + ingest
CALL SYNC_CLIENT_ASSETS('easia-hub');
CALL INGEST_CLIENT_ASSETS('easia-hub');

-- 2. Sync skills from Git
CALL SYNC_SKILLS_FROM_GIT();

-- 3. Start workflow (via Orchestrator or direct)
CALL INIT_WORKFLOW('Easia Hub 2026', 'easia-hub', NULL);

-- 4. After workflow completes
CALL EXPORT_PROPOSAL('<run_id>');
CALL INDEX_FINAL_ASSETS('<run_id>');  -- only after user confirms
```

## Open configuration items

| Item | Where to set |
|------|----------------|
| Google service account JSON | Secret `GOOGLE_DRIVE_SERVICE_ACCOUNT` |
| PDF API host | `spcs-gotenberg/03_configure_pdf_endpoint.sql` → `PIPELINE_CONFIG` |
| SPCS Gotenberg setup | [spcs-gotenberg/README.md](spcs-gotenberg/README.md) |
| Schema/database names | `deploy_config.sql` — replace `SPS_BUSINESS_INSIGHT.NEXUS` in SP bodies if forked |

Replace hardcoded `SPS_BUSINESS_INSIGHT.NEXUS` in Python SP bodies when deploying to a different schema (search/replace before execute).

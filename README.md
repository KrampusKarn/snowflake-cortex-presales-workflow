# Snowflake Cortex — E2E Pre-Sales Workflow

End-to-end pipeline: **Google Drive RFP → 8-stage agent harness → client-ready proposal (MD/PDF)** on Snowflake.

Built with Cortex Agents (Orchestrator / Planner / Worker / Evaluator), Internal Stages, External Access, and Cortex Search.

## Architecture

See [docs/e2e-sales-workflow-architecture.md](docs/e2e-sales-workflow-architecture.md).

## Quick start

1. Clone this repository and connect Snowflake Git integration to it (or copy `skills/pre-sales` into your repo).
2. Copy `nexus-agent-templates/deploy_config.example.sql` → `deploy_config.sql` and set your account/database/schema.
3. Deploy ingest scripts — [nexus-agent-templates/ingest/README.md](nexus-agent-templates/ingest/README.md)
4. Deploy orchestration — [nexus-agent-templates/orchestration/README.md](nexus-agent-templates/orchestration/README.md)
5. Register a client — [nexus-agent-templates/ingest/02c_example_client.sql.example](nexus-agent-templates/ingest/02c_example_client.sql.example)
6. Chat with `ORCHESTRATOR_AGENT` in Snowflake Intelligence:

   ```
   Run the full 8-stage workflow for client your-client-slug, project "My Project 2025".
   One skill per turn. I will reply "continue" between skills.
   ```

## Repository layout

| Path | Purpose |
|------|---------|
| `nexus-agent-templates/ingest/` | Drive sync, parse, chunk, Cortex Search, PDF export |
| `nexus-agent-templates/orchestration/` | Harness stored procedures + Cortex Agents |
| `skills/pre-sales/` | Git-native skills consumed by the Worker agent |
| `docs/` | Architecture and 8-stage workflow guide |

## License

Add your license here before publishing.

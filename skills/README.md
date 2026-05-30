# Cortex Agent Skills

Skills for Snowflake Cortex Agents, organized for Git-based discovery.

## Layout

```
skills/
├── pre-sales/          # Pre-sales workflow skills (26 skills)
│   ├── rfp-analyzer/
│   │   └── SKILL.md
│   └── ...
└── global/             # Deployment & conversion tooling
    ├── cortex-agent-converter/
    ├── cortex-config-generator/
    └── deploy-cortex-agents/
```

Each skill folder contains `SKILL.md` at its root. Supporting scripts must live in the same folder (no nested script directories).

## Snowflake Git paths

Reference skills in agent specs using the repo-relative path:

```sql
-- Pre-sales skill example
@my_db.my_schema.skills_repo/tags/latest/skills/pre-sales/rfp-analyzer

-- List all skills
LS @my_db.my_schema.skills_repo/tags/latest/skills/pre-sales/ PATTERN='.*SKILL\.md';
```

## Workflow reference

The 8-stage pre-sales chain and review gates are documented in [Pre-sales-template/AGENTS.md](../Pre-sales-template/AGENTS.md).

For Cortex Search setup (RFP, outputs, proposal deck), see [templates/cortex-search/README.md](../templates/cortex-search/README.md).

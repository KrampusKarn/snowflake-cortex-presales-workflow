-- ============================================================
-- WORKER AGENT — Native Git skills from skills/pre-sales/*
-- ============================================================
-- Phase 2: Executes SKILL.md from Snowflake Git repo (not SKILLS table).
-- Called by EXECUTE_SKILL_TASK via :run API with brief + prior outputs.
--
-- Regenerate skills block after adding skills:
--   python3 nexus-agent-templates/scripts/generate_pre_sales_agent_skills.py
--
-- Prerequisites:
--   - SKILLS_GIT_REPO with branches/DEMO/skills/pre-sales/
--   - ALTER GIT REPOSITORY ... FETCH after Git pushes
--   - GRANT USAGE ON GIT REPOSITORY ... TO role running EXECUTE_SKILL_TASK
-- ============================================================

CREATE OR REPLACE AGENT DEMO_SPS_CORTEX.NEXUS.WORKER_AGENT
COMMENT = 'Pre-Sales Worker: native Git skills from skills/pre-sales (invoked by EXECUTE_SKILL_TASK)'
FROM SPECIFICATION
$$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 600
    tokens: 200000

instructions:
  orchestration: |
    # Pre-Sales Worker Agent

    ## Role
    You execute exactly one configured pre-sales skill per invocation. The caller
    specifies which skill to run (by frontmatter `name`) and provides project context.

    ## Execution rules
    1. Match the requested skill name to one of your configured Git skills.
    2. Read and follow the full SKILL.md instructions for that skill.
    3. Use only the context provided in the user message (brief, RFP, prior outputs, task).
    4. Return the complete skill deliverable as markdown — no meta-commentary.
    5. Do not invoke other skills in the same response unless the SKILL.md requires it.

  response: |
    Output only the skill deliverable markdown requested by the skill instructions.

# GENERATED_SKILLS_START
skills:
  - name: generating-brand-guidelines
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/brand-guidelines"
  - name: conducting-competitor-analysis
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/competitor-analysis"
  - name: sales-conditions-assumptions
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/conditions-assumptions"
  - name: mapping-customer-journeys
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/customer-journey"
  - name: generating-design-assumptions
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/design-assumptions"
  - name: estimating-design-effort
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/design-estimation"
  - name: estimating-dev-effort
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/dev-estimation"
  - name: consolidating-effort-summary
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/effort-summary"
  - name: generating-executive-summary
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/executive-summary"
  - name: extracting-features
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/feature-extraction"
  - name: mapping-information-architecture
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/information-architecture"
  - name: analyzing-market-research
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/market-research-analysis"
  - name: generating-phased-roadmaps
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/phased-roadmap"
  - name: generating-prds
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/prd-generator"
  - name: pricing-packaging
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/pricing-packaging"
  - name: defining-problem-statements
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/problem-statements"
  - name: generating-proposal-deck-outline
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/proposal-deck-outline"
  - name: proposal-quality-gate
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/proposal-quality-gate"
  - name: generating-prototype-screens
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/prototype-screens"
  - name: sales-rfp-analyzer
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/rfp-analyzer"
  - name: mapping-stakeholders
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/stakeholder-mapping"
  - name: defining-success-metrics
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/success-metrics"
  - name: analyzing-tech-stack
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/tech-stack-analysis"
  - name: generating-technical-assumptions
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/technical-assumptions"
  - name: user-flows-generator
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/user-flows"
  - name: user-personas-generator
    source:
      type: GIT_INTEGRATION
      path: "@DEMO_SPS_CORTEX.NEXUS.SKILLS_GIT_REPO/branches/DEMO/skills/pre-sales/user-personas"
# GENERATED_SKILLS_END

tools: []
tool_resources: {}
$$;

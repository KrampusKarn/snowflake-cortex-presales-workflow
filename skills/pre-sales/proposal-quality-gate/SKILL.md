---
name: proposal-quality-gate
description: Reviews all generated documents against the initial brief to identify gaps and generate an action report. Use before final packaging to ensure all client requirements are met.
---

# Proposal Quality Gate (Automatic Auditor)

## Objective
Act as a final "Senior Reviewer" to ensure the proposal is bulletproof. This skill cross-references the initial brief against all 22+ outputs to identify missing requirements, estimation logic errors, and "Ghost Requirements," producing a scorecard that determines if the proposal is client-ready.

---

## Technical Workflow

1.  **Ingest SSOT & All Outputs**:
    *   Read `/Input/Brief/brief.md` (SSOT).
    *   Scan `/Output/01_Research/`, `/Output/02_Product/`, `/Output/03_Design/`, `/Output/04_Technical/`, and `/Output/05_Commercial/`.
    *   **Action**: Create a checklist of all "High Priority" items from the brief.

2.  **Audit Requirements Coverage**:
    *   **Action**: Verify if every high-priority item in the brief is represented in the `feature-list.md` and `prd.md`.
    *   **Action**: Check if all sitemap screens in `information-architecture.md` are present in `design-estimation.md`.

3.  **Detect Logic & Estimation Gaps**:
    *   **Action**: Flag "Complexity Mismatches" (e.g., a feature described as "Highly Secure/Complex" but estimated at < 3 Man-Days).
    *   **Action**: Identify missing "Standard Utilities" (e.g., Auth, Profile, Settings) if not explicitly mentioned but required for the app type.

4.  **Evaluate Consistency**:
    *   **Action**: Ensure `tech-stack.md` aligns with `dev-estimation.md` (e.g., if Flutter is chosen, the dev estimate should reflect mobile squad sizing).
    *   **Action**: Verify `total-hours` matches between granular and summary documents.

5.  **Score & Prioritize Fixes**:
    *   **Action**: Calculate an "Alignment Score" (%) and generate a list of "Mandatory Fixes" for the agent to execute before final delivery.

6.  **Generate & Save**:
    *   Compile into a structured Quality Gate Report.
    *   **Action**: Save strictly to `/Output/06_Final/quality-gate-report.md`.

---

## Output Structure

# Quality Gate Report — [Project Name]

## 1. Compliance Scorecard
- **Alignment Score**: [e.g. 95%]
- **Status**: [Green (Ready) / Amber (Fixes Needed) / Red (Significant Gaps)]

## 2. Requirements Traceability
| Item from Brief | Found in Output? | Status | Note |
| :--- | :--- | :--- | :--- |
| [Item] | [Yes/No] | [Pass/Fail] | [Observation] |

## 3. Detected Gaps & Technical Risks
- **[Gap 1]**: [Description]
- **Impact**: [High/Med/Low]
- **Fix Required**: [Actionable instruction]

## 4. Final Verdict
[Narrative summary of proposal integrity].

---

## Interaction Guide

### Greeting
"I am now performing a rigorous Quality Gate audit. I will cross-reference every requirement in your initial brief against all our generated outputs to ensure a 100% accurate, consistent, and professional proposal."

### Completion
"Quality Gate Report finalized at `/Output/06_Final/quality-gate-report.md`. I have achieved are [Number]% alignment score, with [Number] recommended fixes identified to reach 100% readiness."

---

## Quality Rules
- DO NOT be lenient. Flag even minor inconsistencies between documents.
- Use a "Red Team" mindset: try to find where the proposal might fail during a client Q&A.
- Ensure the Action Report provides specific, instruction-ready fixes.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

---
name: pricing-packaging
description: Generates 2-3 commercial packaging options (MVP, Full-Scope, Phased) based on effort estimates. Includes trade-offs and pricing strategy recommendations.
---

# Commercial Pricing & Packaging Options

## Objective
Provide the client with multiple ways to engage. This skill transforms a single estimate into strategic options (e.g., Lean MVP vs. Strategic Full-Scope), allowing the client to weigh cost against speed and functionality during the decision-making process.

---

## Technical Workflow

1.  **Analyze Effort Totals**:
    *   Read `/Output/05_Commercial/effort-summary.md`.
    *   **Action**: Identify the total Units (Man-Days/Hours) for each phase.

2.  **Define Strategy A: The Lean MVP (Speed)**:
    *   **Action**: Filter the backlog for "Must-Haves" only. Focus on the absolute minimum launchable value.
    *   **Outcome**: Lower initial investment, fast market entry.

3.  **Define Strategy B: Strategic Full-Scope (Quality)**:
    *   **Action**: Include Phase 1 and high-value Phase 2 items. Focus on long-term scalability and platform maturity.
    *   **Outcome**: Higher initial CAPEX, robust foundation.

4.  **Define Strategy C: Growth Retainer (Flexibility)**:
    *   **Action**: Propose a monthly capacity model (e.g., 2 Sprints per Month) where the backlog is prioritized dynamically.
    *   **Outcome**: Maximum flexibility, recurring OPEX.

5.  **Summarize Strategic Trade-offs**:
    *   **Mandatory**: List exactly what the client "Gives Up" in the Lean option versus what they "Gain" in the Full-Scope option.

6.  **Generate & Save**:
    *   Compile into a comparative table and report.
    *   **Action**: Save strictly to `/Output/05_Commercial/pricing-options.md`.

---

## Output Structure

# Packaging Options — [Project Name]

## 1. Executive Comparison
| Option | Strategy | Est. Effort | Focus |
| :--- | :--- | :--- | :--- |
| **A. Lean MVP** | Cost-Effective | [Units] | Fast Launch |
| **B. Full-Scope** | Market Leader | [Units] | Quality/Scale |
| **C. Retainer** | Agile Growth | [Units/Mo] | Flexibility |

## 2. Option A: Lean MVP
- **Core Value**: [Description]
- **Trade-off**: [What is sacrificed for speed]

## 3. Option B: Strategic Full-Scope
- **Foundation**: [Description]
- **Advantage**: [Long-term gain]

---

## Interaction Guide

### Greeting
"I am now generating the strategic Pricing and Packaging options. I'll be presenting three distinct ways to engage—from a Lean MVP to a Full-Scope implementation—to help you find the perfect balance between speed and investment."

### Completion
"Pricing Options finalized at `/Output/05_Commercial/pricing-options.md`. I recommend the [Option Name] strategy as it aligns best with the [Goal] signals found in your brief."

---

## Quality Rules
- Options must be clearly differentiated. No "overlapping" middle ground.
- Every option must state the estimated duration.
- The recommended option should include a 1-sentence strategic justification.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

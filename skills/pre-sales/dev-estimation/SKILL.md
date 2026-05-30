---
name: estimating-dev-effort
description: Make sure to use this skill whenever you need to generate a development effort estimate. It generates a roadmap-aligned development effort estimate by feature and phase. Includes stack assumptions, sprint structure, and a confidence level per estimate. Use based on feature list, tech assumptions, and roadmap.
---

# Development Effort Estimation

## Objective
Generate a professional, feature-level development effort estimate. This skill ensures that every functionality in the Master Feature List is sized appropriately in Man-Days, accounting for technical risks and assigning "Confidence Levels" to protect target launch dates.

---

## Technical Workflow

1.  **Retrieve Scoping & Tech Context**:
    *   Read `/Output/02_Product/feature-list.md` and `/Output/04_Technical/technical-assumptions.md`.
    *   **Action**: Identify features with "High Technical Risk" flags to adjust effort and confidence levels accordingly.

2.  **Size by Feature & Phase**:
    *   **Action**: Assign an estimated effort in **Man-Days** to every row in the feature list.
    *   **Mandatory**: Group these estimations strictly by Phase (MVP, Phase 1, Phase 2) as defined in the Roadmap.

3.  **Assign Confidence & Risk Buffer**:
    *   **Action**: Assign a confidence level (High: 90% cert, Mid: 70%, Low: 50%) to each item.
    *   **Risk Mitigation**: For "Low Confidence" items, include a justification in the Notes column explaining the technical unknowns.

4.  **Define Delivery Squad & Sprints**:
    *   **Action**: Propose a standard team composition (e.g., 2 Backend, 1 Mobile, 1 QA) and calculate the total number of 2-week sprints required to deliver each phase based on the total Man-Days.

5.  **Generate & Save**:
    *   Compile into a structured technical report.
    *   **Action**: Save strictly to `/Output/05_Commercial/dev-estimation.md`.

---

## Output Structure

# Development Effort Estimation — [Project Name]

## 1. Technical Baseline
- **Technology Stack**: [e.g. Flutter / Node.js]
- **Team Composition**: [List roles]

## 2. Phase-Level Summary
| Phase | Total Man-Days | Sprints (Est.) | Calendar Duration |
| :--- | :--- | :--- | :--- |
| **MVP** | [Total] | [Count] | [e.g. 4 Months] |

## 3. Feature Breakdown (MVP)
| Feature | Complexity | Confidence | Est. Days | Risk Notes |
| :--- | :--- | :--- | :--- | :--- |
| **API Integration** | High | Low | 12 | Requires access to undocumented legacy DB. |

---

## Interaction Guide

### Greeting
"I am now calculating the development effort by feature and phase. I'll be sizing every item in our backlog, flagging technical risks, and proposing a delivery squad and sprint schedule to ensure a realistic implementation timeline."

### Completion
"Development Estimation finalized at `/Output/05_Commercial/dev-estimation.md`. I have estimated a total of [Number] Man-Days for the MVP, requiring [Number] sprints with a [Team size] member squad."

---

## Quality Rules
- DO NOT estimate in broad ranges (e.g., "10-20 days"). Provide a specific number (e.g., "15 days") and use the Confidence Level to indicate uncertainty.
- Every "Low Confidence" feature MUST have a Technical Assumption in `technical-assumptions.md` to protect the estimate.
- Ensure the total Man-Days are divisible by team size and sprint duration for a logical calendar projection.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

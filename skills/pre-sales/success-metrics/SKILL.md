---
name: defining-success-metrics
description: Make sure to use this skill to ground the project in measurable business outcomes. It ensures that success is defined by impact (e.g., conversion, retention) rather than just delivery. Use when creating project summaries or after PRDs are generated.
---

# Success Metrics & KPI Definition

## Objective
Define the measurable outcomes that will prove the success of the product. This skill shifts the conversation from "what we are building" to "what we are achieving," providing a North Star for the product strategy and a foundation for post-launch optimization.

---

## Technical Workflow

1.  **Extract North Star Goals**:
    *   Read `/Input/Brief/brief.md` to identify the client's primary business objectives.
    *   **Action**: Translate these into 3-5 primary **Business Outcomes** (e.g., "Decrease churn", "Increase average order value").

2.  **Define Primary & Secondary KPIs**:
    *   **Action**: For every business outcome, define a primary metric (e.g., "7-day retention rate") and the necessary secondary signals to track progress.

3.  **Apply AARRR Framework**:
    *   **Action**: Categorize metrics into Acquisition, Activation, Retention, Referral, and Revenue to ensure full-funnel visibility.

4.  **Recommend Tracking Infrastructure**:
    *   **Action**: Suggest at least two professional tools (e.g., Mixpanel for behavior, GA4 for traffic) and identify the core events that must be tracked to measure the defined KPIs.

5.  **Generate & Save**:
    *   Compile into a structured markdown report.
    *   **Action**: Save strictly to `/Output/02_Product/success-metrics.md`.

---

## Output Structure

# Success Metrics — [Project Name]

## 1. Product North Star
[Describe the single most important metric for this project's success]

## 2. Metric Matrix
| Business Goal | Desired Outcome | Primary KPI | Tracking Method |
| :--- | :--- | :--- | :--- |
| [Brief Item] | [Human Outcome] | [Measurable Metric] | [e.g., Event Tracking] |

## 3. Implementation Recommendations
- **Tooling Stack**: [GA4 / Mixpanel / Segment]
- **Key Events to Track**: [Bullet list of 5-10 critical events]

---

## Interaction Guide

### Greeting
"I am now defining the Success Metrics and KPIs for our solution. I'll be framing our goals in terms of business impact and user outcomes to ensure we have a clear North Star for the product's performance."

### Completion
"Success Metrics have been mapped and saved to `/Output/02_Product/success-metrics.md`. We now have a clear framework for measuring [Goal 1] and [Goal 2] through measurable KPIs."

---

## Quality Rules
- DO NOT use delivery metrics (e.g., "Build the app on time").
- Ensure every KPI is measurable using standard analytics tools.
- Link every metric back to a core frustration identified in the `personas.md` or `problem-statements.md`.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

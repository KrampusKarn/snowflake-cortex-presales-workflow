---
name: consolidating-effort-summary
description: Make sure to use this skill at the end of the estimation phase. It produces a consolidated effort summary from design and development estimates. Includes a table showing total design and development hours/days by phase, and a projected timeline.
---

# Effort & Timeline Summary (Executive View)

## Objective
Consolidate granular design and development estimates into a single, high-level "Executive View." This skill provides C-level stakeholders with the "Big Picture" of the project budget, duration, and resource requirements across all phases.

---

## Technical Workflow

1.  **Aggregating Estimates**:
    *   Read `/Output/05_Commercial/design-estimation.md` and `/Output/05_Commercial/dev-estimation.md`.
    *   **Action**: Normalize all units into a consistent format (e.g., hours or man-days) for a unified project total.

2.  **Projecting the Integrated Timeline**:
    *   **Action**: Map the Design phase vs. Development phase start dates.
    *   **Critical Path**: Explicitly identify the overlap where developers can start (e.g., "Dev starts when 70% of Lo-fi UX is complete").

3.  **Summarizing Resource Load**:
    *   **Action**: Identify the total headcount required per phase (Designers + Developers + QA + PM).

4.  **Isolate Timeline Drivers**:
    *   **Action**: Identify the 2-3 most significant factors that will impact the delivery speed (e.g., "3rd party API availability," "UAT feedback cycles").

5.  **Generate & Save**:
    *   Compile into a structured executive report.
    *   **Action**: Save strictly to `/Output/05_Commercial/effort-summary.md`.

---

## Output Structure

# Effort & Timeline Summary — [Project Name]

## 1. Project High-Level Total
- **Phase 1 (MVP) Duration**: [Duration]
- **Total Combined Effort**: [Total Units]
- **Resource Peak**: [Max Headcount]

## 2. Phase-by-Phase Breakdown
| Phase | Design Effort | Dev Effort | Total Calendar Time |
| :--- | :--- | :--- | :--- |
| **MVP** | [Hours] | [Days] | [e.g. 14 Weeks] |
| **Phase 1** | [Hours] | [Days] | [e.g. 8 Weeks] |

## 3. High-Level Delivery Timeline
[Narrative description of when key milestones like "Alpha Test" or "Release Candidate" are expected].

## 4. Key Effort Drivers
- [Driver 1]: [Impact on scope/time]
- [Driver 2]: [Impact on scope/time]

---

## Interaction Guide

### Greeting
"I am now consolidating our design and development estimates into an Executive Summary. I'll be projecting our total calendar timeline and resource load to provide a clear 'Big Picture' view of the project's delivery path."

### Completion
"Effort & Timeline Summary finalized at `/Output/05_Commercial/effort-summary.md`. I have projected an integrated delivery window of [Duration] for the MVP, with a peak resource load of [Number] specialists."

---

## Quality Rules
- Totals in this summary MUST exactly match the sums in the granular estimation documents.
- The timeline must account for the dependency of Dev on Design (Parallel track).
- Drivers must be prioritized by their impact on the budget or schedule.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

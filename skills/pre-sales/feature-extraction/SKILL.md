---
name: extracting-features
description: Make sure to use this skill as soon as the project scope is defined. It creates the master "Single Source of Truth" for all functionalities, which is a mandatory prerequisite for technical and design estimations. Extracts an exhaustive feature list from project documentation.
---

# Feature Extraction & Backlog Master

## Objective
Extract an exhaustive, flat-list backlog of every feature and sub-feature required for the project. This skill ensures that "Ghost Requirements" (implied but not stated) are captured early, preventing scope creep and ensuring estimation accuracy.

---

## Technical Workflow

1.  **Analyze Source PRDs**:
    *   Read all documents in `/Output/02_Product/prd-*.md`.
    *   **Action**: Identify every discrete interactive element or system task mentioned in the requirement tables.

2.  **Capture Implicit Support Features**:
    *   **Mandatory**: Identify and add features required for operational success that might be missing from the PRD, such as:
        *   **Admin Utilities**: Audit logs, user impersonation, system health dashboards.
        *   **Data Ops**: CSV/PDF exports, bulk edit capabilities, error logging.

3.  **Tier by Priority (MoSCoW)**:
    *   **Action**: Assign every feature to **Must-have (Launch Critical)**, **Should-have (High Value)**, or **Nice-to-have (Future)**.

4.  **Flag Multi-Dimensional Complexity**:
    *   **Action**: Label features that have high **Technical Risk** (e.g., complex 3rd party API) or high **Design Effort** (e.g., complex multi-step forms).

5.  **Generate & Save**:
    *   Compile the master list into a structured markdown document.
    *   **Action**: Save strictly to `/Output/02_Product/feature-list.md`.

---

## Output Structure

# Master Feature List — [Project Name]

## [Platform Name]
[Summary of the platform's role in the ecosystem]

### Must-have (MVP)
| Feature | Operational Description | Complexity Flag |
| :--- | :--- | :--- |
| [Name] | [How it works in production] | [e.g., High Tech / Low UI] |

### Should-have (Phase 1+)
...

## Complexity & Risk Summary
[Explicitly list the features that will drive the most effort or risk during implementation]

---

## Interaction Guide

### Greeting
"I am now extracting the exhaustive Master Feature List. I'll be auditing our PRDs to ensure every screen, state, and implicit utility is captured, providing a rock-solid foundation for our technical estimates."

### Completion
"The Master Feature List is finalized and saved to `/Output/02_Product/feature-list.md`. I have flagged [Number] features as 'High Complexity' which we should address in the Technical Assumptions phase."

---

## Quality Rules
- No "Generic" features. Instead of "Dashboard", list "KPI Widgets", "Activity Feed", and "Filter Controls".
- Every platform MUST have its own section.
- Complexity flags MUST include a 1-sentence justification.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

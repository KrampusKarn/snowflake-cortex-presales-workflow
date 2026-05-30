---
name: estimating-design-effort
description: Make sure to use this skill whenever you need to generate a design estimation. It generates a granular design estimation sheet (CSV/Table) with Lo-fi and Hi-fi passes. Deliverable types include discovery, wireframes, UI design, design system, prototyping, and handoff. Use based on IA, Brief, and Design Assumptions.
---

# Design Estimation Generator

## Objective
Generate a granular, professional design effort estimate. This skill ensures that every screen identified in the Information Architecture (IA) is accounted for in both wireframing (Lo-fi) and UI Design (Hi-fi) phases, applying standardized complexity-based hour logic and protective revision buffers.

---

## Technical Workflow

1.  **Retrieve IA & Design Scoping Context**:
    *   Read `/Output/02_Product/information-architecture.md` and `/Output/04_Technical/design-assumptions.md`.
    *   **Action**: List all screens and identify "Complexity Signals" (e.g., "Data heavy screen" = Complex).

2.  **Generate Two-Pass Estimation**:
    *   **Pass 1: Lo-fi (Wireframing)**: Apply standardized Lo-fi hours.
    *   **Pass 2: Hi-fi (UI Design)**: Apply standardized Hi-fi hours.
    *   **Action**: For every screen in the sitemap, create a row in both passes.

3.  **Apply Hour & Complexity Logic**:
    *   **Mandatory Logic**:
        *   **Simple**: 1.0h (Lo-fi) / 2.0-3.5h (Hi-fi)
        *   **Average**: 1.5h (Lo-fi) / 6.0h (Hi-fi)
        *   **Complex**: 2.5h (Lo-fi) / 11.0h (Hi-fi)
    *   **Template Optimization**: Reduce Hi-fi hours by 30% if a screen is marked as a "Template" (e.g., standard list view).

4.  **Calculate Protective Buffers**:
    *   **Mandatory**: Apply a **25% Revision Buffer** to the total hours of every line item.
    *   **Action**: Calculate the "Final Total Hours" inclusive of this buffer.

5.  **Generate Structured Output**:
    *   Compile into a professional markdown table organized by Phase and Platform.
    *   **Action**: Save strictly to `/Output/05_Commercial/design-estimation.md`.

---

## Output Structure

# Design Effort Estimation — [Project Name]

## [Platform Name] — Lo-fi (MVP)
| # | Area / Screen | Complexity | Template | Est. Hours | Buffer (25%) | Total |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1.1 | **Login Screen** | Simple | No | 1.0 | 0.25 | 1.25 |

## [Platform Name] — Hi-fi (MVP)
...

## Estimation Summary
- **Total MVP Design Hours**: [Value]
- **Total Phase 2 Design Hours**: [Value]
- **Grand Total**: [Total]

---

## Interaction Guide

### Greeting
"I am now generating the granular Design Effort Estimation. I'll be mapping every screen from our IA into Lo-fi and Hi-fi passes, applying our standardized hour logic and protective buffers to ensure a realistic delivery scope."

### Completion
"Design Estimation is complete and saved to `/Output/05_Commercial/design-estimation.md`. I have estimated [Number] screens across [Number] platforms, with a total effort of [Number] hours inclusive of revision buffers."

---

## Quality Rules
- Every screen in the IA must be accounted for in both Lo-fi and Hi-fi passes.
- Calculation formulas for (Hours * 1.25) must be accurate.
- Complexity justifications must be provided for "Complex" screens in the Notes column.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

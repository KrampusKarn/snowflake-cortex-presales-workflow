---
name: generating-phased-roadmaps
description: Make sure to use this skill when the user requests a roadmap or implementation timeline. Generates a structured implementation roadmap broken down by phases, milestones, and features. Uses MoSCoW prioritization and clusters features by theme.
---

# Phased Implementation Roadmap

## Objective
Produce a strategic implementation timeline that visualizes the evolution of the product. This skill ensures we manage stakeholder expectations by clearly defining what is delivered "Now" (MVP), "Next" (Phase 1), and "Later" (Phase 2+), using a standardized "demo-driven" milestone structure.

---

## Technical Workflow

1.  **Ingest Backlog**:
    *   Read `/Output/02_Product/feature-list.md`.
    *   **Action**: Identify the natural clusters of features that can be grouped into demonstrating value (Milestones).

2.  **Define Phase Strategy**:
    *   **Mandatory**: Organize the roadmap into three distinct phases:
        *   **Phase 1: MVP (Must-Have)**: Foundation and core value.
        *   **Phase 2: Product Fit (Should-Have)**: Experience polish and secondary features.
        *   **Phase 3: Scale & Future (Could-Have)**: Advanced automation and nice-to-haves.

3.  **Cluster into Demo-Ready Milestones**:
    *   **Action**: Group related features into "Milestones" (e.g., "Milestone 1: Seamless Onboarding"). Each milestone must be a demonstrable increment for the client.

4.  **Maintain Global Traceability**:
    *   **Mandatory**: Use **Global Feature Numbering** (#1, #2, #3...) that continues across phases. Never reset the count.

5.  **Apply Syntax & Scoping**:
    *   **Action**: Use the `A → B → C` flow notation for descriptions and explicitly call out "Out of Scope" items for each phase to prevent scope creep.

6.  **Generate & Save**:
    *   Save strictly to `/Output/02_Product/roadmap.md`.

---

## Output Structure

# Implementation Roadmap — [Project Name]

## Release Strategy Overview
[1 paragraph defining how we will iterate toward the full vision]

## Phase [N]: [Name] ([MoSCoW Tag])
*Strategic Goal: [Italicized sentence]*

### Milestone [N]: [Title]
| # | Feature | Included Stories | Operational Description |
| :--- | :--- | :--- | :--- |
| 1 | **[Name]** | [Story • Story] | [Flow A → B. **Logic:** X. [Feature Y] is Out of Scope] |

---

## Interaction Guide

### Greeting
"I am now architecting the Phased Implementation Roadmap. I'll be clustering our features into demo-ready milestones, clearly separating what's critical for the MVP versus future enhancements to manage scope effectively."

### Completion
"The Phased Roadmap is finalized and saved to `/Output/02_Product/roadmap.md`. We have a clear delivery plan spanning [Number] phases, with [Number] Demo Milestones identified."

---

## Quality Rules
- Every feature must have a unique global number.
- Descriptions MUST include platform prefixes (e.g., "Admin:", "Mobile:").
- Use the `A → B → C` notation to describe core process flows within a feature row.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

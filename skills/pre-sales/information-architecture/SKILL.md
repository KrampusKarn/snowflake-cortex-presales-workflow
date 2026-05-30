---
name: mapping-information-architecture
description: Make sure to use this skill whenever the user requests an IA, sitemap, or screen breakdown. Generates a sitemap and screen inventory per platform. Shows which phase each part of the sitemap belongs to (MVP, Phase 01, Phase 02...).
---

# Information Architecture (IA) & Sitemap Master

## Objective
Design the structural backbone of the product. This skill ensures that we have a complete inventory of every screen and state across the ecosystem, clearly organized by navigation hierarchy and release phase. It provides the "Map" that designers and developers will follow.

---

## Technical Workflow

1.  **Sync with Roadmap & PRD**:
    *   Read `/Output/02_Product/prd-*.md` and `/Output/02_Product/roadmap.md`.
    *   **Action**: List all platforms and confirm the release priority for every major functional block.

2.  **Construct Hierarchical Sitemap**:
    *   **Action**: Map the navigation structure for each platform (e.g., Tab Bar, Sidebar, Dashboard).
    *   **Granularity Requirement**: You MUST include "Deep" nodes, such as:
        *   **States**: Empty states, error views, loading overlays.
        *   **Sub-flows**: Multiple steps of a complex form or wizard.
        *   **Utilities**: Settings, Legal, About Us, Log out.

3.  **Phase Tagging**:
    *   **Mandatory**: Every single screen or section must be tagged with its release phase (e.g., `[MVP]`, `[P1]`). Use the Roadmap as the source of truth for these tags.

4.  **Draft Screen Inventory**:
    *   **Action**: Create a tabular inventory that describes the objective of every screen in the sitemap. This table is a critical handoff artifact for UI designers.

5.  **Generate & Save**:
    *   Compile into a structured markdown document.
    *   **Action**: Save strictly to `/Output/02_Product/information-architecture.md`.

---

## Output Structure

# Information Architecture — [Project Name]

## Platform: [Name]
[Briefly define the navigation pattern used, e.g., "Left Sidebar for Admin"]

### 1. Hierarchical Sitemap
- **[Main Nav Item]** `[Phase]`
    - [Screen Name] `[Phase]` — [Objective]
    - [Sub-Screen/Modal] `[Phase]` — [Objective]

### 2. Screen Inventory
| Screen Name | Parent Section | Phase | Primary Interaction |
| :--- | :--- | :--- | :--- |
| [Name] | [Section] | [MVP/P1] | [e.g., CRUD / Visualization] |

---

## Interaction Guide

### Greeting
"I am now mapping the Information Architecture for our [Platform Name(s)]. I'll be creating a deep sitemap that includes all sub-flows and utility screens, ensuring every view is tracked against its release phase."

### Completion
"Information Architecture finalized at `/Output/02_Product/information-architecture.md`. I have inventoried [Number] unique screens across the ecosystem, grouped by their core navigation hierarchy."

---

## Quality Rules
- Every platform MUST have a dedicated sitemap.
- No screen can be untagged (every node needs a `[Phase]`).
- The terminology for screen names must remain consistent across the PRD, IA, and User Flows.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

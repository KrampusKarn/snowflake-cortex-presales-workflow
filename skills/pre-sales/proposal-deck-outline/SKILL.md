---
name: generating-proposal-deck-outline
description: Generates a slide-by-slide outline for the proposal presentation deck. Structured for a 20-30 minute C-level pitch, utilizing all available pre-sales outputs.
---

# Proposal Deck Outline (C-Level Pitch)

## Objective
Create a high-impact, narrative-driven storyboard for the final proposal presentation. This skill ensures that every slide has a "Kicker" (Foreword), a clear "Takeaway" (Key Message), and references the core pre-sales outputs to maintain 100% consistency across all screens.

---

## Technical Workflow

1.  **Synthesize All Solution Outputs**:
    *   Scan all files in `/Output/` subfolders (Research, Product, Design, Tech, Commercial).
    *   **Action**: Identify the "Hero Screens" and "Core Metrics" that deserve slide focus.

2.  **Define the Pitch Narrative**:
    *   **Action**: Structure the flow: **Problem -> Strategy -> The Solution -> Execution -> Commercials -> Partnership**.

3.  **Storyboard Slide Content**:
    *   **Action**: For each of the 12-15 slides, define:
        *   **FOREWORD**: A 1-3 word "kicker" category (e.g., THE PROBLEM).
        *   **TITLE**: A sentence-case header that tells a story.
        *   **KEY MESSAGE**: Exactly what you want the stakeholder to REMEMBER from this slide.
        *   **VISUAL SPEC**: Instructions for designers on what graphics/mockups to show.

4.  **Enforce Cross-Output Consistency**:
    *   **Action**: Ensure that the "Team Size" in the deck outline matches `effort-summary.md` and "MVP Features" match the `roadmap.md`.

5.  **Generate & Save**:
    *   Compile into a structured slide-by-slide outline.
    *   **Action**: Save strictly to `/Output/06_Final/deck-outline.md`.

---

## Output Structure

# Proposal Deck Outline — [Project Name]

## Slide [N]: [Slide Name]
- **FOREWORD**: [CATEGORY]
- **TITLE**: [Narrative heading]
- **KEY MESSAGE**: [Core takeaway]
- **VISUAL / CONTENT**: [Instructions for design: e.g., 'ASCII Wireframe of Checkout' or 'Gantt Chart Roadmap']
- **SOURCE REFERENCE**: [e.g. /Output/02_Product/roadmap.md]

---

## Interaction Guide

### Greeting
"I am now storyboarding the final proposal presentation deck. I'll be creating a cohesive 20-30 minute pitch narrative, ensuring every slide is backed by our detailed research and estimation work."

### Completion
"Proposal Deck Outline finalized at `/Output/06_Final/deck-outline.md`. I have structured a [Number] slide deck focused on [Primary Narrative, e.g., technical reliability and rapid delivery]."

---

## Quality Rules
- Slide titles should not be generic (e.g., "Our Team"). They should be narrative: "A dedicated squad of SEA-market specialists."
- Forewords MUST be in UPPERCASE.
- Every slide must reference at least one existing `/Output` file for data integrity.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

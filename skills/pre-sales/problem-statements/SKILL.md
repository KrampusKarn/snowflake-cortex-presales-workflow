---
name: defining-problem-statements
description: Make sure to use this skill to bridge research and product definition, ensuring every feature solves a validated pain point. Defines clear problem statements per persona and/or platform. Bridges the gap between user pain points and the proposed solution.
---

# Defining Problem Statements

## Objective
Convert raw research into actionable "Problem Statements." This skill ensures that the entire project team (and the client) aligns on the *Why* before we define the *What*. It is the final bridge between Research (Stage 2) and Product Definition (Stage 3).

---

## Technical Workflow

1.  **Synthesize Research Material**:
    *   Read `/Output/01_Research/personas.md` and `/Output/01_Research/customer-journey.md`.
    *   **Action**: Identify the single biggest blocker for each persona and the primary mission for each platform.

2.  **Draft Persona-Centric Problem Statements**:
    *   **Action**: For each primary persona, write a statement using the "Context -> Current Situation -> Core Problem -> Impact -> Proposed Direction" logic.

3.  **Draft Platform-Centric Problem Statements**:
    *   **Action**: For each platform (Admin, Customer App, etc.), define the operational problem it solves for the business (e.g., "Manual reconciliation is causing 10% data error rates").

4.  **Validate Against SSOT**:
    *   **Action**: Cross-check these statements against the client's stated goals in `brief.md`. If a problem statement doesn't solve a brief-level goal, flag it.

5.  **Generate & Save**:
    *   Compile into a structured markdown document.
    *   **Action**: Save strictly to `/Output/01_Research/problem-statements.md`.

---

## Output Structure

# Project Problem Statements — [Project Name]

## 1. Persona-Specific Statements

### [Persona Name]
- **Current Situation**: [What they do today]
- **Core Problem**: [The root friction]
- **Impact if Unsolved**: [Business/personal consequence]
- **Proposed Direction**: [How our solution alieviates this]

## 2. Platform-Specific Statements

### [Platform Name]
- **Operational Need**: [Why the business needs this specific interface]
- **Problem Solved**: [The inefficiency it removes]

---

## Interaction Guide

### Greeting
"I am now distilling our research into definitive Problem Statements. This will ensure every feature we propose later is anchored in a validated user or business need."

### Completion
"Problem Statements have been defined and saved to `/Output/01_Research/problem-statements.md`. We are now ready to move to Stage 3 (Product Definition) with a clear understanding of the 'Why'."

---

## Quality Rules
- Statements are concise and avoid technical jargon.
- The "Proposed Direction" acts as a high-level requirements summary.
- Every platform mentioned in the architecture must have a problem statement.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

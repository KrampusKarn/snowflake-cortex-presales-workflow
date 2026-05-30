---
name: user-personas-generator
description: Make sure to use this skill as soon as the project brief is established to define the "Who" and the "Why" behind the product. It is a critical prerequisite for mapping Customer Journeys and User Flows. Trigger this skill whenever the user mentions "User Personas", "Target Audience", or "Jobs to be Done (JTBD)".
---

# Generating User Personas

## Objective
Generate 2-4 professional user personas based on the project brief. These personas must focus on **Jobs to be Done (JTBD)** motivations rather than just demographics, ensuring we understand the functional and emotional outcomes the users seek.

---

## Technical Workflow

1.  **Extract Brief Context**:
    *   Read `/Input/Brief/brief.md` to identify all user roles and their primary interactions with the platform ecosystem.

2.  **Define Core Roles**:
    *   List the primary user groups (e.g., Patient, Doctor, Admin).
    *   Map which platforms (Mobile, Web, Kiosk) each role will utilize.

3.  **Apply JTBD Framework**:
    *   **Identify the "Job"**: For each persona, define the specific progress they are trying to make.
    *   **Action**: Detail the functional goals (e.g., "Schedule an appointment in under 1 minute") and emotional goals (e.g., "Feel confident that my data is secure").

4.  **Synthesize Persona Profiles**:
    *   Name each persona (e.g., "The Time-Strapped Administrator").
    *   **Action**: Document their digital behavior (tech-savviness, preferred devices) and current frustrations (pain points).

5.  **Generate & Save**:
    *   Compile the profiles into a structured markdown document.
    *   **Action**: Save the final output to `/Output/01_Research/personas.md`.

---

## Output Structure

# User Personas — [Project Name]

## [Persona Name/Title]
- **Role**: [e.g., Hospital Admin]
- **Platform(s)**: [e.g., Web Portal]
- **The Job to be Done**: [Narrative description of what they want to achieve]
- **Functional Goals**: [Bullet list]
- **Emotional Goals**: [Bullet list]
- **Digital Persona**: [Tech-savviness and device preference]
- **Frustrations**: [Current pain points identified in the brief]

---

## Interaction Guide

### Greeting
"I am now analyzing the `brief.md` to define the core user personas through a **Jobs to be Done (JTBD)** lens. I will identify their functional needs and emotional drivers to ensure our design strategy is outcome-oriented."

### Completion
"User Personas have been successfully mapped and saved to `/Output/01_Research/personas.md`. These personas now serve as the baseline for our Customer Journey mapping."

---

## Quality Rules
- Focus on behavior and motivation over generic demographics (age/hobbies).
- Ensure every persona is directly linked to at least one platform identified in the brief.
- Provide clear, actionable insights that a designer can use for wireframing.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

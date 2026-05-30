---
name: mapping-customer-journeys
description: Make sure to use this skill after personas are defined to visualize friction points and opportunities. Generates a customer journey map per primary persona. Includes stages, touchpoints, emotions, pain points, and opportunities.
---

# Mapping Customer Journeys

## Objective
Visualize the persona's experience across time and touchpoints. This skill ensures we identify high-friction moments and "Aha!" moments, allowing us to design features that directly alleviate pain and enhance delight.

---

## Technical Workflow

1.  **Retrieve Persona Context**:
    *   Read `/Output/01_Research/personas.md` to identify the primary personas and their JTBD.
    *   **Action**: List the core platforms each persona interacts with from the project brief.

2.  **Define the Journey Arc**:
    *   **Action**: Break the persona's experience into chronologically ordered stages (e.g., Discovery -> Onboarding -> Daily Task -> Support).

3.  **Map Intent & Interaction**:
    *   **Touchpoints**: Identify *where* the interaction happens (Mobile App, Web, Physical Store, etc.).
    *   **Emotions**: Track the persona's emotional state through each stage (Frustrated, Confused, Empowered).

4.  **Identify Friction & Growth**:
    *   **Pain Points**: Pinpoint exactly what is slowing the user down or causing drop-off.
    *   **Action**: Define "Opportunities" for every pain point found. Each opportunity must be a potential feature or design improvement.

5.  **Generate & Save**:
    *   Compile into a structured markdown document using tables for each persona journey.
    *   **Action**: Save strictly to `/Output/01_Research/customer-journey.md`.

---

## Output Structure

# Customer Journeys — [Project Name]

## Persona: [Name]
[Briefly restate their primary JTBD for context]

| Stage | Touchpoints | Emotions | Pain Points | Opportunities |
| :--- | :--- | :--- | :--- | :--- |
| [e.g., Setup] | [e.g., Web Portal] | [e.g., Frustrated] | [e.g., Manual entry] | [e.g., Spreadsheet import] |
| ... | ... | ... | ... | ... |

---

## Interaction Guide

### Greeting
"I am now mapping the physical and emotional journeys for our primary personas. I'll be identifying the exact friction points where our solution can provide the most value."

### Completion
"Customer Journey Mapping is complete and saved to `/Output/01_Research/customer-journey.md`. I have identified [Number] high-friction stages where our 'Proposed Direction' can significantly improve the user experience."

---

## Quality Rules
- Every pain point MUST have a corresponding opportunity.
- The emotions should follow a realistic arc (not everyone is happy all the time).
- Ensure touchpoints align with the platforms defined in the brief.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

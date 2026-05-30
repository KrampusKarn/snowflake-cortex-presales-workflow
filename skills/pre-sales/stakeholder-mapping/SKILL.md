---
name: mapping-stakeholders
description: Make sure to use this skill for enterprise projects to map the complex decision-making landscape and ensure high-friction departments (Security, IT, Legal) are addressed early. Identifies and maps project stakeholders into a matrix.
---

# Mapping Stakeholders

## Objective
Map the human and organizational landscape of the project. This skill ensures we identify not just the primary users, but the "Blockers" and "Decision Makers" who can impact project success, budget approval, and technical sign-off.

---

## Technical Workflow

1.  **Extract Entity List**:
    *   Read `/Input/Brief/brief.md` and any `/Input` docs to identify roles, departments, and mentioned titles.
    *   **Action**: Look for clues about external stakeholders (consultants, regex, specialized vendors).

2.  **Categorize by Influence & Interest**:
    *   **Action**: Assign every identified stakeholder to one of four tiers:
        *   **Decision Makers**: Final approval/budget authority.
        *   **Influencers**: Expert advisors or department leads.
        *   **End Users**: Daily operators of the solution.
        *   **Blockers**: Legal, Security, IT, or Procurement.

3.  **Analyze Power Dynamics**:
    *   **Action**: Determine the "Key Concern" for each group (e.g., CTO cares about scalability, while Security cares about data residency).

4.  **Define Engagement Strategy**:
    *   Develop a professional plan for how to interact with each tier (e.g., "Weekly Steering Committee for Decision Makers").

5.  **Generate & Save**:
    *   Compile into a structured markdown report.
    *   **Action**: Save strictly to `/Output/01_Research/stakeholder-map.md`.

---

## Output Structure

# Stakeholder Map — [Project Name]

## 1. Stakeholder Matrix
| Category | Role | Primary Concern | Influence Level |
| :--- | :--- | :--- | :--- |
| **Decision Maker** | [Title] | [Key driver] | [High/Mid/Low] |
| **Influencer** | [Title] | [Key driver] | [High/Mid/Low] |
| **End User** | [Title] | [Key driver] | [High/Mid/Low] |
| **Blocker** | [Title] | [Key driver] | [High/Mid/Low] |

## 2. Risk Areas
[Highlight departments or roles that may pose a risk to the timeline or budget.]

## 3. Recommended Engagement Strategy
- **Steering Committee**: [Who participates?]
- **Technical Workstream**: [Who participates?]
- **Legal & Compliance**: [How to handle blockers early]

---

## Interaction Guide

### Greeting
"I am now mapping the project's stakeholder landscape. I'll be identifying the decision-makers, influencers, and potential blockers across departments to ensure our engagement strategy is airtight."

### Completion
"Stakeholder Map finalized at `/Output/01_Research/stakeholder-map.md`. I've flagged IT Security as a high-influence blocker due to [Reason from brief] and provided a strategy to mitigate this risk."

---

## Quality Rules
- Matrix accurately reflects the organizational complexity found in the brief.
- "Blockers" are clearly identified with their specific departmental concerns (e.g., PDPA, Legacy Sync).
- The Engagement Strategy provides a clear cadence for communication.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

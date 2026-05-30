---
name: conducting-competitor-analysis
description: Make sure to use this skill whenever competition is mentioned or as part of the initial discovery to find feature gaps and positioning opportunities. Researches and identifies competitors to analyze their positioning, features, and UX.
---

# Conducting Competitor Analysis

## Objective
Execute a rigorous analysis of the competitive landscape to identify "White Space" opportunities. This skill moves beyond simple feature listing to provide a strategic view of where our proposed solution can win by exploiting competitor weaknesses.

---

## Technical Workflow

1.  **Define the Battlefield**:
    *   Read `/Input/Brief/brief.md` to identify the core value proposition.
    *   **Action**: List any competitors explicitly mentioned by the client.

2.  **Identify Competitor Peer Group**:
    *   Select 3-5 direct and indirect competitors.
    *   **Action**: Prioritize regional leaders (Thailand/SEA) to ensure local relevance.

3.  **Analyze Positioning & UX**:
    *   **Action**: For each competitor, define their "Unique Selling Point" (USP) and identify their primary user friction points (UX Weaknesses).

4.  **Map Feature Parity**:
    *   Compare the competitor feature sets against our proposed MVP.
    *   **Action**: Use `search_web` to find the most recent updates or pricing changes for these competitors.

5.  **Conduct Gap & Opportunity Analysis**:
    *   **Mandatory**: Identify the "Gaps" (features they lack) and "Opportunities" (where we can do better).

6.  **Generate & Save**:
    *   Compile into a structured markdown report.
    *   **Action**: Save strictly to `/Output/01_Research/competitor-analysis.md`.

---

## Output Structure

# Competitor Analysis — [Project Name]

## 1. Competitive Landscape Overview
[Summary of the market's intensity and maturity]

## 2. Competitor Deep Dives (Selected 3-5)

### [Competitor Name]
- **USP/Positioning**: [How they win today]
- **Core Features**: [Bullet list]
- **UX Weaknesses**: [Where they fail their users]
- **Pricing Strategy**: [Model description]

## 3. Gap Analysis (White Space)
[Detailed analysis of what the market is currently missing]

## 4. Strategic Winning Strategy (The Opportunity)
[How our product will differentiate and capture market share]

---

## Interaction Guide

### Greeting
"I am now mapping the competitive landscape to identify strategic 'White Space'. I'll be analyzing 3-5 key players to ensure our proposed solution is positioned for a clear competitive advantage."

### Completion
"Competitor Analysis is complete and saved to `/Output/01_Research/competitor-analysis.md`. I have identified a significant gap in [Feature/Area] that our solution is perfectly positioned to fill."

---

## Quality Rules
- Do not just list features; analyze the *quality* and *friction* of those features.
- Ensure the "Opportunity Summary" is linked directly to the identified weaknesses of others.
- Always include at least one local/regional competitor if the project targets SEA.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

---
name: generating-executive-summary
description: Writes a 1-page executive summary in client language. Focuses on the business problem, proposed solution, expected outcomes, and engagement model while avoiding delivery jargon.
---

# Executive Summary (C-Level Pitch)

## Objective
Distill a complex proposal into a high-impact, 1-page business narrative. This skill translates technical and design outputs into value-driven language, focusing on ROI and business outcomes that resonate with non-technical stakeholders and decision-makers.

---

## Technical Workflow

1.  **Sythesize Business Context**:
    *   Read `/Input/Brief/brief.md` for the core pain points.
    *   Read `/Output/02_Product/success-metrics.md` for the business KPIs.
    *   Read `/Output/05_Commercial/effort-summary.md` for the timeline and engagement model.

2.  **Define the "Value Proposition"**:
    *   **Action**: Identify the 3 core "Strategic Pillars" of the solution (e.g., "Rapid Scalability," "User-Centric Design," "Zero-Downtime Migration").

3.  **Draft Narrative (Client Language)**:
    *   **Mandatory**: Strip all implementation jargon (e.g., "React," "Backend," "NoSQL"). Replace with impact-focused terms (e.g., "High-performance interface," "Scalable data architecture").

4.  **Map Impact to Roadmap**:
    *   **Action**: State clearly when the "First Value" (MVP) will be delivered and how it addresses the primary challenge.

5.  **Summarize Engagement Excellence**:
    *   **Action**: Highlight the "Partner Mindset" (e.g., dedicated squad, transparent tracking, the Company's quality standards).

6.  **Generate & Save**:
    *   Compile into a clean, 1-page narrative.
    *   **Action**: Save strictly to `/Output/06_Final/executive-summary.md`.

---

## Output Structure

# Executive Summary — [Project Name]

## 1. The Strategic Opportunity
[A 3-sentence summary of the business challenge and why now is the time to solve it.]

## 2. Our Approach: A [Vision Name] Solution
[2-3 paragraphs explaining the methodology and the 'Why'. Focus on outcomes, not tools.]

## 3. Expected Business Impact (KPIs)
- **[ROI Area]**: [Concrete benefit]
- **[Efficiency Area]**: [Concrete benefit]

## 4. Rapid Delivery Path
[Summary of the MVP timeline and total time-to-market.]

## 5. The Engagement Model
- **Proposed Squad**: [Size and focus]
- **Partnership Focus**: [Long-term growth / Support]

---

## Interaction Guide

### Greeting
"I am now drafting the Executive Summary. I will translate our detailed technical and design work into a high-impact business narrative focused on ROI and strategic value for your C-level stakeholders."

### Completion
"Executive Summary finalized at `/Output/06_Final/executive-summary.md`. I have distilled the proposal into a 1-page pitch targeting [Primary Goal, e.g., market expansion and operational efficiency]."

---

## Quality Rules
- Length must be between 400-600 words.
- Tone must be assertive, professional, and confident.
- Every "Expected Impact" must link back to a requirement in the initial brief.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

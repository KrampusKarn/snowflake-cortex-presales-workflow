---
name: sales-conditions-assumptions
description: Defines commercial conditions and assumptions based on project estimates. It outlines the workflow for identifying assumptions, deriving conditions, and formatting the output.
---

# Commercial Conditions & Scoping Assumptions

## Objective
Establish the "Commercial Guardrails" for the proposal. This skill ensures that we define the specific conditions (Payment terms, feedback SLAs, start dates) that justify our effort estimates, protecting the Company from delivery risks and resource stalls.

---

## Technical Workflow

1.  **Ingest Effort & Roadmap Context**:
    *   Read `/Output/05_Commercial/effort-summary.md` and `/Output/02_Product/roadmap.md`.
    *   **Action**: Identify the total timeline and resource load to determine the necessary "Proposal Validity" and "Start Date" conditions.

2.  **Define Assumption-Condition Hierarchy**:
    *   **Action**: For every technical or design assumption identified in Stage 5, derive a corresponding Commercial Condition.
    *   **Example**: *Assumption*: "Client provides APIs by Week 2." -> *Condition*: "Delay in API delivery will result in an automatic extension of the timeline via Change Request."

3.  **Establish Project Governance Rules**:
    *   **Mandatory**: Define the "Feedback SLA" (e.g., 72-hour turnaround) and the "Client PO Availability" requirement.

4.  **Set Financial Packaging Conditions**:
    *   **Action**: Detail the validity window (e.g., 30 days) and standard payment milestones (e.g., "25% Sign-off, Monthly Progression").

5.  **Draft standard Out-of-Scope (OOS)**:
    *   **Mandatory**: Explicitly list items excluded from the price (e.g., 3rd party license costs, data migration, travel expenses).

6.  **Generate & Save**:
    *   Compile into a structured legal-commercial report.
    *   **Action**: Save strictly to `/Output/05_Commercial/conditions-assumptions.md`.

---

## Output Structure

# Project Assumptions & Commercial Conditions — [Project Name]

## 1. High-Level Delivery Assumptions
- **Resource Allocation**: [e.g. Squad is pre-allocated for a Q4 start; start delay may impact availability.]
- **Technical Access**: [e.g. Standard REST API access provided by Week 1.]

## 2. Standard Commercial Conditions
- **Proposal Validity**: [e.g. 30 Days]
- **Feedback SLA**: [e.g. 3 business days for any major design/PRD review.]
- **Payment Plan**: [e.g. 20% Initial fee, Monthly T&M billing.]

## 3. Explicit Out-of-Scope (Guardrails)
- [OOS Item 1]
- [OOS Item 2]

---

## Interaction Guide

### Greeting
"I am now defining the Commercial Conditions and Scoping Assumptions. This will shield the project from scope creep and define the 'Engagement Guardrails' required to safeguard our estimated timeline and budget."

### Completion
"Commercial Conditions finalized at `/Output/05_Commercial/conditions-assumptions.md`. I have established a clear 'Assumption-Condition' hierarchy and explicitly listed [Number] items as Out-of-Scope."

---

## Quality Rules
- DO NOT use passive language. Use imperative commands (e.g., "Client MUST provide access").
- Every assumption must have a "so what?" condition attached to it.
- Ensure payment terms align with the "Pricing Options" if available.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

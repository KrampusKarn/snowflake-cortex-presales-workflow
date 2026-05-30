---
name: analyzing-tech-stack
description: Make sure to use this skill whenever technology choices are discussed. It Recommends a technology stack per platform based on project requirements and technical assumptions. Flags integration risks and aligns with preferred development standards. Use during the technical definition phase.
---

# Technical Stack Analysis (Consultant Grade)

## Objective
Recommend a professional, scalable, and maintainable technology stack for the entire project ecosystem. This skill ensures that we are not just picking tools, but building a cohesive architecture that aligns with the Company's high standards and account for regional technical constraints.

---

## Technical Workflow

1.  **Ingest Architecture Drivers**:
    *   Read `/Input/Brief/brief.md` and `/Output/04_Technical/technical-assumptions.md`.
    *   **Action**: Identify the "High Stability" components versus "High Innovation" components.

2.  **Define Multi-Platform Stack**:
    *   **Action**: Recommend frontend, backend, and mobile technologies for every platform identified in the IA.
    *   **Mandatory Recommendation**: Align with industry-standard stacks (e.g., React/Next.js for Web, Flutter/Swift for Mobile, Node.js/TypeScript for Backend) unless the brief specifies otherwise.

3.  **Evaluate Infrastructure & Data Residency**:
    *   **Action**: Recommend a cloud provider (AWS/GCP/Azure) and a database strategy.
    *   **Regional Compliance**: Explicitly recommend data residency solutions if PDPA (Thailand) or similar regulations are applicable.

4.  **Audit Integration Risk**:
    *   **Action**: Create a risk matrix for every third-party integration (e.g., Payment Gateways, Legacy CRMs) and define the technical "Wrapper" or "Middleware" strategy to mitigate these risks.

5.  **Synthesize Technical Rationale**:
    *   **Action**: For every major tool choice, provide a 1-sentence "Why this?" that justifies the decision to a CTO-level stakeholder.

6.  **Generate & Save**:
    *   Compile into a structured technical report.
    *   **Action**: Save strictly to `/Output/04_Technical/tech-stack.md`.

---

## Output Structure

# Technical Stack — [Project Name]

## 1. System Architecture Diagram (Conceptual)
[Narrative description of how data flows between Frontends, APIs, and Databases]

## 2. Platform-Specific Recommendations
| Platform | Tech Choice | Rationale |
| :--- | :--- | :--- |
| [e.g. Admin App] | **React / Next.js** | Industry standard for secure, SEO-friendly back-office tools. |

## 3. Backend & Data Infrastructure
- **Core API**: [e.g. Node.js (NestJS) in TypeScript]
- **Primary Database**: [e.g. PostgreSQL]
- **Cloud Hosting**: [e.g. AWS (Bangkok Region)]

## 4. Technical Risk Matrix
| Integration/Node | Risk Level | Mitigation Strategy |
| :--- | :--- | :--- |
| [Legacy Sync] | High | Implement an anti-corruption layer (ACL) middleware. |

---

## Interaction Guide

### Greeting
"I am now conducting the Technical Stack Analysis. I'll be selecting a robust and scalable architecture for each platform, ensuring we align with the Company's preferred standards and regional compliance requirements."

### Completion
"Technical Stack Analysis is complete and saved to `/Output/04_Technical/tech-stack.md`. I have recommended a [Arch Type] architecture focused on [Priority, e.g., scalability and PDPA compliance]."

---

## Quality Rules
- Recommendations must be specific (version-agnostic but library-aware).
- Every major integration point must have a corresponding risk entry.
- Data residency must be addressed for any project involving PII in Thailand.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

---
name: generating-technical-assumptions
description: Make sure to use this skill to safeguard the project scope. It Generates technical assumptions covering architecture, third-party integrations, platform constraints, data requirements, and security or compliance considerations. Use during the technical scoping phase.
---

# Technical Assumptions & Constraints

## Objective
Establish the "Technical Guardrails" for the project. This skill ensures that our estimates are protected by defining the starting point of our technical responsibility, clearly stating what the client must provide and what we are excluding from the core scope.

---

## Technical Workflow

1.  **Extract Complexity Signals**:
    *   Read `/Input/Brief/brief.md` and `/Output/02_Product/feature-list.md`.
    *   **Action**: Identify any "Black Box" requirements (e.g., "AI Matching Engine," "Legacy Sync") that require protective assumptions.

2.  **Define Infrastructure & Hosting Boundaries**:
    *   **Action**: State who provides the hosting, who manages the CI/CD, and where the data is physically stored.
    *   **Mandatory**: Include a PDPA/Data Sovereignty assumption for any project in the SEA region.

3.  **Map Integration Dependencies**:
    *   **Action**: For every 3rd party service, state the assumption of "RESTful API availability" and "Proper Documentation Provision" by the client.

4.  **Define Device & Browser Support**:
    *   **Action**: Set the boundaries for support (e.g., "Latest 2 versions of Chrome," "iOS 16+").

5.  **Document Security & Performance SLA**:
    *   **Action**: State the base security standard (e.g., "MFA for Admins", "SSL/TLS") and any performance benchmarks being assumed (e.g., "< 2s response time").

6.  **Generate & Save**:
    *   Compile into a structured markdown report.
    *   **Action**: Save strictly to `/Output/04_Technical/technical-assumptions.md`.

---

## Output Structure

# Technical Assumptions — [Project Name]

## 1. Core Architectural Assumptions
- [e.g. System will use a micro-frontend architecture for multi-tenant scalability.]

## 2. Integration & Third-Party Dependencies
| Service | Assumption | Risk if Invalid |
| :--- | :--- | :--- |
| [e.g. SAP CRM] | Client provides Sandbox access by Week 1. | Timeline delay of 2 weeks per week of delay. |

## 3. Platform & Compliance Standards
- **Browser/Mobile Support**: [Bullet list of versions]
- **Regional Compliance**: [e.g., PDPA (Thailand) adherence assumed for all local PII.]

## 4. Developer & DevOps Assumptions
- **Hosting**: [Account owner/provider]
- **CI/CD**: [Automation tool assumed]

---

## Interaction Guide

### Greeting
"I am now defining the Technical Assumptions and Guardrails. This is a critical step to protect our scope and ensure the client understands their technical responsibilities before we commit to a timeline."

### Completion
"Technical Assumptions finalized at `/Output/04_Technical/technical-assumptions.md`. I have flagged [Number] integration dependencies that are critical for our project's success."

---

## Quality Rules
- DO NOT use vague language (e.g., "Standard security"). Be specific: "JWT-based authentication."
- Every "Assumption" should have a corresponding "Risk" or "Implication" if the assumption proves false.
- Ensure the assumed tech stack from `tech-stack.md` is respected.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

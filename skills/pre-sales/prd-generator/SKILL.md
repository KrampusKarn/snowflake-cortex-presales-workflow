---
name: generating-prds
description: Make sure to use this skill whenever you need to translate high-level business goals into granular technical requirements. This is the core engine for defining the "What" and "How" of every platform in the project. Generates Product Requirements Documents (PRDs) broken down by platforms and phases.
---

# Product Requirements Document (PRD) Generator

## Objective
Generate professional, consultant-grade PRDs that decompose business epics into granular, testable features. This skill ensures that every requirement is tied to a specific platform and delivery phase, providing an unambiguous blueprint for design and development.

---

## Technical Workflow

1.  **Ingest Project Brief**:
    *   Read `/Input/Brief/brief.md` to identify the project scope, objectives, and platform list.
    *   **Action**: Identify the "Core Transaction" for each platform to guide feature prioritization.

2.  **Define Epics & Granular Features**:
    *   **Action**: Group requirements into high-level Epics (e.g., User Management, Transaction Engine).
    *   **Decomposition Requirement**: You MUST include "Implicit Features" that are required for a professional product, including:
        *   **Auth Sub-flows**: MFA, Reset Password, Session Timeouts.
        *   **User Management**: Soft Deletion, Avatar Management, Role-Based Access Control (RBAC).
        *   **Platform Utilities**: Dark/Light mode support, Offline state handling, Data pagination.

3.  **Phase & Platform Tagging**:
    *   **Action**: Assign every feature to a specific Platform (Web, iOS, Android, Admin) and a Phase (MVP, Phase 1, Phase 2).

4.  **Audit Against Personas**:
    *   **Action**: Read `/Output/01_Research/personas.md` to ensure every persona's JTBD is supported by at least one feature in the PRD.

5.  **Generate Structured Tables**:
    *   **Mandatory**: Use the standardized PRD table format.
    *   **Action**: Create a separate markdown file for each platform: `/Output/02_Product/prd-[platform].md`.

---

## Output Structure

# PRD — [Platform Name] — [Project Name]

## 1. Platform Summary
- **Primary Goal**: [Narrative description]
- **Target User(s)**: [Persona Name(s)]
- **Release Phase**: [MVP/P1/P2]

## 2. Requirement Table
| ID | Epic | Feature | Description | Constraints |
| :--- | :--- | :--- | :--- | :--- |
| [Code]-[Seq] | [Name] | **[Feature]** | [Clear 'What' & 'Why'] | [e.g., PDPA Compliance] |

---

## Interaction Guide

### Greeting
"I am now generating the Product Requirements Document for the [Platform Name]. I'll be decomposing our high-level goals into granular features, ensuring we cover both explicit brief requirements and essential platform utilities."

### Completion
"PRD for [Platform Name] has been generated and saved to `/Output/02_Product/prd-[platform].md`. All features have been prioritized for [Phase] and cross-verified against our primary user personas."

---

## Quality Rules
- DO NOT combine multiple screens into a single feature row. Every interactive screen deserves a row.
- "Description" must be written in a way that remains clear to a non-technical stakeholder while being precise enough for a developer.
- Ensure all Admin features (CRUD for every entity) are explicitly listed in the Admin PRD.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

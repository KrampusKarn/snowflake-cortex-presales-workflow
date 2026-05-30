---
name: sales-rfp-analyzer
description: Make sure to use this skill whenever you receive a raw RFP, client notes, an SOW, or any raw material that needs to be distilled into a project brief. This is the mandatory entry point for any new project, as it generates the Single Source of Truth (brief.md) that all other skills rely on.
---

# RFP Analysis & Project Brief Generator (Consultant Grade)

**WARNING: Your output must contain ZERO reference links, footnotes, citations, or numbered references. Output clean text only.**

## Objective
Analyze the provided RFP and related documents, search for publicly available information about the client's company, and create a structured business document. You must dynamically identify all required platforms, detail the business logic connecting them, list technical assumptions, and categorize follow-up questions for a kickoff meeting.

---

## Technical Workflow

1.  **Conduct Company Research**:
    *   Search online to extract the Number of employees, Headquarters location, and estimated yearly revenue.
    *   Identify the core value proposition and known competitors.
    *   Mark unavailable data as "Not Available".

2.  **Analyze Source Material**:
    *   Read all documents in the `/Input` folder.
    *   Extract Project name, objectives, budget, and timeline.
    *   **Action**: Identify key stakeholders and decision-makers mentioned in the text.
    *   **Acronym Clarification**: Explain acronyms or mark them as "Requires clarification".

3.  **Map the Platform Ecosystem**:
    *   Determine the mandatory platforms (Customer App, Admin Panel, Service Provider App, etc.).
    *   **Requirement**: You MUST create a dedicated PRD table for *every* platform identified.

4.  **Extract Functional Requirements**:
    *   Group features by platform and Epic.
    *   **Action**: Include "Foundational Features" (Auth, Profile, Notifications, Admin Ops) even if not explicitly requested in the brief.

5.  **Develop the "Golden Thread"**:
    *   Write a narrative describing a core transaction (e.g., booking a room) from the initial user action to the backend completion across all platforms.

6.  **Synthesize Output**:
    *   Compile all findings into a structured markdown document.
    *   **Action**: Save the result to `/Input/Brief/brief.md`. If the file exists, increment the name (e.g., `brief-1.md`).

---

## Output Structure

### 1. Project Summary
*   **Project Name**: [Name]
*   **Client**: [Company]
*   **Business Objectives**: [List]
*   **Key Stakeholders**: [List]

### 2. Company & Market Context
*   Summarize headquarters, revenue, and value proposition.

### 3. Platform Architecture
*   List every platform and its primary purpose.
*   **The Golden Thread**: [Detailed narrative].

### 4. Product Requirements (Table Format)
| ID | Title | Description | Constraints |
|:---|:---|:---|:---|
| AU-01 | Auth | MFA, Reset, Login | Standard |

---

## Interaction Guide

### Greeting
"I will now ingest your raw material and conduct market research to establish the **Single Source of Truth (brief.md)**. This document will serve as the foundation for the entire pre-sales estimation and discovery process."

### Completion
"The Project Brief has been generated at `/Input/Brief/brief.md`. I have mapped [Number] platforms and identified the 'Golden Thread' connecting them. Please review this document before we proceed to Stage 2 (Research & Discovery)."

---

## Quality Rules
- DO NOT include reference links or footnote numbers.
- DO NOT include citations or bibliographic references.
- Use clean, structured markdown for easy copy-pasting to Google Docs.
- Clearly mark missing info as "To Be Confirmed".

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- cortex_search: search_briefs

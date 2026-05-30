---
name: user-flows-generator
description: Make sure to use this skill to map user journeys in detail. Generates user flows for each platform in a project, organized by role and phase.
---

# User Flow Generator (Indented Logic)

## Objective
Map the precise logic and navigation paths for every user role across every platform. This skill ensures we have a non-visual, highly readable logic map that identifies decision points, error states, and cross-platform transitions, serving as the ultimate reference for wireframing.

---

## Technical Workflow

1.  **Retrieve IA & Personas**:
    *   Read `/Output/02_Product/information-architecture.md` and `/Output/01_Research/personas.md`.
    *   **Action**: Confirm the list of "User Roles" and "Platforms" that require flow mapping.

2.  **Draft Authentication & Onboarding (Mandatory)**:
    *   **Mandatory**: You MUST generate these flows for every role even if not in the brief: Signup, Login, Forgot Password, Profile Management, MFA (if Fintech/Health).

3.  **Map Core Functional Flows**:
    *   **Action**: For each role, map their primary "Job to be Done" using the indented bullet list format.
    *   **Inclusion Requirement**: Include [Decision Points], [Outcome A/B], and [Error States] for every core flow.

4.  **Apply Standard Logic Syntax**:
    *   Use `→` for outcomes.
    *   Use `[Error]` for edge cases.
    *   Use `[Phase 2]` for enhancement flows.

5.  **Generate & Save**:
    *   Compile into a self-contained markdown file.
    *   **Action**: Save strictly to `/Output/02_Product/user-flows.md`.

---

## Flow Syntax (Indented Lists)
- [Flow Name]
  - [Trigger / Entry Point]
    - [Standard Step]
      - [Decision Point?]
        - [Condition A] → [Outcome]
        - [Condition B] → [Outcome]
    - [Error Case]
      - [Fallback / Message]

---

## Interaction Guide

### Greeting
"I am now generating the detailed User Flows for our platforms. I'll be mapping every step from authentication to core functional transactions, ensuring we account for every decision point and error state in a highly readable logic map."

### Completion
"User Flows have been successfully mapped and saved to `/Output/02_Product/user-flows.md`. I have detailed [Number] unique flows across [Number] platforms, including both MVP and future phase enhancements."

---

## Quality Rules
- No "dead-end" flows. Every path must have a final state or a redirection.
- Every platform and user role identified in the brief must be covered.
- Flows must be strictly text-based (no mermaid diagrams here) for maximum copy-paste ease.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

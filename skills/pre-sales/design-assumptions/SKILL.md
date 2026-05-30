---
name: generating-design-assumptions
description: Make sure to use this skill to define the visual and UX boundaries of the project. It Analyzes project requirements and documentation to generate structured design assumptions and scope boundaries. Use when preparing for sales estimations, RFP responses, or starting a design phase.
---

# Design assumptions & UI/UX Boundaries

## Objective
Define the "Visual DNA" and UX boundaries of the project. This skill ensures that our design effort estimates are grounded in a clear understanding of branding availability, asset requirements, and device-specific constraints.

---

## Technical Workflow

1.  **Ingest Visual DNA Indicators**:
    *   Read `/Input/Brief/brief.md` and scan the `/Input` folder for any brand books or existing UI links.
    *   **Action**: Identify if this is a "Net New Brand" or an "Evolution of Existing Brand."

2.  **Define Component & System Scope**:
    *   **Action**: Determine if we are building a "Custom Design System" from scratch or utilizing an existing library (e.g., Material UI, Ant Design).
    *   **Mandatory**: State the tool of choice (Figma/Pencil).

3.  **Map Device & Responsive Surface**:
    *   **Action**: Explicitly list the breakpoints (Desktop, Tablet, Mobile) that are IN SCOPE versus OUT OF SCOPE.

4.  **Audit Asset Provisioning**:
    *   **Action**: State the assumption for images, icons, and copywriting (e.g., "Client provides high-res imagery and brand-ready copy").

5.  **Identify UX Edge Cases**:
    *   **Action**: Document assumptions for complex flows (e.g., "Dark mode is not in MVP," "Right-to-Left (RTL) support is out of scope").

6.  **Generate & Save**:
    *   Compile into a structured markdown report.
    *   **Action**: Save strictly to `/Output/04_Technical/design-assumptions.md`.

---

## Output Structure

# Design Assumptions — [Project Name]

## 1. Visual Identity & Branding
- **Source**: [Style guide provided / To be created]
- **Language**: [L1/L2 requirements]

## 2. UI/UX Strategy & Tooling
- **Platform Strategy**: [e.g., Mobile-first responsive]
- **Design System**: [e.g., Customized Tailwind/MUI base]

## 3. Explicit Design Scope
| Category | In Scope | Out of Scope |
| :--- | :--- | :--- |
| **Devices** | Desktop, iPhone 15 | Android Tablet |
| **States** | Empty, Success, Error | Accessibility (WCAG 2.1 AAA) |

## 4. Copy & Asset Governance
- [e.g. Localization files provided in JSON format by client.]

---

## Interaction Guide

### Greeting
"I am now establishing the Design Assumptions and Visual Boundaries. I'll be defining what we are designing for, which devices are supported, and what branding assets we expect the client to provide."

### Completion
"Design Assumptions finalized at `/Output/04_Technical/design-assumptions.md`. I have explicitly listed [Number] items that are Out of Scope to ensure our design estimate remains lean and focused."

---

## Quality Rules
- Every design assumption MUST be verifiable against the final UI library.
- "Out of Scope" list must be assertive to prevent "UX Creep."
- Ensure responsive breakpoints are clearly defined to avoid estimation ambiguity.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

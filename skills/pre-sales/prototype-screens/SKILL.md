---
name: generating-prototype-screens
description: Make sure to use this skill when the user requests wireframes, screen specs, or a prototype outline. Generates high-level prototype specifications for key screens. Aligns with MVP phase, PRD requirements, and brand guidelines.
---

# Prototype Spec & Wireframe Blueprint

## Objective
Translate the PRD and IA into visual specifications. This skill provides the "Blueprint" for the 4-6 most critical screens of the product, detailing content hierarchy, UI component placement, and interaction logic before a designer starts the Hi-Fi UI phase.

---

## Technical Workflow

1.  **Identify Hero Screens**:
    *   Read `/Output/02_Product/information-architecture.md` and `/Output/02_Product/user-flows.md`.
    *   **Action**: Select the 4-6 "High Impact" screens (e.g., Dashboard, Main Transaction Screen, Results List) per platform.

2.  **Apply Brand Blueprint**:
    *   Read `/Output/03_Design/brand-guidelines.md`.
    *   **Action**: Identify the spacing rules, typography hierarchy, and button styles that must be applied to these screens.

3.  **Define Content Hierarchy**:
    *   **Action**: For every screen, list content from Top (Highest Priority) to Bottom.
    *   **Action**: Specify exactly which UI Components (Card, Table, Fab, etc.) are used for each data point.

4.  **Create ASCII Wireframes**:
    *   **Mandatory**: Generate a structured ASCII or block-based wireframe sketch to show the spatial arrangement of elements.

5.  **Document Interaction Logic**:
    *   **Action**: Detail what happens on click, swipe, or hover for every primary action on the screen.

6.  **Generate & Save**:
    *   Save into a structured report strictly to `/Output/03_Design/prototype-[platform].md`.

---

## Output Structure

# Prototype Specification — [Platform] — [Project Name]

## 1. Release & Visual Context
- **Phase**: MVP
- **Visual DNA**: [Key traits from brand guidelines]

## 2. Screen: [Name]
- **Objective**: [Goal]
- **Content Mix**: [Data Points]
- **Interaction Rules**: [Logic]

### Wireframe Sketch
```markdown
+---------------------------+
| [Header]      [Profile]   |
+---------------------------+
| [Hero Segment]            |
+---------------------------+
| [List Card]               |
| [List Card]               |
+---------------------------+
```

---

## Interaction Guide

### Greeting
"I am now drafting the Prototype Specifications for our core MVP screens. I'll be translating our PRD into a visual blueprint, detailing content hierarchy and interaction logic, and providing ASCII wireframes to steer the design direction."

### Completion
"Prototype Specifications for [Platform] have been finalized at `/Output/03_Design/prototype-[platform].md`. I have detailed the 4-6 most critical screens, ensuring they align perfectly with our brand guidelines and MVP scope."

---

## Quality Rules
- Focus strictly on MVP features. DO NOT include Phase 2 elements in the prototype specs.
- The wireframe sketch must clearly show the relative placement of Navigation vs. Content.
- Use descriptive names for sections (e.g., "Global Search", "Primary CTA", "Entity Summary Card").

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

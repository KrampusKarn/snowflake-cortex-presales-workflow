---
name: generating-brand-guidelines
description: Make sure to use this skill whenever the user mentions brand guidelines, design direction, visual tones, typography, color palettes, or wants to extract branding from an existing website or competitor. It generates a high-level design direction document to align stakeholders before UI work begins.
---

# Generating Brand Guidelines

## Objective
- During the "Design Direction" phase (Stage 4).
- To align stakeholders on visual aesthetics before any UI design or prototyping.
- When branding is undefined or needs to be extracted from an existing digital presence.

## Technical Workflow

1. **Gather References**:
    - Ask the user to provide a URL to an existing website or competitor.
    - If they have reference images or brand CI documents, instruct them to upload those files to `/Input/brand_references/`.
    - If they provide manual details (e.g., "Primary color is #FF0000, secondary is blue, logo is here"), note them down.

2. **Automated Analysis**:
    - If the user provides a URL, run `python scripts/analyze_brand.py --url [URL]` to automatically take a screenshot of the site and extract computed colors and typography patterns.
    - Review the resulting data in `/Input/brand_references/analysis_data.json`.

3. **Visual Analysis**:
    - Study the gathered screenshots or reference files in `/Input/brand_references/` to identify qualitative elements:
        - **Visual Tone**: What is the overall vibe? (e.g., Clean, Professional, Bold, Minimalist).
        - **Imagery Style**: What kind of imagery is used? (e.g., Real-world photography, Vector illustrations, 3D).
        - **Spacing & Density**: How dense is the layout? (e.g., Airy with lots of white space, High-density informative).

4. **User Clarification**:
    - Use the `notify_user` tool to proactively ask clarifying questions to resolve any ambiguities. For example:
        - "What is the primary brand color hex code?"
        - "Do you have a preference for Serif or Sans-Serif typography?"
        - "Are there any specific 'brand values' we should reflect?"

5. **Generate Guidelines**:
    - Compile your findings into a structured brand guidelines document.

6. **Save to /Output**:
    - ALWAYS save the final document strictly to `/Output/03_Design/brand-guidelines.md`.

## Output Structure

The output `/Output/03_Design/brand-guidelines.md` MUST use this exact structure:

```markdown
# Brand Guidelines — [Project Name]

## 1. Visual Tone & Mood
[Description of the overall "vibe" — e.g., "Professional & Trustworthy with a modern SaaS aesthetic."]

## 2. Color Palette
- **Primary:** `#[Hex]` — [Rationale]
- **Secondary:** `#[Hex]` — [Rationale]
- **Neutral/Background:** `#[Hex]`
- **Success/Error:** `#[Hex]` / `#[Hex]`

## 3. Typography Direction
- **Primary Typeface:** [e.g., Inter (Sans-Serif)] — [Rationale: Readability, Modernity]
- **Secondary/Heading Typeface:** [e.g., Playfair Display (Serif)]
- **Scale:** [Notes on heading levels and body text weight]

## 4. Iconography & Imagery
- **Icon Style:** [e.g., Outlined, 2px stroke, Rounded]
- **Imagery Direction:** [e.g., "Candid office photography with a blue tint filter."]

## 5. UI Style & Density
- **Spacing:** [e.g., 8px grid, generous white space]
- **Corners:** [e.g., Soft corners (8px radius) vs Sharp]
- **Buttons:** [Description of primary/secondary button style]
```

## Interaction Guide

When this skill is triggered, start by sending a friendly message to the user explaining the process:

"I will now help you define the brand guidelines for [Project Name]. I'll start by asking for a website URL or reference files. I'll then analyze these visual cues, extract colors and typography, and present a structured design direction in `/Output/03_Design/brand-guidelines.md`."

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none


---
name: analyzing-market-research
description: Make sure to use this skillGround the proposal in market reality, especially if the project targets Thailand or Southeast Asia. Conducts industry and market research based on the project brief. Extracts market size, trends, and user behavior patterns.
---

# Analyzing Market Research

## Objective
Provide a strategic, evidence-based research report that validates the market opportunity. This skill ensures that we are not just building a product, but building the *right* product for the current market landscape, with a mandatory focus on regional specificities if applicable.

---

## Technical Workflow

1.  **Ingest Industry Context**:
    *   Read `/Input/Brief/brief.md` to pinpoint the specific industry vertical (e.g., HealthTech, Fintech).
    *   **Action**: List any client-provided research or stated market assumptions in the `/Input` folder.

2.  **Define Market Size & Growth**:
    *   Find credible market size signals (TAM/SAM/SOM) and growth rates (CAGR).
    *   **Action**: Benchmark these against regional standards to ensure realistic expectations.

3.  **Identify Mega-Trends**:
    *   Isolate 3-5 macro trends shaping the sector (e.g., "Shift to cashless payments", "AI-driven diagnostics").
    *   **Action**: Detail the *implication* of each trend for the client's specific project.

4.  **Analyze Regional Dynamics (Thailand/SEA)**:
    *   **Mandatory**: Check for local dominance (e.g., Line OA in Thailand, Super-apps like Grab/Gojek).
    *   **Action**: Identify local regulatory constraints (e.g., PDPA for data privacy).

5.  **Synthesize Strategic Recommendations**:
    *   Based on research, provide 2-3 specific strategic recommendations for the product's MVP.

6.  **Generate & Save**:
    *   Compile into a professional report.
    *   **Action**: Save strictly to `/Output/01_Research/market-research.md`.

---

## Output Structure

# Market Research — [Project Name]

## 1. Market Opportunity Summary
[High-level pitch on the 'Why Now']

## 2. Market Size & Economic Signals
- [Data Point 1] -> [Implication]
- [Data Point 2] -> [Implication]

## 3. Top Industry Trends
- [Trend A] -> Strategic Impact: [Text]
- [Trend B] -> Strategic Impact: [Text]

## 4. Regional Landscape (SEA/Thailand Focus)
- **Local Standards**: [e.g., PromptPay integration requirement]
- **Regulatory**: [e.g., PDPA Compliance]

## 5. Strategic Product Recommendations
1. [Recommendation 1]
2. [Recommendation 2]

---

## Interaction Guide

### Greeting
"I will now ground this proposal in market reality. I'm conducting industry research with a specific focus on the [Industry] landscape in [Region], identifying the signals that will shape our final strategy."

### Completion
"Market Research has been finalized and saved to `/Output/01_Research/market-research.md`. I have identified [Number] key trends that significantly impact our proposed MVP scope."

---

## Quality Rules
- Research reflects current-year data where possible.
- Regional context focuses on actual user behavior (e.g., mobile-first habits).
- Recommendations are actionable and linked to research findings.

## Cortex Agent Tools
<!-- Used by cortex-agent-converter to configure Snowflake agent tools -->
- tools: none

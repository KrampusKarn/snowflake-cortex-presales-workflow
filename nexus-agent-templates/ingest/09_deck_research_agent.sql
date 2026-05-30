-- ═══════════════════════════════════════════════════════════════════
-- DECK_RESEARCH_AGENT — Cortex Search Q&A over proposal deck + outputs
-- Deploy after search services and INDEX_FINAL_ASSETS workflow is tested.
-- Replace database/schema in tool_resources if not using defaults.
-- ═══════════════════════════════════════════════════════════════════

CREATE OR REPLACE AGENT SPS_BUSINESS_INSIGHT.NEXUS.DECK_RESEARCH_AGENT
COMMENT = 'Proposal deck Q&A: searches indexed deck, workflow outputs, and source documents'
FROM SPECIFICATION
$$
models:
  orchestration: auto

orchestration:
  budget:
    seconds: 600
    tokens: 200000

instructions:
  orchestration: |
    # Proposal Deck Research Agent

    ## Role
    You answer questions about the proposal deck, executive summary, and final packaging
    materials for an active pre-sales engagement. Retrieve facts from indexed content — not from memory.

    ## Workflow
    1. Clarify the question — slide/section, topic, or stakeholder concern.
    2. Search the deck first via `search_proposal_deck`.
    3. Cross-reference `search_workflow_outputs` for PRDs, estimates, or research detail.
    4. Use `search_source_documents` only to verify deck claims against the original RFP.
    5. Cite slide/section titles; quote key messages; flag gaps if content is not indexed.

    ## Constraints
    - Always search before answering factual questions.
    - Do not invent slide content not in search results.
    - If content is missing, tell the user to run export + index_final_assets for the run.

  response: |
    When starting: "I can search the proposal deck and related outputs. What slide or topic would you like to explore?"
    When completing: cite indexed sources and offer to cross-check against RFP or estimates.

tools:
  - tool_spec:
      type: cortex_search
      name: search_proposal_deck
      description: "Search proposal deck slides, executive summary, and final packaging documents."

  - tool_spec:
      type: cortex_search
      name: search_workflow_outputs
      description: "Search generated workflow outputs (PRDs, estimates, research)."

  - tool_spec:
      type: cortex_search
      name: search_source_documents
      description: "Search original RFP, brief, and client source documents."

tool_resources:
  search_proposal_deck:
    search_service: SPS_BUSINESS_INSIGHT.NEXUS.PROPOSAL_DECK_SEARCH
    id_column: DOC_ID
    title_column: TITLE
    max_results: 8

  search_workflow_outputs:
    search_service: SPS_BUSINESS_INSIGHT.NEXUS.WORKFLOW_OUTPUTS_SEARCH
    id_column: DOC_ID
    title_column: TITLE
    max_results: 8

  search_source_documents:
    search_service: SPS_BUSINESS_INSIGHT.NEXUS.SOURCE_DOCUMENTS_SEARCH
    id_column: DOC_ID
    title_column: TITLE
    max_results: 5
$$;

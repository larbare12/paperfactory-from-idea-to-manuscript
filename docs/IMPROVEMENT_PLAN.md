# Improvement Plan: Integrate ARS Prompts into paper.skill

## Strategy
paper.skill has executable infrastructure (scripts, APIs, databases) but lean prompts.
ARS has rich prompts (agents, references, templates, protocols) but no executable tools.
**Integrate ARS's prompt assets into paper.skill's executable infrastructure.**

## Phase 1: Import Reference Materials (reference/)
Copy ARS's deep knowledge repositories that paper.skill lacks:
- APA 7 style guide
- Source quality hierarchy
- Methodology patterns catalog
- Logical fallacies catalog
- Ethics checklists & IRB decision tree
- Systematic review toolkit (PRISMA 2020)
- Argumentation reasoning framework
- Academic writing style guide (ARS version, complementary to existing)
- Citation format switcher
- Journal submission guide
- Review criteria framework
- Statistical reporting standards
- Failure paths / AI research failure modes catalog

## Phase 2: Add Templates (templates/)
Copy ARS's structured output templates:
- IMRaD paper template
- Conference paper template
- Bilingual abstract template
- Revision tracking template
- Peer review report template
- Editorial decision template
- Revision response template

## Phase 3: Enhance Existing Modules with ARS Agent Knowledge
- M1 (topic): Enrich with ARS's intake agent patterns, Socratic dialogue protocol
- M2 (literature): Enrich with ARS's source quality hierarchy, bibliography agent, systematic review patterns
- M4 (structure): Enrich with ARS's paper structure patterns (IMRaD, case study, theoretical)
- M5 (argument): Enrich with ARS's logical fallacies catalog, enhanced Devil's Advocate
- M6 (writing): Enrich with ARS's writing style guide, writing quality checklist
- M7 (final-check): Enrich with ARS's review criteria, editorial decision framework

## Phase 4: Add New Modules
- M8 peer-review: Inspired by ARS's academic-paper-reviewer (7 agents, 6 modes)
- M9 compliance-check: PRISMA-trAIce + RAISE compliance verification

## Phase 5: Add Shared Protocols (shared/)
- PRISMA-trAIce protocol (17-item checklist)
- RAISE framework
- Style calibration protocol
- Cross-model verification protocol
- Collaboration depth rubric
- Handoff schemas

## Phase 6: Update SKILL.md
- Register new modules
- Add new modes (peer-review, compliance-check)
- Update workflow diagram
- Add trigger keywords

## Files to NOT copy (paper.skill already has better or equivalent)
- paper.skill M2 already covers literature management better with real API
- paper.skill already has Devil's Advocate in M5
- paper.skill already has Anti-Leakage in M6
- paper.skill already has Material Passport
- ARS's agents are prompt-only; paper.skill's scripts are executable
- ARS's pipeline orchestrator is superseded by paper.skill's M0-M7 pipeline

<div align="center">

# paperfactory: from idea to manuscript

<sub><b>Fully Automated Paper Production Pipeline — Claude Code Plugin</b></sub>

<p>
  <img alt="Claude Code Plugin" src="https://img.shields.io/badge/Claude%20Code-Plugin-7C3AED?style=flat-square">
  <img alt="Skills" src="https://img.shields.io/badge/skills-10-2563EB?style=flat-square">
  <img alt="Hooks" src="https://img.shields.io/badge/hooks-4-059669?style=flat-square">
  <img alt="Status" src="https://img.shields.io/badge/status-active-22C55E?style=flat-square">
</p>

M0 Dashboard · M1–M9 Pipeline · citation-search sub-skill<br>
Topic diagnosis · literature management (<b>Tier 0 anti-hallucination + venue quality</b>) · experimental design<br>
structure planning · argumentation · writing assistance · pre-submission audit · peer review simulation · compliance check

<sub>
  <a href="#quick-start">Quick Start</a> ·
  <a href="#architecture">Architecture</a> ·
  <a href="#features">Features</a> ·
  <a href="../README.md">中文文档</a> ·
  <a href="https://larbare12.github.io/paperfactory-from-idea-to-manuscript/">Web Docs</a>
</sub>

</div>

---

## Why

Grad students worldwide suffer through the paper grind. **paperfactory** automates the entire pipeline — from idea to manuscript. You bring the idea. The assembly line handles the rest.

---

## Quick Start

### 1. Install

**Option A: One-liner**

```bash
curl -fsSL https://raw.githubusercontent.com/larbare12/paperfactory/master/install.sh | bash
```

This clones paperfactory into `~/.claude/plugins/paperfactory/`. If it already exists, it runs `git pull` to update.

**Option B: Manual install (if the script fails)**

```bash
# 1. Clone into Claude Code's plugin directory
mkdir -p ~/.claude/plugins
git clone https://github.com/larbare12/paperfactory-from-idea-to-manuscript.git ~/.claude/plugins/paperfactory

# 2. Verify the plugin is recognized (if /paperfactory:init works, you're good)
claude --version
```

### 2. Run inside your paper project

```bash
cd /path/to/your-paper-project
claude  # start session
```

On first entry, run:

```
/paperfactory:init
```

This will automatically:

1. Check git repo + workspace state
2. Verify S2 API key credentials (`.env`)
3. Initialize `relate-work/` + `manifest.jsonl`
4. Enable hooks (SessionStart / PreToolUse / PostToolUse / Stop)
5. Run the M0 dashboard first scan
6. Suggest next steps

> You'll need an S2 API key: [semanticscholar.org/product/api](https://www.semanticscholar.org/product/api)

### 3. Follow the M0–M9 workflow

<table>
  <thead>
    <tr>
      <th align="left">Task</th>
      <th align="left">Command</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>Find papers / verify citations / check venue quality</td><td><code>@citation-search</code></td></tr>
    <tr><td>Evaluate idea feasibility</td><td><code>@m1-topic</code></td></tr>
    <tr><td>Literature review / bib management</td><td><code>@m2-literature</code></td></tr>
    <tr><td>Experimental design</td><td><code>@m3-experiment</code></td></tr>
    <tr><td>IMRAD outline</td><td><code>@m4-structure</code></td></tr>
    <tr><td>Argument skeleton / DA red-team</td><td><code>@m5-argument</code></td></tr>
    <tr><td>Draft writing / paragraph polishing</td><td><code>@m6-writing</code></td></tr>
    <tr><td>Pre-submission audit</td><td><code>@m7-final-check</code></td></tr>
    <tr><td>Peer review simulation</td><td><code>@m8-peer-review</code></td></tr>
    <tr><td>Compliance + AI disclosure</td><td><code>@m9-compliance-check</code></td></tr>
    <tr><td>View project status</td><td><code>@m0-dashboard</code></td></tr>
  </tbody>
</table>

---

## Architecture

<details>
<summary><b>Click to expand full directory tree</b></summary>

```
.claude-plugin/
└── plugin.json              # plugin manifest

skills/
├── citation-search/         # standalone retrieval/verification base (cross-cutting, used by the other 9 skills)
│   ├── SKILL.md
│   ├── scripts/             # paper_search.sh, verify_citations.sh, venue_lookup.sh, ...
│   ├── config/api.json      # S2/CrossRef endpoints
│   ├── data/                # CCF + JCR IF sqlite
│   └── reference/           # protocols: literature-research / anti-hallucination / venue-quality / manifest-schema
├── m0-dashboard/            # project dashboard (cross-cutting, always active)
├── m1-topic/                # topic diagnosis
├── m2-literature/           # literature management
├── m3-experiment/           # experimental design
├── m4-structure/            # structure planning
├── m5-argument/             # argumentation + DA protocol
├── m6-writing/              # writing assistance + Anti-Leakage
├── m7-final-check/          # pre-submission audit
├── m8-peer-review/          # peer review simulation
└── m9-compliance-check/     # compliance & ethics check

commands/
└── init.md                  # /paperfactory:init

hooks/
├── hooks.json               # plugin-enforced hooks declaration
├── session-start.sh         # auto-runs verify_config + M0 mini on entering a paper project
├── pre-draft-write.sh       # prompts commit checkpoint before writing to draft/
├── post-draft-write.sh      # alerts if new citations haven't gone through Tier 0
└── stop-scan-gaps.sh        # alerts if [NEEDS-EVIDENCE] count changes

reference/                   # cross-skill shared knowledge base (non-retrieval)
├── writing/                 # 15 files, writing style / language / formatting
├── research/                # 12 files, research methodology / experimental design
├── review/                  # 9 files, peer review / quality assessment
└── compliance/              # 11 files, PRISMA-trAIce / RAISE / AI disclosure

templates/                   # 15 output templates (IMRAD / poster / review report / ...)

docs/
├── README_EN.md             # English docs (this file)
├── index.html               # GitHub Pages web documentation
```

</details>

---

## Features

### Anti-Hallucination Hard Constraints

- **Tier 0 verification**: DOI reverse lookup + Levenshtein ≥ 0.70, identifies 5 hallucination types (TF / PAC / IH / PH / SH)
- **Three-layer validation**: Layer 1 Source → Layer 2 Citation → Layer 3 Content consistency
- **Red-line checklist**: model-memorized post-2024 citations / preprint passed as journal / skipping verify_citations.sh — any trigger → immediate STOP
- **Abstract-only anti-pattern**: paraphrasing from abstract alone is forbidden; full-text reading required

See [`skills/citation-search/reference/anti-hallucination-protocol.md`](../skills/citation-search/reference/anti-hallucination-protocol.md).

### Venue Quality Gate

Anti-hallucination only guarantees a citation is **real**, not that it's **top-tier**. M2 screening enforces `venue_lookup.sh`:

- Preprints (NBER WP / arXiv / SSRN) cannot serve as methodology baselines
- Top-journal whitelist + CCF + JCR IF auto-grading
- Real incident: 2026-05-08 NBER WP w29166 used as baseline → entire layer rewritten

See [`skills/citation-search/reference/venue-quality-protocol.md`](../skills/citation-search/reference/venue-quality-protocol.md).

### Three-Stage Literature Workflow

Broad search (`--mode multi`) → Screening (Stage 2) → Collection (`collect_papers.sh` auto-entry into manifest + OA PDF download) → user fills in closed-access gaps → prune unfindable.

See [`skills/citation-search/reference/literature-research-protocol.md`](../skills/citation-search/reference/literature-research-protocol.md).

### Anti-Leakage Protocol (M6 Writing Rule)

Parametric memory must not be used to fill factual gaps. Every data point, citation, and statistic must have either a `relate-work/` local source or a `find_evidence.sh` live retrieval result. Missing evidence must be marked `[MATERIAL GAP: ...]`; `check_material_gaps.sh` rejects any final draft containing GAP markers.

### Devil's Advocate Pass (M5 autonomous, mandatory)

Anti-cascade-concession: for each core claim (3–7), run three rounds of Attack / Rebuttal / Concession. Rebuttal score < 4 triggers soften/drop.

---

## Credentials

```bash
# Create .env in your paper project root
cp ${CLAUDE_PLUGIN_ROOT}/.env.example .env

# Get an S2 API key at https://www.semanticscholar.org/product/api
# Fill in .env:
S2_API_KEY=Bearer xxxxx

# multi mode also requires Python:
pip install -r ${CLAUDE_PLUGIN_ROOT}/requirements.txt
```

`/paperfactory:init` runs `verify_config.sh` automatically.

---

## Acknowledgments

<table>
  <tr>
    <td valign="top" width="50%">
      <h4>citation-assistant</h4>
      <p><b>Web literature search, journal quality assessment, and BibTeX generation</b> capabilities originate from
        <a href="https://github.com/ZhangNy301/citation-assistant">citation-assistant</a>.</p>
      <p><code>skills/citation-search/scripts/</code> — <code>paper_search.sh</code> /
        <code>venue_lookup.sh</code> / <code>author_info.sh</code> / <code>doi2bibtex.sh</code>
        as well as CCF and impact factor databases are adapted from that project.</p>
    </td>
    <td valign="top" width="50%">
      <h4>academic-research-skills (ARS)</h4>
      <p><b>M8 / M9 module design, <code>reference/</code> and <code>templates/</code> (62 reference files and templates)</b>
        originate from the academic-research-skills project (Cheng-I Wu, CC-BY-NC 4.0).</p>
      <p>Including PRISMA-trAIce protocol, RAISE framework, multi-perspective reviewer model, APA 7 style guide,
        logical fallacy catalog, academic writing style guide, and more.</p>
    </td>
  </tr>
</table>

### Platforms

- [Semantic Scholar](https://www.semanticscholar.org/) — academic search API
- [CrossRef](https://www.crossref.org/) — DOI metadata & BibTeX content negotiation
- [OpenAlex](https://openalex.org/) — open scholarly graph
- [arXiv](https://arxiv.org/) — preprint repository
- [impact_factor](https://github.com/suqingdong/impact_factor) — journal IF database

---

<div align="center">
<sub><i>Built for research efficiency.</i></sub>
</div>

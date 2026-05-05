#!/usr/bin/env python3
"""Multi-source paper search with BM25 reranking (paper.skill v0.5).

Fan out one query to arXiv + Semantic Scholar + OpenAlex in parallel,
deduplicate by DOI/title, then rerank with BM25 (title weighted 3x).

Output JSON is field-compatible with paper_search.sh standard mode,
plus extra fields: source, bm25_score, also_in.

Distilled from papercircle-main:
  backend/agents/agents/research_agentv2.py (PaperSearchEngine)
  backend/agents/discovery/pca.py            (_rerank_with_bm25)
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import asdict, dataclass, field
from typing import Optional

# Force UTF-8 on stdout/stderr so Windows GBK consoles don't choke on non-ASCII output.
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass


# ---------- Paper model ----------

@dataclass
class Paper:
    title: str
    abstract: str = ""
    authors: list[str] = field(default_factory=list)
    year: Optional[int] = None
    venue: str = ""
    doi: Optional[str] = None
    arxiv_id: Optional[str] = None
    url: str = ""
    citations: int = 0
    source: str = ""
    also_in: list[str] = field(default_factory=list)
    bm25_score: float = 0.0


# ---------- Sources ----------

ARXIV_THRESHOLD = int(os.environ.get("ARXIV_CITATION_THRESHOLD", "100"))


def _http_get(url: str, params: dict | None = None, headers: dict | None = None,
              timeout: int = 30) -> dict | None:
    import requests  # local import keeps top-level cheap if other modes don't need network
    try:
        r = requests.get(url, params=params, headers=headers, timeout=timeout)
        if r.status_code != 200:
            print(f"[warn] HTTP {r.status_code} for {url}", file=sys.stderr)
            return None
        return r.json()
    except Exception as e:
        print(f"[warn] request failed: {url}: {e}", file=sys.stderr)
        return None


class PaperSource:
    name = "base"

    def search(self, query: str, limit: int, year_from: Optional[int],
               year_to: Optional[int]) -> list[Paper]:
        raise NotImplementedError


class ArxivSource(PaperSource):
    """arXiv via the official `arxiv` Python client.

    arXiv enforces per-IP rate limiting on the search endpoint, with cooldowns
    of ~5-15 min after a burst. Defaults below match arXiv's TOU recommendation:
    one request per 3 s, three retries on transient errors.
    """
    name = "arxiv"

    def search(self, query, limit, year_from, year_to):
        try:
            import arxiv
        except ImportError:
            print("[warn] arxiv package not installed; pip install arxiv", file=sys.stderr)
            return []
        # Respect arXiv TOU: 1 req / 3s; let the library handle 429 backoff.
        client = arxiv.Client(page_size=min(limit, 100), delay_seconds=3, num_retries=3)
        search = arxiv.Search(query=query, max_results=limit,
                              sort_by=arxiv.SortCriterion.Relevance)
        out: list[Paper] = []
        try:
            for r in client.results(search):
                year = r.published.year if r.published else None
                if year_from and year and year < year_from:
                    continue
                if year_to and year and year > year_to:
                    continue
                out.append(Paper(**self._parse_result(r)))
        except Exception as e:
            print(f"[warn] arxiv search failed: {e}", file=sys.stderr)
        return out

    def _parse_result(self, r) -> dict:
        """Convert an arxiv.Result to Paper kwargs. Extracted for unit testing."""
        year = r.published.year if r.published else None
        arxiv_id = r.entry_id.rsplit("/", 1)[-1].split("v")[0]
        return dict(
            title=(r.title or "").strip().replace("\n", " "),
            abstract=(r.summary or "").strip().replace("\n", " "),
            authors=[a.name for a in r.authors][:10],
            year=year,
            venue="arXiv",
            doi=r.doi,
            arxiv_id=arxiv_id,
            url=r.entry_id,
            citations=0,
            source=self.name,
        )


class SemanticScholarSource(PaperSource):
    name = "s2"

    def __init__(self, base_url: str, api_key: Optional[str], api_key_header: str = "Authorization",
                 min_interval: float = 1.0):
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.api_key_header = api_key_header
        self.min_interval = min_interval
        self._last_call = 0.0

    def _wait(self):
        elapsed = time.time() - self._last_call
        if elapsed < self.min_interval:
            time.sleep(self.min_interval - elapsed)
        self._last_call = time.time()

    def search(self, query, limit, year_from, year_to):
        self._wait()
        url = f"{self.base_url}/graph/v1/paper/search"
        fields = "paperId,title,year,authors,venue,journal,citationCount,externalIds,url,abstract"
        params = {"query": query, "limit": min(limit, 100), "fields": fields}
        if year_from or year_to:
            params["year"] = f"{year_from or ''}-{year_to or ''}"
        headers = {self.api_key_header: self.api_key} if self.api_key else None
        data = _http_get(url, params, headers, timeout=30)
        if not data:
            return []
        out: list[Paper] = []
        for p in data.get("data", []) or []:
            ext = p.get("externalIds") or {}
            journal = p.get("journal") or {}
            venue = p.get("venue") or journal.get("name") or ""
            out.append(Paper(
                title=(p.get("title") or "").strip(),
                abstract=(p.get("abstract") or "").strip(),
                authors=[a.get("name", "") for a in (p.get("authors") or [])][:10],
                year=p.get("year"),
                venue=venue,
                doi=ext.get("DOI"),
                arxiv_id=ext.get("ArXiv"),
                url=p.get("url") or "",
                citations=int(p.get("citationCount") or 0),
                source=self.name,
            ))
        return out


class OpenAlexSource(PaperSource):
    """OpenAlex /works endpoint. Free, no API key required."""
    name = "openalex"

    def __init__(self, base_url: str = "https://api.openalex.org", mailto: Optional[str] = None):
        self.base_url = base_url.rstrip("/")
        self.mailto = mailto

    def search(self, query, limit, year_from, year_to):
        url = f"{self.base_url}/works"
        params = {"search": query, "per-page": min(limit, 200)}
        filters = []
        if year_from:
            filters.append(f"from_publication_date:{year_from}-01-01")
        if year_to:
            filters.append(f"to_publication_date:{year_to}-12-31")
        if filters:
            params["filter"] = ",".join(filters)
        if self.mailto:
            params["mailto"] = self.mailto
        data = _http_get(url, params, timeout=30)
        if not data:
            return []
        out: list[Paper] = []
        for w in data.get("results", []) or []:
            doi = (w.get("doi") or "").replace("https://doi.org/", "") or None
            ids = w.get("ids") or {}
            primary_loc = (w.get("primary_location") or {}).get("source") or {}
            venue = primary_loc.get("display_name") or ""
            authors = [(a.get("author") or {}).get("display_name", "")
                       for a in (w.get("authorships") or [])][:10]
            out.append(Paper(
                title=(w.get("title") or w.get("display_name") or "").strip(),
                abstract=_invert_openalex_abstract(w.get("abstract_inverted_index")),
                authors=[a for a in authors if a],
                year=w.get("publication_year"),
                venue=venue,
                doi=doi,
                arxiv_id=_extract_arxiv_id(ids.get("openalex"), w.get("primary_location") or {}),
                url=w.get("id") or "",
                citations=int(w.get("cited_by_count") or 0),
                source=self.name,
            ))
        return out


def _invert_openalex_abstract(idx: dict | None) -> str:
    """OpenAlex returns abstracts as {token: [pos, ...]}; reconstruct text."""
    if not idx:
        return ""
    positions: list[tuple[int, str]] = []
    for tok, poss in idx.items():
        for p in poss:
            positions.append((p, tok))
    positions.sort(key=lambda x: x[0])
    return " ".join(tok for _, tok in positions)


_ARXIV_RE = re.compile(r"arxiv\.org/abs/([\w./-]+)", re.IGNORECASE)


def _extract_arxiv_id(_openalex_id, primary_location):
    pdf = (primary_location or {}).get("pdf_url") or ""
    landing = (primary_location or {}).get("landing_page_url") or ""
    for u in (pdf, landing):
        m = _ARXIV_RE.search(u or "")
        if m:
            return m.group(1)
    return None


# ---------- Dedup ----------

_PUNCT_RE = re.compile(r"[^\w\s]")
_WS_RE = re.compile(r"\s+")


def _norm_title(t: str) -> str:
    t = (t or "").lower()
    t = _PUNCT_RE.sub(" ", t)
    return _WS_RE.sub(" ", t).strip()


def deduplicate(papers: list[Paper]) -> list[Paper]:
    """Group by DOI (preferred) then by normalized title.
    Keep the version with highest citation_count; record other sources in `also_in`."""
    groups: dict[str, list[Paper]] = {}
    for p in papers:
        key = ("doi:" + p.doi.lower()) if p.doi else ("title:" + _norm_title(p.title))
        if not key.endswith(":"):
            groups.setdefault(key, []).append(p)
    merged: list[Paper] = []
    for items in groups.values():
        items.sort(key=lambda x: (x.citations, len(x.abstract)), reverse=True)
        winner = items[0]
        winner.also_in = sorted({p.source for p in items[1:] if p.source != winner.source})
        # fill in missing fields from other sources
        for p in items[1:]:
            if not winner.doi and p.doi:
                winner.doi = p.doi
            if not winner.arxiv_id and p.arxiv_id:
                winner.arxiv_id = p.arxiv_id
            if not winner.abstract and p.abstract:
                winner.abstract = p.abstract
        merged.append(winner)
    return merged


# ---------- BM25 reranking ----------

_TOKEN_RE = re.compile(r"[A-Za-z0-9]+")


def _tokenize(text: str) -> list[str]:
    return [t.lower() for t in _TOKEN_RE.findall(text or "")]


def rerank_bm25(papers: list[Paper], query: str, title_weight: int = 3) -> list[Paper]:
    try:
        from rank_bm25 import BM25Okapi
    except ImportError:
        print("[warn] rank-bm25 not installed; skipping rerank. pip install rank-bm25",
              file=sys.stderr)
        return papers
    if not papers:
        return papers
    docs = [_tokenize(((p.title + " ") * title_weight) + p.abstract) for p in papers]
    if not any(docs):
        return papers
    bm25 = BM25Okapi(docs)
    scores = bm25.get_scores(_tokenize(query))
    for p, s in zip(papers, scores):
        p.bm25_score = float(s)
    papers.sort(key=lambda p: p.bm25_score, reverse=True)
    return papers


# ---------- Output formatting ----------

def _arxiv_status(p: Paper) -> tuple[bool, str, str]:
    """Decide arxiv_status. The arXiv API itself does NOT expose citation
    counts (it's a preprint repo, not a citation index — see arXiv API
    User's Manual §3.3.2). So when a paper comes ONLY from arxiv with no
    cross-source enrichment, we cannot judge citation tier and must say so
    rather than falsely flagging it as "low citation"."""
    is_arxiv = bool(p.arxiv_id) or "arxiv" in (p.venue or "").lower()
    if not is_arxiv:
        return False, "normal", "✅ 正式发表"
    citation_known = p.source != "arxiv" or any(s in ("s2", "openalex") for s in p.also_in)
    if not citation_known:
        return True, "unknown", "ℹ️ arXiv 预印本（引用数未知，arXiv API 不返回 citationCount）"
    if p.citations < ARXIV_THRESHOLD:
        return True, "caution", f"⚠️ arXiv 低引用({p.citations})，谨慎引用"
    return True, "recommended", f"✅ 高影响力 arXiv ({p.citations} 引用)"


def to_output_dict(p: Paper) -> dict:
    is_arxiv, status, rec = _arxiv_status(p)
    return {
        "title": p.title,
        "year": p.year,
        "venue": p.venue or "N/A",
        "citations": p.citations,
        "doi": p.doi,
        "arxiv_id": p.arxiv_id,
        "url": p.url,
        "abstract": p.abstract,
        "authors": [{"name": a, "id": None} for a in p.authors[:3]],
        "is_arxiv": is_arxiv,
        "arxiv_status": status,
        "recommendation": rec,
        "source": p.source,
        "also_in": p.also_in,
        "bm25_score": round(p.bm25_score, 4),
    }


# ---------- Orchestration ----------

def load_config(project_root: str) -> dict:
    cfg_path = os.path.join(project_root, "config", "api.json")
    if not os.path.exists(cfg_path):
        return {}
    with open(cfg_path, encoding="utf-8") as f:
        return json.load(f).get("api", {})


def build_sources(cfg: dict, sources_arg: list[str]) -> list[PaperSource]:
    out: list[PaperSource] = []
    for name in sources_arg:
        name = name.strip().lower()
        if name == "arxiv":
            out.append(ArxivSource())
        elif name in ("s2", "semantic_scholar"):
            s2 = cfg.get("semantic_scholar", {})
            base = s2.get("base_url") or "https://api.semanticscholar.org"
            key_var = s2.get("api_key_env_var", "S2_API_KEY")
            key_header = s2.get("api_key_header", "Authorization")
            interval = float(s2.get("rate_limit_min_interval", 1))
            out.append(SemanticScholarSource(base, os.environ.get(key_var), key_header, interval))
        elif name == "openalex":
            oa = cfg.get("openalex", {})
            base = oa.get("base_url") or "https://api.openalex.org"
            mailto = oa.get("mailto") or os.environ.get("OPENALEX_MAILTO")
            out.append(OpenAlexSource(base, mailto))
        else:
            print(f"[warn] unknown source: {name}", file=sys.stderr)
    return out


def search_multi(query: str, limit: int, sources: list[PaperSource],
                 year_from: Optional[int], year_to: Optional[int],
                 per_source_factor: int = 2) -> list[Paper]:
    """Fan out to all sources in parallel, then merge."""
    per_source = max(limit * per_source_factor, limit + 5)
    all_papers: list[Paper] = []
    with ThreadPoolExecutor(max_workers=max(1, len(sources))) as ex:
        futures = {ex.submit(s.search, query, per_source, year_from, year_to): s for s in sources}
        for fu in as_completed(futures):
            src = futures[fu]
            try:
                got = fu.result() or []
                print(f"[info] {src.name}: {len(got)} papers", file=sys.stderr)
                all_papers.extend(got)
            except Exception as e:
                print(f"[warn] {src.name} failed: {e}", file=sys.stderr)
    return all_papers


def main():
    parser = argparse.ArgumentParser(description="Multi-source paper search with BM25 rerank.")
    parser.add_argument("--query", required=True)
    parser.add_argument("--limit", type=int, default=30)
    parser.add_argument("--year-from", type=int, default=None)
    parser.add_argument("--year-to", type=int, default=None)
    parser.add_argument("--sources", default="arxiv,s2,openalex",
                        help="Comma-separated subset of arxiv,s2,openalex")
    parser.add_argument("--output", choices=("json", "jsonl"), default="jsonl",
                        help="json: single JSON array; jsonl: one JSON per line (default, "
                             "matches paper_search.sh standard mode)")
    parser.add_argument("--no-rerank", action="store_true", help="Skip BM25 rerank")
    args = parser.parse_args()

    project_root = os.environ.get("PAPER_SKILL_ROOT") or os.path.abspath(
        os.path.join(os.path.dirname(__file__), "..", ".."))
    cfg = load_config(project_root)
    sources = build_sources(cfg, args.sources.split(","))
    if not sources:
        print('{"error": "no valid sources configured"}', file=sys.stderr)
        sys.exit(1)

    papers = search_multi(args.query, args.limit, sources, args.year_from, args.year_to)
    papers = deduplicate(papers)
    if not args.no_rerank:
        papers = rerank_bm25(papers, args.query)
    papers = papers[:args.limit]

    print(f"[info] total: {len(papers)} after dedup+rerank+limit", file=sys.stderr)

    if args.output == "json":
        print(json.dumps([to_output_dict(p) for p in papers], ensure_ascii=False, indent=2))
    else:
        for p in papers:
            print(json.dumps(to_output_dict(p), ensure_ascii=False))


if __name__ == "__main__":
    main()

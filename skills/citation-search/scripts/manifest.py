#!/usr/bin/env python3
"""relate-work manifest CRUD + OA PDF download (paper.skill v0.6).

Single source of truth: relate-work/manifest.jsonl (one paper per line).
Subcommands:
  add       Append entries selected from a multi-search jsonl
  download  Try OA PDF download for status in {pending, missing}
  scan      Detect user-supplied PDFs in relate-work/pdf/ and update status
  render    Generate manifest.md (full table) + missing.md (gap list)
  prune     Drop status=missing entries (with confirmation)
  list      Print status counts to stdout
"""
from __future__ import annotations

import argparse
import datetime as dt
import io
import json
import os
import re
import shutil
import sys
import time
import unicodedata
from typing import Iterable, Optional

# Force UTF-8 stdout/stderr for Windows GBK consoles
for _stream in (sys.stdout, sys.stderr):
    try:
        _stream.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass

# Two distinct roots:
#   SKILL_DIR     — where the paper.skill repo is installed (config/, modules/, reference/)
#   PROJECT_DIR   — the user's paper project working dir (relate-work/ lives HERE)
# Default PROJECT_DIR = cwd, so cd-ing into your paper project Just Works.
SKILL_DIR = (os.environ.get("PAPER_SKILL_DIR")
             or os.environ.get("PAPER_SKILL_ROOT")  # back-compat alias
             or os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
PROJECT_DIR = os.environ.get("PAPER_PROJECT_DIR") or os.getcwd()
RELATE_WORK = os.path.join(PROJECT_DIR, "relate-work")
PDF_DIR = os.path.join(RELATE_WORK, "pdf")
MANIFEST = os.path.join(RELATE_WORK, "manifest.jsonl")
MANIFEST_MD = os.path.join(RELATE_WORK, "manifest.md")
MISSING_MD = os.path.join(RELATE_WORK, "missing.md")

STOPWORDS = {"a", "an", "the", "of", "for", "in", "on", "with", "by", "and",
             "or", "to", "is", "are", "via", "from", "as", "at"}


# ---------- IO helpers ----------

def _ensure_dirs() -> None:
    os.makedirs(RELATE_WORK, exist_ok=True)
    os.makedirs(PDF_DIR, exist_ok=True)


def _read_manifest() -> list[dict]:
    if not os.path.exists(MANIFEST):
        return []
    out = []
    with open(MANIFEST, encoding="utf-8") as f:
        for ln in f:
            ln = ln.strip()
            if not ln:
                continue
            try:
                out.append(json.loads(ln))
            except json.JSONDecodeError as e:
                print(f"[warn] skip malformed manifest line: {e}", file=sys.stderr)
    return out


def _write_manifest(entries: list[dict]) -> None:
    """Atomic write: tmp → fsync → replace."""
    _ensure_dirs()
    tmp = MANIFEST + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        for e in entries:
            f.write(json.dumps(e, ensure_ascii=False) + "\n")
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, MANIFEST)


def _read_jsonl(path: str) -> list[dict]:
    out = []
    with open(path, encoding="utf-8") as f:
        for ln in f:
            ln = ln.strip()
            if not ln:
                continue
            out.append(json.loads(ln))
    return out


# ---------- bibkey ----------

def _ascii_lower(s: str) -> str:
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "", s.lower())


def make_bibkey(paper: dict, taken: set[str]) -> str:
    """<surname>-<year>-<title-keyword> with collision suffix.
    Surname = last token of first author. Title keyword = first 2 non-stopwords."""
    authors = paper.get("authors") or []
    if authors and isinstance(authors[0], dict):
        first = authors[0].get("name", "")
    elif authors:
        first = authors[0]
    else:
        first = ""
    surname = first.strip().split()[-1] if first.strip() else "anon"
    surname = _ascii_lower(surname) or "anon"
    year = paper.get("year") or "n.d."
    tokens = [t for t in re.split(r"\W+", (paper.get("title") or "").lower()) if t]
    title_words = [t for t in tokens if t not in STOPWORDS][:2]
    title_part = "-".join(_ascii_lower(t) for t in title_words if _ascii_lower(t)) or "untitled"
    base = f"{surname}-{year}-{title_part}"
    if base not in taken:
        return base
    i = 2
    while f"{base}-{i}" in taken:
        i += 1
    return f"{base}-{i}"


# ---------- Source matching for `add` ----------

def _doi_norm(s: Optional[str]) -> str:
    return (s or "").lower().strip()


def _match_search_to_bibkeys(search_entries: list[dict], bibkeys: list[str],
                              existing: list[dict]) -> list[dict]:
    """For each requested bibkey, find the best search entry by computing the
    bibkey we WOULD assign to each candidate and matching."""
    taken = {e["bibkey"] for e in existing}
    found: list[dict] = []
    for bk in bibkeys:
        match = None
        # Pass 1: try matching the bibkey we'd freshly generate
        for e in search_entries:
            cand = make_bibkey(e, taken)
            if cand == bk:
                match = e
                break
            # Allow user-shortened keys to match by prefix
            if bk.startswith(cand.rsplit("-", 1)[0]):
                match = e  # weak match; keep looking for exact
        if match is None:
            print(f"[warn] no search entry matches bibkey '{bk}'", file=sys.stderr)
            continue
        found.append(match)
    return found


# ---------- Subcommand: add ----------

def cmd_add(args: argparse.Namespace) -> int:
    _ensure_dirs()
    if not os.path.exists(args.from_search):
        print(f"[err] search file not found: {args.from_search}", file=sys.stderr)
        return 2
    search_entries = _read_jsonl(args.from_search)
    requested = [k.strip() for k in args.bibkeys.split(",") if k.strip()]
    existing = _read_manifest()
    existing_keys = {e["bibkey"] for e in existing}
    existing_dois = {_doi_norm(e.get("doi")) for e in existing if e.get("doi")}

    matches = _match_search_to_bibkeys(search_entries, requested, existing)
    today = dt.date.today().isoformat()
    added = 0
    for s in matches:
        if _doi_norm(s.get("doi")) and _doi_norm(s.get("doi")) in existing_dois:
            print(f"[skip] DOI {s.get('doi')} already in manifest", file=sys.stderr)
            continue
        bk = make_bibkey(s, existing_keys)
        existing_keys.add(bk)
        if _doi_norm(s.get("doi")):
            existing_dois.add(_doi_norm(s.get("doi")))
        entry = {
            "bibkey": bk,
            "title": s.get("title", ""),
            "authors": [a.get("name") if isinstance(a, dict) else a
                        for a in (s.get("authors") or [])],
            "year": s.get("year"),
            "venue": s.get("venue", ""),
            "abstract": s.get("abstract", ""),
            "doi": s.get("doi"),
            "arxiv_id": s.get("arxiv_id"),
            "s2_paper_id": s.get("s2_paper_id", ""),
            "openalex_id": s.get("openalex_id", ""),
            "pdf_url": s.get("pdf_url", ""),
            "pdf_source": s.get("source", ""),
            "status": "pending",
            "filename": None,
            "tags": [],
            "added_date": today,
            "downloaded_date": None,
            "notes": "",
        }
        existing.append(entry)
        added += 1
        print(f"[add] {bk}", file=sys.stderr)
    _write_manifest(existing)
    print(f"Added {added} entries to manifest ({len(existing)} total).")
    return 0


# ---------- Subcommand: download ----------

def _polite_ua() -> str:
    mailto = os.environ.get("PAPER_SKILL_MAILTO", "")
    return f"paperfactory/0.1 ({'mailto:' + mailto if mailto else 'github.com/larbare12/paperfactory-from-idea-to-manuscript'})"


def _candidate_urls(entry: dict) -> list[tuple[str, str]]:
    """Return [(url, source_label), ...] in priority order."""
    out: list[tuple[str, str]] = []
    if entry.get("arxiv_id"):
        out.append((f"https://arxiv.org/pdf/{entry['arxiv_id']}", "arxiv"))
    pdf_url = entry.get("pdf_url") or ""
    src = entry.get("pdf_source") or ""
    if pdf_url and not pdf_url.startswith("https://arxiv.org/pdf/"):
        out.append((pdf_url, src or "openalex/s2"))
    return out


def cmd_download(args: argparse.Namespace) -> int:
    import requests
    _ensure_dirs()
    entries = _read_manifest()
    targets = [e for e in entries if e.get("status") in ("pending", "missing")]
    if not targets:
        print("Nothing to download (no pending/missing entries).")
        return 0
    today = dt.date.today().isoformat()
    headers = {"User-Agent": _polite_ua()}
    last_arxiv = 0.0
    for entry in targets:
        bk = entry["bibkey"]
        urls = _candidate_urls(entry)
        if not urls:
            entry["status"] = "missing"
            entry["notes"] = "no OA pdf_url in any source"
            print(f"[miss] {bk}: no OA URL")
            continue
        ok = False
        for url, label in urls:
            # 1 req / 3 s for arxiv (TOU)
            if "arxiv.org" in url:
                wait = 3 - (time.time() - last_arxiv)
                if wait > 0:
                    time.sleep(wait)
                last_arxiv = time.time()
            try:
                r = requests.get(url, headers=headers, stream=True, timeout=60,
                                 allow_redirects=True)
                ct = r.headers.get("content-type", "").lower()
                if r.status_code == 200 and ("pdf" in ct or url.endswith(".pdf")
                                             or url.startswith("https://arxiv.org/pdf/")):
                    dest = os.path.join(PDF_DIR, f"{bk}.pdf")
                    with open(dest, "wb") as fh:
                        for chunk in r.iter_content(chunk_size=64 * 1024):
                            if chunk:
                                fh.write(chunk)
                    size = os.path.getsize(dest)
                    if size < 1024:  # <1KB is likely an error page
                        os.remove(dest)
                        print(f"[fail] {bk} via {label}: response too small ({size}B)")
                        continue
                    entry["status"] = "downloaded"
                    entry["filename"] = f"{bk}.pdf"
                    entry["downloaded_date"] = today
                    entry["pdf_source"] = label
                    entry["notes"] = ""
                    print(f"[ok]   {bk} ← {label} ({size // 1024}KB)")
                    ok = True
                    break
                else:
                    print(f"[fail] {bk} via {label}: HTTP {r.status_code} ct={ct[:40]}")
            except Exception as e:
                print(f"[fail] {bk} via {label}: {type(e).__name__}: {e}")
        if not ok:
            entry["status"] = "missing"
            if not entry.get("notes"):
                entry["notes"] = "all OA candidates failed"
    _write_manifest(entries)
    print()
    cmd_list(argparse.Namespace())
    return 0


# ---------- Subcommand: scan ----------

def cmd_scan(args: argparse.Namespace) -> int:
    _ensure_dirs()
    entries = _read_manifest()
    if not entries:
        print("Manifest empty, nothing to scan.")
        return 0
    files = {os.path.splitext(f)[0]: f for f in os.listdir(PDF_DIR)
             if f.lower().endswith(".pdf")}
    matched = 0
    for entry in entries:
        if entry.get("status") == "downloaded":
            continue
        bk = entry["bibkey"]
        if bk in files:
            entry["status"] = "user-supplied"
            entry["filename"] = files[bk]
            entry["downloaded_date"] = dt.date.today().isoformat()
            matched += 1
            print(f"[scan] {bk} → user-supplied ({files[bk]})")
    _write_manifest(entries)
    print(f"Scan complete: {matched} new user-supplied PDFs detected.")
    return 0


# ---------- Subcommand: render ----------

_STATUS_BADGE = {
    "pending": "⏳ pending",
    "downloaded": "✅ downloaded",
    "user-supplied": "📁 user-supplied",
    "missing": "❌ missing",
    "manual": "🚫 manual-hold",
}


def _md_escape_cell(s: str) -> str:
    return (s or "").replace("|", "\\|").replace("\n", " ").strip()


def _venue_hint(entry: dict) -> str:
    venue = (entry.get("venue") or "").lower()
    if entry.get("arxiv_id"):
        return f"https://arxiv.org/abs/{entry['arxiv_id']}"
    if entry.get("doi"):
        return f"https://doi.org/{entry['doi']}"
    if "acl" in venue or "emnlp" in venue or "naacl" in venue:
        return "https://aclanthology.org/"
    if "neurips" in venue:
        return "https://papers.nips.cc/"
    if "iclr" in venue:
        return "https://openreview.net/"
    if "icml" in venue:
        return "https://proceedings.mlr.press/"
    if "cvpr" in venue or "iccv" in venue or "eccv" in venue:
        return "https://openaccess.thecvf.com/"
    return ""


def cmd_render(args: argparse.Namespace) -> int:
    _ensure_dirs()
    entries = _read_manifest()
    # Full manifest.md
    lines = ["# relate-work 文献清单",
             "",
             f"_由 `manifest.py render` 自动生成；single source of truth: `manifest.jsonl`_",
             "",
             "| bibkey | 标题 | 年 | venue | 状态 | 文件 |",
             "|---|---|---|---|---|---|"]
    for e in sorted(entries, key=lambda x: (x.get("status", ""), x.get("bibkey", ""))):
        lines.append("| {bk} | {t} | {y} | {v} | {s} | {f} |".format(
            bk=_md_escape_cell(e.get("bibkey", "")),
            t=_md_escape_cell(e.get("title", "")),
            y=e.get("year") or "",
            v=_md_escape_cell(e.get("venue", "")),
            s=_STATUS_BADGE.get(e.get("status", ""), e.get("status", "")),
            f=_md_escape_cell(e.get("filename") or ""),
        ))
    counts: dict[str, int] = {}
    for e in entries:
        counts[e.get("status", "?")] = counts.get(e.get("status", "?"), 0) + 1
    lines.extend(["", "## 状态汇总", ""])
    for k, v in sorted(counts.items()):
        lines.append(f"- **{_STATUS_BADGE.get(k, k)}**: {v}")
    with open(MANIFEST_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")

    # missing.md
    missing = [e for e in entries if e.get("status") == "missing"]
    mlines = ["# 待人工收集 PDF 清单", ""]
    if not missing:
        mlines.append("_当前没有缺失文献。_")
    else:
        mlines.append(f"以下 {len(missing)} 篇文献的开放获取 PDF 未能自动下载，"
                      "请手动下载到 `relate-work/pdf/<bibkey>.pdf`，再跑 `manifest.py scan`。")
        mlines.extend(["", "| bibkey | 标题 | venue | 建议来源 | 备注 |",
                       "|---|---|---|---|---|"])
        for e in missing:
            mlines.append("| {bk} | {t} | {v} | {hint} | {n} |".format(
                bk=_md_escape_cell(e["bibkey"]),
                t=_md_escape_cell(e.get("title", "")),
                v=_md_escape_cell(e.get("venue", "")),
                hint=_md_escape_cell(_venue_hint(e)),
                n=_md_escape_cell(e.get("notes", "")),
            ))
    with open(MISSING_MD, "w", encoding="utf-8") as f:
        f.write("\n".join(mlines) + "\n")

    print(f"Rendered: {MANIFEST_MD}")
    print(f"Rendered: {MISSING_MD}")
    return 0


# ---------- Subcommand: prune ----------

def cmd_prune(args: argparse.Namespace) -> int:
    entries = _read_manifest()
    keep_set = {k.strip() for k in (args.keep_bibkeys or "").split(",") if k.strip()}
    missing = [e for e in entries if e.get("status") == "missing" and e["bibkey"] not in keep_set]
    if not missing:
        print("No missing entries to prune.")
        return 0
    dropped: set[str] = set()
    if args.yes:
        dropped = {e["bibkey"] for e in missing}
        print(f"Dropping {len(dropped)} missing entries (--yes).")
    else:
        for e in missing:
            ans = input(f"Drop {e['bibkey']} ({e.get('title', '')[:60]}…)? [y/N] ").strip().lower()
            if ans == "y":
                dropped.add(e["bibkey"])
    new_entries = [e for e in entries if e["bibkey"] not in dropped]
    _write_manifest(new_entries)
    print(f"Pruned {len(dropped)} entries; {len(new_entries)} remain.")
    return 0


# ---------- Subcommand: list ----------

def cmd_list(args: argparse.Namespace) -> int:
    entries = _read_manifest()
    counts: dict[str, int] = {}
    for e in entries:
        counts[e.get("status", "?")] = counts.get(e.get("status", "?"), 0) + 1
    print(f"Manifest: {MANIFEST}")
    print(f"  Total entries: {len(entries)}")
    for k in ("pending", "downloaded", "user-supplied", "missing", "manual"):
        if k in counts:
            print(f"  {_STATUS_BADGE[k]:30}  {counts[k]}")
    other = {k: v for k, v in counts.items() if k not in _STATUS_BADGE}
    for k, v in other.items():
        print(f"  {k:30}  {v}")
    return 0


# ---------- Entry point ----------

def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    pa = sub.add_parser("add", help="Add entries from a multi-search jsonl")
    pa.add_argument("--from-search", required=True, dest="from_search",
                    help="Path to search-*.jsonl produced by paper_search.sh --mode multi")
    pa.add_argument("--bibkeys", required=True,
                    help="Comma-separated bibkeys to add (must match auto-generated keys)")
    pa.set_defaults(func=cmd_add)

    pd = sub.add_parser("download", help="Download OA PDFs for pending/missing entries")
    pd.set_defaults(func=cmd_download)

    ps = sub.add_parser("scan", help="Detect user-supplied PDFs in relate-work/pdf/")
    ps.set_defaults(func=cmd_scan)

    pr = sub.add_parser("render", help="Render manifest.md + missing.md")
    pr.set_defaults(func=cmd_render)

    pp = sub.add_parser("prune", help="Drop missing entries")
    pp.add_argument("--yes", action="store_true", help="Skip confirmation")
    pp.add_argument("--keep-bibkeys", default="", dest="keep_bibkeys",
                    help="Comma-separated bibkeys to KEEP even if missing")
    pp.set_defaults(func=cmd_prune)

    pl = sub.add_parser("list", help="Print status counts")
    pl.set_defaults(func=cmd_list)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())

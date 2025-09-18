#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Plugin: GitHub/ReadTheDocs/MkDocs-aware collection strategy.
Skips nav/headers/footers, prioritizes /docs/, /guide/, /api/ paths, and handles versioned docs.
"""
from __future__ import annotations
import asyncio, re, time
from typing import List, Dict, Any, Tuple, Set
from crawl4ai import AsyncWebCrawler
from crawl4ai.async_configs import BrowserConfig

PRIORITY_PATTERNS = [r"/docs/", r"/guide/", r"/getting-started", r"/api/", r"/reference/"]
SKIP_PATTERNS = [r"/changelog", r"/releases", r"/news"]

async def collect_docs(cfg, crawl_page_markdown):
    roots = cfg.targets.bfs_roots or cfg.targets.urls
    if not roots: return []
    allowed = set(cfg.rules.allowed_domains)
    seen: Set[str] = set(); queue: List[Tuple[str,int]] = [(u,0) for u in roots]
    out: List[Dict[str,Any]] = []
    bcfg = BrowserConfig(headless=True, user_agent=cfg.rules.user_agent)
    async with AsyncWebCrawler(config=bcfg) as crawler:
        while queue and len(out) < cfg.rules.max_pages:
            url, depth = queue.pop(0)
            if url in seen or depth > cfg.rules.max_depth: continue
            seen.add(url)
            if allowed and not any(url.startswith(f"https://{d}") or url.startswith(f"http://{d}") for d in allowed):
                continue
            if any(re.search(p, url) for p in SKIP_PATTERNS):
                continue
            page = await crawl_page_markdown(crawler, url, cfg.rules)
            if cfg.rules.keywords and not any(k.lower() in page["markdown"].lower() for k in cfg.rules.keywords):
                continue
            pri = any(re.search(p, url) for p in PRIORITY_PATTERNS)
            if pri:
                out.append(page)
            else:
                if len(out) < cfg.rules.max_pages:
                    out.append(page)
            links = page.get("links", [])
            for link in links:
                if allowed and not any(link.startswith(f"https://{d}") or link.startswith(f"http://{d}") for d in allowed):
                    continue
                if any(re.search(p, link) for p in cfg.rules.exclude_patterns or []):
                    continue
                if link not in seen:
                    queue.append((link, depth+1))
            if cfg.rules.rate_limit>0: time.sleep(cfg.rules.rate_limit)
    return out

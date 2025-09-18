from __future__ import annotations
import asyncio, json, os, re
from typing import Any, Dict, List, Optional, Tuple, Union
from urllib.parse import urljoin, urlparse
import httpx
from dataclasses import dataclass

@dataclass
class ReconConfig:
    timeout: float = 10.0
    max_workers: int = 12
    respect_robots: bool = True
    allow_write_verbs: bool = False

def _type_of(v):
    if v is None: return "null"
    if isinstance(v, bool): return "boolean"
    if isinstance(v, int): return "integer"
    if isinstance(v, float): return "number"
    if isinstance(v, str): return "string"
    if isinstance(v, list): return "array"
    if isinstance(v, dict): return "object"
    return "string"

def out_dir_for(base_url: str) -> str:
    host = urlparse(base_url).hostname or "output"
    d = os.path.join("out", host)
    os.makedirs(d, exist_ok=True)
    return d

async def fetch_text(client, method, url):
    try:
        r = await client.request(method, url)
        return r, r.text[:250_000]
    except Exception as e:
        return None, str(e)

async def analyze_target(base_url: str, cfg: ReconConfig) -> Dict[str, Any]:
    if not re.match(r"^https?://", base_url):
        base_url = "https://" + base_url
    client = httpx.AsyncClient(timeout=cfg.timeout)
    try:
        results = []
        for path in ["/api","/health","/status"]:
            u = urljoin(base_url.rstrip('/')+'/', path.lstrip('/'))
            r, text = await fetch_text(client, "GET", u)
            if r and r.status_code < 500:
                try: data = r.json()
                except: data = text
                results.append({"url": u, "status": r.status_code, "samples": [data]})
        return {"target": base_url, "probes": results}
    finally:
        await client.aclose()

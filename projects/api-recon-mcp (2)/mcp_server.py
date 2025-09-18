#!/usr/bin/env python3
import os, json
from typing import Any, Dict
from mcp.server.fastmcp import FastMCP
from recon.core import ReconConfig, analyze_target, load_har, parse_curl_blocks
from recon.emit import write_openapi_and_postman, out_dir_for

def build_mcp() -> FastMCP:
    mcp = FastMCP("API Recon MCP")

    @mcp.tool()
    async def analyze_base_url(base_url: str, ignore_robots: bool = False) -> Dict[str, Any]:
        cfg = ReconConfig(
            timeout=float(os.getenv("HTTP_TIMEOUT", 10)),
            max_workers=int(os.getenv("MAX_WORKERS", 12)),
            respect_robots=bool(int(os.getenv("RESPECT_ROBOTS", 1))) and (not ignore_robots),
            allow_write_verbs=bool(int(os.getenv("ALLOW_WRITE_VERBS", 0))),
        )
        summary = await analyze_target(base_url, cfg)
        d = out_dir_for(base_url)
        await write_openapi_and_postman(base_url, summary, d)
        return {"out_dir": d, "files": ["openapi.yaml", "postman_collection.json", "analysis.json"]}

    @mcp.tool()
    async def ingest_har(har_json: str) -> Dict[str, Any]:
        har = json.loads(har_json)
        entries = load_har(har)
        return {"entries": len(entries)}

    @mcp.tool()
    async def ingest_curl(curl_text: str) -> Dict[str, Any]:
        return {"requests": parse_curl_blocks(curl_text)}

    return mcp

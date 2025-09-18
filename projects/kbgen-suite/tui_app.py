#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple Textual TUI to prepare a config and launch a KB job via the API (/jobs) and stream logs.
"""
from __future__ import annotations
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Input, Button, TextLog, Checkbox
from textual.containers import Vertical
import httpx

API_BASE = "http://localhost:5055"

class KBTui(App):
    CSS = """
    Screen { layout: vertical; }
    #controls { height: auto; }
    TextLog { height: 1fr; }
    """

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Vertical(id="controls"):
            yield Input(placeholder="Root URL (e.g., https://example.com/docs/)", id="root")
            yield Input(placeholder="Allowed domain (e.g., example.com)", id="domain")
            yield Input(placeholder="Keywords (comma separated)", id="keywords")
            yield Checkbox(label="Topic discovery", id="topics")
            yield Button("Enqueue Job", id="run")
        self.log = TextLog(highlight=False)
        yield self.log
        yield Footer()

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "run":
            root = self.query_one("#root", Input).value.strip()
            domain = self.query_one("#domain", Input).value.strip()
            keywords = [s.strip() for s in self.query_one("#keywords", Input).value.split(',') if s.strip()]
            topics = self.query_one("#topics", Checkbox).value
            cfg = {
                "objective":"Docs","tags":["docs"],"method":"docs",
                "targets":{"bfs_roots":[root]},
                "rules":{"allowed_domains":[domain],"exclude_patterns":["\\.pdf$"],"keywords":keywords,"obey_robots":True,"max_pages":50,"max_depth":3,"concurrency":5,"rate_limit":0.2,"user_agent":"CBW-KBGen/0.2"},
                "output":{"out_dir":"kb_output","compiled_name":"KB"},
                "storage":{"vector":"qdrant","sql":"sqlite","sqlite_path":"kb.sqlite"},
                "embeddings":{"provider":"sbert","model":"sentence-transformers/all-MiniLM-L6-v2","chunk_tokens":500,"chunk_overlap":50},
                "export":{"enable":False},
                "topic_discovery": bool(topics)
            }
            async with httpx.AsyncClient(timeout=30) as client:
                r = await client.post(f"{API_BASE}/jobs", json={"config": cfg}); r.raise_for_status()
                job_id = r.json()["job_id"]
            self.log.write(f"Enqueued job {job_id}. Streaming logs...\n")
            await self.stream_logs(job_id)

    async def stream_logs(self, job_id: str):
        url = f"{API_BASE}/events/{job_id}"
        async with httpx.AsyncClient(timeout=None) as client:
            async with client.stream("GET", url) as r:
                async for line in r.aiter_lines():
                    if line.startswith("data:"):
                        self.log.write(line[5:].strip())

if __name__ == "__main__":
    KBTui().run()

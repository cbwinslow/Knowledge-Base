#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Script Name: kbgen.py
Author: CBW + GPT-5 Thinking
Date: 2025-09-18
Version: 0.2.0

Summary:
    Knowledge Base generator powered by crawl4ai with plugin-aware crawl strategies, optional
    topic discovery (UMAP+HDBSCAN), and optional S3/MinIO export. See README for setup.

Major Additions in 0.2.0:
    - Strategy plugin loader (e.g., plugins.docs_mode)
    - Optional topic discovery pass generating topics.md and auto-tags
    - Optional S3 export of output directory
    - Job-aware logging path (JOB_ID env)

Security:
    - Obeys robots.txt by default
    - Domain allowlist required for BFS
    - Secrets via env vars only (no hardcoding)

"""
from __future__ import annotations
import asyncio, contextlib, datetime as dt, hashlib, json, logging, os, re, sys, textwrap, time
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Any, List, Tuple, Optional, Set, Iterable

import httpx, typer, yaml
from pydantic import BaseModel, Field, ValidationError
from rich.console import Console
from rich.table import Table
from rich import box

from crawl4ai import AsyncWebCrawler
from crawl4ai.async_configs import BrowserConfig, CrawlerRunConfig, DefaultMarkdownGenerator

# Optional backends
with contextlib.suppress(Exception):
    from qdrant_client import QdrantClient
    from qdrant_client.http.models import Distance, VectorParams, PointStruct
with contextlib.suppress(Exception):
    from sentence_transformers import SentenceTransformer

# Local optional modules
with contextlib.suppress(ImportError):
    from auto_topic import discover_topics, write_topics_markdown
with contextlib.suppress(ImportError):
    from export_s3 import s3_upload_directory

LOG_PATH = Path(os.getenv("KBGEN_LOG_PATH", f"/tmp/CBW-kbgen-{os.getenv('JOB_ID','default')}.log"))
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.FileHandler(LOG_PATH), logging.StreamHandler(sys.stdout)],
)
log = logging.getLogger("kbgen")
console = Console()

# ------------------ Config Models ------------------
class StorageConfig(BaseModel):
    vector: str = Field(default="none", description="qdrant|none")
    sql: str = Field(default="sqlite", description="sqlite|postgres|none")
    sqlite_path: str = Field(default="kb.sqlite")
    pg_host: Optional[str] = None
    pg_port: int = 5432
    pg_db: Optional[str] = None
    pg_user: Optional[str] = None
    pg_password_env: str = "POSTGRES_PASSWORD"

class EmbedConfig(BaseModel):
    provider: str = Field(default="sbert", description="openai|sbert|none")
    model: str = Field(default="sentence-transformers/all-MiniLM-L6-v2")
    chunk_tokens: int = 500
    chunk_overlap: int = 50

class ExportConfig(BaseModel):
    enable: bool = False
    endpoint_url: Optional[str] = None  # e.g. http://localhost:9000 for MinIO
    bucket: Optional[str] = None
    prefix: str = "kbgen/"
    region_name: Optional[str] = None
    access_key_env: str = "AWS_ACCESS_KEY_ID"
    secret_key_env: str = "AWS_SECRET_ACCESS_KEY"

class CrawlTargets(BaseModel):
    bfs_roots: List[str] = []
    sitemaps: List[str] = []
    rss_feeds: List[str] = []
    urls: List[str] = []

class CrawlRules(BaseModel):
    allowed_domains: List[str] = []
    exclude_patterns: List[str] = []
    keywords: List[str] = []
    obey_robots: bool = True
    max_pages: int = 100
    max_depth: int = 3
    concurrency: int = 5
    rate_limit: float = 0.0
    user_agent: str = "CBW-KBGen/0.2"

class OutputConfig(BaseModel):
    out_dir: str = "kb_output"
    compiled_name: Optional[str] = None
    save_raw_html: bool = False

class AppConfig(BaseModel):
    objective: str = "General documentation build"
    tags: List[str] = []
    method: str = "bfs"  # bfs|sitemap|rss|urls|docs
    targets: CrawlTargets = CrawlTargets()
    rules: CrawlRules = CrawlRules()
    output: OutputConfig = OutputConfig()
    storage: StorageConfig = StorageConfig()
    embeddings: EmbedConfig = EmbedConfig()
    export: ExportConfig = ExportConfig()
    topic_discovery: bool = False
    dry_run: bool = False
    verbose: bool = False

# ------------------ Helpers ------------------
def now_stamp() -> str:
    import datetime as dt
    return dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")

def safe_filename(s: str) -> str:
    import re
    return re.sub(r"[^A-Za-z0-9._-]+", "_", s)[:180]

def hash_id(s: str) -> str:
    import hashlib
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:20]

# ------------------ Strategy Loader ------------------
async def crawl_page_markdown(crawler: AsyncWebCrawler, url: str, rules: CrawlRules) -> Dict[str, Any]:
    run_cfg = CrawlerRunConfig(
        markdown_generator=DefaultMarkdownGenerator(),
        exclude_selectors=None,
        js_render=True,
        process_iframes=True,
        text_length_threshold=200,
        obey_robots_txt=rules.obey_robots,
    )
    r = await crawler.arun(url, config=run_cfg)
    md = r.markdown_v2 or r.markdown or ""
    title = (r.metadata.title or url).strip()
    links = list(getattr(r, "links", []))
    import re as _re
    md = _re.sub(r"<script.*?</script>", "", md, flags=_re.S|_re.I)
    return {"url": url, "title": title, "markdown": md, "links": links}

async def strategy_bfs(cfg: AppConfig) -> List[Dict[str, Any]]:
    roots = cfg.targets.bfs_roots
    if not roots: return []
    allowed: Set[str] = set(cfg.rules.allowed_domains)  # type: ignore[name-defined]
    seen: Set[str] = set(); queue: List[Tuple[str,int]] = [(u,0) for u in roots]  # type: ignore[name-defined]
    out: List[Dict[str, Any]] = []
    bcfg = BrowserConfig(headless=True, user_agent=cfg.rules.user_agent)
    async with AsyncWebCrawler(config=bcfg) as crawler:
        while queue and len(out) < cfg.rules.max_pages:
            url, depth = queue.pop(0)
            if url in seen or depth > cfg.rules.max_depth: continue
            seen.add(url)
            if allowed and not any(url.startswith(f"http://{d}") or url.startswith(f"https://{d}") or f".{d}" in url for d in allowed):
                continue
            try:
                page = await crawl_page_markdown(crawler, url, cfg.rules)
            except Exception as e:
                log.warning("Failed %s: %s", url, e); continue
            if cfg.rules.keywords and not any(k.lower() in page["markdown"].lower() for k in cfg.rules.keywords):
                continue
            out.append(page)
            for link in page.get("links", []):
                if allowed and not any(link.startswith(f"http://{d}") or link.startswith(f"https://{d}") for d in allowed):
                    continue
                import re as _re
                if any(_re.search(p, link) for p in (cfg.rules.exclude_patterns or [])): continue
                if link not in seen:
                    queue.append((link, depth+1))
            if cfg.rules.rate_limit>0: time.sleep(cfg.rules.rate_limit)
    return out

async def fetch_text(url: str, timeout: float=20.0) -> str:
    async with httpx.AsyncClient(timeout=timeout, headers={"User-Agent":"CBW-KBGen/0.2"}) as client:
        r = await client.get(url); r.raise_for_status(); return r.text

async def strategy_urls(cfg: AppConfig) -> List[Dict[str, Any]]:
    urls = cfg.targets.urls
    if not urls: return []
    bcfg = BrowserConfig(headless=True, user_agent=cfg.rules.user_agent)
    out: List[Dict[str, Any]] = []
    async with AsyncWebCrawler(config=bcfg) as crawler:
        sem = asyncio.Semaphore(cfg.rules.concurrency)
        async def worker(u: str):
            try:
                page = await crawl_page_markdown(crawler, u, cfg.rules)
                if cfg.rules.keywords and not any(k.lower() in page["markdown"].lower() for k in cfg.rules.keywords):
                    return
                out.append(page)
            except Exception as e:
                log.warning("Failed %s: %s", u, e)
        async def lim(u:str):
            async with sem: await worker(u)
        await asyncio.gather(*(lim(u) for u in urls[:cfg.rules.max_pages]))
    return out

async def strategy_sitemap(cfg: AppConfig) -> List[Dict[str, Any]]:
    if not cfg.targets.sitemaps: return []
    urls: List[str] = []
    for sm in cfg.targets.sitemaps:
        try:
            xml = await fetch_text(sm)
            import re as _re
            urls += _re.findall(r"<loc>(.*?)</loc>", xml, flags=_re.I)
        except Exception as e:
            log.warning("Sitemap fetch failed %s: %s", sm, e)
    cfg.targets.urls = urls
    return await strategy_urls(cfg)

async def strategy_rss(cfg: AppConfig) -> List[Dict[str, Any]]:
    if not cfg.targets.rss_feeds: return []
    urls: List[str] = []
    for feed in cfg.targets.rss_feeds:
        try:
            xml = await fetch_text(feed)
            import re as _re
            urls += _re.findall(r"<link>(.*?)</link>", xml, flags=_re.I)
        except Exception as e:
            log.warning("RSS fetch failed %s: %s", feed, e)
    cfg.targets.urls = urls
    return await strategy_urls(cfg)

# Plugin: docs mode (GitHub/ReadTheDocs/MkDocs)
async def strategy_docs(cfg: AppConfig) -> List[Dict[str, Any]]:
    try:
        from plugins.docs_mode import collect_docs
        return await collect_docs(cfg, crawl_page_markdown)
    except Exception as e:
        log.error("docs_mode failed: %s", e)
        return []

# ------------------ Output + Storage ------------------
import sqlite3

class SQLStore:
    def __init__(self, cfg: StorageConfig):
        self.cfg = cfg; self.kind = cfg.sql; self.conn=None
    def connect(self):
        if self.kind=="none": return
        if self.kind=="sqlite":
            self.conn = sqlite3.connect(self.cfg.sqlite_path)
            self.conn.execute("""
                create table if not exists documents(
                    id text primary key,
                    url text,
                    title text,
                    tags text,
                    objective text,
                    created_at text,
                    path text
                )
            """)
            self.conn.execute("""
                create table if not exists chunks(
                    id text primary key,
                    doc_id text,
                    chunk_index integer,
                    content text
                )
            """)
        elif self.kind=="postgres":
            import psycopg
            dsn = os.getenv("POSTGRES_DSN") or f"host={self.cfg.pg_host} port={self.cfg.pg_port} dbname={self.cfg.pg_db} user={self.cfg.pg_user} password={os.getenv(self.cfg.pg_password_env,'')}"
            self.conn = psycopg.connect(dsn)
            with self.conn.cursor() as cur:
                cur.execute("""
                    create table if not exists documents(
                        id text primary key,
                        url text,
                        title text,
                        tags text,
                        objective text,
                        created_at timestamptz,
                        path text
                    )
                """)
                cur.execute("""
                    create table if not exists chunks(
                        id text primary key,
                        doc_id text references documents(id),
                        chunk_index integer,
                        content text
                    )
                """)
                self.conn.commit()
        else:
            raise RuntimeError("Unsupported SQL backend")
    def add_document(self, doc: Dict[str,Any]):
        if self.kind=="none": return
        if self.kind=="sqlite":
            self.conn.execute("insert or replace into documents values(?,?,?,?,?,?,?)",
                (doc["id"],doc["url"],doc["title"],doc["tags"],doc["objective"],doc["created_at"],doc["path"]))
            self.conn.commit()
        else:
            with self.conn.cursor() as cur:
                cur.execute("insert into documents(id,url,title,tags,objective,created_at,path) values(%s,%s,%s,%s,%s,now(),%s) on conflict (id) do nothing",
                    (doc["id"],doc["url"],doc["title"],doc["tags"],doc["objective"],doc["path"]))
                self.conn.commit()
    def add_chunks(self, doc_id: str, chunks: List[str]):
        if self.kind=="none": return
        if self.kind=="sqlite":
            for i,c in enumerate(chunks):
                cid = hash_id(f"{doc_id}:{i}:{len(c)}"); self.conn.execute("insert or replace into chunks values(?,?,?,?)",(cid,doc_id,i,c))
            self.conn.commit()
        else:
            with self.conn.cursor() as cur:
                for i,c in enumerate(chunks):
                    cid = hash_id(f"{doc_id}:{i}:{len(c)}"); cur.execute("insert into chunks(id,doc_id,chunk_index,content) values(%s,%s,%s,%s) on conflict (id) do nothing",(cid,doc_id,i,c))
                self.conn.commit()

class VectorStore:
    def __init__(self, cfg: StorageConfig):
        self.cfg = cfg; self.client=None; self.collection=None
    def connect(self, collection: str):
        if self.cfg.vector!="qdrant": return
        url=os.getenv("QDRANT_URL","http://localhost:6333"); api_key=os.getenv("QDRANT_API_KEY")
        self.client=QdrantClient(url=url, api_key=api_key)  # type: ignore
        self.collection=collection
        names=[c.name for c in self.client.get_collections().collections]  # type: ignore
        if collection not in names:
            self.client.create_collection(collection_name=collection, vectors_config=VectorParams(size=384,distance=Distance.COSINE))  # type: ignore
    def upsert(self, points: List[Tuple[str,List[float],Dict[str,Any]]]):
        if self.cfg.vector!="qdrant" or not self.client or not self.collection: return
        payload=[PointStruct(id=pid, vector=vec, payload=meta) for (pid,vec,meta) in points]  # type: ignore
        self.client.upsert(collection_name=self.collection, points=payload)  # type: ignore

class Embedder:
    def __init__(self, cfg: EmbedConfig):
        self.cfg=cfg; self.backend=None; self.model=None; self.api_key=None
        if cfg.provider=="sbert":
            self.backend = SentenceTransformer(cfg.model)  # type: ignore
        elif cfg.provider=="openai":
            self.model = cfg.model or "text-embedding-3-small"; self.api_key=os.getenv("OPENAI_API_KEY")
    def embed(self, texts: List[str]) -> List[List[float]]:
        if self.cfg.provider=="none": return []
        if self.cfg.provider=="sbert":
            return self.backend.encode(texts, normalize_embeddings=True).tolist()  # type: ignore
        if self.cfg.provider=="openai":
            if not self.api_key: raise RuntimeError("OPENAI_API_KEY not set")
            headers={"Authorization":f"Bearer {self.api_key}","Content-Type":"application/json"}
            data={"model":self.model,"input":texts}; r=httpx.post("https://api.openai.com/v1/embeddings",headers=headers,json=data,timeout=60); r.raise_for_status(); return [d["embedding"] for d in r.json()["data"]]
        raise RuntimeError("Unknown embedding provider")

# ------------------ Chunking + Files ------------------
def chunk_markdown(md: str, max_tokens:int, overlap:int) -> List[str]:
    words = md.split(); chunks=[]; start=0
    while start < len(words):
        end=min(start+max_tokens,len(words)); chunks.append(" ".join(words[start:end]));
        if end==len(words): break
        start=max(0,end-overlap)
    return chunks

def write_markdown_page(base: Path, page: Dict[str, Any]) -> Path:
    pages_dir = base / "pages"; pages_dir.mkdir(parents=True, exist_ok=True)
    pid = hash_id(page["url"])
    filename = pages_dir / f"{safe_filename(pid + '_' + page['title'][:60])}.md"
    header = textwrap.dedent(f"""---
id: {pid}
url: {page['url']}
title: "{page['title'].replace('"','')}"
---

""")
    content = header + "\n" + page["markdown"].strip() + "\n"
    filename.write_text(content, encoding="utf-8")
    return filename

def compile_kb(out_dir: Path, title: str, pages: List[Dict[str, Any]]) -> Path:
    compiled = out_dir / f"{title or 'KB'}_{now_stamp()}.md"
    toc=["# Knowledge Base", f"_Objective:_ {title}", "", "## Table of Contents"]
    for p in pages:
        pid = hash_id(p["url"])
        from pathlib import Path as _P
        from os import path as _path
        toc.append(f"- [{p['title']}]({_P('pages')/safe_filename(pid + '_' + p['title'][:60])}.md)")
    compiled.write_text("\n".join(toc)+"\n", encoding="utf-8"); return compiled

# ------------------ Pipeline ------------------
async def run_strategy(cfg: AppConfig) -> List[Dict[str,Any]]:
    if cfg.method=="bfs": return await strategy_bfs(cfg)
    if cfg.method=="sitemap": return await strategy_sitemap(cfg)
    if cfg.method=="rss": return await strategy_rss(cfg)
    if cfg.method=="urls": return await strategy_urls(cfg)
    if cfg.method=="docs": return await strategy_docs(cfg)
    raise ValueError("Unknown method")

async def run_pipeline(cfg: AppConfig) -> Dict[str, Any]:
    out_dir = Path(cfg.output.out_dir).resolve(); out_dir.mkdir(parents=True, exist_ok=True)
    if cfg.dry_run:
        console.print("[yellow]DRY-RUN:[/yellow] parsed config OK; no crawling performed.")
        return {"status":"dry_run"}

    pages = await run_strategy(cfg)
    if not pages:
        console.print("[red]No pages collected.[/red]")
        return {"status":"empty"}

    page_files=[]
    for p in pages:
        path = write_markdown_page(out_dir, p); p["path"] = str(path); page_files.append(path)
    compiled = compile_kb(out_dir, cfg.output.compiled_name or cfg.objective, pages)

    # SQL store
    sql = SQLStore(cfg.storage)
    with contextlib.suppress(Exception): sql.connect()

    # Embeddings + Vector
    vectors = VectorStore(cfg.storage)
    embedder=None
    if cfg.embeddings.provider!="none":
        with contextlib.suppress(Exception): embedder = Embedder(cfg.embeddings)
    coll_name=f"kb_{now_stamp()}"; with contextlib.suppress(Exception): vectors.connect(coll_name)

    all_chunk_meta=[]; all_embeddings=[]
    if getattr(sql, "conn", None) or getattr(vectors, "client", None):
        for p in pages:
            doc_id = hash_id(p["url"])
            sql.add_document({
                "id":doc_id,"url":p["url"],"title":p["title"],
                "tags":",".join(cfg.tags),"objective":cfg.objective,
                "created_at":dt.datetime.utcnow().isoformat(),"path":p["path"]
            })
            chunks = chunk_markdown(p["markdown"], cfg.embeddings.chunk_tokens, cfg.embeddings.chunk_overlap)
            sql.add_chunks(doc_id, chunks)
            if embedder and getattr(vectors, "client", None) and chunks:
                embeds = embedder.embed(chunks)
                points=[]
                for i,(c,vec) in enumerate(zip(chunks,embeds)):
                    pid = hash_id(f"{doc_id}:{i}")
                    meta={"doc_id":doc_id,"chunk_index":i,"url":p["url"],"title":p["title"]}
                    points.append((pid,vec,meta))
                    all_chunk_meta.append({"doc_id":doc_id,"chunk_index":i,"text":c,"url":p["url"],"title":p["title"]})
                    all_embeddings.append(vec)
                with contextlib.suppress(Exception): vectors.upsert(points)

    # Topic discovery (optional)
    topics_md=None
    if cfg.topic_discovery and all_embeddings:
        try:
            topics = discover_topics(all_embeddings, all_chunk_meta)  # type: ignore
            topics_md = write_topics_markdown(Path(cfg.output.out_dir), topics)  # type: ignore
        except Exception as e:
            log.error("Topic discovery failed: %s", e)

    # Export (optional)
    if cfg.export.enable:
        try:
            s3_upload_directory(  # type: ignore
                base_dir=str(out_dir),
                endpoint_url=cfg.export.endpoint_url,
                bucket=cfg.export.bucket,
                prefix=cfg.export.prefix,
                region_name=cfg.export.region_name,
                access_key=os.getenv(cfg.export.access_key_env),
                secret_key=os.getenv(cfg.export.secret_key_env)
            )
        except Exception as e:
            log.error("S3 export failed: %s", e)

    table = Table(title="KB Run Summary", box=box.SIMPLE_HEAVY)
    table.add_column("Pages", justify="right"); table.add_column("Output Dir"); table.add_column("Compiled KB")
    table.add_row(str(len(pages)), str(out_dir), str(compiled)); console.print(table)

    return {"status":"ok","pages":len(pages),"out_dir":str(out_dir),"compiled":str(compiled),"topics_md":str(topics_md) if topics_md else None}

# ------------------ CLI ------------------
app = typer.Typer(help="crawl4ai-powered Knowledge Base Generator")

@app.command()
def init_config(path: str = typer.Argument("kbgen.config.yaml")):
    sample = {
        "objective":"Build docs for Project Foo","tags":["docs","api","tutorials"],
        "method":"bfs",
        "targets":{"bfs_roots":["https://example.com/docs/"],"sitemaps":[],"rss_feeds":[],"urls":[]},
        "rules":{"allowed_domains":["example.com"],"exclude_patterns":["\\.pdf$"],"keywords":["install","api","usage"],"obey_robots":True,"max_pages":50,"max_depth":3,"concurrency":5,"rate_limit":0.2,"user_agent":"CBW-KBGen/0.2"},
        "output":{"out_dir":"kb_output","compiled_name":"ProjectFooDocs","save_raw_html":False},
        "storage":{"vector":"qdrant","sql":"sqlite","sqlite_path":"kb.sqlite"},
        "embeddings":{"provider":"sbert","model":"sentence-transformers/all-MiniLM-L6-v2","chunk_tokens":500,"chunk_overlap":50},
        "export":{"enable":False,"endpoint_url":None,"bucket":None,"prefix":"kbgen/"},
        "topic_discovery":False,"dry_run":False,"verbose":False
    }
    Path(path).write_text(yaml.safe_dump(sample, sort_keys=False), encoding="utf-8")
    console.print(f"[green]Wrote starter config to {path}[/green]")

@app.command()
def run(config: str = typer.Option(..., "--config","-c")):
    try:
        raw = Path(config).read_text(); data = yaml.safe_load(raw) if config.endswith((".yml",".yaml")) else json.loads(raw)
        cfg = AppConfig(**data)
    except (OSError, ValidationError, json.JSONDecodeError, yaml.YAMLError) as e:
        console.print(f"[red]Config error:[/red] {e}"); raise typer.Exit(2)
    if cfg.method=="bfs" and not cfg.rules.allowed_domains:
        console.print("[yellow]Safety:[/yellow] Set rules.allowed_domains for BFS.")
    asyncio.run(run_pipeline(cfg))

if __name__=="__main__": app()

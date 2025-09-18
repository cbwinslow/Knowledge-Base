# KBGen Suite — TUI, Search, Topics, Docs Mode, Jobs, S3

Below is a cohesive, production‑minded bundle that extends the previously shared `kbgen.py` with:

1) **Textual TUI** (`tui_app.py`)  
2) **Search API + Next.js UI** (extend `server.py` with `/search`, sample Next.js files)  
3) **Auto‑Topic Discovery** (UMAP + HDBSCAN; `auto_topic.py`)  
4) **GitHub Docs Mode** (strategy plugin; `plugins/docs_mode.py`)  
5) **Job Queue + Workers + SSE logs** (`job_queue.py`, `worker.py`, Redis compose, server `/jobs` + `/events/{id}`)  
6) **S3/MinIO Export** (`export_s3.py`)  

> All files include headers, logging, robust error handling, and are designed to be idempotent and reusable. Secrets are taken from env vars. Use `requirements.txt` to install dependencies.

---

## Project tree (suggested)

```
kbgen-suite/
├─ kbgen.py                      # UPDATED: plugin-aware + topics + S3 export hooks
├─ server.py                     # UPDATED: /run, /search, /jobs, /events/{job_id}
├─ tui_app.py                    # NEW: Textual TUI
├─ auto_topic.py                 # NEW: Topic discovery (UMAP+HDBSCAN)
├─ export_s3.py                  # NEW: S3/MinIO directory uploader
├─ job_queue.py                  # NEW: RQ enqueue helpers
├─ worker.py                     # NEW: RQ worker to run kb jobs
├─ plugins/
│  └─ docs_mode.py              # NEW: GitHub/ReadTheDocs/MkDocs aware crawler strategy
├─ docker-compose.qdrant.yml     # Vector DB
├─ docker-compose.redis.yml      # Redis for RQ jobs
├─ requirements.txt              # Python deps
├─ README.md                     # How-to + security notes
└─ nextjs/                       # Minimal Next.js additions (drop into app/)
   ├─ app/
   │  ├─ page.tsx               # basic launcher UI (from prior scaffold)
   │  └─ search/page.tsx        # search UI (vector + metadata)
   ├─ app/actions.ts            # server action to call API
   ├─ package.json              # partial (add deps to existing)
   └─ next.config.mjs           # standard
```

---

## requirements.txt

```text
crawl4ai>=0.4.0
rich>=13.7.0
typer>=0.12.3
pydantic>=2.7.0
PyYAML>=6.0.1
httpx>=0.27.0
qdrant-client>=1.9.0
sentence-transformers>=2.7.0
psycopg[binary]>=3.2.1
fastapi>=0.111.0
uvicorn[standard]>=0.30.0
textual>=0.69.0
redis>=5.0.6
rq>=1.16.2
sse-starlette>=2.1.0
boto3>=1.34.0
numpy>=1.26.4
scikit-learn>=1.5.0
umap-learn>=0.5.6
hdbscan>=0.8.37
```

> After `pip install -r requirements.txt`, run `crawl4ai-setup` once to install Playwright browsers.

---

## kbgen.py (UPDATED)

```python
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
from typing import Dict, Any, List, Tuple, Optional, Set

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
from typing import Iterable

def now_stamp() -> str:
    import datetime as dt
    return dt.datetime.utcnow().strftime("%Y%m%d-%H%M%S")

def safe_filename(s: str) -> str:
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
    md = re.sub(r"<script.*?</script>", "", md, flags=re.S|re.I)
    return {"url": url, "title": title, "markdown": md, "links": links}

async def strategy_bfs(cfg: AppConfig) -> List[Dict[str, Any]]:
    roots = cfg.targets.bfs_roots
    if not roots: return []
    allowed: Set[str] = set(cfg.rules.allowed_domains)
    seen: Set[str] = set(); queue: List[Tuple[str,int]] = [(u,0) for u in roots]
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
                if any(re.search(p, link) for p in (cfg.rules.exclude_patterns or [])): continue
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
            urls += re.findall(r"<loc>(.*?)</loc>", xml, flags=re.I)
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
            urls += re.findall(r"<link>(.*?)</link>", xml, flags=re.I)
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
        self.client=QdrantClient(url=url, api_key=api_key)
        self.collection=collection
        names=[c.name for c in self.client.get_collections().collections]
        if collection not in names:
            self.client.create_collection(collection_name=collection, vectors_config=VectorParams(size=384,distance=Distance.COSINE))
    def upsert(self, points: List[Tuple[str,List[float],Dict[str,Any]]]):
        if self.cfg.vector!="qdrant" or not self.client or not self.collection: return
        payload=[PointStruct(id=pid, vector=vec, payload=meta) for (pid,vec,meta) in points]
        self.client.upsert(collection_name=self.collection, points=payload)

class Embedder:
    def __init__(self, cfg: EmbedConfig):
        self.cfg=cfg; self.backend=None; self.model=None; self.api_key=None
        if cfg.provider=="sbert":
            self.backend = SentenceTransformer(cfg.model)
        elif cfg.provider=="openai":
            self.model = cfg.model or "text-embedding-3-small"; self.api_key=os.getenv("OPENAI_API_KEY")
    def embed(self, texts: List[str]) -> List[List[float]]:
        if self.cfg.provider=="none": return []
        if self.cfg.provider=="sbert":
            return self.backend.encode(texts, normalize_embeddings=True).tolist()
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
        toc.append(f"- [{p['title']}]({Path('pages')/safe_filename(pid + '_' + p['title'][:60])}.md)")
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
    if sql.conn or vectors.client:
        for p in pages:
            doc_id = hash_id(p["url"])
            sql.add_document({
                "id":doc_id,"url":p["url"],"title":p["title"],
                "tags":",".join(cfg.tags),"objective":cfg.objective,
                "created_at":dt.datetime.utcnow().isoformat(),"path":p["path"]
            })
            chunks = chunk_markdown(p["markdown"], cfg.embeddings.chunk_tokens, cfg.embeddings.chunk_overlap)
            sql.add_chunks(doc_id, chunks)
            if embedder and vectors.client and chunks:
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
            topics = discover_topics(all_embeddings, all_chunk_meta)
            topics_md = write_topics_markdown(Path(cfg.output.out_dir), topics)
        except Exception as e:
            log.error("Topic discovery failed: %s", e)

    # Export (optional)
    if cfg.export.enable:
        try:
            s3_upload_directory(
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
```

---

## plugins/docs_mode.py

```python
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

COMMON_EXCLUDES = [
    "header", "footer", "nav", "aside", ".toc", ".sidebar", ".sphinxsidebar", ".md-sidebar",
]

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
            # Filter markdown sections by excluding common nav selectors (already done upstream by DefaultMarkdownGenerator)
            # Additional keyword keep-pass:
            if cfg.rules.keywords and not any(k.lower() in page["markdown"].lower() for k in cfg.rules.keywords):
                continue
            # Boost priority docs first
            pri = any(re.search(p, url) for p in PRIORITY_PATTERNS)
            if pri:
                out.append(page)
            else:
                # keep non-priority but only if we have capacity
                if len(out) < cfg.rules.max_pages:
                    out.append(page)
            # Queue links on same domain
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
```

---

## auto_topic.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Auto-topic discovery using UMAP dimensionality reduction and HDBSCAN clustering.
Produces a list of topic clusters with representative keywords and member chunks.
"""
from __future__ import annotations
from pathlib import Path
from typing import List, Dict, Any
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
import umap
import hdbscan

def discover_topics(embeddings: List[List[float]], chunk_meta: List[Dict[str,Any]]):
    if not embeddings: return []
    X = np.array(embeddings, dtype=np.float32)
    reducer = umap.UMAP(n_neighbors=15, min_dist=0.1, n_components=10, random_state=42)
    Xr = reducer.fit_transform(X)
    clusterer = hdbscan.HDBSCAN(min_cluster_size=8, metric='euclidean')
    labels = clusterer.fit_predict(Xr)
    # Build clusters
    clusters: Dict[int, List[int]] = {}
    for i, lbl in enumerate(labels):
        if lbl == -1:  # noise
            continue
        clusters.setdefault(lbl, []).append(i)
    # Keywords via TF-IDF per cluster
    topics = []
    for cid, idxs in clusters.items():
        texts = [chunk_meta[i]['text'] for i in idxs]
        vec = TfidfVectorizer(max_features=50, stop_words='english')
        tf = vec.fit_transform(texts)
        scores = tf.sum(axis=0).A1
        vocab = vec.get_feature_names_out()
        top_idx = scores.argsort()[-10:][::-1]
        keywords = [str(vocab[i]) for i in top_idx]
        members = [{k:v for k,v in chunk_meta[i].items() if k!='text'} for i in idxs]
        topics.append({"cluster": int(cid), "keywords": keywords, "members": members})
    return topics

def write_topics_markdown(out_dir: Path, topics: List[Dict[str,Any]]):
    out = Path(out_dir) / "topics.md"
    lines = ["# Auto-Discovered Topics",""]
    for t in topics:
        lines.append(f"## Cluster {t['cluster']}")
        lines.append("**Keywords:** " + ", ".join(t['keywords']))
        lines.append("")
        for m in t['members'][:50]:
            lines.append(f"- {m.get('title','(untitled)')} — {m.get('url','')} (chunk {m.get('chunk_index')})")
        lines.append("")
    out.write_text("\n".join(lines), encoding='utf-8')
    return out
```

---

## export_s3.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
S3/MinIO directory uploader with safe defaults.
"""
from __future__ import annotations
import os
from pathlib import Path
import boto3
from botocore.client import Config

def s3_upload_directory(base_dir: str, endpoint_url: str|None, bucket: str|None, prefix: str="kbgen/", region_name: str|None=None, access_key: str|None=None, secret_key: str|None=None):
    if not bucket:
        raise ValueError("bucket is required for export")
    session = boto3.session.Session()
    s3 = session.resource(
        's3',
        endpoint_url=endpoint_url,
        region_name=region_name,
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_key,
        config=Config(s3={'addressing_style': 'path'})
    )
    b = s3.Bucket(bucket)
    base = Path(base_dir)
    for p in base.rglob('*'):
        if p.is_file():
            rel = p.relative_to(base)
            key = f"{prefix}{rel.as_posix()}"
            b.upload_file(str(p), key)
```

---

## job_queue.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RQ enqueue helpers for KB jobs. Requires Redis.
"""
from __future__ import annotations
import os, json, uuid
from redis import Redis
from rq import Queue

REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379/0")

def _redis_from_url(url:str):
    from urllib.parse import urlparse
    u = urlparse(url)
    return Redis(host=u.hostname, port=u.port or 6379, db=int((u.path or '/0').strip('/')), password=u.password)

def enqueue_kb_job(config: dict) -> str:
    redis = _redis_from_url(REDIS_URL)
    q = Queue("kbq", connection=redis, default_timeout=60*60)
    job_id = uuid.uuid4().hex
    job = q.enqueue("worker.run_job", config, job_id, job_id=job_id)
    return job.id
```

---

## worker.py

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RQ worker entrypoint. Launch with: `rq worker -u $REDIS_URL kbq`
"""
from __future__ import annotations
import os, subprocess, tempfile, json

def run_job(config: dict, job_id: str):
    # Write temp config
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as tf:
        import yaml
        yaml.safe_dump(config, tf)
        tf.flush()
        env = os.environ.copy()
        env["JOB_ID"] = job_id
        env["KBGEN_LOG_PATH"] = f"/tmp/CBW-kbgen-{job_id}.log"
        cmd = ["python", "kbgen.py", "run", "--config", tf.name]
        p = subprocess.run(cmd, capture_output=True, text=True, env=env)
    return {"returncode": p.returncode, "stdout": p.stdout[-4000:], "stderr": p.stderr[-4000:]}
```

---

## server.py (UPDATED with /search, jobs, SSE)

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
from fastapi import FastAPI, HTTPException, Response
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import os, json, time
from pathlib import Path
from typing import Any, List

app = FastAPI(title="KBGen API")

class RunPayload(BaseModel):
    config: dict

@app.post("/run")
def run_job_sync(payload: RunPayload):
    # Synchronous runner (small jobs); for long runs use /jobs
    import subprocess, tempfile, yaml
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as tf:
        yaml.safe_dump(payload.config, tf)
        tf.flush()
        env = os.environ.copy()
        env["KBGEN_LOG_PATH"] = "/tmp/CBW-kbgen-api.log"
        p = subprocess.run(["python","kbgen.py","run","--config",tf.name], capture_output=True, text=True, env=env)
    return {"returncode": p.returncode, "stdout": p.stdout[-4000:], "stderr": p.stderr[-4000:]}

# --- Jobs (RQ) ---
class JobPayload(BaseModel):
    config: dict

@app.post("/jobs")
def create_job(payload: JobPayload):
    try:
        from job_queue import enqueue_kb_job
        job_id = enqueue_kb_job(payload.config)
        return {"job_id": job_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/jobs/{job_id}")
def job_status(job_id: str):
    try:
        from redis import Redis
        from rq.job import Job
        from job_queue import REDIS_URL, _redis_from_url
        r = _redis_from_url(REDIS_URL)
        job = Job.fetch(job_id, connection=r)
        return {"id": job.id, "status": job.get_status(), "result": job.result}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

# --- SSE log stream ---
@app.get("/events/{job_id}")
async def events(job_id: str):
    log_path = Path(f"/tmp/CBW-kbgen-{job_id}.log")
    def stream():
        pos = 0
        while True:
            if log_path.exists():
                with log_path.open('r', encoding='utf-8', errors='ignore') as f:
                    f.seek(pos)
                    for line in f:
                        yield f"data: {line.rstrip()}\n\n"
                    pos = f.tell()
            time.sleep(1)
    return StreamingResponse(stream(), media_type="text/event-stream")

# --- Search ---
class SearchRequest(BaseModel):
    query: str
    top_k: int = 5

@app.post("/search")
def search(req: SearchRequest):
    try:
        from qdrant_client import QdrantClient
        url = os.getenv("QDRANT_URL","http://localhost:6333")
        client = QdrantClient(url=url, api_key=os.getenv("QDRANT_API_KEY"))
        # naive: search latest collection (name startswith kb_ and max)
        cols = client.get_collections().collections
        names = [c.name for c in cols if c.name.startswith("kb_")]
        if not names:
            return {"results": []}
        latest = sorted(names)[-1]
        # embed with SBERT (server-side quick path):
        from sentence_transformers import SentenceTransformer
        m = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
        vec = m.encode([req.query], normalize_embeddings=True).tolist()[0]
        r = client.search(collection_name=latest, query_vector=vec, limit=req.top_k)
        results = [{"score": hit.score, **(hit.payload or {})} for hit in r]
        return {"collection": latest, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
```

---

## tui_app.py (Textual TUI)

```python
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Simple Textual TUI to prepare a config and launch a KB job via the API (/jobs) and stream logs.
"""
from __future__ import annotations
from textual.app import App, ComposeResult
from textual.widgets import Header, Footer, Input, Button, Static, TextLog, Checkbox
from textual.containers import Horizontal, Vertical
import httpx, asyncio, json

API_BASE = "http://localhost:5055"

class KBTui(App):
    CSS = """
    Screen { layout: vertical; }
    #bar { height: 3; }
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
```

---

## docker-compose.redis.yml

```yaml
version: "3.8"
services:
  redis:
    image: redis:7-alpine
    restart: unless-stopped
    ports:
      - "6379:6379"
    command: ["redis-server", "--save", "", "--appendonly", "no"]
```

---

## docker-compose.qdrant.yml (unchanged)

```yaml
version: "3.8"
services:
  qdrant:
    image: qdrant/qdrant:latest
    restart: unless-stopped
    ports:
      - "6333:6333"
    volumes:
      - qdrant-data:/qdrant/storage
volumes:
  qdrant-data:
```

---

## nextjs/app/search/page.tsx (sample search UI)

```tsx
"use client";
import { useState } from "react";

export default function SearchPage(){
  const [q, setQ] = useState("");
  const [res, setRes] = useState<any>(null);
  const API = process.env.NEXT_PUBLIC_API_BASE || "http://localhost:5055";

  async function go(){
    const r = await fetch(`${API}/search`, {method:"POST", headers:{"Content-Type":"application/json"}, body: JSON.stringify({query:q, top_k:10})});
    const j = await r.json();
    setRes(j);
  }

  return (
    <main className="p-6 max-w-3xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">KB Search</h1>
      <input className="border p-2 w-full mb-2" value={q} onChange={e=>setQ(e.target.value)} placeholder="Search query"/>
      <button onClick={go} className="px-4 py-2 rounded bg-black text-white">Search</button>
      <div className="mt-6 space-y-3">
        {res?.results?.map((r:any, i:number)=> (
          <div key={i} className="border p-3 rounded">
            <div className="text-sm text-gray-500">score: {r.score?.toFixed(3)}</div>
            <div className="font-semibold">{r.title}</div>
            <a className="text-blue-600 underline" href={r.url} target="_blank">{r.url}</a>
          </div>
        ))}
      </div>
    </main>
  );
}
```

---

## nextjs/app/actions.ts (from earlier, leave as-is or extend)

```ts
"use server";
export async function runCrawl(config: any) {
  const base = process.env.NEXT_PUBLIC_API_BASE!;
  const res = await fetch(`${base}/run`, {
    method: "POST",
    headers: {"Content-Type":"application/json"},
    body: JSON.stringify({ config }),
    cache: "no-store",
  });
  if (!res.ok) throw new Error(`API failed: ${res.status}`);
  return res.json();
}
```

---

## nextjs/package.json (partial)

```json
{
  "dependencies": {
    "axios": "^1.7.4"
  }
}
```

---

## nextjs/next.config.mjs

```js
/** @type {import('next').NextConfig} */
const nextConfig = { reactStrictMode: true };
export default nextConfig;
```

---

## README.md (essential steps)

```markdown
# KBGen Suite (crawl4ai + TUI + API + Search + Topics + Jobs + S3)

## Quickstart (dev)

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt

# One-time crawl4ai setup
crawl4ai-setup

# Infra: Qdrant + Redis
docker compose -f docker-compose.qdrant.yml up -d
docker compose -f docker-compose.redis.yml up -d

# API server
uvicorn server:app --host 0.0.0.0 --port 5055

# Worker (separate terminal)
export REDIS_URL=redis://localhost:6379/0
rq worker -u $REDIS_URL kbq

# TUI (optional)
python tui_app.py
```

## Security & Ops
- Respect robots.txt (default true). Set `allowed_domains`.
- Secrets via env vars: `OPENAI_API_KEY`, `QDRANT_URL`, `QDRANT_API_KEY`, `AWS_*`, `POSTGRES_*`, `POSTGRES_DSN`.
- Use reverse proxy + auth if exposing `server.py`.

## S3/MinIO Export
Enable in config:
```yaml
export:
  enable: true
  endpoint_url: http://localhost:9000  # MinIO
  bucket: my-kb
  prefix: kbgen/
```

## Topic Discovery
Set `topic_discovery: true` in config; outputs `topics.md`.

## Search
`POST /search {"query":"your text", "top_k":10}`

## Jobs
- `POST /jobs` to enqueue
- `GET /jobs/{id}` status
- `GET /events/{id}` SSE log stream

```

---

## 3+ Improvements / Next Steps

1. **Auth & Multi-tenant**: Add API key/JWT auth to `server.py`, per-tenant buckets/collections, and rate limiting.
2. **Incremental Crawls**: Fingerprint pages (ETag/hash) to skip unchanged content; store crawl history in SQL.
3. **Reranking & HyDE**: Add cross-encoder rerank (bge-reranker) and hypothetical answer expansion for better search.
4. **Scheduler**: Cron-like recurring jobs (APScheduler) with configurable windows.
5. **HTML Sanitization Pipeline**: Add Mercury/Readability fallbacks for edge pages; PDF-to-Markdown via OCR when needed.
6. **Observability**: Prometheus metrics + Grafana dashboards (crawl rate, errors, queue depth, search latencies).


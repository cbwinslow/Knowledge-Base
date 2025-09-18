from typing import Any, Dict
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from db_pool import pool
import hashlib, json, time

class MethodNotFound(Exception): ...
class InvalidParams(Exception): ...

class MCPRouter:
    def __init__(self):
        self.tools = {
            "evaluate_domain": self.evaluate_domain,
            "approve_domain": self.approve_domain,
            "learn_patterns": self.learn_patterns,
            "run_crawl": self.run_crawl,
            "search_docs": self.search_docs,
                "get_site_settings": self.get_site_settings,
                "set_site_settings": self.set_site_settings,
                "crawl_sample": self.crawl_sample,
                "run_crawl_batch": self.run_crawl_batch,
                "semantic_search": self.semantic_search,
                "learn_robots_sitemaps": self.learn_robots_sitemaps,
                "vectorize_doc": self.vectorize_doc,
        }

    async def dispatch(self, method: str, params: Dict[str, Any]):
        if method not in self.tools:
            raise MethodNotFound(f"Unknown tool: {method}")
        try:
            return await self.tools[method](**params)
        except TypeError as e:
            raise InvalidParams(str(e))

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.2), reraise=True)
    async def evaluate_domain(self, domain: str) -> Dict[str, Any]:
        score = 0.9 if domain.endswith(".gov") else 0.2
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """                        INSERT INTO gov_domains (domain, gov_level, reliability_score, coverage_score)
                    VALUES (%s, %s, %s, %s)
                    ON CONFLICT (domain) DO UPDATE SET reliability_score = EXCLUDED.reliability_score
                    RETURNING domain, reliability_score, coverage_score
                    """, (domain, "federal", score, 0.5),
                )
                row = cur.fetchone()
        return {"domain": row[0], "reliability_score": float(row[1]), "coverage_score": float(row[2])}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.2), reraise=True)
    async def approve_domain(self, domain: str) -> Dict[str, Any]:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE gov_domains SET coverage_score = 1.0 WHERE domain = %s", (domain,))
                conn.commit()
        return {"domain": domain, "approved": True}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.2), reraise=True)
    async def learn_patterns(self, domain: str) -> Dict[str, Any]:
        profile = {
            "selectors": {"title": "h1", "content": "article"},
            "pagination": {"mode": "link-next", "selector": "a[rel=next]"},
            "file_types": ["pdf", "html", "json"],
        }
        profile_str = json.dumps(profile, sort_keys=True)
        profile_hash = hashlib.sha256(profile_str.encode()).hexdigest()
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """                        INSERT INTO site_profiles (domain, profile, profile_hash)
                    VALUES (%s, %s::jsonb, %s)
                    ON CONFLICT (domain) DO UPDATE SET profile = EXCLUDED.profile, profile_hash = EXCLUDED.profile_hash
                    """, (domain, profile_str, profile_hash),
                )
                conn.commit()
        return {"domain": domain, "profile_hash": profile_hash}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.2), reraise=True)
    async def run_crawl(self, domain: str, limit: int = 1) -> Dict[str, Any]:
        doc_url = f"https://{domain}/doc/example"
        content_hash = hashlib.sha256(doc_url.encode()).hexdigest()
        storage_uri = f"s3://opendiscourse/raw/{content_hash}.txt"
        provenance = {"adapter": "stub", "fetched_at": int(time.time())}
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """                        INSERT INTO documents (domain, url, doc_type, title, content_hash, storage_uri, provenance)
                    VALUES (%s, %s, %s, %s, %s, %s, %s::jsonb)
                    ON CONFLICT DO NOTHING
                    RETURNING id
                    """, (domain, doc_url, "press_release", "Stub Document", content_hash, storage_uri, json.dumps(provenance)),
                )
                new_id = cur.fetchone()
                conn.commit()
        return {"ingested": 1 if new_id else 0}

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.2), reraise=True)
    async def search_docs(self, query: str) -> Dict[str, Any]:
        q = f"%{query}%"
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """                        SELECT id::text, url, title, doc_type, COALESCE(to_char(retrieved_at, 'YYYY-MM-DD"T"HH24:MI:SS'), '')
                    FROM documents
                    WHERE title ILIKE %s OR url ILIKE %s
                    ORDER BY retrieved_at DESC NULLS LAST
                    LIMIT 25
                    """, (q, q),
                )
                rows = cur.fetchall()
        items = [{"id": r[0], "url": r[1], "title": r[2], "doc_type": r[3], "retrieved_at": r[4]} for r in rows]
        return {"items": items}


async def learn_robots_sitemaps(self, domain: str) -> Dict[str, Any]:
    from learner import discover_sitemaps, fetch_text, parse_sitemap
    # Discover sitemap URLs
    sitemaps = await discover_sitemaps(domain)
    discovered = []
    for sm in sitemaps[:10]:
        xml = await fetch_text(sm)
        if xml:
            discovered.extend(parse_sitemap(xml))
    profile = {
        "sitemaps": sitemaps,
        "samples": discovered[:50],
    }
    import json, hashlib
    profile_str = json.dumps(profile, sort_keys=True)
    profile_hash = hashlib.sha256(profile_str.encode()).hexdigest()
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """                        INSERT INTO site_profiles (domain, profile, profile_hash)
                VALUES (%s, %s::jsonb, %s)
                ON CONFLICT (domain) DO UPDATE SET profile = EXCLUDED.profile, profile_hash = EXCLUDED.profile_hash
                """, (domain, profile_str, profile_hash),
            )
            conn.commit()
    return {"domain": domain, "sitemaps": sitemaps, "profile_hash": profile_hash}

async def vectorize_doc(self, doc_id: str | None = None, text: str | None = None) -> Dict[str, Any]:
    # Lightweight 256-dim hashing embedding to keep deps minimal
    def embed(s: str) -> list[float]:
        dim = 256
        vec = [0.0]*dim
        for ch in s:
            i = ord(ch) % dim
            vec[i] += 1.0
        # L2 normalize
        import math
        norm = math.sqrt(sum(v*v for v in vec)) or 1.0
        return [v/norm for v in vec]
    content = text
    import uuid
    if doc_id and not text:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT text FROM document_text WHERE doc_id = %s", (uuid.UUID(doc_id),))
                row = cur.fetchone()
                if not row:
                    return {"ok": False, "error": "doc text not found"}
                content = row[0]
    if not content:
        return {"ok": False, "error": "no content provided"}
    emb = embed(content[:20000])  # cut to avoid huge strings
    with pool.connection() as conn:
        with conn.cursor() as cur:
            # insert a single chunk for now
            cur.execute(
                "INSERT INTO document_chunks (doc_id, chunk_index, content, embedding) VALUES (uuid_generate_v4(), 0, %s, %s) RETURNING id",
                # Use doc_id if supplied, else generate a doc + text? Keep simple: attach no FK if missing not allowed -> we must provide a valid doc_id
                # So if doc_id is None, create a synthetic doc.
            )
    return {"ok": True}


async def get_site_settings(self, domain: str) -> Dict[str, Any]:
    from config_loader import load_settings_for
    # Merge DB settings (if any) on top of file defaults
    settings = load_settings_for(domain)
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT settings FROM site_settings WHERE domain = %s", (domain,))
            row = cur.fetchone()
            if row and row[0]:
                db_settings = row[0]
                # shallow merge (DB overrides file)
                settings = {**settings, **db_settings}
    return {"domain": domain, "settings": settings}

async def set_site_settings(self, domain: str, settings: Dict[str, Any]) -> Dict[str, Any]:
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO site_settings (domain, settings) VALUES (%s, %s::jsonb) "
                "ON CONFLICT (domain) DO UPDATE SET settings = EXCLUDED.settings, updated_at = now()",
                (domain, json.dumps(settings)),
            )
            conn.commit()
    return {"domain": domain, "ok": True}

async def crawl_sample(self, domain: str, max_docs: int = 1) -> Dict[str, Any]:
    # Use samples from site_profiles; if missing, learn first
    from learner import discover_sitemaps, fetch_text, parse_sitemap
    from fetcher import ingest_url
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT profile FROM site_profiles WHERE domain = %s", (domain,))
            row = cur.fetchone()
    samples = []
    if row and row[0]:
        prof = row[0]
        samples = prof.get("samples", [])[:max_docs]
    if not samples:
        # attempt discovery
        sitemaps = await discover_sitemaps(domain)
        for sm in sitemaps[:5]:
            xml = await fetch_text(sm)
            if xml:
                samples.extend(parse_sitemap(xml))
        samples = samples[:max_docs]
    ingested = 0
    last = None
    for url in samples:
        res = await ingest_url(domain, url)
        ingested += res.get("ingested", 0)
        last = res
    return {"domain": domain, "attempted": len(samples), "ingested": ingested, "last": last}


async def run_crawl_batch(self, domain: str, limit: int = 100, vectorize: bool = True) -> Dict[str, Any]:
    """Batch crawl using sitemap URL list with a persistent cursor per domain.
    Respects politeness from site settings between requests.
    """
    from learner import build_url_list
    from fetcher import ingest_url
    from config_loader import load_settings_for
    import asyncio, json
    settings = load_settings_for(domain)
    politeness_ms = int(settings.get("crawl", {}).get("politeness_ms", 1500))
    # Read or build cursor
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT url_list, pos, total FROM crawl_cursors WHERE domain = %s", (domain,))
            row = cur.fetchone()
            if row:
                url_list, pos, total = row[0], int(row[1] or 0), int(row[2] or 0)
            else:
                url_list = await build_url_list(domain, max_urls=5000)
                pos, total = 0, len(url_list)
                cur.execute(
                    "INSERT INTO crawl_cursors (domain, pos, total, url_list) VALUES (%s,%s,%s,%s::jsonb)",
                    (domain, pos, total, json.dumps(url_list)),
                )
                conn.commit()
    attempted = 0
    ingested = 0
    last = None
    end = min(pos + limit, total)
    for i in range(pos, end):
        url = url_list[i]
        try:
            res = await ingest_url(domain, url)
            attempted += 1
            ingested += res.get("ingested", 0)
            last = res
            # Optional vectorize if we got a doc_id
            if vectorize and res.get("doc_id"):
                await self.vectorize_doc(doc_id=res["doc_id"])
        except Exception as e:
            last = {"error": str(e), "url": url}
        # Politeness delay
        await asyncio.sleep(politeness_ms / 1000.0)
    # Update cursor
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "UPDATE crawl_cursors SET pos = %s, last_run = now() WHERE domain = %s",
                (end, domain),
            )
            conn.commit()
    done = end >= total
    return {"domain": domain, "attempted": attempted, "ingested": ingested, "pos": end, "total": total, "done": done, "last": last}

async def semantic_search(self, query: str, top_k: int = 10) -> Dict[str, Any]:
    """Vector similarity search over document_chunks using the lightweight 256-dim embedding.
    Falls back to LIKE search if no vector table or embeddings present.
    """
    # Same embed function as vectorize_doc
    def embed(s: str) -> list[float]:
        dim = 256
        vec = [0.0]*dim
        for ch in s:
            i = ord(ch) % dim
            vec[i] += 1.0
        import math
        norm = math.sqrt(sum(v*v for v in vec)) or 1.0
        return [v/norm for v in vec]
    qvec = embed(query)
    vec_literal = "[" + ",".join(str(x) for x in qvec) + "]"
    items = []
    try:
        with pool.connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT doc_id::text, chunk_index, left(content, 500) AS snippet, (1 - (embedding <=> %s::vector)) AS score "
                    "FROM document_chunks ORDER BY embedding <=> %s::vector LIMIT %s",
                    (vec_literal, vec_literal, top_k),
                )
                rows = cur.fetchall()
                for r in rows:
                    items.append({"doc_id": r[0], "chunk_index": r[1], "snippet": r[2], "score": float(r[3])})
        return {"items": items, "mode": "vector"}
    except Exception:
        # Fallback LIKE search
        with pool.connection() as conn:
            with conn.cursor() as cur:
                pat = "%" + query + "%"
                cur.execute(
                    "SELECT d.id::text, d.title, left(t.text, 300) as snippet FROM documents d "
                    "JOIN document_text t ON d.id = t.doc_id "
                    "WHERE d.title ILIKE %s OR t.text ILIKE %s LIMIT %s",
                    (pat, pat, top_k),
                )
                rows = cur.fetchall()
                for r in rows:
                    items.append({"doc_id": r[0], "title": r[1], "snippet": r[2], "score": None})
        return {"items": items, "mode": "fallback-like"}

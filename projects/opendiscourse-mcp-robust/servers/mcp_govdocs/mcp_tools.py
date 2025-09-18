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

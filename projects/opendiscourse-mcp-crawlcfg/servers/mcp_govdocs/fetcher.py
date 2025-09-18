from __future__ import annotations
import httpx, hashlib, time, uuid, os
from bs4 import BeautifulSoup
from readability import Document as ReadabilityDocument
from pdfminer.high_level import extract_text as pdf_extract_text
from io import BytesIO
from typing import Dict, Any, Tuple
from db_pool import pool
from minio_utils import ensure_bucket, put_object_bytes
from config_loader import load_settings_for

async def fetch_url(url: str, user_agent: str) -> Tuple[bytes, str, Dict[str, str]]:
    async with httpx.AsyncClient(timeout=30.0, follow_redirects=True, headers={"User-Agent": user_agent}) as client:
        r = await client.get(url)
        r.raise_for_status()
        content_type = r.headers.get("content-type", "").split(";")[0].strip().lower()
        return (r.content, content_type, dict(r.headers))

def normalize_html(content: bytes) -> Tuple[str, str]:
    html = content.decode("utf-8", errors="ignore")
    doc = ReadabilityDocument(html)
    title = doc.short_title() or ""
    summary_html = doc.summary()
    text = BeautifulSoup(summary_html, "lxml").get_text("\n")
    if len(text.strip()) < 10:
        # fallback to full text
        text = BeautifulSoup(html, "lxml").get_text("\n")
    return title, text

def normalize_pdf(content: bytes) -> Tuple[str, str]:
    text = pdf_extract_text(BytesIO(content)) or ""
    title = ""
    return title, text

async def ingest_url(domain: str, url: str) -> Dict[str, Any]:
    settings = load_settings_for(domain)
    ua = settings.get("user_agent", "OpenDiscourseGovDocs/0.1")
    raw, ctype, headers = await fetch_url(url, ua)
    sha = hashlib.sha256(raw).hexdigest()
    bucket = ensure_bucket()
    raw_prefix = settings.get("storage", {}).get("raw_prefix", "raw")
    text_prefix = settings.get("storage", {}).get("text_prefix", "text")

    # Determine type & normalize
    if "pdf" in ctype or url.lower().endswith(".pdf"):
        title, text = normalize_pdf(raw)
        ext = "pdf"
        doc_type = "pdf"
        raw_ct = "application/pdf"
    else:
        title, text = normalize_html(raw)
        ext = "html"
        doc_type = "html"
        raw_ct = ctype or "text/html"

    # Store raw and text
    raw_key = f"{raw_prefix}/{domain}/{sha}.{ext}"
    text_key = f"{text_prefix}/{domain}/{sha}.txt"
    put_object_bytes(bucket, raw_key, raw, raw_ct)
    put_object_bytes(bucket, text_key, text.encode("utf-8"), "text/plain; charset=utf-8")

    # Insert DB rows
    storage_uri = f"s3://{bucket}/{raw_key}"
    provenance = {"content_type": ctype, "headers": headers, "fetched_at": int(time.time())}
    with pool.connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO documents (domain, url, doc_type, title, content_hash, storage_uri, provenance) "
                "VALUES (%s,%s,%s,%s,%s,%s,%s::jsonb) "
                "ON CONFLICT DO NOTHING RETURNING id",
                (domain, url, doc_type, title or url.rsplit('/',1)[-1], sha, storage_uri, json.dumps(provenance)),
            )
            row = cur.fetchone()
            if row:
                doc_id = row[0]
                cur.execute(
                    "INSERT INTO document_text (doc_id, text) VALUES (%s, %s) ON CONFLICT (doc_id) DO NOTHING",
                    (doc_id, text),
                )
                # Update gov_domains stats
                cur.execute("UPDATE gov_domains SET docs_count = COALESCE(docs_count,0)+1, last_crawled = now() WHERE domain = %s", (domain,))
                conn.commit()
                return {"ingested": 1, "doc_id": str(doc_id), "raw_key": raw_key, "text_key": text_key}
    return {"ingested": 0, "reason": "duplicate"}

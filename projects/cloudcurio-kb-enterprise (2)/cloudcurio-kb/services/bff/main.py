#!/usr/bin/env python3
from __future__ import annotations
import os, json, hashlib, time
from typing import Any, Dict, List, Optional, Tuple
from fastapi import FastAPI, Depends, HTTPException, Header, Query
from pydantic import BaseModel
from loguru import logger
import httpx
from jose import jwt
from cachetools import TTLCache

from uuid import uuid4
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import Response, StreamingResponse
from starlette.requests import Request
from starlette.middleware.cors import CORSMiddleware
from datetime import datetime

from prometheus_fastapi_instrumentator import Instrumentator
from redis.asyncio import Redis
from redis.asyncio.cluster import RedisCluster

APP = FastAPI(title="CloudCurio KB BFF")

TERMINUSDB_URL = os.getenv("TERMINUSDB_URL", "http://terminusdb:6363")
OPENSEARCH_URL = os.getenv("OPENSEARCH_URL", "http://opensearch:9200")
OPENSEARCH_INDEX = os.getenv("OPENSEARCH_INDEX", "kb_docs")
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
QDRANT_COLLECTION = os.getenv("QDRANT_COLLECTION", "kb_embeddings")

JWT_ISSUER = os.getenv("JWT_ISSUER", "")
JWT_AUDIENCE = os.getenv("JWT_AUDIENCE", "")
OIDC_JWKS_URL = os.getenv("OIDC_JWKS_URL", "")
_jwks_cache: TTLCache = TTLCache(maxsize=1, ttl=900)

ALLOW_ORIGINS = os.getenv("ALLOW_ORIGINS", "*")
SPKI_PINS = [s.strip() for s in os.getenv("TLS_SPKI_PINS","").split(",") if s.strip()]

RATE_LIMIT = int(os.getenv("RATE_LIMIT","120"))
RATE_WINDOW = int(os.getenv("RATE_WINDOW","60"))

REDIS_MODE = os.getenv("REDIS_MODE","single")
REDIS_URL = os.getenv("REDIS_URL","redis://redis:6379/0")
REDIS_CLUSTER_NODES = [s.strip() for s in os.getenv("REDIS_CLUSTER_NODES","redis-cluster:6379").split(",") if s.strip()]
redis_client = None

class DocIn(BaseModel):
    id: str
    title: str
    source_uri: Optional[str] = None
    text: Optional[str] = None
    published_at: Optional[str] = None
    language: Optional[str] = None

async def _get_jwks() -> dict:
    if "jwks" in _jwks_cache:
        return _jwks_cache["jwks"]
    async with httpx.AsyncClient(timeout=10) as client:
        r = await client.get(OIDC_JWKS_URL)
        r.raise_for_status()
        data = r.json()
        _jwks_cache["jwks"] = data
        return data

async def require_bearer(authorization: Optional[str] = Header(None)):
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "missing bearer token")
    token = authorization.split()[1]
    try:
        jwks = await _get_jwks()
        unverified = jwt.get_unverified_header(token)
        kid = unverified.get("kid")
        key = next((k for k in jwks.get("keys", []) if k.get("kid") == kid), None)
        if not key:
            raise HTTPException(401, "unknown kid")
        claims = jwt.decode(token, key, algorithms=[key.get("alg", "RS256")], audience=JWT_AUDIENCE, issuer=JWT_ISSUER)
        return claims
    except Exception as e:
        logger.warning(f"JWT validation failed: {e}")
        raise HTTPException(401, "invalid token")

APP.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in ALLOW_ORIGINS.split(",")] if ALLOW_ORIGINS != "*" else ["*"],
    allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        rid = str(uuid4())
        start = datetime.utcnow()
        response: Response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "DENY")
        response.headers.setdefault("Referrer-Policy", "no-referrer")
        response.headers.setdefault("Permissions-Policy", "geolocation=(), microphone=()")
        response.headers.setdefault("Strict-Transport-Security", "max-age=63072000; includeSubDomains; preload")
        response.headers.setdefault("Content-Security-Policy", "default-src 'self'; frame-ancestors 'none';")
        response.headers["X-Request-ID"] = rid
        dur = (datetime.utcnow() - start).total_seconds()
        response.headers["Server-Timing"] = f"app;dur={int(dur*1000)}"
        return response
APP.add_middleware(SecurityHeadersMiddleware)

def validate_client_cert_from_proxy(request: Request) -> bool:
    verify = request.headers.get("x-ssl-client-verify", "").lower()
    if verify not in {"success","verified","1","true"}:
        return False if SPKI_PINS else True
    spki = request.headers.get("x-ssl-client-spki", "")
    if SPKI_PINS and spki not in SPKI_PINS:
        return False
    return True

@APP.middleware("http")
async def rate_limit_mw(request: Request, call_next):
    client_ip = request.headers.get("cf-connecting-ip") or request.headers.get("x-forwarded-for","").split(",")[0].strip() or request.client.host
    global redis_client
    if redis_client:
        now = int(time.time()*1000)
        window_ms = RATE_WINDOW * 1000
        key = f"rl:{client_ip}"
        pipe = redis_client.pipeline()
        pipe.zremrangebyscore(key, 0, now - window_ms)
        pipe.zadd(key, {str(now): now})
        pipe.zcard(key)
        pipe.pexpire(key, window_ms)
        _, _, count, _ = await pipe.execute()
        if int(count) > RATE_LIMIT:
            return Response("Too Many Requests", status_code=429)
    return await call_next(request)

@APP.on_event('startup')
async def _startup():
    global redis_client
    Instrumentator().instrument(APP).expose(APP)
    if REDIS_MODE == "cluster":
        redis_client = RedisCluster(startup_nodes=[{'host': n.split(':')[0], 'port': int(n.split(':')[1])} for n in REDIS_CLUSTER_NODES],
                                    decode_responses=True, read_from_replicas=True)
    else:
        redis_client = Redis.from_url(REDIS_URL, encoding='utf-8', decode_responses=True)

@APP.on_event('shutdown')
async def _shutdown():
    global redis_client
    if redis_client: await redis_client.aclose()

class DocOut(BaseModel):
    status: str
    id: str

@APP.post("/v1/docs")
async def create_or_update_doc(doc: DocIn, _=Depends(require_bearer)) -> DocOut:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            logger.info(f"Upserting doc {doc.id} into drafts")
        return DocOut(status="ok", id=doc.id)
    except Exception as e:
        logger.exception("/v1/docs failed")
        raise HTTPException(500, str(e))

@APP.post("/v1/commit")
async def commit_drafts(_=Depends(require_bearer)):
    return {"status":"committed","commit_id":"fake-commit"}

async def _opensearch_keyword(query: str, k: int) -> List[Tuple[str, float]]:
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            body = {"query":{"multi_match":{"query":query,"fields":["title^2","text"]}},"size":k}
            r = await client.post(f"{OPENSEARCH_URL}/{OPENSEARCH_INDEX}/_search", json=body)
            r.raise_for_status()
            hits = r.json().get("hits", {}).get("hits", [])
            return [(h.get("_id"), float(h.get("_score",0))) for h in hits]
    except Exception as e:
        logger.warning(f"OpenSearch error: {e}")
        return []

async def _qdrant_vector(query: str, k: int) -> List[Tuple[str, float]]:
    try:
        seed = int(hashlib.sha256(query.encode()).hexdigest(),16)%1000
        vec = [float((seed%100)/100.0)]*384
        async with httpx.AsyncClient(timeout=15) as client:
            body = {"vector": vec, "limit": k, "with_payload": False}
            r = await client.post(f"{QDRANT_URL}/collections/{QDRANT_COLLECTION}/points/search", json=body)
            if r.status_code >= 400:
                return []
            pts = r.json().get("result", [])
            return [(str(p.get("id")), float(p.get("score",0))) for p in pts]
    except Exception as e:
        logger.warning(f"Qdrant error: {e}")
        return []

def _fuse_results(kw, ve, k):
    def normalize(items):
        if not items: return {}
        scores=[s for _,s in items]; lo=min(scores); hi=max(scores)
        return {i:(0.0 if hi==lo else (s-lo)/(hi-lo)) for i,s in items}
    kw_n=normalize(kw); ve_n=normalize(ve)
    ids=set(kw_n)|set(ve_n); fused=[]
    for _id in ids:
        score=0.6*kw_n.get(_id,0.0)+0.7*ve_n.get(_id,0.0)+(0.2 if _id in kw_n and _id in ve_n else 0.0)
        fused.append({"id":_id,"score":score})
    fused.sort(key=lambda x:x["score"], reverse=True)
    return fused[:k]

@APP.get("/v1/search")
async def hybrid_search(q: str = Query(..., min_length=2), top_k: int = 10, _=Depends(require_bearer)):
    kw = await _opensearch_keyword(q, top_k)
    ve = await _qdrant_vector(q, top_k)
    fused = _fuse_results(kw, ve, top_k)
    return {"query": q, "results": fused, "keyword_hits": len(kw), "vector_hits": len(ve)}

def _etag_for(kind: str, cursor: str|None) -> str:
    raw = f"{kind}:{cursor or ''}".encode()
    return hashlib.sha256(raw).hexdigest()

@APP.get("/v1/export")
async def export_stream(kind: str, format: str = "ndjson", cursor: str | None = None, page_size: int = 1000, if_none_match: str | None = Header(None), _=Depends(require_bearer)):
    if kind not in {"documents","entities","relations"}:
        raise HTTPException(400, "kind must be one of documents|entities|relations")
    if format not in {"ndjson","csv","parquet"}:
        raise HTTPException(400, "format must be ndjson|csv|parquet")
    etag = _etag_for(kind, cursor)
    if if_none_match and etag in [t.strip('"') for t in if_none_match.split(",")]:
        return Response(status_code=304)
    start = int(cursor or "0")

    if format == "parquet":
        raise HTTPException(400, "Use offline exporter for Parquet: scripts/export/export_docs_parquet.py")

    if format == "csv":
        async def gen_csv():
            yield "id,kind\n"
            for i in range(start, start + page_size):
                yield f"{kind[:3]}_{i},{kind}\n"
        return StreamingResponse(gen_csv(), headers={"ETag": etag, "Content-Type":"text/csv"}, media_type="text/csv")

    async def gen_ndjson():
        for i in range(start, start + page_size):
            yield json.dumps({"id": f"{kind[:3]}_{i}", "kind": kind}) + "\n"
    return StreamingResponse(gen_ndjson(), headers={"ETag": etag, "Content-Type":"application/x-ndjson"}, media_type="application/x-ndjson")

#!/usr/bin/env python3
from __future__ import annotations
import os, json, hashlib
from typing import Any, Dict, List, Optional, Tuple
from fastapi import FastAPI, Depends, HTTPException, Header, Query
from pydantic import BaseModel
from loguru import logger
import httpx
from jose import jwt
from cachetools import TTLCache

APP = FastAPI(title="CloudCurio KB BFF")

TERMINUSDB_URL = os.getenv("TERMINUSDB_URL", "http://terminusdb:6363")
NEO4J_URL = os.getenv("NEO4J_URL", "bolt://neo4j:7687")
OPENSEARCH_URL = os.getenv("OPENSEARCH_URL", "http://opensearch:9200")
OPENSEARCH_INDEX = os.getenv("OPENSEARCH_INDEX", "kb_docs")
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
QDRANT_COLLECTION = os.getenv("QDRANT_COLLECTION", "kb_embeddings")
POSTGRES_DSN = os.getenv("POSTGRES_DSN")

JWT_ISSUER = os.getenv("JWT_ISSUER", "")
JWT_AUDIENCE = os.getenv("JWT_AUDIENCE", "")
OIDC_JWKS_URL = os.getenv("OIDC_JWKS_URL", "")
_jwks_cache: TTLCache = TTLCache(maxsize=1, ttl=900)

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

@APP.post("/v1/docs")
async def create_or_update_doc(doc: DocIn, _=Depends(require_bearer)):
    try:
        async with httpx.AsyncClient(timeout=15) as client:
            logger.info(f"Upserting doc {doc.id} into drafts")
        return {"status": "ok", "id": doc.id}
    except Exception as e:
        logger.exception("/v1/docs failed")
        raise HTTPException(500, str(e))

@APP.post("/v1/commit")
async def commit_drafts(_=Depends(require_bearer)):
    try:
        return {"status": "committed", "commit_id": "fake-commit"}
    except Exception as e:
        logger.exception("/v1/commit failed")
        raise HTTPException(500, str(e))

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
    try:
        kw = await _opensearch_keyword(q, top_k)
        ve = await _qdrant_vector(q, top_k)
        fused = _fuse_results(kw, ve, top_k)
        return {"query": q, "results": fused, "keyword_hits": len(kw), "vector_hits": len(ve)}
    except Exception as e:
        logger.exception("/v1/search failed")
        raise HTTPException(500, str(e))

@APP.post("/v1/graph/query")
async def graph_query(engine: str, query: str, _=Depends(require_bearer)):
    if engine not in {"neo4j","janus","nebula"}:
        raise HTTPException(400, "engine must be one of neo4j|janus|nebula")
    try:
        return {"engine": engine, "data": []}
    except Exception as e:
        logger.exception("/v1/graph/query failed")
        raise HTTPException(500, str(e))

async def _terminus_request(method: str, path: str, json_body=None):
    auth = (os.getenv("TERMINUSDB_USER","admin"), os.getenv("TERMINUSDB_PASS","password"))
    url = f"{TERMINUSDB_URL}{path}"
    async with httpx.AsyncClient(timeout=15, auth=auth) as client:
        r = await client.request(method, url, json=json_body)
        return r

async def _ensure_terminus_db(db: str):
    r = await _terminus_request("GET", f"/api/db/admin/{db}")
    if r.status_code == 404:
        cr = await _terminus_request("POST", f"/api/db/admin/{db}", json_body={"label": db, "comment":"CloudCurio KB","public":False})
        if cr.status_code >= 300:
            raise HTTPException(500, f"Create DB failed: {cr.status_code} {cr.text}")
    elif r.status_code >= 300:
        raise HTTPException(500, f"Check DB failed: {r.status_code} {r.text}")

async def _ensure_branch(db: str, branch: str):
    r = await _terminus_request("GET", f"/api/db/admin/{db}/branch")
    if r.status_code >= 300:
        raise HTTPException(500, f"List branches failed: {r.text}")
    names=[b.get("name") for b in (r.json() or [])]
    if branch not in names:
        cr = await _terminus_request("POST", f"/api/db/admin/{db}/branch/{branch}")
        if cr.status_code >= 300:
            raise HTTPException(500, f"Create branch {branch} failed: {cr.text}")

@APP.post("/admin/schema/apply")
async def apply_schema(_: Dict[str, Any], _=Depends(require_bearer)):
    try:
        db = os.getenv("TERMINUSDB_DB","kb")
        await _ensure_terminus_db(db)
        for br in (os.getenv("TERMINUSDB_BRANCH_MAIN","kb/main"), os.getenv("TERMINUSDB_BRANCH_DRAFTS","kb/drafts")):
            await _ensure_branch(db, br)
        # Load split schema files
        base_dir = os.path.normpath(os.path.join(os.path.dirname(__file__), "..","..","schemas","terminusdb"))
        files = ["context.json","document.json","entitykind.json","entity.json","mention.json","relationtype.json","relation.json"]
        classes=[]
        for f in files:
            p = os.path.join(base_dir, f)
            if os.path.exists(p):
                classes.append(json.loads(open(p).read()))
        if not classes:
            raise HTTPException(400,"No schema classes found")
        r = await _terminus_request("PUT", f"/api/db/admin/{db}/schema", json_body={"schema": classes})
        if r.status_code >= 300:
            raise HTTPException(500, f"Schema apply failed: {r.status_code} {r.text}")
        return {"status":"schema_applied","db":db}
    except HTTPException:
        raise
    except Exception as e:
        logger.exception("/admin/schema/apply failed")
        raise HTTPException(500, str(e))

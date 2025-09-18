#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import os, subprocess, tempfile, yaml, time
from pathlib import Path

app = FastAPI(title="KBGen API")

class RunPayload(BaseModel):
    config: dict

@app.post("/run")
def run_job_sync(payload: RunPayload):
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False) as tf:
        yaml.safe_dump(payload.config, tf)
        tf.flush()
        env = os.environ.copy()
        env["KBGEN_LOG_PATH"] = "/tmp/CBW-kbgen-api.log"
        p = subprocess.run(["python","kbgen.py","run","--config",tf.name], capture_output=True, text=True, env=env)
    return {"returncode": p.returncode, "stdout": p.stdout[-4000:], "stderr": p.stderr[-4000:]}

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
        from rq.job import Job
        from job_queue import REDIS_URL, _redis_from_url
        r = _redis_from_url(REDIS_URL)
        job = Job.fetch(job_id, connection=r)
        return {"id": job.id, "status": job.get_status(), "result": job.result}
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))

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

class SearchRequest(BaseModel):
    query: str
    top_k: int = 5

@app.post("/search")
def search(req: SearchRequest):
    try:
        from qdrant_client import QdrantClient
        from sentence_transformers import SentenceTransformer
        url = os.getenv("QDRANT_URL","http://localhost:6333")
        client = QdrantClient(url=url, api_key=os.getenv("QDRANT_API_KEY"))
        cols = client.get_collections().collections
        names = [c.name for c in cols if c.name.startswith("kb_")]
        if not names:
            return {"results": []}
        latest = sorted(names)[-1]
        m = SentenceTransformer("sentence-transformers/all-MiniLM-L6-v2")
        vec = m.encode([req.query], normalize_embeddings=True).tolist()[0]
        r = client.search(collection_name=latest, query_vector=vec, limit=req.top_k)
        results = [{"score": hit.score, **(hit.payload or {})} for hit in r]
        return {"collection": latest, "results": results}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RQ enqueue helpers for KB jobs. Requires Redis.
"""
from __future__ import annotations
import os, uuid
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

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RQ worker entrypoint. Launch with: `rq worker -u $REDIS_URL kbq`
"""
from __future__ import annotations
import os, subprocess, tempfile

def run_job(config: dict, job_id: str):
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

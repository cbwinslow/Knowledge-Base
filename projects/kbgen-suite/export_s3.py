#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
S3/MinIO directory uploader with safe defaults.
"""
from __future__ import annotations
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

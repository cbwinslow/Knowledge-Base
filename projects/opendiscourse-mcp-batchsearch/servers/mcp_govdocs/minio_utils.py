import os
from minio import Minio
from minio.error import S3Error

def ensure_bucket():
    endpoint = os.environ.get("MINIO_ENDPOINT", "minio:9000")
    access_key = os.environ.get("MINIO_ROOT_USER", "minioadmin")
    secret_key = os.environ.get("MINIO_ROOT_PASSWORD", "minioadmin")
    bucket = os.environ.get("MINIO_BUCKET", "opendiscourse")
    secure = False if ":" in endpoint else True
    client = Minio(endpoint, access_key=access_key, secret_key=secret_key, secure=secure)
    found = client.bucket_exists(bucket)
    if not found:
        client.make_bucket(bucket)
    return bucket


import io

def put_object_bytes(bucket: str, key: str, data: bytes, content_type: str = "application/octet-stream"):
    endpoint = os.environ.get("MINIO_ENDPOINT", "minio:9000")
    access_key = os.environ.get("MINIO_ROOT_USER", "minioadmin")
    secret_key = os.environ.get("MINIO_ROOT_PASSWORD", "minioadmin")
    secure = False if ":" in endpoint else True
    client = Minio(endpoint, access_key=access_key, secret_key=secret_key, secure=secure)
    client.put_object(bucket, key, io.BytesIO(data), length=len(data), content_type=content_type)

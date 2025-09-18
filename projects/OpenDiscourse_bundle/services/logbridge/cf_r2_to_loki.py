#!/usr/bin/env python3
import os, json, time, gzip, boto3, requests

LOKI = os.environ.get('LOKI_URL', 'http://127.0.0.1:3100')
S3   = boto3.client('s3', endpoint_url=os.environ.get('R2_ENDPOINT'))
BUCKET = os.environ.get('R2_BUCKET','od-cf-logs')

def push_loki(record, labels):
    payload = {"streams":[{"stream": labels, "values": [[str(int(time.time()*1e9)), json.dumps(record)]]}]}
    requests.post(f"{LOKI}/loki/api/v1/push", json=payload, timeout=10)

def main():
    print("TODO: iterate bucket/prefix, read gz/ndjson, push to Loki with labels.")

if __name__ == "__main__":
    main()

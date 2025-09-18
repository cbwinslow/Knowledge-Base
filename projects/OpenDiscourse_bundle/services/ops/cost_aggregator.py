#!/usr/bin/env python3
import os, json, subprocess, boto3
R2 = boto3.client('s3', endpoint_url=os.getenv('R2_ENDPOINT'))
BUCKET = os.getenv('R2_BUCKET','od-raw')

pg_db = os.getenv('PGDATABASE','opendiscourse')
pg_user = os.getenv('PGUSER','postgres')

def r2_bytes():
    total = 0
    resp = R2.list_objects_v2(Bucket=BUCKET)
    for obj in resp.get('Contents',[]):
        total += obj['Size']
    return total

def pg_bytes():
    q = "SELECT pg_database_size(%s);"
    cmd = ['psql','-U',pg_user,'-d',pg_db,'-tAc',q,pg_db]
    out = subprocess.check_output(cmd, text=True)
    return int(out.strip())

if __name__=='__main__':
    data = {'r2_bytes': r2_bytes(), 'pg_bytes': pg_bytes()}
    print(json.dumps(data, indent=2))

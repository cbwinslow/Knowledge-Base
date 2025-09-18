#!/usr/bin/env python3
import time, yaml, redis, os
r = redis.Redis(host=os.getenv('REDIS_HOST','127.0.0.1'))
conf = yaml.safe_load(open('services/etl/providers.yaml')) if os.path.exists('services/etl/providers.yaml') else {'providers': []}

def allow(key, rate_per_min):
    now = int(time.time()//60)
    bucket = f"rl:{key}:{now}"
    used = r.incr(bucket)
    r.expire(bucket, 120)
    return used <= rate_per_min

if __name__=='__main__':
    for p in conf.get('providers', []):
        key = p['name']
        print(key, 'limit', p.get('rpm'))

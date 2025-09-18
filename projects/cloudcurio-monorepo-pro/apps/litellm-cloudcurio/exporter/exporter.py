import os, time, requests, psycopg
BASE = os.getenv("LITELLM_BASE","http://litellm:4000")
conn = None
def db():
    global conn
    if conn is None or conn.closed:
        conn = psycopg.connect(host=os.getenv("PGHOST","postgres"),
                               user=os.getenv("PGUSER","litellm"),
                               password=os.getenv("PGPASSWORD","postgres"),
                               dbname=os.getenv("PGDATABASE","analytics"))
        with conn.cursor() as cur:
            cur.execute("create table if not exists metrics (ts timestamptz default now(), requests bigint, errors bigint, cache_hits bigint)")
            conn.commit()
    return conn
def loop():
    while True:
        try:
            r = requests.get(f"{BASE}/metrics", timeout=10)
            req=err=hit=0
            for line in r.text.splitlines():
                if line.startswith("#"): continue
                if "litellm_requests_total" in line: req += float(line.split()[-1])
                if "litellm_errors_total" in line: err += float(line.split()[-1])
                if "litellm_cache_hits_total" in line: hit += float(line.split()[-1])
            d=db()
            with d.cursor() as cur:
                cur.execute("insert into metrics(requests,errors,cache_hits) values (%s,%s,%s)",(int(req),int(err),int(hit)))
                d.commit()
        except Exception as e:
            print("exporter error:", e, flush=True)
        time.sleep(300)
if __name__=="__main__":
    loop()

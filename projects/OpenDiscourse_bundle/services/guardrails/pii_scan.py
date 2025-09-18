#!/usr/bin/env python3
Scan logs/raw payloads for PII heuristics; write findings to Loki/OpenSearch.
import os, re, json, gzip, glob, time
PII_PATTERNS = {
  'email': re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
  'ssn':   re.compile(r"(?!000|666|9\d{2})\d{3}-?(?!00)\d{2}-?(?!0000)\d{4}"),
  'phone': re.compile(r"\+?1?\s*\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}"),
}
SRC = os.environ.get('SCAN_DIR','/var/log')

def scan_file(path):
    hits = []
    opener = gzip.open if path.endswith('.gz') else open
    with opener(path, 'rt', errors='ignore') as f:
        for i, line in enumerate(f,1):
            for k, pat in PII_PATTERNS.items():
                for m in pat.findall(line):
                    hits.append({'file': path,'line': i,'kind': k,'match': str(m)[:64]})
    return hits

if __name__ == '__main__':
    results = []
    for p in glob.glob(os.path.join(SRC,'**/*'), recursive=True):
        if not os.path.isfile(p):
            continue
        if any(ext in p for ext in ('.log','.json','.ndjson','.txt','.gz')):
            results.extend(scan_file(p))
    print(json.dumps({'ts': int(time.time()), 'findings': results[:1000]}, indent=2))

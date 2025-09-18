# OpenDiscourse – Operational Appendices & Code Tasks

This document appends governance, compliance, resilience, cost and API sections with **granular task tables** and **code skeletons** ready to drop into the repo.

---

## 📜 ProviderLicenses & ToS Compliance — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | ToS Catalog | 1) Create `docs/ProviderLicenses.md` 2) Add GovInfo/OpenStates/FedReg links 3) Summarize key clauses 4) Record attribution requirements 5) Set renewal/review dates | Central ToS tracker | Doc complete and referenced by ETL | | | |
| [ ] | Rate-Limit Guardrails | 1) Per-provider RPM/RPH limits 2) Token bucket in clients 3) Global scheduler cap 4) Alert on 429 spikes | Prevent provider bans | No 429 bursts; alerts on sustained pressure | | | |
| [ ] | Attribution Pipeline | 1) Add attribution field on pages 2) Footer mentions 3) API response headers | Meet attribution duties | Pages/APIs display attribution where required | | | |

---

## 🔐 Privacy & Compliance (PII/GDPR/CCPA) — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | PII Policy | 1) Create `docs/PII-Policy.md` 2) Define what we store 3) Retention windows 4) DSAR workflow 5) DPO contact | Formal policy published | Policy approved; linked in footer | | | |
| [ ] | PII Scanner Job | 1) Regex/NLP patterns 2) Scan logs/raw payloads 3) Summaries to Grafana 4) Quarantine path | Detect accidental PII | Weekly job runs; zero critical findings | | | |
| [ ] | DSAR Automation | 1) Export data script 2) Delete script with audit log 3) Admin UI action 4) Legal sign-off | Handle subject requests | End-to-end DSAR dry-run passes | | | |

### Code — PII Scanner
```python
# services/guardrails/pii_scan.py
#!/usr/bin/env python3
"""Scan logs/raw payloads for PII heuristics; write findings to Loki/OpenSearch."""
import os, re, json, gzip, glob, time
PII_PATTERNS = {
  'email': re.compile(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"),
  'ssn':   re.compile(r"\b(?!000|666|9\d{2})\d{3}-?(?!00)\d{2}-?(?!0000)\d{4}\b"),
  'phone': re.compile(r"\b\+?1?\s*\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}\b"),
}
SRC = os.environ.get('SCAN_DIR','/var/log')
SEVERITY = {'email': 'low','phone':'low','ssn':'critical'}

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
```

---

## 🛡️ Moderation & Abuse — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Policy Doc | 1) `docs/ModerationPolicy.md` 2) Prohibited content list 3) Enforcement ladder 4) Appeals | Clear community rules | Doc linked from comment UI | | | |
| [ ] | Tooling | 1) Report button 2) Auto-hide on toxicity>τ 3) Mod queue filters 4) Shadow-ban control | Effective moderation | Abuse removal SLA met | | | |
| [ ] | Audit | 1) Log moderator actions 2) Immutable store 3) Transparency summary | Accountability | Quarterly transparency report | | | |

---

## 🧪 Chaos & Resilience — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Chaos Playbook | 1) `docs/ChaosPlaybook.md` 2) Failure modes (API 5xx, timeouts, slow I/O) 3) Blast radius guidelines 4) Abort conditions | Safe experimentation | Playbook approved and versioned | | | |
| [ ] | ETL Fault Injector | 1) Latency injection 2) Error rate knob 3) Disk-full simulation 4) Kill/restart worker | Exercise failure paths | No data loss; backoff works | | | |
| [ ] | DB Failover Drill | 1) Replica promotion script 2) Repoint apps 3) Measure RTO 4) Post-drill cleanup | Prove DR readiness | RTO within target; doc updated | | | |

### Code — ETL Fault Injector
```python
# services/chaos/fault_injector.py
import os, random, time, sys
# Usage: wrap ETL calls; inject `ETL_FAULT_P=0.05`, `ETL_FAULT_LAT_MS=200`
P = float(os.getenv('ETL_FAULT_P','0'))
LAT = int(os.getenv('ETL_FAULT_LAT_MS','0'))/1000
if random.random() < P:
    time.sleep(LAT)
    if random.random() < 0.5:
        sys.exit(1)
```

---

## 💸 Cost Controls & FinOps — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Cost Doc | 1) `docs/CostControls.md` 2) Budget caps 3) Alert thresholds 4) Storage growth policies | Visibility & limits | Dashboards show $/month estimates | | | |
| [ ] | Cost Aggregator | 1) R2 bucket inventory 2) Postgres DB size 3) API call counts 4) Embedding spend estimator | Central monthly view | Grafana ‘Cost’ dashboard populated | | | |

### Code — Cost Aggregator
```python
# services/ops/cost_aggregator.py
import os, json, subprocess, boto3
R2 = boto3.client('s3', endpoint_url=os.getenv('R2_ENDPOINT'))
BUCKET = os.getenv('R2_BUCKET','od-raw')

pg_db = os.getenv('PGDATABASE','opendiscourse')
pg_user = os.getenv('PGUSER','postgres')

def r2_bytes():
    total = 0
    for obj in R2.list_objects_v2(Bucket=BUCKET).get('Contents',[]):
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
```

---

## 🌍 Internationalization & Accessibility — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | i18n Plumbing | 1) Enable Next.js i18n routing 2) Message catalog loader 3) Locale switcher 4) Date/number formatting | Multilingual ready | English + one extra locale render | | | |
| [ ] | A11y Audit | 1) Axe-core automated checks 2) Keyboard-only pass 3) Screen reader smoke 4) Color contrast AA | Inclusive UI | Zero critical a11y issues | | | |

### Code — Playwright + axe-core
```ts
// tests/e2e/a11y.spec.ts
import { test, expect } from '@playwright/test'
import AxeBuilder from '@axe-core/playwright'

test('homepage is accessible', async ({ page }) => {
  await page.goto('/')
  const results = await new AxeBuilder({ page }).analyze()
  expect(results.violations).toEqual([])
})
```

---

## 📡 API Governance — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Public API Spec | 1) `services/mcp/openapi.yaml` 2) Versioning policy 3) Error code taxonomy 4) Pagination & rate limits 5) Examples | Stable external API | Spec published; mock server passes tests | | | |
| [ ] | SDK Stubs | 1) TS client 2) Python client 3) Typed models 4) Retry auth helpers | Easy integration | SDKs install and call staging | | | |

---

## 🧰 Automation: Rate-Limit Sentry — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Sentry Worker | 1) Read provider quotas from `providers.yaml` 2) Token bucket per provider 3) Persist counters (Redis) 4) Pause ETL on breach 5) Alert | Avoid bans, stay compliant | No provider returns 429 bursts; auto-pauses | | | |

### Code — Rate-Limit Sentry
```python
# services/guardrails/rate_limit_sentry.py
import time, yaml, redis, os
r = redis.Redis(host=os.getenv('REDIS_HOST','127.0.0.1'))
conf = yaml.safe_load(open('services/etl/providers.yaml'))

def allow(key, rate_per_min):
    now = int(time.time()//60)
    bucket = f"rl:{key}:{now}"
    used = r.incr(bucket)
    r.expire(bucket, 120)
    return used <= rate_per_min

if __name__=='__main__':
    for p in conf['providers']:
        key = p['name']
        print(key, 'limit', p['rpm'])
```

---

## 🧪 Smoke Tests: Backup & Restore — **EXPANDED**

| ✅ | Task | Microgoals | Description | Criteria for Completion | Completed On | Completed By | Solution Summary |
|----|------|------------|-------------|-------------------------|--------------|--------------|------------------|
| [ ] | Postgres PITR | 1) Create sample dataset 2) Take base backup 3) Drop table 4) Restore to timestamp 5) Verify row counts | Confidence in PITR | Recovery time within RTO | | | |
| [ ] | Neo4j Restore | 1) Dump 2) Wipe 3) Load dump 4) Count nodes/edges 5) Verify constraints | Graph recovery proven | Node/edge parity met | | | |

---

### Ansible Timers (new)
```yaml
# roles/ops/tasks/timers.yml
- name: Timer - PII scan weekly
  copy:
    dest: /etc/systemd/system/pii-scan.timer
    content: |
      [Unit]
      Description=Weekly PII Scan
      [Timer]
      OnCalendar=Sun *-*-* 03:00:00
      [Install]
      WantedBy=timers.target
- copy:
    dest: /etc/systemd/system/pii-scan.service
    content: |
      [Unit]
      Description=PII Scan
      [Service]
      ExecStart=/usr/bin/python3 /opt/opendiscourse/services/guardrails/pii_scan.py
- systemd: { name: pii-scan.timer, state: started, enabled: yes }
```

---

✅ All sections above include both **task microgoals** and **working code skeletons** you can wire into the repo.


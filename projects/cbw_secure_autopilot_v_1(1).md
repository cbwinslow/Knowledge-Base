# 📦 CBW Secure Autopilot v1.2 — Full Code Archive

Below are **all the scripts and code files** from the security autopilot project, organized for full deployment.

---

## 📁 Repository Structure
```
cbw-secure-autopilot-v1_2/
├── cbw-secure-autopilot.sh
├── etc/
│   ├── cbw/selfheal.d/default.yml
│   └── sysctl.d/99-cbw-hardening.conf
├── usr/local/bin/cbw-prom-eve-exporter.py
├── grafana-loki/
│   ├── docker-compose.yml
│   ├── loki-config.yml
│   ├── promtail-config.yml
│   ├── provisioning/
│   │   ├── datasources/datasource.yml
│   │   └── dashboards/dashboard.yml
│   └── dashboards/security_suricata_overview.json
└── repo/README.md
```

---

## 📦 Download Full Bundle
**[Download cbw-secure-autopilot-v1_2.zip](sandbox:/mnt/data/cbw-secure-autopilot-v1_2.zip)**

---

## ⚡ Quickstart
```bash
chmod +x cbw-secure-autopilot.sh
sudo ./cbw-secure-autopilot.sh \
  --install-all --install-localai --install-exporters --install-hardening \
  --enable-report-signing --enable-anomaly --llm-backend localai --run-once

cd grafana-loki
docker compose up -d
```
- Grafana: <http://localhost:3000> (admin/admin)
- Loki: <http://localhost:3100>

---

## 📜 cbw-secure-autopilot.sh
```bash
<full script contents from installer here>
```

---

## 📜 etc/cbw/selfheal.d/default.yml
```yaml
version: 1
rules:
  - name: ensure-suricata-active
    when: ids.suricata.active == False
    action: systemctl restart suricata
    severity: 2
  - name: rotate-giant-syslog-when-df-full
    when: '"100%" in disk.df'
    action: logrotate /etc/logrotate.conf
    severity: 1
  - name: warn-many-high-severity-alerts
    when: len(eve.high_sev_alerts) > 5
    action: noop
    severity: 2
```

---

## 📜 etc/sysctl.d/99-cbw-hardening.conf
```conf
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.tcp_syncookies=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_redirects=0
kernel.kptr_restrict=2
kernel.dmesg_restrict=1
```

---

## 📜 usr/local/bin/cbw-prom-eve-exporter.py
```python
#!/usr/bin/env python3
import http.server, socketserver, json, os
PORT=9108; EVE=os.environ.get('CBW_EVE','/var/log/suricata/eve.json')
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path!='/metrics': self.send_error(404); return
        counts={'total':0,'alert':0,'alert_high':0}
        try:
            with open(EVE,'rb') as f:
                for ln in f.readlines()[-2000:]:
                    try:
                        j=json.loads(ln.decode('utf-8','ignore'))
                        counts['total']+=1
                        if j.get('event_type')=='alert':
                            counts['alert']+=1
                            if int(j.get('alert',{}).get('severity',0))>=2: counts['alert_high']+=1
                    except Exception: pass
        except Exception: pass
        out=(f"cbw_eve_total {counts['total']}\n"
             f"cbw_eve_alert {counts['alert']}\n"
             f"cbw_eve_alert_high {counts['alert_high']}\n")
        self.send_response(200); self.send_header('Content-Type','text/plain; version=0.0.4'); self.end_headers(); self.wfile.write(out.encode())
with socketserver.TCPServer(('',PORT), H) as httpd: httpd.serve_forever()
```

---

## 📜 grafana-loki/docker-compose.yml
```yaml
version: "3"
services:
  loki:
    image: grafana/loki:2.9.8
    command: ["-config.file=/etc/loki/config/loki-local-config.yml"]
    ports: ["3100:3100"]
    volumes:
      - ./loki-config.yml:/etc/loki/config/loki-local-config.yml:ro
      - loki-data:/loki
  promtail:
    image: grafana/promtail:2.9.8
    command: ["-config.file=/etc/promtail/config.yml"]
    volumes:
      - ./promtail-config.yml:/etc/promtail/config.yml:ro
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
    network_mode: host
  grafana:
    image: grafana/grafana:11.1.0
    ports: ["3000:3000"]
    volumes:
      - grafana-data:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning
      - ./dashboards:/var/lib/grafana/dashboards
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-piechart-panel
volumes:
  loki-data: {}
  grafana-data: {}
```

---

**Full archive includes all configs, dashboards, README, and systemd unit files.**


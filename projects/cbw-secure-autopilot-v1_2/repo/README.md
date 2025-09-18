# CBW Secure Autopilot v1.2

What this installs:
- Suricata + Snort (best-effort)
- rkhunter + chkrootkit + daily reports
- AI self-heal agent with YAML playbooks, EVE watcher, anomaly, LocalAI backend
- Prometheus exporter for EVE metrics
- Optional report signing, host hardening sysctl
- Optional Grafana + Loki stack with prebuilt dashboard

Quickstart
```bash
chmod +x cbw-secure-autopilot.sh
sudo ./cbw-secure-autopilot.sh   --install-all --install-localai --install-exporters --install-hardening   --enable-report-signing --enable-anomaly   --llm-backend localai --run-once

# Grafana + Loki
cd grafana-loki && docker compose up -d
```

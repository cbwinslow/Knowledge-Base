# Project Rules

- Use project_memory.md for this server; use global_memory.md for cross-project prefs.
- Always enable node_exporter and postgres_exporter; enable JMX exporter when service exists.
- Dashboards live under /var/lib/grafana/dashboards; provision via /etc/grafana/provisioning/dashboards.
- /etc/cbw-ports.conf is the source of truth for port bindings.

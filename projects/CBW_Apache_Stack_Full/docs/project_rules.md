# Project Rules
- Use project_memory.md for this server; global_memory.md for cross-project prefs.
- Always enable node_exporter & postgres_exporter; enable JMX exporters when service exists.
- Dashboards under /var/lib/grafana/dashboards; provision via /etc/grafana/provisioning/dashboards.
- /etc/cbw-ports.conf is the source of truth for port bindings.

# Global Rules
1. Security-first: bind UIs to 127.0.0.1; expose via Cloudflare Tunnel.
2. Port truth: allocate via cbw-port-guard.sh -> /etc/cbw-ports.conf.
3. Prefer Postgres for app state; avoid SQLite.
4. Idempotent scripts/roles.
5. Logging via systemd; /var/log/<svc> when needed.
6. Backups: nightly Postgres + restore drills.
7. Observability: Prometheus + Grafana; exporters (node, postgres, jmx).
8. Secrets: /etc/cbw-secrets.env (0600) or external vault.

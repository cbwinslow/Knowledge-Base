# Global Rules

1. Security-first: bind UIs to 127.0.0.1; expose only via Cloudflare Tunnel.
2. Port truth: allocate via /usr/local/sbin/cbw-port-guard.sh and persist to /etc/cbw-ports.conf.
3. Prefer Postgres for app state; avoid SQLite.
4. Idempotent scripts/roles.
5. Logging: systemd units; /var/log/<svc> where needed.
6. Backups: nightly Postgres backups + restore drills.
7. Observability: Prometheus + Grafana; exporters for node, postgres, jmx where available.
8. Secrets: /etc/cbw-secrets.env (0600) or external vault; rotate regularly.

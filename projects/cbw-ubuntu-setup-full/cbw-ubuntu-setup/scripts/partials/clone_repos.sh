#!/usr/bin/env bash
set -euo pipefail
mkdir -p /opt/cbw-repos
cd /opt/cbw-repos
for repo in \
  "https://github.com/cbwinslow/local-ai-packaged" \
  "https://github.com/Qdrant/qdrant" \
  "https://github.com/pgvector/pgvector" \
  "https://github.com/pigsty/pigsty" \
  "https://github.com/Kong/docker-kong" \
  "https://github.com/grafana/loki" \
  "https://github.com/grafana/promtail" \
  "https://github.com/prometheus/node_exporter" \
  "https://github.com/google/cadvisor" \
  "https://github.com/netdata/netdata" \
  "https://github.com/goaccess/goaccess" \
  ; do
  name=$(basename "$repo")
  [[ -d "$name" ]] || git clone "$repo" || true
done
[[ -n "${DOTFILES_REPO:-}" ]] && { [[ -d "dotfiles" ]] || git clone "$DOTFILES_REPO" dotfiles || true; }
[[ -n "${SCRIPTS_REPO:-}" ]] && { [[ -d "binfiles" ]] || git clone "$SCRIPTS_REPO" binfiles || true; }
echo "[✓] Repositories cloned under /opt/cbw-repos."

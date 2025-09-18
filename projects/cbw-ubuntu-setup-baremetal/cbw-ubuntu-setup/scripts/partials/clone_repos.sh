#!/usr/bin/env bash
set -euo pipefail

mkdir -p /opt/cbw-repos
cd /opt/cbw-repos

# Common repos (edit as desired)
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
  if [[ ! -d "$name" ]]; then
    git clone "$repo" || true
  fi
done

# Dotfiles/script repos
if [[ -n "${DOTFILES_REPO:-}" ]]; then
  if [[ ! -d "dotfiles" ]]; then
    git clone "$DOTFILES_REPO" dotfiles || true
  fi
fi
if [[ -n "${SCRIPTS_REPO:-}" ]]; then
  if [[ ! -d "binfiles" ]]; then
    git clone "$SCRIPTS_REPO" binfiles || true
  fi
fi

echo "[✓] Repositories cloned under /opt/cbw-repos."

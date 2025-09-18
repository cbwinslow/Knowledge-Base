#!/usr/bin/env bash
# orchestrate_install.sh — interactive menu to install selected components
set -Eeuo pipefail
LOG="/tmp/CBW-orchestrate.log"; exec > >(tee -a "$LOG") 2>&1

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
B="${HERE}/baremetal"

declare -A ITEMS=(
  [Ollama]="${B}/install_ollama.sh"
  [LocalAI]="${B}/install_localai.sh"
  [LocalRecall]="${B}/install_localrecall.sh"
  [GPT4All]="${B}/install_gpt4all.sh"
  [AnythingLLM]="${B}/install_anythingllm.sh"
  [Redis]="${B}/install_redis.sh"
  [FalkorDB]="${B}/install_falkordb.sh"
  [Graphite]="${B}/install_graphite.sh"
  [Keycloak]="${B}/install_keycloak.sh"
  [MinIO]="${B}/install_minio.sh"
  [pgAdmin]="${B}/install_pgadmin.sh"
  [Adminer]="${B}/install_adminer.sh"
  [NGINX]="${B}/install_nginx.sh"
  [Caddy]="${B}/install_caddy.sh"
  [Traefik]="${B}/install_traefik.sh"
  [Clone-local-ai-packaged]="${B}/clone_local_ai_packaged.sh"
)

echo "Select components to install (space to toggle, enter to confirm):"
choices=()
for k in "${!ITEMS[@]}"; do choices+=("$k"); done

# Fallback simple prompt (no fzf/whiptail dependencies)
echo "Available:"
i=1
for k in "${choices[@]}"; do echo "  $i) $k"; i=$((i+1)); done
echo "Enter numbers separated by spaces (or 'all'): "
read -r PICK

run() { echo ">>> $*"; bash -c "$*"; }

to_run=()
if [[ "$PICK" == "all" ]]; then
  for k in "${choices[@]}"; do to_run+=("${ITEMS[$k]}"); done
else
  for n in $PICK; do
    idx=$((n-1))
    key="${choices[$idx]}"
    [[ -n "$key" ]] && to_run+=("${ITEMS[$key]}")
  done
fi

for s in "${to_run[@]}"; do
  echo "=== Running $s ==="
  sudo bash "$s"
done
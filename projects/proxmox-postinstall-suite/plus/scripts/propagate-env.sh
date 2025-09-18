#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "Usage: $0 hosts.txt"; exit 1; }
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT/.env"
source "$ENV_FILE"
: "${PROP_USER:=cbwinslow}"; : "${PROP_SSH_KEY:=$HOME/.ssh/id_ed25519}"
while IFS= read -r HOST || [[ -n "$HOST" ]]; do
  [[ -z "$HOST" || "$HOST" =~ ^# ]] && continue
  scp -i "$PROP_SSH_KEY" -o StrictHostKeyChecking=no "$ENV_FILE" "$PROP_USER@$HOST:/tmp/cloudcurio.env"
  ssh -i "$PROP_SSH_KEY" -o StrictHostKeyChecking=no "$PROP_USER@$HOST" "sudo mkdir -p /etc/cloudcurio && sudo mv /tmp/cloudcurio.env /etc/cloudcurio/.env && sudo chmod 640 /etc/cloudcurio/.env"
  echo "Propagated to $HOST"
done < "$1"

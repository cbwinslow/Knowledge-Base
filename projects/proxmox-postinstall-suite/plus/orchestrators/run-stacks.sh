#!/usr/bin/env bash
set -euo pipefail
CMD="${1:-status}"
BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for d in "$BASE"/stacks/*; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  case "$CMD" in
    up)     (cd "$d" && ./up.sh) ;;
    down)   (cd "$d" && ./down.sh) ;;
    status) echo "== $name =="; (cd "$d" && docker compose ps || true) ;;
    *) echo "Usage: $0 [up|down|status]"; exit 1;;
  esac
done

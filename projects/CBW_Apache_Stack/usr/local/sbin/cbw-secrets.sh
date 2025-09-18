#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-secrets.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Minimal secrets manager for local server. Stores key=value pairs
#               in /etc/cbw-secrets.env (600). Provides get/set/list.
#===============================================================================
set -euo pipefail; IFS=$'\n\t'
FILE="/etc/cbw-secrets.env"
[[ -f "$FILE" ]] || { umask 177; touch "$FILE"; chmod 600 "$FILE"; }
case "${1:-}" in
  set)
    [[ $# -eq 3 ]] || { echo "usage: $0 set KEY VALUE"; exit 1; }
    k="$2"; v="$3"
    grep -qE "^${k}=" "$FILE" && sed -i "s/^${k}=.*/${k}=${v//\//\/}/" "$FILE" || echo "${k}=${v}" >> "$FILE";
    ;;
  get)
    [[ $# -eq 2 ]] || { echo "usage: $0 get KEY"; exit 1; }
    grep -E "^${2}=" "$FILE" | head -n1 | awk -F= '{print $2}'
    ;;
  list)
    sed 's/=.*/=<hidden>/' "$FILE"
    ;;
  *) echo "Usage: $0 {set|get|list}"; exit 1;;
esac

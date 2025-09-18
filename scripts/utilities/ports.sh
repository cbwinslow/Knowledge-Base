#!/usr/bin/env bash
# tools/ports.sh — simple port registry & conflict check
set -Eeuo pipefail

REG="${REG:-./PORTS.registry}"

usage(){ cat <<EOF
Usage: $0 [reserve <port> <name>] | [list] | [check <port>]
EOF
}

list_ports(){ [ -f "$REG" ] && column -t "$REG" || echo "No registry yet."; }
reserve(){ 
  local port="$1" name="$2"
  grep -E "^[[:space:]]*$port[[:space:]]" "$REG" >/dev/null 2>&1 && { echo "Port already reserved"; exit 1; }
  echo -e "${port}\t${name}" >> "$REG"; sort -n -o "$REG" "$REG"; echo "Reserved $port for $name"
}
check(){
  local port="$1"
  if ss -tulpn | grep -q ":$port "; then
    echo "Port $port is IN USE"
    ss -tulpn | grep ":$port "
  else
    echo "Port $port appears free"
  fi
}
case "${1:-}" in
  reserve) reserve "$2" "$3" ;;
  list) list_ports ;;
  check) check "$2" ;;
  *) usage ;;
esac
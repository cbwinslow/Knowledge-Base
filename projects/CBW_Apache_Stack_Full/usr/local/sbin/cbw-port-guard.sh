#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'
CONF="/etc/cbw-ports.conf"; LOCK="/var/lock/cbw-ports.lock"
require_root(){ [[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }; }
init_conf(){ [[ -f "$CONF" ]] || { umask 022; echo "# CBW Port Map - SERVICE=PORT" > "$CONF"; chmod 0644 "$CONF"; }; }
port_in_use(){ ss -lnt "( sport = :$1 )" | awk 'NR>1{print $4}' | grep -q ":$1$"; }
find_free(){ local p=$1 a=2000; while ((a-- > 0)); do port_in_use "$p" || { echo "$p"; return; }; p=$((p+1)); done; echo "No free port near $1" >&2; exit 2; }
get(){ awk -F= -v s="$1" '$1==s{print $2}' "$CONF" 2>/dev/null || true; }
setmap(){ local s="$1" p="$2"; grep -qE "^${s}=" "$CONF" && sed -i "s/^${s}=.*/${s}=${p}/" "$CONF" || echo "${s}=${p}" >> "$CONF"; }
reserve(){ local s="$1" pref="$2"; [[ $pref =~ ^[0-9]+$ ]] || { echo "pref port must be number"; exit 2; }; local cur; cur="$(get "$s")"; if [[ -n "$cur" ]]; then if port_in_use "$cur"; then local np; np="$(find_free "$pref")"; setmap "$s" "$np"; echo "$np"; else echo "$cur"; fi; else local ch; ch="$(find_free "$pref")"; setmap "$s" "$ch"; echo "$ch"; fi; }
release(){ local s="$1"; grep -qE "^${s}=" "$CONF" && sed -i "/^${s}=/d" "$CONF" || echo "[*] ${s} not present"; }
status(){ printf "%-18s  %-6s  %s\n" SERVICE PORT STATE; printf "%-18s  %-6s  %s\n" ------ ---- -----; while IFS='=' read -r s p; do [[ $s =~ ^#|^$ ]] && continue; st=FREE; port_in_use "$p" && st=LISTENING; printf "%-18s  %-6s  %s\n" "$s" "$p" "$st"; done < "$CONF"; }
with_lock(){ exec 9>"$LOCK"; flock -w 10 9 || { echo "Cannot lock $LOCK"; exit 3; }; "$@"; }
main(){ require_root; init_conf; case "${1:-}" in reserve) [[ $# -eq 3 ]]||{echo usage;exit 1;}; with_lock reserve "$2" "$3";; release) [[ $# -eq 2 ]]||{echo usage;exit 1;}; with_lock release "$2";; status) status;; get) [[ $# -eq 2 ]]||{echo usage;exit 1;}; get "$2";; suggest) [[ $# -eq 2 ]]||{echo usage;exit 1;}; find_free "$2";; *) echo "Usage: $0 {reserve|get|release|status|suggest}"; exit 1;; esac; }
main "$@"

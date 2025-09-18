#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'
CONF="/etc/cbw-ports.conf"
[[ -f "$CONF" ]] || { echo "No $CONF"; exit 1; }
printf "%-14s %-8s %-20s %-20s %-10s\n" SERVICE PORT BIND PROCESS UNIT
printf "%-14s %-8s %-20s %-20s %-10s\n" ------ ---- ---- ------- ----
while IFS='=' read -r svc port; do [[ $svc =~ ^#|^$ ]] && continue; bind=$(ss -lntp | awk -v P=":$port" '$4 ~ P {print $4}' | head -n1); proc=$(ss -lntp | awk -v P=":$port" '$4 ~ P {print $NF}' | sed 's/users:\[//;s/\]//' | head -n1); unit=$(systemctl -pNames --type=service --no-legend | awk '{print $1}' | grep -E "${svc}|airflow|tomcat|tika|kafka|solr|nifi|guacd|superset" | head -n1); printf "%-14s %-8s %-20s %-20s %-10s\n" "$svc" "$port" "${bind:-N/A}" "${proc:-N/A}" "${unit:-N/A}"; done < "$CONF"
echo; echo "Conflicts:"; awk -F= '{print $2}' "$CONF" | sort | uniq -d | sed 's/^/  Duplicate port: /' || true

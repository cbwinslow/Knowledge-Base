#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'
SRC_DIR="${1:-$(pwd)}"
install -Dm755 "$SRC_DIR/usr/local/sbin/cbw-port-guard.sh" /usr/local/sbin/cbw-port-guard.sh || true
install -Dm755 "$SRC_DIR/usr/local/sbin/cbw-svc-audit.sh" /usr/local/sbin/cbw-svc-audit.sh || true
install -Dm700 "$SRC_DIR/usr/local/sbin/cbw-secrets.sh" /usr/local/sbin/cbw-secrets.sh || true
mkdir -p /root/installers
for f in cbw-metrics-install.sh cbw-install-kafka.sh cbw-install-solr.sh cbw-install-nifi.sh cbw-install-opensearch.sh cbw-install-apache-httpd.sh cbw-harden-ubuntu.sh cbw-postgres-readonly.sh cbw-install-superset.sh cbw-install-guacamole.sh cbw-install-tika-pdfbox.sh; do
  [[ -f "$SRC_DIR/root/installers/$f" ]] && install -Dm755 "$SRC_DIR/root/installers/$f" "/root/installers/$f"
done
[[ -f /etc/cbw-ports.conf ]] || { echo "# CBW Port Map - SERVICE=PORT" > /etc/cbw-ports.conf; chmod 644 /etc/cbw-ports.conf; }
[[ -f /etc/cbw-secrets.env ]] || { touch /etc/cbw-secrets.env; chmod 600 /etc/cbw-secrets.env; }
echo "[+] Bootstrap copy complete."
/usr/local/sbin/cbw-port-guard.sh status || true

#!/usr/bin/env bash
set -euo pipefail
LOG="/tmp/CBW-watchdog.log"
exec > >(tee -a "$LOG") 2>&1

DRY_RUN=${DRY_RUN:-false}
VERBOSE=${CBW_VERBOSE:-false}

do() {
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

echo "Installing port watchdog (systemd timer)..."
install -d /opt/cbw/bin
cat > /opt/cbw/bin/cbw-port-watchdog.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
REPORT="/var/log/cbw/port-watchdog.log"
install -d -m 0755 /var/log/cbw
date +"==== %F %T ====" >> "$REPORT"
ss -tulpn >> "$REPORT" 2>&1 || true
docker ps --format 'table {{.Names}}	{{.Status}}	{{.Ports}}' >> "$REPORT" 2>&1 || true
SH
chmod +x /opt/cbw/bin/cbw-port-watchdog.sh

cat > /etc/systemd/system/cbw-port-watchdog.service <<'UNIT'
[Unit]
Description=CBW Port & Service Watchdog

[Service]
Type=oneshot
ExecStart=/opt/cbw/bin/cbw-port-watchdog.sh
User=root
UNIT

cat > /etc/systemd/system/cbw-port-watchdog.timer <<'UNIT'
[Unit]
Description=Run CBW Port & Service Watchdog every 5 minutes

[Timer]
OnBootSec=2m
OnUnitActiveSec=5m
Unit=cbw-port-watchdog.service

[Install]
WantedBy=timers.target
UNIT

do "systemctl daemon-reload"
do "systemctl enable --now cbw-port-watchdog.timer"

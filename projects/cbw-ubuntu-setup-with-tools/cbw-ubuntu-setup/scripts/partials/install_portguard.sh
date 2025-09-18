#!/usr/bin/env bash
set -euo pipefail
install -d -m 0755 /usr/local/bin
install -m 0755 "$(dirname "$0")/../tools/cbw-portguard.py" /usr/local/bin/cbw-portguard
install -d -m 0755 /etc/cbw
cat > /etc/cbw/ports.yaml <<'EOF'
pgadmin: 5050
mongo_express: 8081
neo4j_bloom: 7475
EOF
echo "[✓] PortGuard (placeholder) installed."

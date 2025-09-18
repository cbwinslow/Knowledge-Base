#!/usr/bin/env bash
set -euo pipefail
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor -o /etc/apt/keyrings/opensearch.gpg
echo "deb [signed-by=/etc/apt/keyrings/opensearch.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/2.x/apt stable main" > /etc/apt/sources.list.d/opensearch-dashboards-2.x.list
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y opensearch-dashboards
sed -i 's/^#*server.host:.*/server.host: "0.0.0.0"/' /etc/opensearch-dashboards/opensearch-dashboards.yml
systemctl enable --now opensearch-dashboards
echo "[✓] OpenSearch Dashboards running on :5601."

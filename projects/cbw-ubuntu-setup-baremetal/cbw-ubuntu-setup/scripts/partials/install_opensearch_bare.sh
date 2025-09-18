#!/usr/bin/env bash
set -euo pipefail

echo "[*] Installing OpenSearch 2.x"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor -o /etc/apt/keyrings/opensearch.gpg
echo "deb [signed-by=/etc/apt/keyrings/opensearch.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" > /etc/apt/sources.list.d/opensearch-2.x.list

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y opensearch

# Single-node config
sed -i 's/^#*cluster.name:.*/cluster.name: cbw-opensearch/' /etc/opensearch/opensearch.yml
sed -i 's/^#*node.name:.*/node.name: node-1/' /etc/opensearch/opensearch.yml
sed -i 's/^#*network.host:.*/network.host: 0.0.0.0/' /etc/opensearch/opensearch.yml
grep -q '^discovery.type:' /etc/opensearch/opensearch.yml || echo 'discovery.type: single-node' >> /etc/opensearch/opensearch.yml

systemctl enable --now opensearch
echo "[✓] OpenSearch running on :9200 (HTTPS) and :9600."

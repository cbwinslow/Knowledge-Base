#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-opensearch.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Single-node OpenSearch + Dashboards with port guard (localhost).
#===============================================================================
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PG=/usr/local/sbin/cbw-port-guard.sh
HTTP_PORT=$($PG reserve OPENSEARCH_HTTP 9200 | tail -n1)
TRANS_PORT=$($PG reserve OPENSEARCH_TCP 9300 | tail -n1)
DASH_PORT=$($PG reserve OPENSEARCH_DASH 5601 | tail -n1)

apt update && apt install -y wget gnupg apt-transport-https
wget -qO - https://artifacts.opensearch.org/publickeys/opensearch.pgp | gpg --dearmor | tee /usr/share/keyrings/opensearch-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/opensearch-keyring.gpg] https://artifacts.opensearch.org/releases/bundle/opensearch/2.x/apt stable main" > /etc/apt/sources.list.d/opensearch-2.x.list
apt update && apt install -y opensearch opensearch-dashboards

sed -i "s/^#\?network.host:.*/network.host: 127.0.0.1/" /etc/opensearch/opensearch.yml
sed -i "s/^#\?http.port:.*/http.port: ${HTTP_PORT}/" /etc/opensearch/opensearch.yml
sed -i "s/^#\?transport.port:.*/transport.port: ${TRANS_PORT}/" /etc/opensearch/opensearch.yml
grep -q '^discovery.type:' /etc/opensearch/opensearch.yml || echo 'discovery.type: single-node' >> /etc/opensearch/opensearch.yml
sed -i 's/^#\?plugins.security.disabled: .*/plugins.security.disabled: true/' /etc/opensearch/opensearch.yml

sed -i 's/^#\?server.host:.*/server.host: "127.0.0.1"/' /etc/opensearch-dashboards/opensearch_dashboards.yml
sed -i "s/^#\?server.port:.*/server.port: ${DASH_PORT}/" /etc/opensearch-dashboards/opensearch_dashboards.yml

systemctl enable --now opensearch
systemctl enable --now opensearch-dashboards

echo "[+] OpenSearch http : ${HTTP_PORT} | Dashboards : ${DASH_PORT} (localhost only)"

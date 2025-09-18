#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-solr.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Bare-metal install of Apache Solr 9.x with localhost binding.
#===============================================================================
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PORT_SOLR_DEFAULT=8983
PORT_SOLR=$( /usr/local/sbin/cbw-port-guard.sh reserve SOLR "$PORT_SOLR_DEFAULT" | tail -n1 )
SVER="9.7.0"; cd /tmp; wget -q "https://dlcdn.apache.org/solr/${SVER}/solr-${SVER}.tgz" -O solr.tgz
tar -xzf solr.tgz; bash /tmp/solr-${SVER}/bin/install_solr_service.sh /tmp/solr.tgz -n
sed -i 's/^#\?SOLR_JETTY_HOST=.*/SOLR_JETTY_HOST="127.0.0.1"/' /etc/default/solr.in.sh
sed -i "s/^#\?SOLR_PORT=.*/SOLR_PORT=${PORT_SOLR}/" /etc/default/solr.in.sh
systemctl restart solr
echo "[+] Solr on http://127.0.0.1:${PORT_SOLR}/solr"

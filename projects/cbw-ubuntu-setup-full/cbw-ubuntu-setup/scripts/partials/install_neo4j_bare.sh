#!/usr/bin/env bash
set -euo pipefail
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /etc/apt/keyrings/neo4j.gpg
echo "deb [signed-by=/etc/apt/keyrings/neo4j.gpg] https://debian.neo4j.com stable 5" > /etc/apt/sources.list.d/neo4j.list
apt-get update -y
apt-get install -y neo4j neo4j-apoc neo4j-gds
NEO4J_CONF="/etc/neo4j/neo4j.conf"
sed -i 's/^#*dbms.default_listen_address=.*/dbms.default_listen_address=0.0.0.0/' "$NEO4J_CONF"
sed -i 's/^#*dbms.security.auth_enabled=.*/dbms.security.auth_enabled=true/' "$NEO4J_CONF"
grep -q '^dbms.security.procedures.unrestricted=' "$NEO4J_CONF" || echo "dbms.security.procedures.unrestricted=apoc.*,gds.*" >> "$NEO4J_CONF"
grep -q '^dbms.security.procedures.allowlist=' "$NEO4J_CONF" || echo "dbms.security.procedures.allowlist=apoc.*,gds.*" >> "$NEO4J_CONF"
systemctl enable --now neo4j
echo "[✓] Neo4j started on :7474 / :7687."

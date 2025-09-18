#!/usr/bin/env bash
set -euo pipefail
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /etc/apt/keyrings/mongodb-server-7.0.gpg
echo "deb [signed-by=/etc/apt/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME)/mongodb-org/7.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-7.0.list
apt-get update -y
apt-get install -y mongodb-org
systemctl enable --now mongod
echo "[✓] MongoDB started on :27017."

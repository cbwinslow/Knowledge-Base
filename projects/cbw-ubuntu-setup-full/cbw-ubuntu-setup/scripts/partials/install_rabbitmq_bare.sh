#!/usr/bin/env bash
set -euo pipefail
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc | gpg --dearmor -o /etc/apt/keyrings/esl.gpg
echo "deb [signed-by=/etc/apt/keyrings/esl.gpg] https://packages.erlang-solutions.com/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) contrib" > /etc/apt/sources.list.d/erlang.list
curl -fsSL https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey | gpg --dearmor -o /etc/apt/keyrings/rabbitmq.gpg
echo "deb [signed-by=/etc/apt/keyrings/rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ $(. /etc/os-release && echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/rabbitmq.list
apt-get update -y
apt-get install -y esl-erlang rabbitmq-server
systemctl enable --now rabbitmq-server
rabbitmq-plugins enable rabbitmq_management || true
systemctl restart rabbitmq-server
echo "[✓] RabbitMQ running (:5672) UI :15672."

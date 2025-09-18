#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-kafka.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Bare-metal install of Apache Kafka (KRaft mode) with auto-port.
#===============================================================================
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PORT_KAFKA_DEFAULT=9092
PORT_KAFKA=$( /usr/local/sbin/cbw-port-guard.sh reserve KAFKA "$PORT_KAFKA_DEFAULT" | tail -n1 )
PORT_KRAFT_CTRL_DEFAULT=9093
PORT_KRAFT_CTRL=$( /usr/local/sbin/cbw-port-guard.sh reserve KAFKA_CTRL "$PORT_KRAFT_CTRL_DEFAULT" | tail -n1 )

id -u kafka &>/dev/null || useradd -m -s /usr/sbin/nologin kafka
KVER="3.7.1"; cd /opt; wget -qO /tmp/kafka.tgz "https://downloads.apache.org/kafka/${KVER}/kafka_2.13-${KVER}.tgz"
tar -xzf /tmp/kafka.tgz -C /opt && mv /opt/kafka_2.13-${KVER} /opt/kafka
chown -R kafka:kafka /opt/kafka
cat >/opt/kafka/config/kraft.properties <<EOF
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@127.0.0.1:${PORT_KRAFT_CTRL}
listeners=PLAINTEXT://:${PORT_KAFKA},CONTROLLER://:${PORT_KRAFT_CTRL}
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER
advertised.listeners=PLAINTEXT://127.0.0.1:${PORT_KAFKA}
log.dirs=/opt/kafka/kraft-data
EOF
chown kafka:kafka /opt/kafka/config/kraft.properties
sudo -u kafka /opt/kafka/bin/kafka-storage.sh random-uuid > /opt/kafka/cluster.uuid
sudo -u kafka /opt/kafka/bin/kafka-storage.sh format -t "$(cat /opt/kafka/cluster.uuid)" -c /opt/kafka/config/kraft.properties
cat >/etc/systemd/system/kafka.service <<'UNIT'
[Unit]
Description=Apache Kafka (KRaft)
After=network-online.target
[Service]
User=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft.properties
Restart=on-failure
LimitNOFILE=100000
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload; systemctl enable --now kafka
echo "[+] Kafka on 127.0.0.1:${PORT_KAFKA} (controller ${PORT_KRAFT_CTRL})"

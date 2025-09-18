#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-metrics-install.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Installs Prometheus, Grafana, and key exporters; wires JMX
#               exporter for Java services (Kafka/Solr/NiFi/Tomcat) with ports
#               reserved via cbw-port-guard. Creates sane scrape configs.
#===============================================================================
set -euo pipefail; IFS=$'\n\t'; trap 'echo "[ERROR] $LINENO" >&2' ERR
PGUARD=/usr/local/sbin/cbw-port-guard.sh
[[ -x $PGUARD ]] || { echo "cbw-port-guard.sh missing"; exit 1; }

PROM_PORT=$($PGUARD reserve PROMETHEUS 9090 | tail -n1)
GRAF_PORT=$($PGUARD reserve GRAFANA 3000 | tail -n1)
NODEXP_PORT=$($PGUARD reserve NODE_EXPORTER 9100 | tail -n1)
PGEXP_PORT=$($PGUARD reserve POSTGRES_EXPORTER 9187 | tail -n1)
JMX_KAFKA=$($PGUARD reserve JMX_KAFKA 9404 | tail -n1)
JMX_SOLR=$($PGUARD reserve JMX_SOLR 9405 | tail -n1)
JMX_NIFI=$($PGUARD reserve JMX_NIFI 9406 | tail -n1)
JMX_TOMCAT=$($PGUARD reserve JMX_TOMCAT 9407 | tail -n1)

apt update
apt install -y prometheus grafana node-exporter wget curl jq unzip
systemctl enable --now node-exporter grafana-server || true

useradd -r -s /usr/sbin/nologin postgres_exporter 2>/dev/null || true
cd /opt
PEX_VER="0.15.0"
wget -qO /tmp/pgexp.tar.gz "https://github.com/prometheus-community/postgres_exporter/releases/download/v${PEX_VER}/postgres_exporter-${PEX_VER}.linux-amd64.tar.gz"
tar -xzf /tmp/pgexp.tar.gz -C /opt
mv "/opt/postgres_exporter-${PEX_VER}.linux-amd64" /opt/postgres_exporter
chown -R postgres_exporter:postgres_exporter /opt/postgres_exporter

PG_DSN_AIRFLOW="postgresql://airflow:airflow_strong_pw_change@127.0.0.1:5432/airflow?sslmode=disable"

cat >/etc/systemd/system/postgres-exporter.service <<EOF
[Unit]
Description=Prometheus Postgres Exporter
After=network-online.target
[Service]
User=postgres_exporter
Environment=DATA_SOURCE_NAME=${PG_DSN_AIRFLOW}
ExecStart=/opt/postgres_exporter/postgres_exporter --web.listen-address=127.0.0.1:${PGEXP_PORT}
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload; systemctl enable --now postgres-exporter

mkdir -p /opt/jmx-exporter
JMX_VER="0.20.0"
wget -q "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_VER}/jmx_prometheus_javaagent-${JMX_VER}.jar" -O /opt/jmx-exporter/jmx_prometheus_javaagent.jar

cat >/opt/jmx-exporter/basic.yaml <<'YAML'
lowercaseOutputName: true
lowercaseOutputLabelNames: true
rules:
  - pattern: ".*"
YAML

if systemctl is-enabled kafka >/dev/null 2>&1; then
  sed -i "/^KAFKA_HEAP_OPTS/d" /etc/systemd/system/kafka.service
  sed -i "/^ExecStart=/d" /etc/systemd/system/kafka.service
  cat >>/etc/systemd/system/kafka.service <<EOF
Environment=KAFKA_HEAP_OPTS=-javaagent:/opt/jmx-exporter/jmx_prometheus_javaagent.jar=${JMX_KAFKA}:/opt/jmx-exporter/basic.yaml
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft.properties
EOF
  systemctl daemon-reload; systemctl restart kafka || true
fi

if [[ -d /usr/share/tomcat10/bin ]]; then
  mkdir -p /usr/share/tomcat10/bin
  cat >/usr/share/tomcat10/bin/setenv.sh <<EOF
export CATALINA_OPTS="\$CATALINA_OPTS -javaagent:/opt/jmx-exporter/jmx_prometheus_javaagent.jar=${JMX_TOMCAT}:/opt/jmx-exporter/basic.yaml"
EOF
  chmod +x /usr/share/tomcat10/bin/setenv.sh
  systemctl restart tomcat10 || true
fi

if systemctl is-enabled solr >/dev/null 2>&1; then
  sed -i "/^SOLR_OPTS=/d" /etc/default/solr.in.sh
  echo "SOLR_OPTS=\"\$SOLR_OPTS -javaagent:/opt/jmx-exporter/jmx_prometheus_javaagent.jar=${JMX_SOLR}:/opt/jmx-exporter/basic.yaml\"" >> /etc/default/solr.in.sh
  systemctl restart solr || true
fi

if [[ -f /opt/nifi/bin/nifi-env.sh ]]; then
  sed -i "/^JAVA_OPTS=/d" /opt/nifi/bin/nifi-env.sh
  echo "export JAVA_OPTS=\"\$JAVA_OPTS -javaagent:/opt/jmx-exporter/jmx_prometheus_javaagent.jar=${JMX_NIFI}:/opt/jmx-exporter/basic.yaml\"" >> /opt/nifi/bin/nifi-env.sh
  systemctl restart nifi || true
fi

mkdir -p /etc/prometheus/file_sd
cat >/etc/prometheus/prometheus.yml <<PROM
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: node
    static_configs:
      - targets: ['127.0.0.1:${NODEXP_PORT}']
  - job_name: postgres
    static_configs:
      - targets: ['127.0.0.1:${PGEXP_PORT}']
  - job_name: airflow
    static_configs:
      - targets: ['127.0.0.1:8793']
  - job_name: kafka-jmx
    static_configs:
      - targets: ['127.0.0.1:${JMX_KAFKA}']
  - job_name: tomcat-jmx
    static_configs:
      - targets: ['127.0.0.1:${JMX_TOMCAT}']
  - job_name: solr-jmx
    static_configs:
      - targets: ['127.0.0.1:${JMX_SOLR}']
  - job_name: nifi-jmx
    static_configs:
      - targets: ['127.0.0.1:${JMX_NIFI}']
PROM

sed -i "s/^#\?--web.listen-address=.*/--web.listen-address=127.0.0.1:${PROM_PORT}/" /etc/default/prometheus 2>/dev/null || true
sed -i "s/^ARGS=.*/ARGS=\"--web.listen-address=127.0.0.1:${PROM_PORT}\"/" /etc/default/prometheus 2>/dev/null || echo 'ARGS="--web.listen-address=127.0.0.1:'${PROM_PORT}'"' >> /etc/default/prometheus
systemctl enable --now prometheus

if [[ -f /etc/grafana/grafana.ini ]]; then
  sed -i 's/^;http_addr =.*/http_addr = 127.0.0.1/' /etc/grafana/grafana.ini
  sed -i "s/^;http_port =.*/http_port = ${GRAF_PORT}/" /etc/grafana/grafana.ini
  systemctl restart grafana-server
fi

echo "[+] Metrics stack ready. Prometheus : ${PROM_PORT}, Grafana : ${GRAF_PORT}"

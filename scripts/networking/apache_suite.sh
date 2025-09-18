#!/usr/bin/env bash
#===============================================================================
# Script Name: install_apache_suite.sh
# Author: CBW + ChatGPT
# Date: 2025-09-15
# Description: Bare-metal installer for core Apache software (Guacamole, Airflow,
#              Superset, Tika, PDFBox, Kafka, Solr) on Ubuntu 24.04
#===============================================================================

set -euo pipefail
trap 'echo "[ERROR] at line $LINENO"; exit 1' ERR

LOG="/tmp/CBW-apache-suite-install.log"
exec > >(tee -a "$LOG") 2>&1

#----------------------#
# Preflight Checks
#----------------------#
if [[ $EUID -ne 0 ]]; then
  echo "Run as root (sudo)" && exit 1
fi

apt update && apt install -y curl wget gnupg openjdk-21-jdk maven python3-pip python3-venv git unzip build-essential libpq-dev

# Java env for Apache tools
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment

#----------------------#
# Apache Guacamole
#----------------------#
install_guacamole() {
  echo "[*] Installing Guacamole..."
  apt install -y tomcat10 freerdp2-dev libssh2-1-dev libtelnet-dev libvncserver-dev libjpeg62-turbo-dev libcairo2-dev libpng-dev libossp-uuid-dev
  useradd -r -s /bin/false guacd || true
  mkdir -p /etc/guacamole /var/lib/guacamole/extensions
  wget -qO /tmp/guacamole-server.tar.gz https://apache.org/dyn/closer.lua/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz?action=download
  tar -xzf /tmp/guacamole-server.tar.gz -C /tmp
  pushd /tmp/guacamole-server-* && ./configure --with-init-dir=/etc/init.d && make -j$(nproc) && make install && ldconfig && popd
  systemctl enable guacd && systemctl start guacd
}

#----------------------#
# Apache Airflow
#----------------------#
install_airflow() {
  echo "[*] Installing Airflow..."
  useradd -m -s /bin/bash airflow || true
  su - airflow -c "
    python3 -m venv ~/airflow_venv && source ~/airflow_venv/bin/activate && \
    pip install --upgrade pip && \
    pip install apache-airflow[postgres]==2.10.2 psycopg2-binary
  "
  mkdir -p /opt/airflow && chown airflow:airflow /opt/airflow
  cat >/etc/systemd/system/airflow-webserver.service <<EOF
[Unit]
Description=Apache Airflow Webserver
After=network.target
[Service]
User=airflow
ExecStart=/home/airflow/airflow_venv/bin/airflow webserver
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  cat >/etc/systemd/system/airflow-scheduler.service <<EOF
[Unit]
Description=Apache Airflow Scheduler
After=network.target
[Service]
User=airflow
ExecStart=/home/airflow/airflow_venv/bin/airflow scheduler
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload && systemctl enable --now airflow-webserver airflow-scheduler
}

#----------------------#
# Apache Superset
#----------------------#
install_superset() {
  echo "[*] Installing Superset..."
  useradd -m -s /bin/bash superset || true
  su - superset -c "
    python3 -m venv ~/superset_venv && source ~/superset_venv/bin/activate && \
    pip install --upgrade pip && \
    pip install apache-superset psycopg2-binary
  "
  cat >/etc/systemd/system/superset.service <<EOF
[Unit]
Description=Apache Superset
After=network.target
[Service]
User=superset
ExecStart=/home/superset/superset_venv/bin/superset run -p 8088 --with-threads --reload --debugger
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload && systemctl enable --now superset
}

#----------------------#
# Apache Tika + PDFBox
#----------------------#
install_tika_pdfbox() {
  echo "[*] Installing Tika + PDFBox..."
  mkdir -p /opt/tika && cd /opt/tika
  wget -q https://dlcdn.apache.org/tika/tika-server-2.9.2.jar -O tika-server.jar
  wget -q https://dlcdn.apache.org/pdfbox/2.0.31/pdfbox-app-2.0.31.jar -O pdfbox.jar
  cat >/etc/systemd/system/tika.service <<EOF
[Unit]
Description=Apache Tika Server
After=network.target
[Service]
ExecStart=/usr/bin/java -jar /opt/tika/tika-server.jar -p 9998
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload && systemctl enable --now tika
}

#----------------------#
# Apache Kafka (Optional)
#----------------------#
install_kafka() {
  echo "[*] Installing Kafka..."
  useradd -m -s /bin/bash kafka || true
  wget -qO /tmp/kafka.tgz https://downloads.apache.org/kafka/3.7.1/kafka_2.13-3.7.1.tgz
  tar -xzf /tmp/kafka.tgz -C /opt && mv /opt/kafka_* /opt/kafka
  chown -R kafka:kafka /opt/kafka
  cat >/etc/systemd/system/kafka.service <<EOF
[Unit]
Description=Apache Kafka
After=network.target
[Service]
User=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
Restart=always
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload && systemctl enable --now kafka
}

#----------------------#
# Apache Solr (Optional)
#----------------------#
install_solr() {
  echo "[*] Installing Solr..."
  wget -q https://dlcdn.apache.org/solr/9.7.0/solr-9.7.0.tgz -O /tmp/solr.tgz
  tar -xzf /tmp/solr.tgz -C /tmp
  bash /tmp/solr-9.7.0/bin/install_solr_service.sh /tmp/solr.tgz
}

#----------------------#
# Main
#----------------------#
install_guacamole
install_airflow
install_superset
install_tika_pdfbox
# install_kafka         # <-- uncomment if you want Kafka
# install_solr           # <-- uncomment if you want Solr

echo "[+] Apache Suite install complete. Logs: $LOG"

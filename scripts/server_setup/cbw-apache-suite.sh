#!/usr/bin/env bash
#===============================================================================
# Script Name: cbw-apache-suite.sh
# Author: Blaine "CBW" Winslow + ChatGPT (GPT-5 Thinking)
# Date: 2025-09-15
# Summary:
#   Bare-metal installer for a curated Apache stack + PostgreSQL on Ubuntu 24.04.
#   Installs: PostgreSQL, Guacamole (guacd+Tomcat+webapp), Airflow (venv),
#             Superset (venv), Tika server, PDFBox, optional Kafka (KRaft),
#             optional Solr, optional NiFi. Creates systemd services, users,
#             basic hardening, port checks, and simple defaults.
#
# Inputs:
#   - Flags (optional): --all, --postgres, --guacamole, --airflow, --superset,
#                       --tika, --kafka, --solr, --nifi, --noninteractive
#   - Environment overrides via /etc/cbw-apache-suite.conf (created if missing)
#
# Outputs:
#   - Installed services with systemd units, logs in /var/log/<service> or /tmp
#   - Default admin bootstrap for Airflow & Superset
#
# Security:
#   - Creates dedicated system users
#   - Binds services to localhost where sensible (expose via reverse proxy)
#   - Advises Cloudflare Tunnel + Access for public exposure
#
# Modification Log:
#   2025-09-15: Initial release.
#===============================================================================

set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Failed at line $LINENO"; exit 1' ERR

LOG="/tmp/CBW-apache-suite-$(date +%s).log"
exec > >(tee -a "$LOG") 2>&1

#------------------------------#
# Defaults (overridable)
#------------------------------#
CONF_FILE="/etc/cbw-apache-suite.conf"
POSTGRES_VER="${POSTGRES_VER:-16}"             # Ubuntu 24.04 default repo has 16
PG_SUPERUSER="${PG_SUPERUSER:-postgres}"
AIRFLOW_DB="${AIRFLOW_DB:-airflow}"
AIRFLOW_DB_USER="${AIRFLOW_DB_USER:-airflow}"
AIRFLOW_DB_PASS="${AIRFLOW_DB_PASS:-airflow_strong_pw_change}"
SUPERSET_DB="${SUPERSET_DB:-superset}"
SUPERSET_DB_USER="${SUPERSET_DB_USER:-superset}"
SUPERSET_DB_PASS="${SUPERSET_DB_PASS:-superset_strong_pw_change}"

# Ports (override if you must)
PORT_GUACAMOLE="${PORT_GUACAMOLE:-8080}"       # Tomcat webapps (path /guacamole)
PORT_AIRFLOW="${PORT_AIRFLOW:-8081}"
PORT_SUPERSET="${PORT_SUPERSET:-8088}"
PORT_TIKA="${PORT_TIKA:-9998}"
PORT_SOLR="${PORT_SOLR:-8983}"
PORT_NIFI="${PORT_NIFI:-8089}"
PORT_KAFKA="${PORT_KAFKA:-9092}"               # KRaft listener

# Create config file with defaults if missing
if [[ ! -f "$CONF_FILE" ]]; then
  sudo bash -c "cat > '$CONF_FILE' <<EOF
POSTGRES_VER=$POSTGRES_VER
PG_SUPERUSER=$PG_SUPERUSER
AIRFLOW_DB=$AIRFLOW_DB
AIRFLOW_DB_USER=$AIRFLOW_DB_USER
AIRFLOW_DB_PASS=$AIRFLOW_DB_PASS
SUPERSET_DB=$SUPERSET_DB
SUPERSET_DB_USER=$SUPERSET_DB_USER
SUPERSET_DB_PASS=$SUPERSET_DB_PASS
PORT_GUACAMOLE=$PORT_GUACAMOLE
PORT_AIRFLOW=$PORT_AIRFLOW
PORT_SUPERSET=$PORT_SUPERSET
PORT_TIKA=$PORT_TIKA
PORT_SOLR=$PORT_SOLR
PORT_NIFI=$PORT_NIFI
PORT_KAFKA=$PORT_KAFKA
EOF"
fi
# shellcheck disable=SC1090
source "$CONF_FILE"

require_root() { [[ $EUID -eq 0 ]] || { echo "Run with sudo/root."; exit 1; }; }
port_in_use() { ss -lnt "( sport = :$1 )" | awk 'NR>1{print $4}' | grep -q ":$1$" || return 1; }

apt_base() {
  echo "[*] Updating base packages..."
  apt update
  DEBIAN_FRONTEND=noninteractive apt install -y \
    curl wget gnupg ca-certificates unzip tar build-essential \
    openjdk-21-jdk maven \
    python3 python3-venv python3-pip python3-dev libpq-dev \
    git pkg-config libssl-dev
}

#------------------------------#
# PostgreSQL (bare metal)
#------------------------------#
install_postgres() {
  echo "[*] Installing PostgreSQL $POSTGRES_VER..."
  apt install -y "postgresql-$POSTGRES_VER" "postgresql-contrib"
  systemctl enable --now "postgresql@$POSTGRES_VER-main" || systemctl enable --now postgresql

  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '$AIRFLOW_DB_USER';" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER $AIRFLOW_DB_USER WITH PASSWORD '$AIRFLOW_DB_PASS';"

  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$AIRFLOW_DB';" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $AIRFLOW_DB OWNER $AIRFLOW_DB_USER;"

  sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname = '$SUPERSET_DB_USER';" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE USER $SUPERSET_DB_USER WITH PASSWORD '$SUPERSET_DB_PASS';"

  sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname = '$SUPERSET_DB';" | grep -q 1 || \
    sudo -u postgres psql -c "CREATE DATABASE $SUPERSET_DB OWNER $SUPERSET_DB_USER;"

  echo "[+] PostgreSQL ready. Consider enabling daily pg_dump backups."
}

#------------------------------#
# Apache Guacamole (guacd + Tomcat + webapp)
#------------------------------#
install_guacamole() {
  echo "[*] Installing Guacamole (guacd + Tomcat webapp)..."
  # deps for guacd
  apt install -y tomcat10 freerdp2-dev libssh2-1-dev libtelnet-dev \
     libvncserver-dev libjpeg62-turbo-dev libcairo2-dev libpng-dev \
     libossp-uuid-dev libwebp-dev libpulse-dev

  # guacd (server) from source
  GUAC_VER="1.5.5"
  wget -qO /tmp/guac.tar.gz "https://downloads.apache.org/guacamole/$GUAC_VER/source/guacamole-server-$GUAC_VER.tar.gz"
  tar -xzf /tmp/guac.tar.gz -C /tmp
  pushd "/tmp/guacamole-server-$GUAC_VER"
  ./configure --with-init-dir=/etc/init.d
  make -j"$(nproc)"
  make install
  ldconfig
  popd
  systemctl enable --now guacd

  # webapp (guacamole-client .war)
  wget -qO /var/lib/tomcat10/webapps/guacamole.war "https://downloads.apache.org/guacamole/$GUAC_VER/binary/guacamole-$GUAC_VER.war"
  mkdir -p /etc/guacamole /var/lib/guacamole/{extensions,lib}
  # basic file-based auth (change these!)
  cat >/etc/guacamole/user-mapping.xml <<'EOF'
<user-mapping>
  <authorize username="cbw" password="change_me_now">
    <connection name="Local-SSH">
      <protocol>ssh</protocol>
      <param name="hostname">127.0.0.1</param>
      <param name="port">22</param>
    </connection>
  </authorize>
</user-mapping>
EOF
  cat >/etc/guacamole/guacamole.properties <<EOF
guacd-hostname: 127.0.0.1
guacd-port: 4822
user-mapping: /etc/guacamole/user-mapping.xml
# Consider moving to a DB auth provider later.
EOF
  # Tell Tomcat where guac config lives
  ln -sf /etc/guacamole /usr/share/tomcat10/.guacamole || true
  systemctl restart tomcat10
  echo "[+] Guacamole at http://<host>:$PORT_GUACAMOLE/guacamole (Tomcat default 8080)."
}

#------------------------------#
# Apache Airflow (venv + systemd)
#------------------------------#
install_airflow() {
  echo "[*] Installing Airflow..."
  id -u airflow &>/dev/null || useradd -m -s /bin/bash airflow
  su - airflow -c "
    python3 -m venv ~/airflow_venv && source ~/airflow_venv/bin/activate && \
    pip install --upgrade pip && \
    pip install 'apache-airflow[postgres]==2.10.2' psycopg2-binary
  "
  # airflow config (SQL conn + ports)
  su - airflow -c "
    source ~/airflow_venv/bin/activate && \
    AIRFLOW_HOME=\$HOME/airflow \
    airflow db init
  "
  AIRFLOW_CONN="postgresql+psycopg2://$AIRFLOW_DB_USER:$AIRFLOW_DB_PASS@127.0.0.1:5432/$AIRFLOW_DB"
  su - airflow -c "sed -i \"s#^sql_alchemy_conn = .*#sql_alchemy_conn = $AIRFLOW_CONN#\" \$HOME/airflow/airflow.cfg"
  su - airflow -c "sed -i \"s#^web_server_port = .*#web_server_port = $PORT_AIRFLOW#\" \$HOME/airflow/airflow.cfg"
  # create admin
  su - airflow -c "
    source ~/airflow_venv/bin/activate && \
    airflow users create --role Admin --username cbw --password change_me_now \
      --firstname Blaine --lastname Winslow --email blaine.winslow@gmail.com || true
  "
  # systemd units
  cat >/etc/systemd/system/airflow-webserver.service <<EOF
[Unit]
Description=Airflow Webserver
After=network.target
[Service]
User=airflow
Environment=AIRFLOW_HOME=/home/airflow/airflow
ExecStart=/home/airflow/airflow_venv/bin/airflow webserver
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  cat >/etc/systemd/system/airflow-scheduler.service <<EOF
[Unit]
Description=Airflow Scheduler
After=network.target
[Service]
User=airflow
Environment=AIRFLOW_HOME=/home/airflow/airflow
ExecStart=/home/airflow/airflow_venv/bin/airflow scheduler
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now airflow-webserver airflow-scheduler
  echo "[+] Airflow at http://<host>:$PORT_AIRFLOW"
}

#------------------------------#
# Apache Superset (venv + systemd)
#------------------------------#
install_superset() {
  echo "[*] Installing Superset..."
  id -u superset &>/dev/null || useradd -m -s /bin/bash superset
  su - superset -c "
    python3 -m venv ~/superset_venv && source ~/superset_venv/bin/activate && \
    pip install --upgrade pip && \
    pip install apache-superset psycopg2-binary
  "
  # DB binding
  SUPERSET_CONN="postgresql+psycopg2://$SUPERSET_DB_USER:$SUPERSET_DB_PASS@127.0.0.1:5432/$SUPERSET_DB"
  su - superset -c "
    source ~/superset_venv/bin/activate && \
    export SUPERSET_CONFIG_PATH=\$HOME/superset_config.py && \
    cat >\$HOME/superset_config.py <<CFG
SQLALCHEMY_DATABASE_URI = '$SUPERSET_CONN'
ENABLE_PROXY_FIX = True
CFG
  "
  su - superset -c "
    source ~/superset_venv/bin/activate && \
    superset fab create-admin --username cbw --firstname Blaine --lastname Winslow \
      --email blaine.winslow@gmail.com --password change_me_now || true && \
    superset db upgrade && superset init
  "
  cat >/etc/systemd/system/superset.service <<EOF
[Unit]
Description=Apache Superset
After=network.target
[Service]
User=superset
Environment=SUPERSET_CONFIG_PATH=/home/superset/superset_config.py
ExecStart=/home/superset/superset_venv/bin/superset run -p $PORT_SUPERSET --with-threads
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now superset
  echo "[+] Superset at http://<host>:$PORT_SUPERSET"
}

#------------------------------#
# Apache Tika + PDFBox (JARs + systemd)
#------------------------------#
install_tika_pdfbox() {
  echo "[*] Installing Tika server + PDFBox..."
  mkdir -p /opt/tika /var/log/tika
  TIKA_VER="2.9.2"
  PDFBOX_VER="2.0.31"
  wget -q "https://dlcdn.apache.org/tika/tika-server-$TIKA_VER.jar" -O /opt/tika/tika-server.jar
  wget -q "https://dlcdn.apache.org/pdfbox/$PDFBOX_VER/pdfbox-app-$PDFBOX_VER.jar" -O /opt/tika/pdfbox.jar
  cat >/etc/systemd/system/tika.service <<EOF
[Unit]
Description=Apache Tika Server
After=network-online.target
[Service]
ExecStart=/usr/bin/java -jar /opt/tika/tika-server.jar -p $PORT_TIKA
Restart=on-failure
User=root
StandardOutput=append:/var/log/tika/tika.log
StandardError=append:/var/log/tika/tika.err
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now tika
  echo "[+] Tika at http://127.0.0.1:$PORT_TIKA"
}

#------------------------------#
# Apache Kafka (KRaft single-node)
#------------------------------#
install_kafka() {
  echo "[*] Installing Kafka (KRaft mode)..."
  id -u kafka &>/dev/null || useradd -m -s /usr/sbin/nologin kafka
  KAFKA_VER="3.7.1"
  wget -qO /tmp/kafka.tgz "https://downloads.apache.org/kafka/$KAFKA_VER/kafka_2.13-$KAFKA_VER.tgz"
  tar -xzf /tmp/kafka.tgz -C /opt && mv /opt/kafka_2.13-$KAFKA_VER /opt/kafka
  chown -R kafka:kafka /opt/kafka

  # Minimal KRaft config
  cat >/opt/kafka/config/kraft.properties <<EOF
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@127.0.0.1:9093
listeners=PLAINTEXT://:9092,CONTROLLER://:9093
inter.broker.listener.name=PLAINTEXT
controller.listener.names=CONTROLLER
advertised.listeners=PLAINTEXT://127.0.0.1:$PORT_KAFKA
log.dirs=/opt/kafka/kraft-data
EOF
  chown kafka:kafka /opt/kafka/config/kraft.properties
  sudo -u kafka /opt/kafka/bin/kafka-storage.sh random-uuid > /opt/kafka/cluster.uuid
  sudo -u kafka /opt/kafka/bin/kafka-storage.sh format -t "$(cat /opt/kafka/cluster.uuid)" -c /opt/kafka/config/kraft.properties

  cat >/etc/systemd/system/kafka.service <<'EOF'
[Unit]
Description=Apache Kafka (KRaft)
After=network-online.target
[Service]
User=kafka
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft.properties
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now kafka
  echo "[+] Kafka broker listening on 127.0.0.1:$PORT_KAFKA"
}

#------------------------------#
# Apache Solr (install script)
#------------------------------#
install_solr() {
  echo "[*] Installing Solr..."
  SOLR_VER="9.7.0"
  wget -q "https://dlcdn.apache.org/solr/$SOLR_VER/solr-$SOLR_VER.tgz" -O /tmp/solr.tgz
  tar -xzf /tmp/solr.tgz -C /tmp
  bash /tmp/solr-$SOLR_VER/bin/install_solr_service.sh /tmp/solr.tgz -n
  # Bind to localhost for safety; adjust if reverse proxying
  sed -i 's/SOLR_JETTY_HOST=.*/SOLR_JETTY_HOST="127.0.0.1"/' /etc/default/solr.in.sh
  systemctl restart solr
  echo "[+] Solr at http://127.0.0.1:$PORT_SOLR/solr"
}

#------------------------------#
# Apache NiFi
#------------------------------#
install_nifi() {
  echo "[*] Installing NiFi..."
  NIFI_VER="1.27.0"
  id -u nifi &>/null || useradd -m -s /bin/bash nifi || true
  wget -q "https://dlcdn.apache.org/nifi/$NIFI_VER/nifi-$NIFI_VER-bin.tar.gz" -O /tmp/nifi.tgz
  tar -xzf /tmp/nifi.tgz -C /opt
  ln -sfn /opt/nifi-$NIFI_VER /opt/nifi
  chown -R nifi:nifi /opt/nifi-$NIFI_VER /opt/nifi
  sed -i "s/^nifi.web.http.port=.*/nifi.web.http.port=$PORT_NIFI/" /opt/nifi/conf/nifi.properties
  cat >/etc/systemd/system/nifi.service <<EOF
[Unit]
Description=Apache NiFi
After=network-online.target
[Service]
User=nifi
ExecStart=/opt/nifi/bin/nifi.sh run
ExecStop=/opt/nifi/bin/nifi.sh stop
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable --now nifi
  echo "[+] NiFi at http://127.0.0.1:$PORT_NIFI/nifi"
}

#------------------------------#
# Port sanity check
#------------------------------#
check_ports() {
  local -a ports=("$PORT_GUACAMOLE" "$PORT_AIRFLOW" "$PORT_SUPERSET" "$PORT_TIKA" "$PORT_SOLR" "$PORT_NIFI" "$PORT_KAFKA")
  local names=("Tomcat/Guac" "Airflow" "Superset" "Tika" "Solr" "NiFi" "Kafka")
  for i in "${!ports[@]}"; do
    local p="${ports[$i]}"; local n="${names[$i]}"
    [[ "$p" =~ ^[0-9]+$ ]] || { echo "[-] $n port '$p' invalid."; exit 1; }
    if port_in_use "$p"; then
      echo "[-] Port $p ($n) is in use. Edit $CONF_FILE and re-run."
      exit 1
    fi
  done
  echo "[+] Ports look free."
}

#------------------------------#
# CLI
#------------------------------#
usage() {
  cat <<USAGE
Usage: sudo ./cbw-apache-suite.sh [--all] [--postgres] [--guacamole] [--airflow] [--superset] [--tika] [--kafka] [--solr] [--nifi] [--noninteractive]

You can also edit defaults in: $CONF_FILE
USAGE
}

main() {
  require_root
  local NONINT=0; local DO_ALL=0
  local DO_PG=0 DO_GUAC=0 DO_AIR=0 DO_SUP=0 DO_TIKA=0 DO_KAFKA=0 DO_SOLR=0 DO_NIFI=0

  if [[ $# -eq 0 ]]; then
    echo "[?] No flags provided; interactive menu."
    select opt in "Install ALL (safe defaults)" "PostgreSQL" "Guacamole" "Airflow" "Superset" "Tika+PDFBox" "Kafka (KRaft)" "Solr" "NiFi" "Quit"; do
      case $opt in
        "Install ALL (safe defaults)") DO_ALL=1; break ;;
        "PostgreSQL") DO_PG=1; break ;;
        "Guacamole") DO_GUAC=1; break ;;
        "Airflow") DO_AIR=1; break ;;
        "Superset") DO_SUP=1; break ;;
        "Tika+PDFBox") DO_TIKA=1; break ;;
        "Kafka (KRaft)") DO_KAFKA=1; break ;;
        "Solr") DO_SOLR=1; break ;;
        "NiFi") DO_NIFI=1; break ;;
        "Quit") exit 0 ;;
      esac
    done
  else
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --all) DO_ALL=1 ;;
        --postgres) DO_PG=1 ;;
        --guacamole) DO_GUAC=1 ;;
        --airflow) DO_AIR=1 ;;
        --superset) DO_SUP=1 ;;
        --tika) DO_TIKA=1 ;;
        --kafka) DO_KAFKA=1 ;;
        --solr) DO_SOLR=1 ;;
        --nifi) DO_NIFI=1 ;;
        --noninteractive) NONINT=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown flag: $1"; usage; exit 1 ;;
      esac
      shift
    done
  fi

  apt_base
  check_ports

  if (( DO_ALL==1 )); then DO_PG=1; DO_GUAC=1; DO_AIR=1; DO_SUP=1; DO_TIKA=1; fi

  (( DO_PG )) && install_postgres
  (( DO_GUAC )) && install_guacamole
  (( DO_AIR )) && install_airflow
  (( DO_SUP )) && install_superset
  (( DO_TIKA )) && install_tika_pdfbox
  (( DO_KAFKA )) && install_kafka
  (( DO_SOLR )) && install_solr
  (( DO_NIFI )) && install_nifi

  echo
  echo "[✓] Done. Log: $LOG"
  echo "Next: put services behind Cloudflare Tunnel + Access; change default passwords;"
  echo "      and set up backups/monitoring."
}

main "$@"


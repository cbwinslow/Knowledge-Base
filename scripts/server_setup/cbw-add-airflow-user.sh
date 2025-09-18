#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-add-airflow-user.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-15
# Summary     : Creates the 'airflow' system user safely with a proper home,
#               shell, directories, and permissions on Ubuntu 24.04.
# Inputs      : None
# Outputs     : User 'airflow' and ~/airflow directory ready for DAGs
#===============================================================================

set -euo pipefail
trap 'echo "[ERROR] Failed at line $LINENO" >&2' ERR

AIRFLOW_USER="airflow"
AIRFLOW_HOME="/home/${AIRFLOW_USER}/airflow"

# 1) Create user if it doesn't exist
if id -u "$AIRFLOW_USER" >/dev/null 2>&1; then
  echo "[*] User '$AIRFLOW_USER' already exists. Skipping creation."
else
  # Use adduser for friendly defaults (creates home dir)
  adduser --disabled-password --gecos "Apache Airflow" "$AIRFLOW_USER"
  echo "[+] Created user '$AIRFLOW_USER' with home /home/${AIRFLOW_USER}"
fi

# 2) Create Airflow home + DAGs directory
mkdir -p "${AIRFLOW_HOME}/dags" "${AIRFLOW_HOME}/logs" "${AIRFLOW_HOME}/plugins"
chown -R "${AIRFLOW_USER}:${AIRFLOW_USER}" "/home/${AIRFLOW_USER}"

echo "[✓] Airflow user and directories are ready:"
echo "    - User:      ${AIRFLOW_USER}"
echo "    - AIRFLOW_HOME: ${AIRFLOW_HOME}"
echo "    - DAGs dir:  ${AIRFLOW_HOME}/dags"

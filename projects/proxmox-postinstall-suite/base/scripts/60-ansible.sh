#!/usr/bin/env bash
set -euo pipefail
[[ "${INSTALL_ANSIBLE:-true}" == "true" ]] || { echo "skip ansible"; exit 0; }
apt-get update -y && apt-get install -y python3 python3-pip git
pip3 install --upgrade pip && pip3 install ansible
mkdir -p ~/infra-ansible/{playbooks,roles,files,templates,collections,inventories/{lab,prod}/{group_vars,host_vars}}
cat > ~/infra-ansible/ansible.cfg <<'EOF'
[defaults]
inventory = inventories/lab
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
interpreter_python = auto_silent
EOF
echo "[pve]\nlocalhost ansible_connection=local" > ~/infra-ansible/inventories/lab/hosts

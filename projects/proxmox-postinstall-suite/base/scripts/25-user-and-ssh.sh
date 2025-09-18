#!/usr/bin/env bash
set -euo pipefail
ADMIN_USER="${ADMIN_USER:?}"; PUBKEY="${ADMIN_SSH_PUBKEY:?}"
id "$ADMIN_USER" &>/dev/null || { useradd -m -s /bin/bash "$ADMIN_USER"; echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-$ADMIN_USER; chmod 0440 /etc/sudoers.d/90-$ADMIN_USER; }
HOME_DIR="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
install -d -m 0700 "$HOME_DIR/.ssh"
AUTH="$HOME_DIR/.ssh/authorized_keys"
grep -qF "$PUBKEY" "$AUTH" 2>/dev/null || echo "$PUBKEY" >> "$AUTH"
chown -R "$ADMIN_USER":"$ADMIN_USER" "$HOME_DIR/.ssh"; chmod 600 "$AUTH"
SSHD="/etc/ssh/sshd_config"; cp "$SSHD" "${SSHD}.bak.$(date +%s)"
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD"
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' "$SSHD"
grep -q '^PubkeyAuthentication yes' "$SSHD" || echo 'PubkeyAuthentication yes' >> "$SSHD"
systemctl restart ssh || systemctl restart sshd || true

#!/usr/bin/env bash
set -euo pipefail

ADMIN_USER="${ADMIN_USER:?ADMIN_USER not set}"
PUBKEY="${ADMIN_SSH_PUBKEY:?ADMIN_SSH_PUBKEY not set}"

if ! id "$ADMIN_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$ADMIN_USER"
  echo "$ADMIN_USER ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/90-$ADMIN_USER
  chmod 0440 /etc/sudoers.d/90-$ADMIN_USER
  echo "Created user $ADMIN_USER with sudo NOPASSWD."
else
  echo "User $ADMIN_USER already exists."
fi

# SSH key
HOME_DIR="$(getent passwd "$ADMIN_USER" | cut -d: -f6)"
install -d -m 0700 "$HOME_DIR/.ssh"
AUTH_KEYS="$HOME_DIR/.ssh/authorized_keys"
if ! grep -qF "$PUBKEY" "$AUTH_KEYS" 2>/dev/null; then
  echo "$PUBKEY" >> "$AUTH_KEYS"
  chown -R "$ADMIN_USER":"$ADMIN_USER" "$HOME_DIR/.ssh"
  chmod 0600 "$AUTH_KEYS"
  echo "Installed admin public key."
else
  echo "Admin public key already present."
fi

# SSHD hardening
SSHD="/etc/ssh/sshd_config"
cp "$SSHD" "${SSHD}.bak.$(date +%s)"
sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' "$SSHD"
sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin prohibit-password/' "$SSHD"
grep -q '^PubkeyAuthentication yes' "$SSHD" || echo 'PubkeyAuthentication yes' >> "$SSHD"
systemctl restart ssh || systemctl restart sshd || true
echo "SSHD hardened."

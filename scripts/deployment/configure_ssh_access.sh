#!/bin/bash

# SSH and Network Access Configuration Script
# This script configures SSH for external access and sets up network monitoring

echo "=== SSH and Network Access Configuration ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# SSH and Network Access Configuration"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Configuration Log"
    echo ""
} > $DOCS_DIR/ssh_config.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/ssh_config.md
}

# 1. Configure SSH for external access
log_action "Configuring SSH for external access..."

# Check current SSH config
CURRENT_SSH_CONFIG="/etc/ssh/sshd_config"
BACKUP_SSH_CONFIG="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
sudo cp $CURRENT_SSH_CONFIG $BACKUP_SSH_CONFIG
log_action "Backed up SSH config to $BACKUP_SSH_CONFIG"

# Configure SSH
sudo bash -c "cat > $CURRENT_SSH_CONFIG" << 'EOL'
# Package generated configuration file
# See the sshd_config(5) manpage for details

# What ports, IPs and protocols we listen for
Port 22
# Use these options to restrict which interfaces/protocols sshd will bind to
#ListenAddress ::
ListenAddress 0.0.0.0
Protocol 2

# HostKeys for protocol version 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Logging
SyslogFacility AUTH
LogLevel INFO

# Authentication:
LoginGraceTime 120
PermitRootLogin no
StrictModes yes

# Change to no to disable tunnelled clear text passwords
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile	%h/.ssh/authorized_keys

# Don't read the user's ~/.rhosts and ~/.shosts files
IgnoreRhosts yes
# For this to work you will also need host keys in /etc/ssh_known_hosts
RhostsRSAAuthentication no
# similar for protocol version 2
HostbasedAuthentication no
# Uncomment if you don't trust ~/.ssh/known_hosts for RhostsRSAAuthentication
#IgnoreUserKnownHosts yes

# To enable empty passwords, change to yes (NOT RECOMMENDED)
PermitEmptyPasswords no

# Change to yes to enable challenge-response passwords (beware issues with
# some PAM modules and threads)
ChallengeResponseAuthentication no

# Kerberos options
#KerberosAuthentication no
#KerberosOrLocalPasswd yes
#KerberosTicketCleanup yes

# GSSAPI options
#GSSAPIAuthentication no
#GSSAPICleanupCredentials yes

X11Forwarding yes
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes
#UseLogin no

# MaxStartups 10:30:60
#Banner /etc/issue.net

# Allow client to pass locale environment variables
AcceptEnv LANG LC_*

Subsystem sftp /usr/lib/openssh/sftp-server

# Set this to 'yes' to enable PAM authentication, account processing,
# and session processing. If this is enabled, PAM authentication will
# be allowed through the ChallengeResponseAuthentication and
# PasswordAuthentication.  Depending on your PAM configuration,
# PAM authentication via ChallengeResponseAuthentication may bypass
# the setting of "PermitRootLogin without-password".
# If you just want the PAM account and session checks to run without
# PAM authentication, then enable this but set PasswordAuthentication
# and ChallengeResponseAuthentication to 'no'.
UsePAM yes

# Security enhancements
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
AllowTcpForwarding yes
GatewayPorts no
AllowAgentForwarding yes
PermitTunnel no
EOL

log_action "Updated SSH configuration"

# 2. Configure firewall for SSH access
log_action "Configuring firewall for SSH access..."

# Enable UFW if not already enabled
if ! sudo ufw status | grep -q "Status: active"; then
    echo "y" | sudo ufw enable
    log_action "Enabled UFW firewall"
fi

# Allow SSH
sudo ufw allow ssh
log_action "Allowed SSH through firewall"

# Allow other common services
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3128/tcp # Squid proxy
log_action "Allowed common services through firewall"

# 3. Restart SSH service
log_action "Restarting SSH service..."
sudo systemctl restart ssh
log_action "SSH service restarted"

# 4. Check SSH status
SSH_STATUS=$(systemctl is-active ssh)
log_action "SSH service status: $SSH_STATUS"

# 5. Document network configuration
{
    echo ""
    echo "## Network Configuration"
    echo ""
    echo "### IP Addresses"
    echo "\`\`\`"
    ip addr show | grep -E "inet.*eth|inet.*ens|inet.*enp"
    echo "\`\`\`"
    echo ""
    echo "### SSH Service Status"
    echo "\`\`\`"
    systemctl status ssh | grep -E "Active|Loaded"
    echo "\`\`\`"
    echo ""
    echo "### Firewall Status"
    echo "\`\`\`"
    sudo ufw status
    echo "\`\`\`"
    echo ""
    echo "### Listening Ports"
    echo "\`\`\`"
    ss -tlnp | grep -E "(22|80|443|3128)"
    echo "\`\`\`"
} >> $DOCS_DIR/ssh_config.md

# 6. Create Ansible configuration for remote access
log_action "Creating Ansible configuration for remote access..."

mkdir -p /home/cbwinslow/ansible_remote

cat > /home/cbwinslow/ansible_remote/inventory << 'EOL'
[local]
localhost ansible_connection=local

[servers]
$(hostname) ansible_host=192.168.4.117 ansible_user=cbwinslow
EOL

cat > /home/cbwinslow/ansible_remote/ansible.cfg << 'EOL'
[defaults]
inventory = ./inventory
host_key_checking = False
remote_user = cbwinslow
private_key_file = ~/.ssh/id_rsa
EOL

cat > /home/cbwinslow/ansible_remote/test-connection.yml << 'EOL'
---
- name: Test connection to server
  hosts: servers
  tasks:
    - name: Test connection
      ping:
    
    - name: Gather facts
      setup:
    
    - name: Check disk space
      command: df -h
      register: disk_space
    
    - name: Display disk space
      debug:
        var: disk_space.stdout_lines
EOL

log_action "Created Ansible configuration for remote access"

# 7. Final summary
{
    echo ""
    echo "## Configuration Complete"
    echo ""
    echo "### Next Steps"
    echo "1. Ensure your SSH public key is in ~/.ssh/authorized_keys"
    echo "2. Test SSH connection from another machine:"
    echo "   ssh cbwinslow@192.168.4.117"
    echo "3. Test Ansible connection:"
    echo "   cd /home/cbwinslow/ansible_remote"
    echo "   ansible-playbook test-connection.yml"
    echo ""
    echo "### Important Notes"
    echo "- Password authentication is disabled for security"
    echo "- Only key-based authentication is allowed"
    echo "- SSH is accessible from any IP (0.0.0.0)"
    echo "- Firewall allows SSH, HTTP, HTTPS, and proxy connections"
    echo "- Backup of original SSH config is at $BACKUP_SSH_CONFIG"
    echo ""
    echo "### Troubleshooting"
    echo "If you can't connect:"
    echo "1. Check that your public key is in ~/.ssh/authorized_keys"
    echo "2. Verify SSH service is running: systemctl status ssh"
    echo "3. Check firewall rules: sudo ufw status"
    echo "4. Check listening ports: ss -tlnp | grep 22"
} >> $DOCS_DIR/ssh_config.md

log_action "SSH and network access configuration complete!"
echo ""
echo "=== Configuration Complete ==="
echo "Documentation created in $DOCS_DIR/ssh_config.md"
echo "Ansible configuration in /home/cbwinslow/ansible_remote/"
echo ""
echo "Next steps:"
echo "1. Ensure your SSH public key is in ~/.ssh/authorized_keys"
echo "2. Test SSH connection from another machine"
echo "3. Test Ansible connection"
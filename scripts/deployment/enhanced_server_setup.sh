#!/bin/bash

# Enhanced Server Setup Script
# More robust version with better error handling and security

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Exit immediately if a command exits with a non-zero status.
set -e

# --- 🚀 Configuration Variables (EDIT THESE) ---
NEW_USER="" # Will be prompted if not set
SSH_PUBLIC_KEY="" # Will be prompted if not set

# Function to prompt for configuration if not set
prompt_for_config() {
    if [ -z "$NEW_USER" ]; then
        read -p "Enter desired username: " NEW_USER
    fi
    
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        echo "Enter your public SSH key (entire line):"
        read -r SSH_PUBLIC_KEY
    fi
    
    # Validate inputs
    if [ -z "$NEW_USER" ]; then
        error "Username cannot be empty"
        exit 1
    fi
    
    if [ -z "$SSH_PUBLIC_KEY" ]; then
        error "SSH public key cannot be empty"
        exit 1
    fi
    
    log "Configuration set - User: $NEW_USER"
}

# --- Error handling ---
handle_error() {
    local line_no=$1
    local exit_code=$2
    error "Script failed at line $line_no with exit code $exit_code"
    error "Check the logs above for details"
    exit $exit_code
}

trap 'handle_error $LINENO $?' ERR

# --- 1. Initial System Update & Essential Tools ---
setup_system_packages() {
    log "▶️ Starting initial system update and package installation..."
    apt-get update
    apt-get upgrade -y
    apt-get install -y curl wget git ufw python3 python3-pip fail2ban htop nano
    success "System packages installed"
}

# --- 2. Create and Configure New User ---
create_user() {
    log "▶️ Creating new user: $NEW_USER"
    
    # Check if user already exists
    if id "$NEW_USER" &>/dev/null; then
        warning "User $NEW_USER already exists, skipping creation"
    else
        # Create user with a home directory
        useradd -m -s /bin/bash "$NEW_USER"
        # Add user to the sudo group to grant administrative privileges
        usermod -aG sudo "$NEW_USER"
        success "User $NEW_USER created and added to sudo group"
    fi
    
    # Create .ssh directory and set up authorized_keys for the new user
    log "▶️ Setting up SSH key for $NEW_USER..."
    HOME_DIR="/home/$NEW_USER"
    mkdir -p "$HOME_DIR/.ssh"
    echo "$SSH_PUBLIC_KEY" > "$HOME_DIR/.ssh/authorized_keys"
    
    # Set correct permissions
    chown -R "$NEW_USER:$NEW_USER" "$HOME_DIR/.ssh"
    chmod 700 "$HOME_DIR/.ssh"
    chmod 600 "$HOME_DIR/.ssh/authorized_keys"
    success "SSH key configured for $NEW_USER"
}

# --- 3. Harden SSH Server 🛡️ ---
harden_ssh() {
    log "▶️ Hardening SSH configuration..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
    
    # Disable root login over SSH
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    
    # Disable password-based authentication (force key-based auth)
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    
    # Additional security settings
    echo "AllowUsers $NEW_USER" >> /etc/ssh/sshd_config
    echo "PermitEmptyPasswords no" >> /etc/ssh/sshd_config
    echo "MaxAuthTries 3" >> /etc/ssh/sshd_config
    echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
    echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config
    
    log "▶️ Restarting SSH service to apply changes..."
    systemctl restart sshd
    success "SSH hardened and restarted"
}

# --- 4. Configure Firewall (UFW) ---
setup_firewall() {
    log "▶️ Configuring firewall with UFW..."
    
    # Deny all incoming traffic and allow all outgoing traffic by default
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow necessary ports
    ufw allow ssh     # Allows traffic on port 22
    ufw allow http    # Allows traffic on port 80
    ufw allow https   # Allows traffic on port 443
    
    # Enable the firewall
    echo "y" | ufw enable
    success "Firewall enabled and configured"
}

# --- 5. Install Development Tools (as the new user) ---
install_dev_tools() {
    log "▶️ Installing development tools for $NEW_USER..."
    
    # Run the installation commands as the new user
    su - "$NEW_USER" <<'EOF'
        set -e
        
        # Install Homebrew (for Linux)
        if ! command -v brew &> /dev/null; then
            echo "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null
        else
            echo "Homebrew already installed"
        fi
        
        # Add Homebrew to the path
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        
        # Install NVM (Node Version Manager)
        if [ ! -d "$HOME/.nvm" ]; then
            echo "Installing NVM..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
        else
            echo "NVM already installed"
        fi
        
        # Source nvm script
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Install the latest Long-Term Support (LTS) version of Node.js
        nvm install --lts
        nvm use --lts
        
        # Install pnpm globally using npm
        npm install -g pnpm
        
        # Install additional useful tools
        brew install gh docker-compose
EOF
    
    success "Development tools installed for $NEW_USER"
}

# --- 6. Install ZeroTier ---
install_zerotier() {
    log "▶️ Installing ZeroTier..."
    
    # Check if ZeroTier is already installed
    if ! command -v zerotier-cli &> /dev/null; then
        curl -s https://install.zerotier.com | bash
        systemctl enable zerotier-one.service
        success "ZeroTier installed"
    else
        warning "ZeroTier already installed, skipping"
    fi
}

# --- 7. Prepare for Ansible Control ---
setup_ansible_access() {
    log "▶️ Configuring user for passwordless sudo for Ansible..."
    
    # Check if the file already exists
    if [ ! -f /etc/sudoers.d/90-ansible-user ]; then
        # This allows Ansible to run commands with sudo without asking for a password
        echo "$NEW_USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/90-ansible-user
        chmod 0440 /etc/sudoers.d/90-ansible-user
        success "Ansible access configured"
    else
        warning "Ansible access already configured, skipping"
    fi
}

# --- 8. Setup Fail2Ban ---
setup_fail2ban() {
    log "▶️ Configuring Fail2Ban..."
    
    # Create local config file
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 10m
EOF
    
    systemctl restart fail2ban
    success "Fail2Ban configured"
}

# --- 9. System Monitoring Setup ---
setup_monitoring() {
    log "▶️ Setting up system monitoring..."
    
    # Install and configure logrotate
    apt-get install -y logrotate
    
    # Create a basic system monitoring script
    cat > /usr/local/bin/system-monitor.sh <<'EOF'
#!/bin/bash
# Simple system monitoring script

LOG_FILE="/var/log/system-monitor.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# Log basic system info
echo "[$DATE] System Monitor Report" >> $LOG_FILE
echo "Uptime: $(uptime)" >> $LOG_FILE
echo "Disk usage:" >> $LOG_FILE
df -h >> $LOG_FILE
echo "Memory usage:" >> $LOG_FILE
free -h >> $LOG_FILE
echo "---" >> $LOG_FILE
EOF

    chmod +x /usr/local/bin/system-monitor.sh
    
    # Add to crontab to run every hour
    (crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/system-monitor.sh") | crontab -
    
    success "System monitoring configured"
}

# --- Main Execution ---
main() {
    log "🚀 Starting enhanced server setup..."
    
    # Prompt for configuration if needed
    prompt_for_config
    
    # Execute setup functions
    setup_system_packages
    create_user
    harden_ssh
    setup_firewall
    install_dev_tools
    install_zerotier
    setup_ansible_access
    setup_fail2ban
    setup_monitoring
    
    # Final success message
    echo
    success "✅✅✅ Server setup is complete! ✅✅✅"
    echo -e "${BLUE}--- IMPORTANT NEXT STEPS ---${NC}"
    echo "1. Log out from the root user and log back in as '$NEW_USER' using your SSH key."
    echo "   ssh $NEW_USER@<your_server_ip>"
    echo "2. Join your ZeroTier network by running:"
    echo "   sudo zerotier-cli join <YOUR_ZEROTIER_NETWORK_ID>"
    echo "3. Authorize this new server in your ZeroTier Central dashboard."
    echo "4. Test Ansible from your control machine:"
    echo "   ansible all -i 'your_server_ip,' -m ping --user $NEW_USER"
    echo
    log "Setup completed successfully!"
}

# Run main function
main
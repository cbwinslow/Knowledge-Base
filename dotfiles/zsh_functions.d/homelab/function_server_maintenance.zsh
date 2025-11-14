#!/bin/zsh

# =============================================================================
# SERVER MAINTENANCE (HOMELAB)
# =============================================================================
# Regular server maintenance and cleanup utilities
# =============================================================================

# Full system maintenance
server_maintenance() {
    echo "🔧 Starting server maintenance..."
    
    # Update system
    echo "📦 Updating system packages..."
    sudo dnf update -y
    
    # Clean package cache
    echo "🧹 Cleaning package cache..."
    sudo dnf clean all
    
    # Remove old kernels
    echo "🗑️  Removing old kernels..."
    sudo dnf remove -y $(dnf list --installed | grep -E 'kernel-[0-9]' | awk '{print $1}' | tail -n +3)
    
    # Clean journal logs
    echo "📋 Cleaning journal logs..."
    sudo journalctl --vacuum-time=7d
    
    # Clean temp files
    echo "🗂️  Cleaning temporary files..."
    sudo rm -rf /tmp/* 2>/dev/null || true
    sudo rm -rf /var/tmp/* 2>/dev/null || true
    
    # Check filesystem
    echo "💿 Checking filesystem..."
    sudo fsck -n /dev/sda1 2>/dev/null || true
    
    echo "✅ Server maintenance completed"
}

# Security hardening
security_hardening() {
    echo "🔒 Starting security hardening..."
    
    # Check for failed login attempts
    echo "🔍 Checking failed login attempts..."
    sudo journalctl -u sshd | grep "Failed password" | tail -10
    
    # Update firewall rules
    echo "🛡️  Updating firewall..."
    if command -v firewall-cmd >/dev/null 2>&1; then
        sudo firewall-cmd --reload
    fi
    
    # Check open ports
    echo "🔍 Checking open ports..."
    ss -tuln | head -10
    
    # Check for suspicious processes
    echo "🔍 Checking suspicious processes..."
    ps aux | grep -E '(nc|ncat|netcat)' | grep -v grep
    
    echo "✅ Security hardening completed"
}

# Log rotation
rotate_logs() {
    echo "📋 Rotating logs..."
    
    # Rotate application logs
    find /var/log -name "*.log" -type f -size +100M -exec truncate -s 50M {} \;
    
    # Compress old logs
    find /var/log -name "*.log.*" -type f -mtime +7 -exec gzip {} \;
    
    # Clean old compressed logs
    find /var/log -name "*.log.*.gz" -type f -mtime +30 -delete
    
    echo "✅ Log rotation completed"
}

# System health check
health_check() {
    echo "🏥 Running system health check..."
    
    # Check disk space
    echo "💿 Disk space check:"
    df -h | grep -E '^/dev/' | awk '{print $5 " " $1}' | while read usage mount; do
        if [[ "${usage%}" -gt 80 ]]; then
            echo "⚠️  WARNING: $mount at $usage"
        else
            echo "✅ $mount: $usage"
        fi
    done
    
    # Check memory
    echo ""
    echo "💾 Memory check:"
    local mem_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
    if [[ "$mem_usage" -gt 80 ]]; then
        echo "⚠️  WARNING: Memory usage at ${mem_usage}%"
    else
        echo "✅ Memory usage: ${mem_usage}%"
    fi
    
    # Check load average
    echo ""
    echo "⚡ Load average:"
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_count=$(nproc)
    if (( $(echo "$load > $cpu_count" | bc -l) )); then
        echo "⚠️  WARNING: High load average: $load (CPU cores: $cpu_count)"
    else
        echo "✅ Load average: $load (CPU cores: $cpu_count)"
    fi
    
    # Check critical services
    echo ""
    echo "🔧 Service status:"
    for service in sshd docker NetworkManager; do
        if systemctl is-active --quiet "$service"; then
            echo "✅ $service: running"
        else
            echo "❌ $service: not running"
        fi
    done
    
    echo "✅ Health check completed"
}

# Schedule regular maintenance
schedule_maintenance() {
    local cron_file="/etc/cron.d/server-maintenance"
    
    echo "📅 Scheduling regular maintenance..."
    
    sudo tee "$cron_file" > /dev/null << EOF
# Server maintenance tasks
0 2 * * 0 root /usr/local/bin/server_maintenance.sh
0 3 * * 0 root /usr/local/bin/security_hardening.sh
0 4 * * * root /usr/local/bin/rotate_logs.sh
EOF
    
    echo "✅ Maintenance scheduled in $cron_file"
}
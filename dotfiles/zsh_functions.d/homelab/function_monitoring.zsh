#!/bin/zsh

# =============================================================================
# MONITORING FUNCTIONS (HOMELAB)
# =============================================================================
# System monitoring and alerting utilities
# =============================================================================

# Show system overview
system_overview() {
    echo "🖥️  System Overview - $(hostname)"
    echo "================================"
    echo "Uptime: $(uptime -p)"
    echo "Kernel: $(uname -r)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo ""
    echo "💾 Memory Usage:"
    free -h
    echo ""
    echo "💿 Disk Usage:"
    df -h | grep -E '^/dev/'
    echo ""
    echo "🌐 Network Interfaces:"
    ip addr show | grep -E '^[0-9]+:|inet ' | sed 'N;s/\n/ /'
    echo ""
    echo "🔥 Top Processes:"
    ps aux --sort=-%cpu | head -6
}

# Monitor specific service
monitor_service() {
    local service="$1"
    local interval="${2:-5}"
    
    if [[ -z "$service" ]]; then
        echo "Usage: monitor_service <service_name> [interval_seconds]"
        return 1
    fi
    
    echo "🔍 Monitoring service: $service (interval: ${interval}s)"
    watch -n "$interval" "systemctl status $service"
}

# Check disk space and alert if low
check_disk_space() {
    local threshold="${1:-80}"
    
    echo "💿 Checking disk space (threshold: ${threshold}%)..."
    
    df -h | grep -E '^/dev/' | while read filesystem size used avail use_percent mount; do
        local percent_num=$(echo "$use_percent" | sed 's/%//')
        if [[ "$percent_num" -gt "$threshold" ]]; then
            echo "⚠️  WARNING: $filesystem at $use_percent capacity ($avail available)"
        else
            echo "✅ $filesystem: $use_percent ($avail available)"
        fi
    done
}

# Monitor network connections
monitor_network() {
    echo "🌐 Network Monitoring"
    echo "===================="
    echo "Active connections:"
    ss -tuln | head -10
    echo ""
    echo "Top talkers:"
    ss -tuln | awk 'NR>1 {print $6}' | sort | uniq -c | sort -nr | head -5
    echo ""
    echo "Interface stats:"
    cat /proc/net/dev | head -3
}

# Generate system report
generate_report() {
    local report_file="/tmp/system_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "System Report - $(date)"
        echo "======================"
        echo "Hostname: $(hostname)"
        echo "Uptime: $(uptime)"
        echo ""
        system_overview
        echo ""
        echo "🔧 Services Status:"
        systemctl list-units --type=service --state=running | head -10
        echo ""
        echo "📦 Installed Packages:"
        dnf list installed | wc -l
        echo "packages installed"
        echo ""
        echo "🔒 Security Updates:"
        dnf check-update | grep -E '^(security|bugfix)' | head -5
    } > "$report_file"
    
    echo "📄 System report generated: $report_file"
    cat "$report_file"
}
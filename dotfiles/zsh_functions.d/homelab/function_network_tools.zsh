#!/bin/zsh

# =============================================================================
# NETWORK TOOLS (HOMELAB)
# =============================================================================
# Network configuration and troubleshooting utilities
# =============================================================================

# Show network configuration
network_info() {
    echo "🌐 Network Information"
    echo "===================="
    echo "Interfaces:"
    ip addr show | grep -E '^[0-9]+:|inet ' | sed 'N;s/\n/ /'
    echo ""
    echo "Routing table:"
    ip route show
    echo ""
    echo "DNS servers:"
    cat /etc/resolv.conf | grep nameserver
    echo ""
    echo "Public IP:"
    curl -s ifconfig.me 2>/dev/null || echo "Unable to determine"
}

# Port scanner
scan_ports() {
    local host="${1:-localhost}"
    local ports="${2:-1-1000}"
    
    echo "🔍 Scanning ports on $host (range: $ports)..."
    nmap -p "$ports" "$host"
}

# Monitor network traffic
network_monitor() {
    local interface="${1:-eth0}"
    
    echo "📊 Monitoring network traffic on $interface..."
    sudo iftop -i "$interface"
}

# Speed test
speed_test() {
    echo "🚀 Running network speed test..."
    
    if command -v speedtest-cli >/dev/null 2>&1; then
        speedtest-cli
    elif command -v curl >/dev/null 2>&1; then
        echo "Download speed test:"
        curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3
    else
        echo "❌ Neither speedtest-cli nor curl available"
        return 1
    fi
}

# Check if port is open
check_port() {
    local host="$1"
    local port="$2"
    
    if [[ -z "$host" || -z "$port" ]]; then
        echo "Usage: check_port <host> <port>"
        return 1
    fi
    
    echo "🔍 Checking if $host:$port is open..."
    timeout 3 bash -c ">/dev/tcp/$host/$port" && echo "✅ Port is open" || echo "❌ Port is closed"
}

# Network latency test
ping_test() {
    local host="${1:-8.8.8.8}"
    local count="${2:-4}"
    
    echo "🏓 Pinging $host ($count packets)..."
    ping -c "$count" "$host"
}

# Bandwidth usage by process
bandwidth_usage() {
    if command -v nethogs >/dev/null 2>&1; then
        echo "📊 Real-time bandwidth usage by process:"
        sudo nethogs
    else
        echo "❌ nethogs not installed. Install with: sudo dnf install nethogs"
        return 1
    fi
}
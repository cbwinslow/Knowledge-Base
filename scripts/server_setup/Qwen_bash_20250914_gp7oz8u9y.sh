#!/bin/bash

# Final Integration and Configuration Script
echo "Running final integration..."

# Create centralized management script
cat > /opt/scripts/server-manager.sh << 'EOF'
#!/bin/bash

# Centralized Server Management Script

ACTION=$1
SERVICE=$2

case $ACTION in
    start)
        case $SERVICE in
            all)
                docker start $(docker ps -aq)
                systemctl start wg-quick@wg0
                echo "All services started"
                ;;
            mcp)
                /opt/mcp-servers/scripts/mcp-manager.sh start bedrock
                /opt/mcp-servers/scripts/mcp-manager.sh start java
                ;;
            databases)
                cd /opt/database/postgres && docker-compose up -d
                cd /opt/database/supabase && docker-compose up -d
                ;;
            vector)
                cd /opt/vector-dbs/chroma && docker-compose up -d
                cd /opt/vector-dbs/qdrant && docker-compose up -d
                cd /opt/vector-dbs/weaviate && docker-compose up -d
                ;;
            *)
                echo "Usage: $0 start {all|mcp|databases|vector}"
                ;;
        esac
        ;;
    stop)
        case $SERVICE in
            all)
                docker stop $(docker ps -aq)
                systemctl stop wg-quick@wg0
                echo "All services stopped"
                ;;
            mcp)
                /opt/mcp-servers/scripts/mcp-manager.sh stop bedrock
                /opt/mcp-servers/scripts/mcp-manager.sh stop java
                ;;
            databases)
                cd /opt/database/postgres && docker-compose down
                cd /opt/database/supabase && docker-compose down
                ;;
            vector)
                cd /opt/vector-dbs/chroma && docker-compose down
                cd /opt/vector-dbs/qdrant && docker-compose down
                cd /opt/vector-dbs/weaviate && docker-compose down
                ;;
            *)
                echo "Usage: $0 stop {all|mcp|databases|vector}"
                ;;
        esac
        ;;
    status)
        case $SERVICE in
            all)
                echo "=== Docker Services ==="
                docker ps
                echo "=== System Services ==="
                systemctl status wg-quick@wg0
                echo "=== ZeroTier ==="
                zerotier-cli listnetworks
                ;;
            mcp)
                /opt/mcp-servers/scripts/mcp-manager.sh status
                ;;
            *)
                echo "Usage: $0 status {all|mcp}"
                ;;
        esac
        ;;
    backup)
        case $SERVICE in
            all)
                /opt/mcp-servers/scripts/mcp-manager.sh backup bedrock
                /opt/mcp-servers/scripts/mcp-manager.sh backup java
                /opt/backups/backup.sh
                ;;
            mcp)
                /opt/mcp-servers/scripts/mcp-manager.sh backup bedrock
                /opt/mcp-servers/scripts/mcp-manager.sh backup java
                ;;
            system)
                /opt/backups/backup.sh
                ;;
            *)
                echo "Usage: $0 backup {all|mcp|system}"
                ;;
        esac
        ;;
    *)
        echo "Usage: $0 {start|stop|status|backup} {all|mcp|databases|vector|system}"
        echo ""
        echo "Examples:"
        echo "  $0 start all          # Start all services"
        echo "  $0 stop mcp           # Stop MCP servers"
        echo "  $0 status all         # Show status of all services"
        echo "  $0 backup all         # Backup all services"
        ;;
esac
EOF

chmod +x /opt/scripts/server-manager.sh

# Create system monitoring dashboard script
cat > /opt/scripts/system-dashboard.sh << 'EOF'
#!/bin/bash

# System Dashboard Script

clear
echo "=========================================="
echo "        PROXMOX SERVER DASHBOARD          "
echo "=========================================="
echo ""

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "IP Addresses: $(hostname -I)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo ""

echo "=== Disk Usage ==="
df -h | grep -v tmpfs
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Running Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "=== Network Status ==="
echo "ZeroTier: $(zerotier-cli info 2>/dev/null || echo 'Not connected')"
echo "WireGuard: $(systemctl is-active wg-quick@wg0 2>/dev/null || echo 'Not running')"
echo ""

echo "=== Services Status ==="
echo "SSH: $(systemctl is-active ssh)"
echo "Docker: $(systemctl is-active docker)"
echo "Fail2Ban: $(systemctl is-active fail2ban)"
echo ""

echo "=== Quick Actions ==="
echo "1. View system logs: journalctl -f"
echo "2. Check disk health: smartctl -H /dev/sdX"
echo "3. Manage services: /opt/scripts/server-manager.sh"
echo "4. Monitor network: /opt/scripts/zt-monitor.sh"
EOF

chmod +x /opt/scripts/system-dashboard.sh

# Create documentation update script
cat > /opt/scripts/update-docs.sh << 'EOF'
#!/bin/bash

# Update Server Documentation

cat > /root/SERVER_DOCUMENTATION.md << 'DOCEND'
# Proxmox Server Documentation

## System Overview
- Hostname: $(hostname)
- IP Addresses: $(hostname -I)
- OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
- Kernel: $(uname -r)

## Installed Services

### Core Services
- Docker: Container management
- SSH: Secure shell access (hardened)
- Fail2Ban: Intrusion prevention
- WireGuard: VPN service
- ZeroTier: Virtual network

### Database Services
- PostgreSQL: Relational database
- Supabase: Firebase alternative
- ChromaDB: Vector database
- Qdrant: Vector similarity search
- Weaviate: Vector search engine

### Gaming Services
- Minecraft Bedrock Server
- Minecraft Java Server

### Media Services
- Plex Media Server
- Sonarr/Radarr/Bazarr
- Transmission (Torrent client)
- Jackett (Torrent indexer)

### Monitoring Services
- Prometheus: Metrics collection
- Grafana: Dashboard and visualization
- Node Exporter: System metrics
- cAdvisor: Container metrics

### Home Automation
- Home Assistant
- Zigbee2MQTT
- Mosquitto (MQTT broker)

### Utility Services
- Portainer: Docker management
- AdGuard Home: Network-wide ad blocking
- Traefik: Reverse proxy
- Uptime Kuma: Status monitoring
- Watchtower: Automatic container updates

## Disk Configuration
$(lsblk -o NAME,SIZE,TYPE,MOUNTPOINT)

## Network Configuration
ZeroTier Network: $(zerotier-cli listnetworks 2>/dev/null || echo "Not connected")
WireGuard Status: $(systemctl is-active wg-quick@wg0 2>/dev/null || echo "Not running")

## Management Commands
- System Dashboard: /opt/scripts/system-dashboard.sh
- Service Management: /opt/scripts/server-manager.sh
- SSH Key Propagation: /opt/scripts/ssh-propagate.sh
- Disk Monitoring: /opt/scripts/disk-monitor.sh
- ZeroTier Monitoring: /opt/scripts/zt-monitor.sh

## Backup Information
- Daily backups: /opt/backups/
- MCP server backups: Automated
- System backups: Weekly cron job

## Security Features
- SSH hardening with key-based authentication
- Fail2Ban for intrusion prevention
- Firewall configuration
- Regular security updates
- Service isolation with Docker

## Maintenance Schedule
- Daily: System monitoring and log rotation
- Weekly: System updates and cleanup
- Monthly: Security audit and backup verification

## Troubleshooting
- Check service status: systemctl status <service>
- View logs: journalctl -u <service>
- Docker logs: docker logs <container>
- Network issues: /opt/scripts/zt-monitor.sh

## Contact Information
System Administrator: $(logname)@$(hostname)
Last Updated: $(date)
DOCEND

echo "Documentation updated: /root/SERVER_DOCUMENTATION.md"
EOF

chmod +x /opt/scripts/update-docs.sh

# Run documentation update
/opt/scripts/update-docs.sh

# Create system health check script
cat > /opt/scripts/health-check.sh << 'EOF'
#!/bin/bash

# System Health Check Script

HEALTH_LOG="/var/log/system-health.log"

echo "$(date): Starting system health check..." >> $HEALTH_LOG

# Check system resources
echo "$(date): Checking system resources..." >> $HEALTH_LOG
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf("%.2f%%"), $3/$2 * 100.0}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

echo "$(date): CPU: ${CPU_USAGE}%, Memory: $MEMORY_USAGE, Disk: ${DISK_USAGE}%" >> $HEALTH_LOG

# Check critical services
SERVICES=("docker" "ssh" "fail2ban" "zerotier-one" "wg-quick@wg0")
for service in "${SERVICES[@]}"; do
    if systemctl is-active --quiet $service; then
        echo "$(date): Service $service is running" >> $HEALTH_LOG
    else
        echo "$(date): ALERT - Service $service is NOT running" >> $HEALTH_LOG
    fi
done

# Check Docker containers
RUNNING_CONTAINERS=$(docker ps -q | wc -l)
TOTAL_CONTAINERS=$(docker ps -a -q | wc -l)
echo "$(date): Docker containers - Running: $RUNNING_CONTAINERS, Total: $TOTAL_CONTAINERS" >> $HEALTH_LOG

# Check disk health
for disk in $(lsblk -d -o NAME | grep -E 'sd[a-z]|nvme[0-9]n[0-9]'); do
    HEALTH=$(smartctl -H /dev/$disk 2>/dev/null | grep "test result" | awk '{print $NF}')
    if [ "$HEALTH" != "PASSED" ] && [ -n "$HEALTH" ]; then
        echo "$(date): ALERT - Disk /dev/$disk health: $HEALTH" >> $HEALTH_LOG
    fi
done

echo "$(date): Health check completed" >> $HEALTH_LOG
EOF

chmod +x /opt/scripts/health-check.sh

# Add health check to cron
echo "*/30 * * * * root /opt/scripts/health-check.sh" > /etc/cron.d/health-check

# Create alias for easy access
cat >> ~/.bashrc << 'EOF'

# Server Management Aliases
alias server-status='/opt/scripts/server-manager.sh status all'
alias server-start='/opt/scripts/server-manager.sh start all'
alias server-stop='/opt/scripts/server-manager.sh stop all'
alias dashboard='/opt/scripts/system-dashboard.sh'
alias health-check='/opt/scripts/health-check.sh'
alias update-docs='/opt/scripts/update-docs.sh'
EOF

# Reload bashrc
source ~/.bashrc

echo "Final integration completed."
echo "Documentation available at /root/SERVER_DOCUMENTATION.md"
echo "Use 'dashboard' command for system overview"
echo "Use 'server-manager.sh' for service management"
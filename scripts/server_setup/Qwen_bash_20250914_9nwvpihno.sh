#!/bin/bash

# Final setup and cleanup
echo "Running final setup..."

# Create useful aliases
cat >> ~/.bashrc << EOF

# Docker aliases
alias dps='docker ps'
alias dlogs='docker logs'
alias dstats='docker stats'
alias dprune='docker system prune -af'

# System aliases
alias dfree='df -h'
alias duse='du -sh * | sort -hr'
alias meminfo='free -m'
alias psmem='ps aux --sort=-%mem | head -20'
alias psproc='ps aux --sort=-%cpu | head -20'

# Proxmox aliases
alias pve='pveclient'
alias pvestat='pveperf'
EOF

# Create system info script
cat > /usr/local/bin/system-info.sh << 'EOF'
#!/bin/bash

echo "=== System Information ==="
echo "Hostname: $(hostname)"
echo "IP Address: $(hostname -I)"
echo "Uptime: $(uptime)"
echo "Load Average: $(cat /proc/loadavg)"
echo ""
echo "=== Disk Usage ==="
df -h
echo ""
echo "=== Memory Usage ==="
free -h
echo ""
echo "=== Running Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "=== Proxmox Version ==="
pveversion
EOF

chmod +x /usr/local/bin/system-info.sh

# Create startup script
cat > /etc/rc.local << 'EOF'
#!/bin/bash

# Custom startup script
echo "$(date): System started" >> /var/log/startup.log

# Ensure all Docker containers are running
docker start $(docker ps -aq) 2>/dev/null

exit 0
EOF

chmod +x /etc/rc.local

# Create documentation
cat > /root/SERVER_SETUP.md << EOF
# Proxmox Server Setup Documentation

## Installed Services

### Docker Services
- **Portainer**: Web-based Docker management (https://your-ip:9443)
- **Media Stack**: Plex, Sonarr, Radarr, Bazarr, Transmission, Jackett
- **Monitoring**: Prometheus, Grafana, Node Exporter, cAdvisor
- **Home Automation**: Home Assistant, Zigbee2MQTT, Mosquitto
- **Utilities**: AdGuard Home, Traefik, Uptime Kuma, Watchtower

### System Services
- **SSH**: Secured SSH access
- **Firewall**: Basic iptables configuration
- **Fail2Ban**: Intrusion prevention
- **Automatic Updates**: Unattended security updates

## Important Directories
- **Media**: /opt/media/
- **Monitoring**: /opt/monitoring/
- **Home Automation**: /opt/home-automation/
- **Utilities**: /opt/utility/
- **Backups**: /opt/backups/

## Useful Commands
- \`system-info.sh\`: Display system information
- \`docker ps\`: List running containers
- \`docker logs <container>\`: View container logs

## Maintenance
- Weekly system maintenance runs automatically
- Daily backups to /opt/backups/
- Automatic Docker container updates via Watchtower

## Security
- SSH root login disabled
- Password authentication disabled
- Fail2Ban configured for SSH
- Firewall enabled with basic rules
EOF

echo "Final setup completed."
echo "Please reboot the system to apply all changes."
echo "Documentation available at /root/SERVER_SETUP.md"
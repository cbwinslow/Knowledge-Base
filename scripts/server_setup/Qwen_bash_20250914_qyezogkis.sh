#!/bin/bash

# Optimize Proxmox settings
echo "Optimizing Proxmox settings..."

# Disable enterprise repository
sed -i 's/^deb/#deb/' /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repository
echo "deb http://download.proxmox.com/debian/pve $(grep "VERSION=" /etc/os-release | sed 's/VERSION="\(.*\)"/\1/' | tr ' ' '_') pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Remove subscription nag
sed -i.backup "s/data.status !== 'Active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# Optimize kernel parameters
cat >> /etc/sysctl.conf << EOF
# Proxmox optimizations
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
EOF

# Apply sysctl changes
sysctl -p

# Configure swappiness
echo 'vm.swappiness=1' >> /etc/sysctl.conf

# Optimize I/O scheduler for SSDs
echo 'deadline' > /sys/block/sda/queue/scheduler

# Create cron job for system maintenance
cat > /etc/cron.weekly/proxmox-maintenance << EOF
#!/bin/bash
# Weekly Proxmox maintenance

# Clean up old kernels
apt autoremove -y

# Update system
apt update && apt upgrade -y

# Clean Docker
docker system prune -af

# Backup important configs
tar -czf /var/backups/proxmox-config-\$(date +\%Y\%m\%d).tar.gz /etc/pve /etc/hosts
EOF

chmod +x /etc/cron.weekly/proxmox-maintenance

echo "Proxmox optimization completed."
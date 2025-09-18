#!/bin/bash

# WireGuard Setup Script
# This script helps configure WireGuard VPN

echo "=== WireGuard Setup ==="
echo ""

# Create documentation
DOCS_DIR="/home/cbwinslow/server_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# WireGuard Setup Guide"
    echo ""
    echo "Date: $(date)"
    echo ""
} > $DOCS_DIR/wireguard_setup.md

# Check if WireGuard is installed
if ! command -v wg &> /dev/null; then
    echo "WireGuard is not installed. Please run the networking setup script first."
    echo "- Command to install: /home/cbwinslow/server_setup/setup_networking_services.sh"
    exit 1
fi

echo "WireGuard is installed."
echo "- Command line tool: wg"
echo "- Service management: systemctl {start|stop|restart|status} wg-quick@<interface>"
echo ""

# Show current status
echo "Current WireGuard interfaces:"
sudo wg show
echo ""

# Instructions for setting up WireGuard
cat >> $DOCS_DIR/wireguard_setup.md << 'EOL'
## WireGuard Setup Guide

### Prerequisites
- WireGuard installed (already done if you ran the networking setup script)
- Root access
- Firewall configured to allow UDP port 51820

### Server Configuration

1. Generate private and public keys:
```bash
# Create directory for WireGuard configs
sudo mkdir -p /etc/wireguard/

# Generate private key
sudo wg genkey | sudo tee /etc/wireguard/private.key

# Generate public key from private key
sudo cat /etc/wireguard/private.key | wg pubkey | sudo tee /etc/wireguard/public.key
```

2. Create server configuration file:
```bash
# Replace with your server's public IP
SERVER_IP=$(curl -s ifconfig.me)

# Replace with desired IP range for VPN
VPN_SUBNET="10.100.0.1/24"

# Create the configuration
sudo bash -c "cat > /etc/wireguard/wg0.conf" << EOF
[Interface]
Address = $VPN_SUBNET
PrivateKey = $(sudo cat /etc/wireguard/private.key)
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
SaveConfig = true
EOF
```

3. Set proper permissions:
```bash
sudo chmod 600 /etc/wireguard/private.key
sudo chmod 600 /etc/wireguard/wg0.conf
```

4. Enable IP forwarding:
```bash
echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

5. Start and enable the service:
```bash
sudo systemctl start wg-quick@wg0
sudo systemctl enable wg-quick@wg0
```

### Client Configuration

To add a client:

1. Generate client keys:
```bash
sudo wg genkey | sudo tee /etc/wireguard/client1_private.key
sudo cat /etc/wireguard/client1_private.key | wg pubkey | sudo tee /etc/wireguard/client1_public.key
```

2. Add client to server config:
```bash
sudo wg set wg0 \
    peer $(sudo cat /etc/wireguard/client1_public.key) \
    allowed-ips 10.100.0.2/32
```

3. Create client configuration file:
```bash
sudo bash -c "cat > /home/cbwinslow/client1.conf" << EOF
[Interface]
PrivateKey = $(sudo cat /etc/wireguard/client1_private.key)
Address = 10.100.0.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = $(sudo cat /etc/wireguard/public.key)
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
```

4. Set permissions for client config:
```bash
sudo chmod 600 /home/cbwinslow/client1.conf
```

### Management Commands

```bash
# Check status
sudo wg show

# Check specific interface
sudo wg show wg0

# View configuration
sudo cat /etc/wireguard/wg0.conf

# Start service
sudo systemctl start wg-quick@wg0

# Stop service
sudo systemctl stop wg-quick@wg0

# Restart service
sudo systemctl restart wg-quick@wg0

# Check service status
sudo systemctl status wg-quick@wg0

# Enable service at boot
sudo systemctl enable wg-quick@wg0
```

### Firewall Configuration

Ensure UDP port 51820 is open:
```bash
sudo ufw allow 51820/udp
```

### Troubleshooting

- If clients can't connect, check that port 51820/UDP is open in firewall
- If clients connect but can't access internet, check IP forwarding is enabled
- View logs with: `sudo journalctl -u wg-quick@wg0`

### Security Notes

- Keep private keys secure
- Change client configurations as needed
- Regularly update and patch the system
- Monitor connection logs for suspicious activity

## Next Steps

1. Run the server configuration commands above
2. Generate client configurations for each device
3. Distribute client configs securely
4. Test connections
5. Configure firewall rules as needed
EOL

echo "Documentation created in $DOCS_DIR/wireguard_setup.md"
echo ""
echo "WireGuard setup guide is complete."
echo "Documentation is available in $DOCS_DIR/wireguard_setup.md"
echo ""
echo "To set up WireGuard, follow the instructions in the documentation."
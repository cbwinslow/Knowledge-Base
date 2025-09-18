#!/bin/bash

# Setup WireGuard VPN
echo "Setting up WireGuard VPN..."

# Install WireGuard
apt update
apt install -y wireguard qrencode

# Create WireGuard directory
mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate keys
umask 077
wg genkey | tee privatekey | wg pubkey > publickey

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')
read -p "Enter VPN subnet (default: 10.8.0.0): " VPN_SUBNET
VPN_SUBNET=${VPN_SUBNET:-10.8.0.0}

# Create server configuration
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
Address = $VPN_SUBNET/24
SaveConfig = true
PrivateKey = $(cat privatekey)
ListenPort = 51820
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Client 1
PublicKey = 
AllowedIPs = $VPN_SUBNET.2/32

[Peer]
# Client 2
PublicKey = 
AllowedIPs = $VPN_SUBNET.3/32
EOF

# Set proper permissions
chmod 600 /etc/wireguard/wg0.conf

# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Create client configuration script
cat > /opt/scripts/wg-client-setup.sh << 'EOF'
#!/bin/bash

# WireGuard Client Setup Script

CLIENT_NAME=$1
CLIENT_IP=$2

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_IP" ]; then
    echo "Usage: $0 <client_name> <client_ip>"
    echo "Example: $0 client1 10.8.0.2"
    exit 1
fi

cd /etc/wireguard

# Generate client keys
umask 077
wg genkey | tee $CLIENT_NAME-privatekey | wg pubkey > $CLIENT_NAME-publickey

# Add client to server config
SERVER_PUBKEY=$(cat publickey)
CLIENT_PUBKEY=$(cat $CLIENT_NAME-publickey)

# Add peer to server config
cat >> wg0.conf << EOL

[Peer]
# $CLIENT_NAME
PublicKey = $CLIENT_PUBKEY
AllowedIPs = $CLIENT_IP/32
EOL

# Create client config
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_PUBKEY=$(cat publickey)

cat > $CLIENT_NAME.conf << EOL
[Interface]
PrivateKey = $(cat $CLIENT_NAME-privatekey)
Address = $CLIENT_IP/32
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $SERVER_PUBKEY
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOL

# Generate QR code for mobile clients
qrencode -t ansiutf8 < $CLIENT_NAME.conf

echo "Client configuration created: $CLIENT_NAME.conf"
echo "QR code generated for mobile setup"
echo "Restart WireGuard service to apply changes: systemctl restart wg-quick@wg0"
EOF

chmod +x /opt/scripts/wg-client-setup.sh

# Create WireGuard management script
cat > /opt/scripts/wg-manager.sh << 'EOF'
#!/bin/bash

# WireGuard Management Script

ACTION=$1

case $ACTION in
    start)
        systemctl start wg-quick@wg0
        echo "WireGuard started"
        ;;
    stop)
        systemctl stop wg-quick@wg0
        echo "WireGuard stopped"
        ;;
    restart)
        systemctl restart wg-quick@wg0
        echo "WireGuard restarted"
        ;;
    status)
        systemctl status wg-quick@wg0
        ;;
    enable)
        systemctl enable wg-quick@wg0
        echo "WireGuard enabled at boot"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|enable}"
        ;;
esac
EOF

chmod +x /opt/scripts/wg-manager.sh

# Enable and start WireGuard
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

echo "WireGuard setup completed."
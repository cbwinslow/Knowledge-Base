#!/bin/bash
echo "Fixing firewall issues..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3128/tcp
sudo ufw reload
echo "Firewall rules updated."

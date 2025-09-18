#!/bin/bash
# Script to configure proxy for another IP address

echo "Proxy Configuration Script"
echo "========================"

# Check if we have LXD available
if command -v lxc &> /dev/null; then
    echo "LXD is available. You can create containers for proxy configurations."
    
    # Show available containers
    echo "Available containers:"
    lxc list 2>/dev/null || echo "No containers found or LXD not properly configured"
    
    echo ""
    echo "To create a new container for proxy configuration:"
    echo "  lxc launch ubuntu:24.04 proxy-container"
    echo "  lxc exec proxy-container -- apt update"
    echo "  lxc exec proxy-container -- apt install -y squid"
else
    echo "LXD is not available. You can install it with:"
    echo "  sudo apt install -y lxd"
    echo "  lxd init --auto"
fi

echo ""
echo "For network proxy configuration, you can set environment variables:"
echo "  export http_proxy=http://proxy-server:port"
echo "  export https_proxy=http://proxy-server:port"
echo "  export no_proxy=localhost,127.0.0.1,localaddress,.localdomain.com"

echo ""
echo "To configure system-wide proxy settings on Ubuntu:"
echo "  sudo nano /etc/environment"
echo "  Add the proxy settings to the file"

echo ""
echo "For Docker containers, you can configure the daemon:"
echo "  sudo mkdir -p /etc/systemd/system/docker.service.d"
echo "  sudo nano /etc/systemd/system/docker.service.d/http-proxy.conf"
echo "  Add:"
echo "    [Service]"
echo "    Environment=\"HTTP_PROXY=http://proxy-server:port\""
echo "    Environment=\"HTTPS_PROXY=http://proxy-server:port\""
echo "    Environment=\"NO_PROXY=localhost,127.0.0.1\""
echo "  Then restart Docker:"
echo "    sudo systemctl daemon-reload"
echo "    sudo systemctl restart docker"
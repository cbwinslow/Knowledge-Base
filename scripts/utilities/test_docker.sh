#!/usr/bin/env bash
# Simple Docker test script

echo "Testing Docker access..."

# Try to run a simple Docker command
if docker info >/tmp/docker_info.txt 2>&1; then
    echo "SUCCESS: Docker is accessible"
    cat /tmp/docker_info.txt | head -5
    rm /tmp/docker_info.txt
else
    echo "FAILED: Docker is not accessible"
    echo "Error output:"
    cat /tmp/docker_info.txt
    rm /tmp/docker_info.txt
    exit 1
fi
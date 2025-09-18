#!/usr/bin/env bash
# Script to stop conflicting services before running CBW setup

echo "Stopping conflicting services..."

# Stop PostgreSQL
if systemctl is-active --quiet postgresql; then
    echo "Stopping PostgreSQL..."
    sudo systemctl stop postgresql
else
    echo "PostgreSQL is not running"
fi

# Stop Prometheus
if systemctl is-active --quiet snap.prometheus.prometheus; then
    echo "Stopping Prometheus..."
    sudo systemctl stop snap.prometheus.prometheus
else
    echo "Prometheus is not running"
fi

# Stop PostgreSQL cluster
if systemctl is-active --quiet postgresql@16-main.service; then
    echo "Stopping PostgreSQL cluster..."
    sudo systemctl stop postgresql@16-main.service
else
    echo "PostgreSQL cluster is not running"
fi

echo "Conflicting services stopped."
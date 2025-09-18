#!/bin/bash

# Setup monitoring stack with Grafana, Prometheus, etc.
echo "Setting up monitoring stack..."

mkdir -p /opt/monitoring/{prometheus,grafana,loki,tempo}

# Create docker-compose.yml for monitoring
cat > /opt/monitoring/docker-compose.yml << EOF
version: "3.8"

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus:/etc/prometheus
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    ports:
      - 9090:9090
    restart: unless-stopped

  grafana:
    image: grafana/grafana-enterprise
    container_name: grafana
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - 3000:3000
    restart: unless-stopped
    depends_on:
      - prometheus

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    ports:
      - 9100:9100
    restart: unless-stopped

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    container_name: cadvisor
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    ports:
      - 8080:8080
    restart: unless-stopped

volumes:
  prometheus_data:
  grafana_data:
EOF

# Create basic Prometheus config
mkdir -p /opt/monitoring/prometheus
cat > /opt/monitoring/prometheus/prometheus.yml << EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

# Start monitoring stack
cd /opt/monitoring
docker-compose up -d

echo "Monitoring stack setup completed."
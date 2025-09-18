#!/bin/bash

# Simple Docker Status Checker
# Shows what Docker containers are running (if any)

echo "====================================="
echo "   DOCKER STATUS CHECK"
echo "====================================="
echo

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed on this system."
    echo "To install Docker, run: sudo apt install docker.io"
    exit 1
fi

echo "Docker version: $(docker --version)"
echo

# Check if we can access Docker
if docker info &> /dev/null; then
    echo "Docker daemon is accessible."
    
    # Check for running containers
    RUNNING_CONTAINERS=$(docker ps -q | wc -l)
    if [ "$RUNNING_CONTAINERS" -gt 0 ]; then
        echo "Found $RUNNING_CONTAINERS running container(s):"
        echo "----------------------------------------"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "No containers are currently running."
    fi
    
    # Check for existing containers (running or stopped)
    TOTAL_CONTAINERS=$(docker ps -a -q | wc -l)
    if [ "$TOTAL_CONTAINERS" -gt 0 ] && [ "$TOTAL_CONTAINERS" -ne "$RUNNING_CONTAINERS" ]; then
        echo
        echo "Stopped containers:"
        echo "----------------------------------------"
        docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | grep -v "Up"
    fi
else
    echo "Cannot access Docker daemon. You may need to:"
    echo "1. Run this script with sudo, or"
    echo "2. Add your user to the docker group with: sudo usermod -aG docker $USER"
    echo "3. Log out and log back in"
fi

echo
echo "====================================="
echo "   AI MONITORING SYSTEM"
echo "====================================="
echo
echo "The AI Monitoring System includes these services:"
echo "  - RabbitMQ (Message Broker): Will run on ports 5672, 15672"
echo "  - Redis (Cache): Will run on port 6379"
echo "  - Weaviate (Vector DB): Will run on port 8080"
echo "  - PostgreSQL (Relational DB): Will run on port 5432"
echo "  - InfluxDB (Time-series DB): Will run on port 8086"
echo "  - OpenSearch (Search Engine): Will run on ports 9200, 9600"
echo "  - Graylog (Log Management): Will run on ports 9000, 12201, 1514"
echo "  - Prometheus (Metrics): Will run on port 9090"
echo "  - Grafana (Visualization): Will run on port 3000"
echo "  - Loki (Log Aggregation): Will run on port 3100"
echo "  - Alertmanager (Alerting): Will run on port 9093"
echo
echo "To deploy the full system, run with sudo:"
echo "sudo /home/cbwinslow/setup_ai_monitoring.sh"
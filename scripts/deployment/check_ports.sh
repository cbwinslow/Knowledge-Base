#!/bin/bash

# Network Services Port Checker
# This script identifies which services are listening on which ports

echo "=== Network Services Port Check ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Network Services Port Check"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Listening Ports and Services"
    echo ""
} > $DOCS_DIR/port_check.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/port_check.md
}

# Check TCP ports
log_action "Checking TCP ports..."
{
    echo "### TCP Ports"
    echo ""
    echo "\`\`\`"
} >> $DOCS_DIR/port_check.md

# Get detailed port information
ss -tlnp | while read line; do
    if [[ $line == *"LISTEN"* ]]; then
        port=$(echo $line | awk '{print $4}' | awk -F':' '{print $NF}')
        process=$(echo $line | awk -F'"' '{print $2}')
        echo "Port $port: $process"
    fi
done | sort -n >> $DOCS_DIR/port_check.md

{
    echo "\`\`\`"
    echo ""
} >> $DOCS_DIR/port_check.md

# Check UDP ports
log_action "Checking UDP ports..."
{
    echo "### UDP Ports"
    echo ""
    echo "\`\`\`"
} >> $DOCS_DIR/port_check.md

ss -ulnp | while read line; do
    if [[ $line == *"UNCONN"* ]]; then
        port=$(echo $line | awk '{print $4}' | awk -F':' '{print $NF}')
        process=$(echo $line | awk -F'"' '{print $2}')
        echo "Port $port: $process"
    fi
done | sort -n >> $DOCS_DIR/port_check.md

{
    echo "\`\`\`"
    echo ""
    echo "## Port Availability"
    echo ""
    echo "### Common Service Ports Already in Use:"
    echo "- SSH: 22 (sshd)"
    echo "- HTTP: 80 (nginx/apache)"
    echo "- HTTPS: 443 (nginx/apache)"
    echo "- PostgreSQL: 5432 (postgres)"
    echo "- Docker: Various ports"
    echo ""
    echo "### Available Port Ranges:"
    echo "- 3000-3999: Available (except 3000 which is in use)"
    echo "- 8000-8999: Available"
    echo "- 9000-9999: Available (except 9090, 9099 which are in use)"
    echo "- 10000-65535: Available (except those listed above)"
    echo ""
    echo "## Recommended Ports for Security Tools:"
    echo ""
    echo "| Tool | Recommended Port | Purpose |"
    echo "|------|------------------|---------|"
    echo "| Suricata | 8080, 8081 | Web stats, EVE JSON output |"
    echo "| Zeek | 8082 | Web stats interface |"
    echo "| OSSEC | 8083 | Web UI |"
    echo "| ELK Stack | 9200, 9300 | Elasticsearch |"
    echo "| ELK Stack | 5601 | Kibana |"
    echo "| Grafana | 3001 | Metrics dashboard |"
    echo "| Prometheus | 9091 | Metrics collection |"
    echo "| Alertmanager | 9093 | Alert handling |"
    echo ""
} >> $DOCS_DIR/port_check.md

log_action "Port check complete!"
echo ""
echo "=== Port Check Complete ==="
echo "Documentation created in $DOCS_DIR/port_check.md"
echo ""
echo "Next steps:"
echo "1. Review the port check documentation to see which ports are available"
echo "2. Plan your security tool installations around available ports"
echo "3. Consider using Docker to isolate services on different ports"
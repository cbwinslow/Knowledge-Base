#!/bin/bash

# Security Setup Status Checker
# This script checks the status of installed security tools and services

echo "=== Security Setup Status Checker ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Security Setup Status Report"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Service Status"
    echo ""
} > $DOCS_DIR/status_report.md

# Function to log status
log_status() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/status_report.md
}

# Check SSH status
if systemctl is-active --quiet ssh; then
    log_status "✅ SSH: Active and running"
else
    log_status "❌ SSH: Not running"
fi

# Check Docker status
if systemctl is-active --quiet docker; then
    log_status "✅ Docker: Active and running"
else
    log_status "❌ Docker: Not running"
fi

# Check PostgreSQL status
if systemctl is-active --quiet postgresql; then
    log_status "✅ PostgreSQL: Active and running"
else
    log_status "❌ PostgreSQL: Not running"
fi

# Check Apache status
if systemctl is-active --quiet apache2; then
    log_status "✅ Apache: Active and running"
else
    log_status "❌ Apache: Not running"
fi

# Check Fail2ban status
if systemctl is-active --quiet fail2ban; then
    log_status "✅ Fail2ban: Active and running"
else
    log_status "❌ Fail2ban: Not running"
fi

# Check Suricata status
if systemctl is-active --quiet suricata; then
    log_status "✅ Suricata: Active and running"
else
    log_status "❌ Suricata: Not running"
fi

# Check OSSEC status
if systemctl is-active --quiet ossec; then
    log_status "✅ OSSEC: Active and running"
else
    log_status "❌ OSSEC: Not running"
fi

echo ""
echo "=== Port Check ==="
echo ""

# Check which ports are listening
log_status "Listening ports:"
echo "" >> $DOCS_DIR/status_report.md

# Show listening ports
netstat -tlnp | grep LISTEN | while read line; do
    log_status "  $line"
done

echo ""
echo "=== Disk Space ==="
echo ""

# Check disk space
log_status "Disk space usage:"
echo "" >> $DOCS_DIR/status_report.md
df -h | while read line; do
    log_status "  $line"
done

echo ""
echo "=== Next Steps ==="
echo ""
log_status "Next steps:"
log_status "1. Check detailed logs in $DOCS_DIR/status_report.md"
log_status "2. Review individual service configurations"
log_status "3. Run specific setup scripts for any missing services"
log_status "4. Complete Nextcloud installation if desired"

echo ""
echo "Status check complete. Detailed report saved to $DOCS_DIR/status_report.md"
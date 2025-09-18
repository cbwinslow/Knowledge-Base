#!/bin/bash

# PostgreSQL Status Check Script
# This script checks the status of PostgreSQL and provides troubleshooting information

echo "=== PostgreSQL Status Check ==="
echo ""

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "PostgreSQL client is not installed."
    echo "Install with: sudo apt install postgresql-client"
    exit 1
fi

# Check PostgreSQL service status
echo "Checking PostgreSQL service status..."
sudo systemctl status postgresql --no-pager

# Check if PostgreSQL is listening
echo ""
echo "Checking if PostgreSQL is listening..."
sudo ss -tlnp | grep postgres

# Check PostgreSQL version
echo ""
echo "PostgreSQL version:"
psql --version

# Check available databases
echo ""
echo "Available databases:"
sudo -u postgres psql -c "\l" 2>/dev/null || echo "Unable to list databases. You may need to authenticate as postgres user."

# Check PostgreSQL configuration
echo ""
echo "PostgreSQL configuration directory:"
sudo -u postgres psql -c "SHOW config_file;" 2>/dev/null || echo "/etc/postgresql/16/main/postgresql.conf"

echo ""
echo "=== PostgreSQL Status Check Complete ==="
echo ""
echo "Troubleshooting tips:"
echo "1. If PostgreSQL is not running, start it with: sudo systemctl start postgresql"
echo "2. If you need to enable it at boot: sudo systemctl enable postgresql"
echo "3. To connect to PostgreSQL: sudo -u postgres psql"
echo "4. To check logs: sudo journalctl -u postgresql"
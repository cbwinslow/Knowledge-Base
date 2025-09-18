#!/bin/bash

# Nextcloud Dependencies Check Script
# This script checks if all dependencies required for Nextcloud are installed

echo "=== Nextcloud Dependencies Check ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Dependencies Check"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Dependency Check Results"
    echo ""
} > $DOCS_DIR/nextcloud_deps_check.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_deps_check.md
}

# Check if Apache is installed
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -1)
    log_action "✅ Apache installed ($APACHE_VERSION)"
else
    log_action "❌ Apache not installed"
fi

# Check if PHP is installed
if command -v php &> /dev/null; then
    PHP_VERSION=$(php -v | head -1)
    log_action "✅ PHP installed ($PHP_VERSION)"
else
    log_action "❌ PHP not installed"
fi

# Check required PHP modules
REQUIRED_PHP_MODULES=("curl" "gd" "imagick" "intl" "mbstring" "pgsql" "zip" "xml")
MISSING_MODULES=()

for module in "${REQUIRED_PHP_MODULES[@]}"; do
    if php -m | grep -qi "$module"; then
        log_action "✅ PHP module '$module' installed"
    else
        log_action "❌ PHP module '$module' not installed"
        MISSING_MODULES+=("$module")
    fi
done

# Check if PostgreSQL is installed
if command -v psql &> /dev/null; then
    PG_VERSION=$(psql --version | head -1)
    log_action "✅ PostgreSQL installed ($PG_VERSION)"
else
    log_action "❌ PostgreSQL not installed"
fi

# Check if Composer is installed (optional but useful)
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | head -1)
    log_action "✅ Composer installed ($COMPOSER_VERSION)"
else
    log_action "ℹ️ Composer not installed (optional)"
fi

# Summary
{
    echo ""
    echo "## Summary"
    echo ""
} >> $DOCS_DIR/nextcloud_deps_check.md

if [ ${#MISSING_MODULES[@]} -eq 0 ] && command -v apache2 &> /dev/null && command -v php &> /dev/null && command -v psql &> /dev/null; then
    log_action "✅ All required dependencies for Nextcloud are installed"
    echo ""
    echo "=== All Dependencies Check Complete ==="
    echo "All required dependencies for Nextcloud are installed."
    echo "You can now proceed with the Nextcloud installation."
else
    log_action "⚠️ Some dependencies are missing"
    echo ""
    echo "=== Dependencies Check Complete ==="
    echo "Some dependencies are missing:"
    if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
        echo "  Missing PHP modules: ${MISSING_MODULES[*]}"
    fi
    if ! command -v apache2 &> /dev/null; then
        echo "  Missing Apache web server"
    fi
    if ! command -v php &> /dev/null; then
        echo "  Missing PHP"
    fi
    if ! command -v psql &> /dev/null; then
        echo "  Missing PostgreSQL"
    fi
    echo ""
    echo "Install missing dependencies before proceeding with Nextcloud installation."
fi

echo ""
echo "Documentation created in $DOCS_DIR/nextcloud_deps_check.md"
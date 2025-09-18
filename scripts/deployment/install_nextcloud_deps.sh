#!/bin/bash

# Nextcloud Dependencies Installation Script
# This script installs all dependencies required for Nextcloud

echo "=== Nextcloud Dependencies Installation ==="
echo ""

# Create documentation directory
DOCS_DIR="/home/cbwinslow/security_setup/docs"
mkdir -p $DOCS_DIR

{
    echo "# Nextcloud Dependencies Installation"
    echo ""
    echo "Date: $(date)"
    echo ""
    echo "## Installation Log"
    echo ""
} > $DOCS_DIR/nextcloud_deps_install.md

# Function to log actions
log_action() {
    echo "$1"
    echo "- $1" >> $DOCS_DIR/nextcloud_deps_install.md
}

# 1. Update package lists
log_action "Updating package lists..."
sudo apt update

# 2. Install Apache web server
log_action "Installing Apache web server..."
sudo apt install -y apache2

# 3. Install PHP and required modules
log_action "Installing PHP 8.3 and required modules..."
sudo apt install -y \
    php8.3 \
    php8.3-cli \
    php8.3-common \
    php8.3-curl \
    php8.3-gd \
    php8.3-imagick \
    php8.3-intl \
    php8.3-mbstring \
    php8.3-pgsql \
    php8.3-zip \
    php8.3-xml \
    php8.3-bz2 \
    php8.3-fpm \
    libapache2-mod-php8.3

# 4. Enable Apache modules
log_action "Enabling Apache modules..."
sudo a2enmod rewrite headers env dir mime ssl
sudo a2enmod php8.3

# 5. Install additional useful tools
log_action "Installing additional useful tools..."
sudo apt install -y \
    curl \
    wget \
    unzip \
    zip \
    rsync \
    git

# 6. Install Composer (optional but useful)
log_action "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 7. Restart Apache to apply changes
log_action "Restarting Apache..."
sudo systemctl restart apache2

# 8. Verify installations
{
    echo ""
    echo "## Verification"
    echo ""
} >> $DOCS_DIR/nextcloud_deps_install.md

# Check Apache
if command -v apache2 &> /dev/null; then
    APACHE_VERSION=$(apache2 -v | head -1)
    log_action "✅ Apache installed ($APACHE_VERSION)"
else
    log_action "❌ Apache not installed"
fi

# Check PHP
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

# Check if Composer is installed
if command -v composer &> /dev/null; then
    COMPOSER_VERSION=$(composer --version | head -1)
    log_action "✅ Composer installed ($COMPOSER_VERSION)"
else
    log_action "❌ Composer not installed"
fi

# Summary
{
    echo ""
    echo "## Summary"
    echo ""
} >> $DOCS_DIR/nextcloud_deps_install.md

if [ ${#MISSING_MODULES[@]} -eq 0 ] && command -v apache2 &> /dev/null && command -v php &> /dev/null && command -v composer &> /dev/null; then
    log_action "✅ All dependencies for Nextcloud have been successfully installed"
    echo ""
    echo "=== Installation Complete ==="
    echo "All dependencies for Nextcloud have been successfully installed."
    echo "You can now proceed with the Nextcloud installation."
else
    log_action "⚠️ Some dependencies may not have been installed correctly"
    echo ""
    echo "=== Installation Complete ==="
    echo "Some dependencies may not have been installed correctly."
    if [ ${#MISSING_MODULES[@]} -gt 0 ]; then
        echo "  Missing PHP modules: ${MISSING_MODULES[*]}"
    fi
    echo "Check the documentation for details."
fi

echo ""
echo "Documentation created in $DOCS_DIR/nextcloud_deps_install.md"
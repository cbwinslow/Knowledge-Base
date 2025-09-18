#!/usr/bin/env bash
#===============================================================================
# Script Name : cbw-install-apache-httpd.sh
# Author      : CBW + GPT-5 Thinking
# Date        : 2025-09-18
# Summary     : Install Apache httpd, bind to localhost, serve /var/www/html.
#===============================================================================
set -euo pipefail; trap 'echo "[ERROR] $LINENO" >&2' ERR
PG=/usr/local/sbin/cbw-port-guard.sh
HTTP=$($PG reserve APACHE_HTTP 8080 | tail -n1)
apt update && apt install -y apache2
sed -i "s/^Listen .*/Listen 127.0.0.1:${HTTP}/" /etc/apache2/ports.conf || echo "Listen 127.0.0.1:${HTTP}" >> /etc/apache2/ports.conf
cat >/etc/apache2/sites-available/cbw-local.conf <<EOF
<VirtualHost 127.0.0.1:${HTTP}>
  ServerName localhost
  DocumentRoot /var/www/html
  <Directory /var/www/html>
    Options -Indexes +FollowSymLinks
    AllowOverride None
    Require all granted
  </Directory>
  ErrorLog \${APACHE_LOG_DIR}/cbw_error.log
  CustomLog \${APACHE_LOG_DIR}/cbw_access.log combined
</VirtualHost>
EOF
a2dissite 000-default.conf || true
a2ensite cbw-local.conf
a2enmod headers ssl rewrite
mkdir -p /var/www/html
cat >/var/www/html/index.html <<HTML
<!doctype html><html><head><meta charset="utf-8"><title>CBW Host</title></head>
<body><h1>CBW Apache Host</h1><p>It works. Port: ${HTTP}</p></body></html>
HTML
chown -R www-data:www-data /var/www/html
systemctl restart apache2 && systemctl enable apache2
echo "[+] Apache httpd on 127.0.0.1:${HTTP}"

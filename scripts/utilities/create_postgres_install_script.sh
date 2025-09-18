#!/bin/bash
# Script to install PostgreSQL with extensions

echo "Creating installation script for PostgreSQL..."

# Create a script that we can run with sudo
cat > /tmp/install_postgres.sh << 'EOF'
#!/bin/bash

# Update package lists
apt-get update

# Install PostgreSQL 16
apt-get install -y postgresql-16 postgresql-client-16 postgresql-contrib-16

# Install common extensions
apt-get install -y \
    postgresql-plpython3-16 \
    postgresql-pltcl-16 \
    postgresql-plperl-16 \
    postgresql-postgis-3 \
    postgresql-pgrouting \
    postgresql-16-ip4r \
    postgresql-16-hll \
    postgresql-16-hypopg \
    postgresql-16-pg-stat-kcache \
    postgresql-16-pg-qualstats \
    postgresql-16-pg-wait-sampling \
    postgresql-16-pgaudit \
    postgresql-16-pgextwlist \
    postgresql-16-pgfincore \
    postgresql-16-pldebugger \
    postgresql-16-plpgsql-check \
    postgresql-16-plprofiler \
    postgresql-16-prefix \
    postgresql-16-rational \
    postgresql-16-repack \
    postgresql-16-semver \
    postgresql-16-tablelog \
    postgresql-16-tdigest \
    postgresql-16-unit

# Start and enable PostgreSQL service
systemctl start postgresql
systemctl enable postgresql

echo "PostgreSQL installation completed!"
EOF

# Make the script executable
chmod +x /tmp/install_postgres.sh

echo "Installation script created at /tmp/install_postgres.sh"
echo "You can run it with: sudo /tmp/install_postgres.sh"
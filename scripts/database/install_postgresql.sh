#!/bin/bash
# Script to install PostgreSQL with extensions using pigsty package definitions

# Exit on any error
set -e

echo "Installing PostgreSQL with extensions..."

# Install PostgreSQL 16 and related packages
echo "Installing PostgreSQL 16 packages..."
sudo apt-get update
sudo apt-get install -y postgresql-16 postgresql-client-16 postgresql-contrib-16

# Check if installation was successful
if command -v psql &> /dev/null; then
    echo "PostgreSQL installed successfully!"
    PG_VERSION=16
    echo "PostgreSQL version: $PG_VERSION"
else
    echo "Failed to install PostgreSQL with apt. Trying alternative approach..."
    exit 1
fi

# Install common extensions
echo "Installing common PostgreSQL extensions..."
sudo apt-get install -y \
    postgresql-plpython3-16 \
    postgresql-pltcl-16 \
    postgresql-plperl-16 \
    postgresql-postgis-3 \
    postgresql-pgrouting

# Install additional extensions that are commonly available
sudo apt-get install -y \
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

echo "PostgreSQL installation completed with extensions!"

# Start PostgreSQL service
sudo systemctl start postgresql
sudo systemctl enable postgresql

echo "PostgreSQL service started and enabled!"

# Show installed extensions
echo "Checking installed extensions..."
sudo -u postgres psql -c "SELECT name FROM pg_available_extensions WHERE installed_version IS NOT NULL ORDER BY name;" || echo "Unable to list extensions"

echo "PostgreSQL setup completed successfully!"
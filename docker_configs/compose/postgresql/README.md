# PostgreSQL Docker Compose Setup

Complete PostgreSQL database setup with pgAdmin for easy management.

## Features

- PostgreSQL 16 (Alpine-based for smaller image size)
- pgAdmin 4 for web-based administration
- Health checks for service dependencies
- Persistent data volumes
- Custom initialization scripts support
- Resource limits and security hardening
- Structured logging

## Quick Start

### 1. Setup Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env with your values
nano .env
```

### 2. Create Init Scripts (Optional)

Create custom initialization scripts in `init-scripts/`:

```bash
mkdir -p init-scripts
```

Example init script (`init-scripts/01-create-schema.sql`):

```sql
-- Create application schema
CREATE SCHEMA IF NOT EXISTS app;

-- Create application user
CREATE USER app_user WITH PASSWORD 'app_password';
GRANT ALL PRIVILEGES ON SCHEMA app TO app_user;

-- Create example table
CREATE TABLE IF NOT EXISTS app.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Start Services

```bash
# Start in detached mode
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. Access Services

- **PostgreSQL**: `localhost:5432`
- **pgAdmin**: `http://localhost:5050`

## Usage Examples

### Connect to PostgreSQL CLI

```bash
# Using docker exec
docker exec -it postgres_db psql -U postgres -d appdb

# Using psql from host (requires psql installed)
psql -h localhost -p 5432 -U postgres -d appdb
```

### Backup Database

```bash
# Full database backup
docker exec postgres_db pg_dump -U postgres appdb > backup_$(date +%Y%m%d_%H%M%S).sql

# Compressed backup
docker exec postgres_db pg_dump -U postgres appdb | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Backup all databases
docker exec postgres_db pg_dumpall -U postgres > backup_all_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Database

```bash
# Restore from backup
docker exec -i postgres_db psql -U postgres -d appdb < backup.sql

# Restore from compressed backup
gunzip -c backup.sql.gz | docker exec -i postgres_db psql -U postgres -d appdb
```

### Database Maintenance

```bash
# Vacuum database
docker exec postgres_db psql -U postgres -d appdb -c "VACUUM ANALYZE;"

# Check database size
docker exec postgres_db psql -U postgres -c "SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) FROM pg_database;"

# List all tables
docker exec postgres_db psql -U postgres -d appdb -c "\dt"
```

## Configuration

### Custom PostgreSQL Configuration

Create `postgresql.conf` with custom settings:

```conf
# Memory Settings
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB
maintenance_work_mem = 128MB

# Connection Settings
max_connections = 100

# WAL Settings
wal_buffers = 8MB
checkpoint_completion_target = 0.9

# Query Tuning
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging
log_statement = 'all'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL superuser name | `postgres` |
| `POSTGRES_PASSWORD` | PostgreSQL superuser password | (required) |
| `POSTGRES_DB` | Default database name | `appdb` |
| `POSTGRES_PORT` | Host port mapping | `5432` |
| `PGADMIN_EMAIL` | pgAdmin login email | `admin@example.com` |
| `PGADMIN_PASSWORD` | pgAdmin login password | (required) |
| `PGADMIN_PORT` | pgAdmin host port | `5050` |

## pgAdmin Configuration

### First-Time Setup

1. Open pgAdmin at `http://localhost:5050`
2. Login with credentials from `.env`
3. Add new server:
   - **General Tab**:
     - Name: `Local PostgreSQL`
   - **Connection Tab**:
     - Host: `postgres` (container name)
     - Port: `5432`
     - Username: From `POSTGRES_USER`
     - Password: From `POSTGRES_PASSWORD`
     - Save password: ✓

## Troubleshooting

### Connection Refused

```bash
# Check if containers are running
docker-compose ps

# Check PostgreSQL logs
docker-compose logs postgres

# Verify health check
docker inspect postgres_db | grep -A 10 Health
```

### Permission Denied

```bash
# Fix volume permissions
docker-compose down -v  # WARNING: This deletes data!
docker-compose up -d
```

### Out of Memory

Adjust resource limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      memory: 4G  # Increase as needed
```

## Production Considerations

### Security

1. **Strong Passwords**: Use complex passwords for all accounts
2. **Network Isolation**: Use internal networks where possible
3. **SSL/TLS**: Enable SSL for connections
4. **Regular Updates**: Keep PostgreSQL image updated
5. **Secrets Management**: Use Docker secrets instead of environment variables

### Backup Strategy

```bash
# Create backup script
cat > backup-postgres.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backups/postgres"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

# Create backup
docker exec postgres_db pg_dumpall -U postgres | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Remove old backups
find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: backup_$DATE.sql.gz"
EOF

chmod +x backup-postgres.sh

# Add to cron for daily backups
# 0 2 * * * /path/to/backup-postgres.sh
```

### Monitoring

```bash
# Monitor active connections
docker exec postgres_db psql -U postgres -c "SELECT count(*) FROM pg_stat_activity;"

# Monitor database size growth
docker exec postgres_db psql -U postgres -c "SELECT datname, pg_size_pretty(pg_database_size(datname)) FROM pg_database;"

# Check for long-running queries
docker exec postgres_db psql -U postgres -c "SELECT pid, now() - query_start AS duration, query FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC;"
```

## Scaling

### Read Replicas

For read-heavy workloads, add read replicas:

```yaml
postgres-replica:
  image: postgres:16-alpine
  environment:
    POSTGRES_USER: replicator
    POSTGRES_PASSWORD: replicator_password
    PGDATA: /var/lib/postgresql/data/pgdata
  command: |
    postgres 
    -c wal_level=replica
    -c hot_standby=on
    -c max_wal_senders=10
    -c max_replication_slots=10
    -c hot_standby_feedback=on
```

### Connection Pooling

Add PgBouncer for connection pooling:

```yaml
pgbouncer:
  image: pgbouncer/pgbouncer:latest
  environment:
    DATABASES_HOST: postgres
    DATABASES_PORT: 5432
    DATABASES_USER: postgres
    DATABASES_PASSWORD: ${POSTGRES_PASSWORD}
  ports:
    - "6432:6432"
```

## Maintenance Commands

```bash
# Stop services
docker-compose stop

# Start services
docker-compose start

# Restart services
docker-compose restart

# Stop and remove containers (keeps volumes)
docker-compose down

# Stop and remove everything including volumes (DATA LOSS!)
docker-compose down -v

# Update images
docker-compose pull
docker-compose up -d

# View real-time logs
docker-compose logs -f postgres

# Execute SQL command
docker-compose exec postgres psql -U postgres -d appdb -c "SELECT version();"
```

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [pgAdmin Documentation](https://www.pgadmin.org/docs/)
- [Docker PostgreSQL Image](https://hub.docker.com/_/postgres)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

## License

See main repository license.

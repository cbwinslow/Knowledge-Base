# Docker Compose Deployment Guide

Complete guide to deploying multi-container applications with Docker Compose.

## Overview

Learn how to:
- Structure a Docker Compose project
- Configure services and networks
- Manage environment variables
- Deploy and scale applications
- Monitor and troubleshoot

**Time required**: 20-30 minutes

## Prerequisites

- Docker 20.10+ installed
- Docker Compose V2 installed
- Basic understanding of Docker
- Git (optional, for version control)

## Project Structure

```
myapp/
├── docker-compose.yml          # Main compose file
├── docker-compose.prod.yml     # Production overrides
├── .env.example                # Environment template
├── .env                        # Local environment (gitignored)
├── .gitignore                  # Git ignore file
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       └── default.conf
├── backend/
│   ├── Dockerfile
│   └── app/
├── frontend/
│   ├── Dockerfile
│   └── src/
└── README.md
```

## Step 1: Create Docker Compose File

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  # Database
  postgres:
    image: postgres:16-alpine
    container_name: ${PROJECT_NAME:-myapp}_postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: ${PROJECT_NAME:-myapp}_redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - backend
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # Backend API
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        - ENV=${ENVIRONMENT:-development}
    container_name: ${PROJECT_NAME:-myapp}_backend
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379/0
      - SECRET_KEY=${SECRET_KEY}
      - ENVIRONMENT=${ENVIRONMENT}
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - backend
      - frontend
    expose:
      - "8000"
    volumes:
      - ./backend/app:/app
      - backend_uploads:/app/uploads
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
      args:
        - API_URL=${API_URL}
    container_name: ${PROJECT_NAME:-myapp}_frontend
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - frontend
    expose:
      - "3000"

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: ${PROJECT_NAME:-myapp}_nginx
    restart: unless-stopped
    ports:
      - "${HTTP_PORT:-80}:80"
      - "${HTTPS_PORT:-443}:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./ssl:/etc/nginx/ssl:ro
      - nginx_logs:/var/log/nginx
    depends_on:
      - backend
      - frontend
    networks:
      - frontend
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
  backend_uploads:
  nginx_logs:

networks:
  backend:
    driver: bridge
  frontend:
    driver: bridge
```

## Step 2: Create Production Override

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  redis:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  backend:
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G

  frontend:
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  nginx:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
```

## Step 3: Configure Environment

Create `.env.example`:

```bash
# Project
PROJECT_NAME=myapp
ENVIRONMENT=production

# Database
DB_USER=appuser
DB_PASSWORD=changeme
DB_NAME=appdb

# Redis
REDIS_PASSWORD=changeme

# Backend
SECRET_KEY=changeme
API_URL=https://api.example.com

# Nginx
HTTP_PORT=80
HTTPS_PORT=443
```

Create `.env` from example:

```bash
cp .env.example .env
# Edit with your values
nano .env
```

## Step 4: Create .gitignore

Create `.gitignore`:

```
.env
*.log
node_modules/
__pycache__/
*.pyc
.DS_Store
volumes/
```

## Step 5: Deploy Application

### Development

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### Production

```bash
# Build images
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build

# Start services
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps
```

## Step 6: Scaling Services

```bash
# Scale backend to 5 instances
docker-compose up -d --scale backend=5

# Scale frontend to 3 instances
docker-compose up -d --scale frontend=3

# Verify scaling
docker-compose ps
```

## Common Commands

### Service Management

```bash
# Start services
docker-compose start

# Stop services
docker-compose stop

# Restart service
docker-compose restart backend

# Remove stopped containers
docker-compose rm -f

# Stop and remove everything
docker-compose down

# Stop and remove with volumes (DATA LOSS!)
docker-compose down -v
```

### Logs and Monitoring

```bash
# View all logs
docker-compose logs

# Follow logs
docker-compose logs -f

# Logs for specific service
docker-compose logs backend

# Last 100 lines
docker-compose logs --tail=100 backend

# Show timestamps
docker-compose logs -t backend
```

### Executing Commands

```bash
# Execute command in running container
docker-compose exec backend python manage.py migrate

# Run one-off command
docker-compose run --rm backend python script.py

# Open shell
docker-compose exec backend bash
```

### Updates and Rebuilds

```bash
# Pull latest images
docker-compose pull

# Rebuild specific service
docker-compose build backend

# Rebuild without cache
docker-compose build --no-cache backend

# Update and restart
docker-compose pull && docker-compose up -d
```

## Health Checks

### Check Service Health

```bash
# Check all services
docker-compose ps

# Inspect specific service
docker inspect myapp_backend | grep -A 10 Health

# Check health status
docker-compose exec backend curl http://localhost:8000/health
```

### Custom Health Check Script

Create `healthcheck.sh`:

```bash
#!/bin/bash

services=("postgres" "redis" "backend" "frontend" "nginx")

for service in "${services[@]}"; do
    health=$(docker inspect --format='{{.State.Health.Status}}' "myapp_${service}" 2>/dev/null || echo "not found")
    echo "$service: $health"
done
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs service_name

# Check configuration
docker-compose config

# Validate compose file
docker-compose -f docker-compose.yml config

# Start with verbose output
docker-compose up --verbose
```

### Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect myapp_backend

# Reconnect service to network
docker network connect myapp_backend myapp_postgres
```

### Database Connection Issues

```bash
# Check database is ready
docker-compose exec postgres pg_isready -U appuser

# Test connection from backend
docker-compose exec backend psql -h postgres -U appuser -d appdb

# Check environment variables
docker-compose exec backend env | grep DATABASE
```

### Volume Issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect myapp_postgres_data

# Remove unused volumes
docker volume prune

# Backup volume
docker run --rm -v myapp_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres_backup.tar.gz /data
```

## Backup and Restore

### Backup Script

Create `backup.sh`:

```bash
#!/bin/bash
set -euo pipefail

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup database
docker-compose exec -T postgres pg_dump -U appuser appdb > "${BACKUP_DIR}/db_${TIMESTAMP}.sql"

# Backup volumes
docker run --rm \
    -v myapp_postgres_data:/data \
    -v $(pwd)/backups:/backup \
    alpine tar czf "/backup/postgres_volume_${TIMESTAMP}.tar.gz" /data

echo "Backup completed: $TIMESTAMP"
```

### Restore Script

Create `restore.sh`:

```bash
#!/bin/bash
set -euo pipefail

BACKUP_FILE=$1

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: $0 <backup_file>"
    exit 1
fi

# Stop services
docker-compose stop backend

# Restore database
docker-compose exec -T postgres psql -U appuser -d appdb < "$BACKUP_FILE"

# Restart services
docker-compose start

echo "Restore completed"
```

## Production Checklist

- [ ] Environment variables configured
- [ ] Strong passwords set
- [ ] SSL/TLS certificates configured
- [ ] Resource limits set
- [ ] Health checks configured
- [ ] Logging configured
- [ ] Backup script created and tested
- [ ] Monitoring set up
- [ ] Firewall rules configured
- [ ] Documentation updated

## Next Steps

1. Set up monitoring (Prometheus + Grafana)
2. Configure SSL/TLS certificates
3. Set up CI/CD pipeline
4. Implement log aggregation
5. Configure alerting

## Additional Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Compose File Reference](https://docs.docker.com/compose/compose-file/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)

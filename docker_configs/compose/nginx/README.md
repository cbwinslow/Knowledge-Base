# Nginx Reverse Proxy Setup

Complete Nginx reverse proxy configuration with SSL support, load balancing, and caching.

## Features

- Nginx Alpine (lightweight)
- Reverse proxy configuration
- SSL/TLS support
- WebSocket support
- Static content serving
- Compression (gzip)
- Security headers
- Health checks
- Logging

## Quick Start

```bash
# Create necessary directories
mkdir -p conf.d ssl html backend

# Copy environment template
cp .env.example .env

# Create a simple index page
echo "<h1>Welcome</h1>" > html/index.html
echo "<h1>Backend</h1>" > backend/index.html

# Start services
docker-compose up -d
```

## Configuration Examples

### Basic Reverse Proxy

Add to `conf.d/app.conf`:

```nginx
server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### SSL/HTTPS Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name app.example.com;

    # SSL certificates
    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;

    # SSL settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS
    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name app.example.com;
    return 301 https://$server_name$request_uri;
}
```

### Load Balancing

```nginx
upstream backend_pool {
    least_conn;
    server backend1:8000 weight=3;
    server backend2:8000 weight=2;
    server backend3:8000 weight=1 backup;
    
    keepalive 32;
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend_pool;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
    }
}
```

### Caching Configuration

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=my_cache:10m 
                 max_size=1g inactive=60m use_temp_path=off;

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_cache my_cache;
        proxy_cache_valid 200 60m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;
        
        add_header X-Cache-Status $upstream_cache_status;
        
        proxy_pass http://backend:8000;
    }
}
```

### Rate Limiting

```nginx
limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    listen 80;
    server_name app.example.com;

    location /api/ {
        limit_req zone=mylimit burst=20 nodelay;
        limit_conn addr 10;
        
        proxy_pass http://backend:8000;
    }
}
```

## Usage Examples

### Test Configuration

```bash
# Test nginx configuration
docker exec nginx_proxy nginx -t

# Reload nginx (without downtime)
docker exec nginx_proxy nginx -s reload

# View error logs
docker exec nginx_proxy tail -f /var/log/nginx/error.log

# View access logs
docker exec nginx_proxy tail -f /var/log/nginx/access.log
```

### Generate Self-Signed SSL Certificate

```bash
# Create SSL directory
mkdir -p ssl

# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/key.pem -out ssl/cert.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

### Get Let's Encrypt Certificate

```bash
# Install certbot
apt-get install certbot python3-certbot-nginx

# Get certificate (standalone mode)
certbot certonly --standalone -d example.com -d www.example.com

# Copy certificates to nginx directory
cp /etc/letsencrypt/live/example.com/fullchain.pem ssl/cert.pem
cp /etc/letsencrypt/live/example.com/privkey.pem ssl/key.pem
```

## Common Patterns

### API Gateway

```nginx
server {
    listen 80;
    server_name api.example.com;

    # User service
    location /users/ {
        proxy_pass http://user-service:8001/;
    }

    # Auth service
    location /auth/ {
        proxy_pass http://auth-service:8002/;
    }

    # Product service
    location /products/ {
        proxy_pass http://product-service:8003/;
    }

    # Rate limiting for all APIs
    limit_req zone=api_limit burst=100 nodelay;
}
```

### SPA (Single Page Application)

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /usr/share/nginx/html;

    # Try files, fallback to index.html for client-side routing
    location / {
        try_files $uri $uri/ /index.html;
    }

    # API proxy
    location /api/ {
        proxy_pass http://backend:8000/;
    }

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

### Basic Authentication

```nginx
server {
    listen 80;
    server_name admin.example.com;

    # Create password file with: htpasswd -c /etc/nginx/.htpasswd username
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://admin-panel:8000;
    }
}
```

## Monitoring

### Check Nginx Status

```bash
# Add to nginx.conf
server {
    listen 8080;
    location /nginx_status {
        stub_status on;
        access_log off;
        allow 127.0.0.1;
        deny all;
    }
}

# Check status
docker exec nginx_proxy curl http://localhost:8080/nginx_status
```

### Analyze Logs

```bash
# Count requests by status code
docker exec nginx_proxy awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Top 10 IPs
docker exec nginx_proxy awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Average response time
docker exec nginx_proxy awk '{sum+=$10; count++} END {print sum/count}' /var/log/nginx/access.log
```

## Performance Tuning

### Worker Processes

```nginx
# Auto-detect CPU cores
worker_processes auto;

# Set worker priority
worker_priority -10;

# Maximum number of open files
worker_rlimit_nofile 65535;
```

### Connection Tuning

```nginx
events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

### Buffer Tuning

```nginx
http {
    client_body_buffer_size 10K;
    client_header_buffer_size 1k;
    client_max_body_size 100M;
    large_client_header_buffers 4 16k;
}
```

## Troubleshooting

### Configuration Errors

```bash
# Test configuration
docker exec nginx_proxy nginx -t

# Check syntax
docker exec nginx_proxy nginx -T

# View error log
docker-compose logs nginx
```

### Permission Issues

```bash
# Check file permissions
docker exec nginx_proxy ls -la /etc/nginx/

# Fix permissions if needed
chmod 644 nginx.conf
chmod 644 conf.d/*.conf
```

### Connection Issues

```bash
# Check if nginx is listening
docker exec nginx_proxy netstat -tlnp

# Test connectivity
curl -v http://localhost
```

## Production Checklist

- [ ] Configure SSL/TLS certificates
- [ ] Set up automatic certificate renewal
- [ ] Configure rate limiting
- [ ] Enable access logging
- [ ] Set up log rotation
- [ ] Configure security headers
- [ ] Test configuration before deployment
- [ ] Set up monitoring
- [ ] Configure backups for configs
- [ ] Document all custom configurations

## Additional Resources

- [Nginx Documentation](https://nginx.org/en/docs/)
- [Nginx Best Practices](https://www.nginx.com/blog/nginx-best-practices/)
- [SSL Configuration Generator](https://ssl-config.mozilla.org/)

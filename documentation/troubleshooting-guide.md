# Troubleshooting Guide

Comprehensive troubleshooting guide for common issues with Docker, databases, APIs, and more.

## Quick Diagnosis

### Docker Issues

#### Container Won't Start

**Symptoms**: Container exits immediately or won't start

**Diagnosis**:
```bash
# Check container status
docker ps -a

# View container logs
docker logs container_name

# Inspect container
docker inspect container_name

# Check recent events
docker events --since 1h
```

**Common Solutions**:

1. **Port Already in Use**
   ```bash
   # Check what's using the port
   lsof -i :8080
   netstat -tulpn | grep 8080
   
   # Solution: Change port in docker-compose.yml or stop conflicting service
   ```

2. **Permission Denied on Volumes**
   ```bash
   # Fix volume permissions
   sudo chown -R 1000:1000 ./data
   
   # Or use named volumes instead of bind mounts
   ```

3. **Missing Environment Variables**
   ```bash
   # Check environment variables
   docker exec container_name env
   
   # Solution: Verify .env file exists and has correct values
   cp .env.example .env
   nano .env
   ```

4. **Out of Disk Space**
   ```bash
   # Check Docker disk usage
   docker system df
   
   # Clean up
   docker system prune -a --volumes
   ```

#### Container Running but Unreachable

**Symptoms**: Container is running but can't connect to it

**Diagnosis**:
```bash
# Check if service is listening
docker exec container_name netstat -tulpn

# Check network
docker network inspect network_name

# Test from inside container
docker exec container_name curl http://localhost:8000

# Test from host
curl http://localhost:8000
```

**Solutions**:

1. **Service Not Listening on 0.0.0.0**
   ```yaml
   # Ensure service binds to all interfaces
   command: app --host 0.0.0.0 --port 8000
   ```

2. **Wrong Network**
   ```bash
   # Attach container to correct network
   docker network connect network_name container_name
   ```

3. **Firewall Blocking**
   ```bash
   # Check firewall rules
   sudo iptables -L
   sudo ufw status
   
   # Allow port
   sudo ufw allow 8000
   ```

### Database Issues

#### PostgreSQL Connection Refused

**Symptoms**: `Connection refused` or `could not connect to server`

**Diagnosis**:
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check PostgreSQL logs
docker logs postgres_container

# Try connecting from inside container
docker exec -it postgres_container psql -U postgres

# Test connection with verbose output
psql -h localhost -p 5432 -U postgres -d dbname -W
```

**Solutions**:

1. **PostgreSQL Not Ready Yet**
   ```yaml
   # Add depends_on with health check
   depends_on:
     postgres:
       condition: service_healthy
   ```

2. **Wrong Connection String**
   ```bash
   # Correct format
   postgresql://user:password@host:port/database
   
   # Inside Docker network, use container name as host
   postgresql://user:password@postgres:5432/database
   ```

3. **Authentication Failed**
   ```bash
   # Check pg_hba.conf
   docker exec postgres_container cat /var/lib/postgresql/data/pg_hba.conf
   
   # Solution: Update postgresql.conf
   host all all 0.0.0.0/0 md5
   ```

#### Database Out of Connections

**Symptoms**: `FATAL: sorry, too many clients already`

**Diagnosis**:
```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Check max connections
SHOW max_connections;

-- View active connections
SELECT pid, usename, datname, state, query_start 
FROM pg_stat_activity 
WHERE state = 'active';
```

**Solutions**:

1. **Increase Max Connections**
   ```conf
   # In postgresql.conf
   max_connections = 200
   ```

2. **Close Idle Connections**
   ```sql
   -- Kill idle connections
   SELECT pg_terminate_backend(pid) 
   FROM pg_stat_activity 
   WHERE state = 'idle' 
   AND query_start < now() - interval '1 hour';
   ```

3. **Use Connection Pooling**
   ```yaml
   # Add PgBouncer
   pgbouncer:
     image: pgbouncer/pgbouncer
     environment:
       - DATABASES_HOST=postgres
       - DATABASES_PORT=5432
   ```

#### Slow Queries

**Symptoms**: Database queries taking too long

**Diagnosis**:
```sql
-- Enable query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

-- Find slow queries
SELECT pid, now() - query_start as duration, query 
FROM pg_stat_activity 
WHERE state = 'active' 
ORDER BY duration DESC;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation
FROM pg_stats
WHERE schemaname NOT IN ('pg_catalog', 'information_schema');

-- Analyze query plan
EXPLAIN ANALYZE SELECT * FROM table WHERE condition;
```

**Solutions**:

1. **Add Missing Indexes**
   ```sql
   -- Create index on frequently queried columns
   CREATE INDEX idx_users_email ON users(email);
   
   -- Create composite index
   CREATE INDEX idx_orders_user_date ON orders(user_id, created_at);
   ```

2. **Update Statistics**
   ```sql
   -- Analyze tables
   ANALYZE;
   
   -- Or specific table
   ANALYZE users;
   ```

3. **Optimize Query**
   ```sql
   -- Use EXPLAIN to understand query plan
   EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
   
   -- Limit results
   SELECT * FROM large_table LIMIT 100;
   
   -- Use proper JOINs
   SELECT * FROM users u 
   INNER JOIN orders o ON u.id = o.user_id
   WHERE u.active = true;
   ```

### API Issues

#### 502 Bad Gateway

**Symptoms**: Nginx returns 502 error

**Diagnosis**:
```bash
# Check backend service
docker ps | grep backend

# Check backend logs
docker logs backend_container

# Check nginx error log
docker logs nginx_container | grep error

# Test backend directly
docker exec backend_container curl http://localhost:8000
```

**Solutions**:

1. **Backend Not Running**
   ```bash
   # Restart backend
   docker-compose restart backend
   ```

2. **Backend Timeout**
   ```nginx
   # Increase timeout in nginx.conf
   proxy_read_timeout 300;
   proxy_connect_timeout 300;
   ```

3. **Wrong Upstream Address**
   ```nginx
   # Use container name, not localhost
   proxy_pass http://backend:8000;  # Correct
   proxy_pass http://localhost:8000;  # Wrong
   ```

#### 429 Too Many Requests

**Symptoms**: Rate limit exceeded

**Diagnosis**:
```bash
# Check rate limit configuration
docker exec nginx_container cat /etc/nginx/conf.d/default.conf | grep limit

# Monitor request rate
docker logs nginx_container | grep -c "$(date +'%d/%b/%Y:%H:%M')"
```

**Solutions**:

1. **Increase Rate Limit**
   ```nginx
   limit_req_zone $binary_remote_addr zone=api_limit:10m rate=100r/s;
   limit_req zone=api_limit burst=200 nodelay;
   ```

2. **Use Redis for Distributed Rate Limiting**
   ```python
   from redis import Redis
   from ratelimit import limits, RateLimitException
   
   redis_client = Redis(host='redis', port=6379)
   
   @limits(calls=100, period=60, storage=RedisStorage(redis_client))
   def api_endpoint():
       pass
   ```

#### Slow API Response

**Symptoms**: API taking too long to respond

**Diagnosis**:
```bash
# Time API request
time curl http://localhost:8000/api/endpoint

# Check with verbose output
curl -w "@curl-format.txt" -o /dev/null -s http://localhost:8000/api/endpoint

# curl-format.txt content:
# time_total: %{time_total}s
# time_namelookup: %{time_namelookup}s
# time_connect: %{time_connect}s
# time_appconnect: %{time_appconnect}s
# time_pretransfer: %{time_pretransfer}s
# time_redirect: %{time_redirect}s
# time_starttransfer: %{time_starttransfer}s
```

**Solutions**:

1. **Enable Caching**
   ```python
   from functools import lru_cache
   
   @lru_cache(maxsize=1000)
   def expensive_function(param):
       # Expensive computation
       return result
   ```

2. **Use Async/Await**
   ```python
   import asyncio
   
   async def fetch_data():
       # Non-blocking I/O
       return await db.fetch_all(query)
   ```

3. **Add Database Indexes**
   ```sql
   CREATE INDEX idx_orders_user_id ON orders(user_id);
   ```

4. **Use Connection Pooling**
   ```python
   from sqlalchemy.pool import QueuePool
   
   engine = create_engine(
       DATABASE_URL,
       poolclass=QueuePool,
       pool_size=20,
       max_overflow=0
   )
   ```

### Performance Issues

#### High CPU Usage

**Diagnosis**:
```bash
# Check system CPU
top
htop

# Check Docker container CPU
docker stats

# Find CPU-intensive processes
ps aux --sort=-%cpu | head -10

# Profile Python application
python -m cProfile -o output.prof script.py
```

**Solutions**:

1. **Limit Container Resources**
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2.0'
   ```

2. **Optimize Code**
   - Use caching
   - Reduce loops
   - Use list comprehensions
   - Parallelize with multiprocessing

3. **Scale Horizontally**
   ```bash
   docker-compose up -d --scale backend=3
   ```

#### High Memory Usage

**Diagnosis**:
```bash
# Check system memory
free -h

# Check Docker container memory
docker stats

# Find memory-intensive processes
ps aux --sort=-%mem | head -10

# Python memory profiling
pip install memory_profiler
python -m memory_profiler script.py
```

**Solutions**:

1. **Limit Container Memory**
   ```yaml
   deploy:
     resources:
       limits:
         memory: 1G
   ```

2. **Fix Memory Leaks**
   ```python
   # Close connections
   connection.close()
   
   # Clear caches
   cache.clear()
   
   # Use generators instead of lists
   def process_large_file():
       with open('large.txt') as f:
           for line in f:  # Generator
               yield line
   ```

3. **Optimize Data Structures**
   ```python
   # Use slots for classes
   class MyClass:
       __slots__ = ['attr1', 'attr2']
   
   # Use appropriate data types
   import array
   numbers = array.array('i', [1, 2, 3, 4, 5])
   ```

### Network Issues

#### DNS Resolution Fails

**Symptoms**: `Could not resolve host`

**Diagnosis**:
```bash
# Test DNS resolution
docker exec container_name nslookup google.com
docker exec container_name dig google.com

# Check DNS configuration
docker exec container_name cat /etc/resolv.conf
```

**Solutions**:

1. **Set Custom DNS**
   ```yaml
   services:
     app:
       dns:
         - 8.8.8.8
         - 8.8.4.4
   ```

2. **Use Host's DNS**
   ```yaml
   services:
     app:
       network_mode: "host"
   ```

#### Connection Timeout

**Symptoms**: Request times out

**Diagnosis**:
```bash
# Test connectivity
telnet host port
nc -zv host port

# Trace route
traceroute host

# Check firewall
sudo iptables -L
sudo ufw status
```

**Solutions**:

1. **Increase Timeout**
   ```python
   requests.get(url, timeout=30)
   ```

2. **Check Firewall Rules**
   ```bash
   # Allow port
   sudo ufw allow 8000
   ```

3. **Use Retry Logic**
   ```python
   from tenacity import retry, stop_after_attempt, wait_exponential
   
   @retry(stop=stop_after_attempt(3), wait=wait_exponential())
   def make_request():
       return requests.get(url)
   ```

## Common Error Messages

### Error: "Cannot connect to the Docker daemon"

**Solution**:
```bash
# Start Docker service
sudo systemctl start docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Error: "No space left on device"

**Solution**:
```bash
# Clean up Docker
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Remove unused volumes
docker volume prune
```

### Error: "port is already allocated"

**Solution**:
```bash
# Find process using port
lsof -i :8080

# Kill process
kill -9 PID

# Or change port in docker-compose.yml
```

## Debugging Tools

### Useful Commands

```bash
# Docker debugging
docker inspect container_name
docker logs -f container_name
docker exec -it container_name /bin/bash
docker stats

# Network debugging
docker network ls
docker network inspect network_name
tcpdump -i any port 8000

# Database debugging
docker exec -it postgres psql -U user -d database
EXPLAIN ANALYZE query;

# System debugging
top
htop
iostat
vmstat
```

### Log Analysis

```bash
# Search logs
docker logs container_name | grep ERROR

# Follow logs with timestamps
docker logs -f --timestamps container_name

# Last N lines
docker logs --tail 100 container_name

# Logs between time range
docker logs --since 2024-01-01T00:00:00 --until 2024-01-02T00:00:00 container_name
```

## Getting Help

If you're still stuck:

1. Check container logs: `docker logs container_name`
2. Check system resources: `docker stats`
3. Verify configuration: `docker-compose config`
4. Search for error messages in documentation
5. Check GitHub issues for similar problems
6. Ask for help with detailed error messages and logs

## Prevention

Best practices to avoid issues:

- [ ] Always use health checks
- [ ] Set resource limits
- [ ] Implement proper logging
- [ ] Use monitoring tools
- [ ] Regular backups
- [ ] Keep dependencies updated
- [ ] Document configuration
- [ ] Test in staging first
- [ ] Use version control
- [ ] Implement error handling

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [PostgreSQL Troubleshooting](https://wiki.postgresql.org/wiki/FAQ)
- [Nginx Debugging](https://nginx.org/en/docs/debugging_log.html)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

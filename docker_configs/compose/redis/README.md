# Redis Docker Compose Setup

Production-ready Redis cache setup with Redis Commander for management.

## Features

- Redis 7 (Alpine-based)
- Password authentication
- Persistence with AOF (Append-Only File)
- Memory limits and eviction policies
- Redis Commander web UI
- Health checks
- Resource limits

## Quick Start

```bash
# Setup environment
cp .env.example .env
nano .env

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f redis
```

## Access

- **Redis**: `localhost:6379`
- **Redis Commander**: `http://localhost:8081`

## Usage Examples

### Connect with Redis CLI

```bash
# Using docker exec
docker exec -it redis_cache redis-cli -a your_password

# Test connection
docker exec redis_cache redis-cli -a your_password ping
# Should return: PONG
```

### Basic Operations

```bash
# Set a key
docker exec redis_cache redis-cli -a your_password SET mykey "Hello World"

# Get a key
docker exec redis_cache redis-cli -a your_password GET mykey

# Set with expiration (10 seconds)
docker exec redis_cache redis-cli -a your_password SETEX tempkey 10 "Temporary value"

# Check if key exists
docker exec redis_cache redis-cli -a your_password EXISTS mykey

# Delete a key
docker exec redis_cache redis-cli -a your_password DEL mykey

# Get all keys
docker exec redis_cache redis-cli -a your_password KEYS '*'
```

### Cache Operations

```bash
# Cache with TTL (Time To Live)
docker exec redis_cache redis-cli -a your_password SET user:1001:session "xyz123" EX 3600

# Increment counter
docker exec redis_cache redis-cli -a your_password INCR page:views
docker exec redis_cache redis-cli -a your_password INCRBY page:views 10

# Hash operations (for objects)
docker exec redis_cache redis-cli -a your_password HSET user:1001 name "John Doe"
docker exec redis_cache redis-cli -a your_password HSET user:1001 email "john@example.com"
docker exec redis_cache redis-cli -a your_password HGETALL user:1001

# List operations (for queues)
docker exec redis_cache redis-cli -a your_password LPUSH queue:tasks "task1"
docker exec redis_cache redis-cli -a your_password LPUSH queue:tasks "task2"
docker exec redis_cache redis-cli -a your_password RPOP queue:tasks

# Set operations (for unique items)
docker exec redis_cache redis-cli -a your_password SADD tags:post:1 "redis" "cache" "docker"
docker exec redis_cache redis-cli -a your_password SMEMBERS tags:post:1
```

### Monitoring

```bash
# Get server info
docker exec redis_cache redis-cli -a your_password INFO

# Monitor memory usage
docker exec redis_cache redis-cli -a your_password INFO memory

# Get statistics
docker exec redis_cache redis-cli -a your_password INFO stats

# Monitor commands in real-time
docker exec redis_cache redis-cli -a your_password MONITOR

# Get slow queries
docker exec redis_cache redis-cli -a your_password SLOWLOG GET 10

# Check connected clients
docker exec redis_cache redis-cli -a your_password CLIENT LIST
```

### Backup and Restore

```bash
# Trigger save
docker exec redis_cache redis-cli -a your_password SAVE

# Background save
docker exec redis_cache redis-cli -a your_password BGSAVE

# Copy backup file
docker cp redis_cache:/data/dump.rdb ./backup-$(date +%Y%m%d_%H%M%S).rdb

# Restore from backup
docker cp backup.rdb redis_cache:/data/dump.rdb
docker-compose restart redis
```

## Configuration

### Memory Policies

Available `REDIS_MAXMEMORY_POLICY` options:

- `noeviction`: Return errors when memory limit is reached
- `allkeys-lru`: Remove least recently used keys
- `allkeys-lfu`: Remove least frequently used keys (Redis 4.0+)
- `volatile-lru`: Remove LRU keys with expiration set
- `volatile-lfu`: Remove LFU keys with expiration set
- `allkeys-random`: Remove random keys
- `volatile-random`: Remove random keys with expiration set
- `volatile-ttl`: Remove keys with shortest TTL

### Custom Configuration

Create `redis.conf` for advanced settings:

```conf
# Network
bind 0.0.0.0
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# General
daemonize no
supervised no
pidfile /var/run/redis.pid
loglevel notice

# Snapshotting
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb

# Replication
replica-serve-stale-data yes
replica-read-only yes

# Security
requirepass your_secure_password

# Limits
maxclients 10000

# Append Only Mode
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Slow Log
slowlog-log-slower-than 10000
slowlog-max-len 128
```

## Python Client Example

```python
import redis
import json

# Connect to Redis
r = redis.Redis(
    host='localhost',
    port=6379,
    password='your_password',
    decode_responses=True
)

# Basic operations
r.set('key', 'value')
value = r.get('key')

# Cache with expiration
r.setex('session:user123', 3600, 'session_data')

# Hash operations
r.hset('user:1001', mapping={
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30
})
user = r.hgetall('user:1001')

# List operations (queue)
r.lpush('queue:tasks', json.dumps({'task': 'process_image', 'id': 1}))
task = json.loads(r.rpop('queue:tasks'))

# Set operations
r.sadd('tags:post:1', 'redis', 'cache', 'python')
tags = r.smembers('tags:post:1')

# Increment counters
r.incr('page:views')
r.incrby('api:calls', 10)

# Pub/Sub
pubsub = r.pubsub()
pubsub.subscribe('notifications')

# Publish message
r.publish('notifications', json.dumps({'type': 'alert', 'message': 'High CPU'}))
```

## Node.js Client Example

```javascript
const redis = require('redis');

// Create client
const client = redis.createClient({
    host: 'localhost',
    port: 6379,
    password: 'your_password'
});

client.on('error', (err) => console.error('Redis Error:', err));
client.on('connect', () => console.log('Connected to Redis'));

// Basic operations
await client.connect();

await client.set('key', 'value');
const value = await client.get('key');

// Cache with expiration
await client.setEx('session:user123', 3600, 'session_data');

// Hash operations
await client.hSet('user:1001', {
    name: 'John Doe',
    email: 'john@example.com',
    age: 30
});
const user = await client.hGetAll('user:1001');

// List operations
await client.lPush('queue:tasks', JSON.stringify({task: 'process_image', id: 1}));
const task = JSON.parse(await client.rPop('queue:tasks'));

// Set operations
await client.sAdd('tags:post:1', ['redis', 'cache', 'nodejs']);
const tags = await client.sMembers('tags:post:1');

// Increment counters
await client.incr('page:views');
await client.incrBy('api:calls', 10);

// Close connection
await client.quit();
```

## Performance Tips

1. **Use pipelining** for multiple commands
2. **Use connection pooling** in production
3. **Set appropriate TTLs** to prevent memory bloat
4. **Monitor slow queries** regularly
5. **Use hashes** for complex objects instead of multiple keys
6. **Avoid KEYS command** in production (use SCAN instead)

## Troubleshooting

### Connection Issues

```bash
# Check if Redis is running
docker-compose ps

# Check logs
docker-compose logs redis

# Test connection
docker exec redis_cache redis-cli -a your_password ping
```

### High Memory Usage

```bash
# Check memory stats
docker exec redis_cache redis-cli -a your_password INFO memory

# Find big keys
docker exec redis_cache redis-cli -a your_password --bigkeys

# Clear database (CAUTION!)
docker exec redis_cache redis-cli -a your_password FLUSHALL
```

### Performance Issues

```bash
# Check slow queries
docker exec redis_cache redis-cli -a your_password SLOWLOG GET 10

# Monitor latency
docker exec redis_cache redis-cli -a your_password --latency

# Check client list
docker exec redis_cache redis-cli -a your_password CLIENT LIST
```

## Production Checklist

- [ ] Set strong password
- [ ] Configure memory limits
- [ ] Enable persistence (AOF/RDB)
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Use connection pooling
- [ ] Implement retry logic
- [ ] Set appropriate TTLs
- [ ] Monitor slow queries
- [ ] Plan for high availability (Redis Sentinel/Cluster)

## Additional Resources

- [Redis Documentation](https://redis.io/documentation)
- [Redis Commands](https://redis.io/commands)
- [Redis Best Practices](https://redis.io/topics/best-practices)
- [Redis Persistence](https://redis.io/topics/persistence)

# MongoDB Docker Compose Setup

Complete MongoDB setup with Mongo Express for web-based management.

## Features

- MongoDB 7
- Authentication enabled
- Mongo Express web UI
- Persistent data volumes
- Health checks
- Resource limits
- Custom initialization scripts support

## Quick Start

```bash
# Setup environment
cp .env.example .env
nano .env

# Start services
docker-compose up -d

# Check logs
docker-compose logs -f mongodb
```

## Access

- **MongoDB**: `mongodb://localhost:27017`
- **Mongo Express**: `http://localhost:8081`

## Usage Examples

### Connect with Mongo Shell

```bash
# Using docker exec
docker exec -it mongodb mongosh -u admin -p your_password --authenticationDatabase admin

# Connect to specific database
docker exec -it mongodb mongosh appdb -u admin -p your_password --authenticationDatabase admin
```

### Basic Operations

```javascript
// Switch to database
use appdb

// Create collection and insert document
db.users.insertOne({
    name: "John Doe",
    email: "john@example.com",
    age: 30,
    created_at: new Date()
})

// Insert multiple documents
db.users.insertMany([
    { name: "Alice", email: "alice@example.com", age: 25 },
    { name: "Bob", email: "bob@example.com", age: 35 }
])

// Find documents
db.users.find()
db.users.find({ age: { $gt: 28 } })
db.users.findOne({ email: "john@example.com" })

// Update document
db.users.updateOne(
    { email: "john@example.com" },
    { $set: { age: 31 } }
)

// Delete document
db.users.deleteOne({ email: "john@example.com" })

// Count documents
db.users.countDocuments()

// Create index
db.users.createIndex({ email: 1 }, { unique: true })
```

### User Management

```javascript
// Create application user
use admin
db.createUser({
    user: "appuser",
    pwd: "apppassword",
    roles: [
        { role: "readWrite", db: "appdb" },
        { role: "read", db: "analytics" }
    ]
})

// List users
db.getUsers()

// Grant additional role
db.grantRolesToUser("appuser", [
    { role: "dbAdmin", db: "appdb" }
])

// Remove user
db.dropUser("appuser")
```

### Backup and Restore

```bash
# Full database backup
docker exec mongodb mongodump \
    --username admin \
    --password your_password \
    --authenticationDatabase admin \
    --out /backup

# Copy backup from container
docker cp mongodb:/backup ./backup-$(date +%Y%m%d_%H%M%S)

# Backup specific database
docker exec mongodb mongodump \
    --username admin \
    --password your_password \
    --authenticationDatabase admin \
    --db appdb \
    --out /backup

# Restore database
docker exec -i mongodb mongorestore \
    --username admin \
    --password your_password \
    --authenticationDatabase admin \
    /backup

# Restore specific database
docker exec -i mongodb mongorestore \
    --username admin \
    --password your_password \
    --authenticationDatabase admin \
    --db appdb \
    /backup/appdb
```

### Database Maintenance

```javascript
// Database statistics
db.stats()

// Collection statistics
db.users.stats()

// Check indexes
db.users.getIndexes()

// Compact database
db.runCommand({ compact: "users" })

// Get current operations
db.currentOp()

// Kill operation
db.killOp(operationId)
```

## Python Client Example

```python
from pymongo import MongoClient
from datetime import datetime

# Connect to MongoDB
client = MongoClient(
    'mongodb://localhost:27017/',
    username='admin',
    password='your_password',
    authSource='admin'
)

# Select database
db = client['appdb']

# Select collection
users = db['users']

# Insert document
user_id = users.insert_one({
    'name': 'John Doe',
    'email': 'john@example.com',
    'age': 30,
    'created_at': datetime.now()
}).inserted_id

# Find documents
for user in users.find():
    print(user)

# Find with filter
young_users = users.find({'age': {'$lt': 30}})

# Update document
users.update_one(
    {'email': 'john@example.com'},
    {'$set': {'age': 31}}
)

# Delete document
users.delete_one({'email': 'john@example.com'})

# Aggregation
pipeline = [
    {'$match': {'age': {'$gte': 25}}},
    {'$group': {'_id': '$age', 'count': {'$sum': 1}}},
    {'$sort': {'count': -1}}
]
results = users.aggregate(pipeline)

# Close connection
client.close()
```

## Node.js Client Example

```javascript
const { MongoClient } = require('mongodb');

// Connection URL
const url = 'mongodb://admin:your_password@localhost:27017?authSource=admin';
const client = new MongoClient(url);

async function main() {
    try {
        // Connect to MongoDB
        await client.connect();
        console.log('Connected to MongoDB');

        // Select database and collection
        const db = client.db('appdb');
        const users = db.collection('users');

        // Insert document
        const result = await users.insertOne({
            name: 'John Doe',
            email: 'john@example.com',
            age: 30,
            created_at: new Date()
        });
        console.log('Inserted:', result.insertedId);

        // Find documents
        const allUsers = await users.find({}).toArray();
        console.log('Users:', allUsers);

        // Find with filter
        const youngUsers = await users.find({ age: { $lt: 30 } }).toArray();

        // Update document
        await users.updateOne(
            { email: 'john@example.com' },
            { $set: { age: 31 } }
        );

        // Delete document
        await users.deleteOne({ email: 'john@example.com' });

        // Aggregation
        const ageGroups = await users.aggregate([
            { $match: { age: { $gte: 25 } } },
            { $group: { _id: '$age', count: { $sum: 1 } } },
            { $sort: { count: -1 } }
        ]).toArray();

    } finally {
        await client.close();
    }
}

main().catch(console.error);
```

## Initialization Scripts

Create `init-scripts/01-init.js`:

```javascript
// Create application user
db = db.getSiblingDB('admin');
db.createUser({
    user: 'appuser',
    pwd: 'apppassword',
    roles: [
        { role: 'readWrite', db: 'appdb' }
    ]
});

// Switch to application database
db = db.getSiblingDB('appdb');

// Create collections with validation
db.createCollection('users', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['name', 'email'],
            properties: {
                name: {
                    bsonType: 'string',
                    description: 'must be a string and is required'
                },
                email: {
                    bsonType: 'string',
                    pattern: '^.+@.+$',
                    description: 'must be a valid email and is required'
                },
                age: {
                    bsonType: 'int',
                    minimum: 0,
                    maximum: 150,
                    description: 'must be an integer between 0 and 150'
                }
            }
        }
    }
});

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ name: 1 });

// Insert sample data
db.users.insertMany([
    { name: 'Alice', email: 'alice@example.com', age: 25 },
    { name: 'Bob', email: 'bob@example.com', age: 35 }
]);

print('Database initialized successfully');
```

## Monitoring

```javascript
// Server status
db.serverStatus()

// List all databases
show dbs

// Database statistics
db.stats()

// Collection statistics
db.users.stats()

// Check replication status (if replica set)
rs.status()

// Get profiling level
db.getProfilingLevel()

// Enable profiling (log slow queries)
db.setProfilingLevel(1, { slowms: 100 })

// View profile data
db.system.profile.find().limit(10).sort({ ts: -1 }).pretty()
```

## Performance Tuning

### Indexing Strategies

```javascript
// Single field index
db.users.createIndex({ email: 1 })

// Compound index
db.orders.createIndex({ customerId: 1, orderDate: -1 })

// Text index for full-text search
db.articles.createIndex({ title: "text", content: "text" })

// Geospatial index
db.locations.createIndex({ coordinates: "2dsphere" })

// Check index usage
db.users.aggregate([
    { $indexStats: {} }
])

// Drop unused index
db.users.dropIndex("index_name")
```

### Query Optimization

```javascript
// Use explain to analyze queries
db.users.find({ age: { $gt: 25 } }).explain("executionStats")

// Create indexes for frequently queried fields
db.users.createIndex({ age: 1 })

// Use projections to limit returned fields
db.users.find({}, { name: 1, email: 1, _id: 0 })

// Use limit for pagination
db.users.find().limit(10).skip(20)
```

## Replication Setup

For production, set up a replica set:

```yaml
mongodb-primary:
  image: mongo:7
  command: mongod --replSet rs0 --bind_ip_all
  
mongodb-secondary1:
  image: mongo:7
  command: mongod --replSet rs0 --bind_ip_all
  
mongodb-secondary2:
  image: mongo:7
  command: mongod --replSet rs0 --bind_ip_all
```

Initialize replica set:

```javascript
rs.initiate({
    _id: "rs0",
    members: [
        { _id: 0, host: "mongodb-primary:27017" },
        { _id: 1, host: "mongodb-secondary1:27017" },
        { _id: 2, host: "mongodb-secondary2:27017" }
    ]
})
```

## Troubleshooting

### Connection Issues

```bash
# Check if MongoDB is running
docker-compose ps

# Check logs
docker-compose logs mongodb

# Test connection
docker exec mongodb mongosh --eval "db.runCommand({ ping: 1 })"
```

### Authentication Errors

```bash
# Verify credentials
docker exec -it mongodb mongosh -u admin -p your_password --authenticationDatabase admin

# Check users
docker exec mongodb mongosh --eval "db.getSiblingDB('admin').getUsers()"
```

### Performance Issues

```javascript
// Check slow queries
db.system.profile.find({ millis: { $gt: 100 } }).sort({ ts: -1 }).limit(10)

// Check current operations
db.currentOp()

// Kill long-running operation
db.killOp(operationId)
```

## Production Checklist

- [ ] Enable authentication
- [ ] Use strong passwords
- [ ] Set up replica set
- [ ] Configure backups
- [ ] Enable SSL/TLS
- [ ] Set up monitoring
- [ ] Create indexes for queries
- [ ] Configure resource limits
- [ ] Set up log rotation
- [ ] Test backup restoration

## Additional Resources

- [MongoDB Documentation](https://docs.mongodb.com/)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/administration/production-checklist/)
- [MongoDB University](https://university.mongodb.com/)

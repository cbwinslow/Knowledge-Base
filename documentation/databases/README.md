# Database Documentation

Comprehensive documentation covering SQL, NoSQL, vector databases, optimization, and data management.

## 📚 Contents

### [SQL Databases](sql/)
Relational database management systems.

#### [PostgreSQL](sql/postgresql/)
- Installation and setup
- Database design
- Advanced data types (JSONB, arrays)
- Full-text search
- Extensions (PostGIS, pgvector)
- Replication and high availability
- Performance tuning
- Backup and recovery

#### [MySQL](sql/mysql/)
- Installation and configuration
- Database schema design
- Storage engines (InnoDB, MyISAM)
- Replication strategies
- Clustering
- Optimization techniques
- Security best practices

#### [SQLite](sql/sqlite/)
- Embedded database usage
- File-based storage
- Concurrent access
- Performance optimization
- Use cases
- Backup strategies

#### [Queries](sql/queries/)
- SELECT statements
- JOINs (inner, outer, cross)
- Subqueries and CTEs
- Window functions
- Aggregations
- Complex queries

#### [Indexes](sql/indexes/)
- Index types (B-tree, hash, GiST, GIN)
- Index design
- Covering indexes
- Partial indexes
- Index maintenance
- Performance impact

#### [Performance](sql/performance/)
- Query optimization
- Execution plans
- Statistics and analysis
- Connection pooling
- Caching strategies
- Partitioning

### [NoSQL Databases](nosql/)
Non-relational data stores.

#### [MongoDB](nosql/mongodb/)
- Document model
- CRUD operations
- Aggregation pipeline
- Indexing strategies
- Replication
- Sharding
- Performance tuning

#### [Redis](nosql/redis/)
- Data structures
- Persistence options
- Pub/Sub messaging
- Clustering
- Sentinel for HA
- Cache patterns
- Performance optimization

#### [Cassandra](nosql/cassandra/)
- Wide-column store
- CQL (Cassandra Query Language)
- Data modeling
- Consistency levels
- Replication strategies
- Performance tuning

#### [DynamoDB](nosql/dynamodb/)
- Table design
- Partition keys
- GSI and LSI
- DynamoDB Streams
- Capacity modes
- Best practices

#### [CouchDB](nosql/couchdb/)
- Document storage
- Map/Reduce views
- Replication
- HTTP API
- Conflict resolution

### [Vector Databases](vector_databases/)
Specialized databases for embeddings and similarity search.

#### [Pinecone](vector_databases/pinecone/)
- Index creation
- Upsert operations
- Query vectors
- Metadata filtering
- Namespaces
- Performance optimization
- Pricing and scaling

#### [Weaviate](vector_databases/weaviate/)
- Schema design
- Vector search
- Hybrid search
- Generative search
- Modules and integrations
- Deployment options

#### [Milvus](vector_databases/milvus/)
- Collection management
- Index types (HNSW, IVF)
- Query operations
- Partitioning
- Distributed deployment
- Performance tuning

#### [Qdrant](vector_databases/qdrant/)
- Collection setup
- Payload indexing
- Filtering
- Snapshots
- Clustering
- API usage

#### [Chroma](vector_databases/chroma/)
- Lightweight setup
- Collection operations
- Embedding functions
- Metadata filtering
- Client libraries
- Use cases

#### [pgvector](vector_databases/pgvector/)
- PostgreSQL extension
- Vector data types
- Index types
- Similarity search
- Performance optimization
- Integration with SQL

### [Optimization](optimization/)
Database performance tuning and best practices.

#### [Query Tuning](optimization/query_tuning/)
- Execution plan analysis
- Query rewriting
- Join optimization
- Index usage
- Statistics updates
- Parameter tuning

#### [Indexing](optimization/indexing/)
- Index strategy
- Composite indexes
- Index maintenance
- Bloom filters
- Full-text indexes
- Spatial indexes

#### [Caching](optimization/caching/)
- Query result caching
- Application-level caching
- Redis integration
- Cache invalidation
- CDN caching
- Cache warming

#### [Partitioning](optimization/partitioning/)
- Table partitioning
- Range partitioning
- List partitioning
- Hash partitioning
- Partition pruning

#### [Sharding](optimization/sharding/)
- Horizontal sharding
- Shard key selection
- Cross-shard queries
- Rebalancing
- Consistent hashing

### [Backup](backup/)
Data protection and recovery strategies.

- Backup strategies (full, incremental, differential)
- Point-in-time recovery
- Backup tools and automation
- Testing recovery procedures
- Disaster recovery planning
- Backup verification
- Cloud backup solutions

### [Migration](migration/)
Schema evolution and data migration.

- Migration tools
- Schema versioning
- Zero-downtime migrations
- Data transformation
- Rollback strategies
- Testing migrations
- Blue-green database deployment

## 🎯 Key Concepts

### Relational Databases
- **ACID**: Atomicity, Consistency, Isolation, Durability
- **Normalization**: Reducing data redundancy
- **Transactions**: Atomic operations
- **Constraints**: Data integrity
- **Indexes**: Query performance

### NoSQL Databases
- **BASE**: Basically Available, Soft state, Eventual consistency
- **CAP Theorem**: Consistency, Availability, Partition tolerance
- **Denormalization**: Query optimization
- **Eventual Consistency**: Distributed systems
- **Horizontal Scaling**: Sharding and replication

### Vector Databases
- **Embeddings**: Vector representations
- **Similarity Search**: Finding similar items
- **ANN**: Approximate Nearest Neighbor
- **HNSW**: Hierarchical Navigable Small World
- **Indexing**: Fast retrieval

## 📖 Learning Path

### Beginner
1. SQL basics (SELECT, INSERT, UPDATE, DELETE)
2. Database design fundamentals
3. Basic queries and joins
4. Primary and foreign keys
5. Simple indexing

### Intermediate
1. Complex queries and CTEs
2. Index optimization
3. Transaction management
4. Replication basics
5. NoSQL introduction

### Advanced
1. Query optimization
2. Partitioning and sharding
3. High availability setups
4. Performance tuning
5. Vector database integration

## 🛠️ Essential Tools

### SQL Tools
- pgAdmin (PostgreSQL)
- MySQL Workbench
- DBeaver (multi-database)
- DataGrip

### CLI Tools
- psql (PostgreSQL)
- mysql CLI
- mongosh (MongoDB)
- redis-cli

### Monitoring
- pg_stat_statements
- MySQL Performance Schema
- MongoDB Compass
- Redis Monitor

### Migration Tools
- Flyway
- Liquibase
- Alembic (Python)
- Prisma Migrate

## 🚀 Quick Start Examples

### PostgreSQL Query
```sql
-- Create table with indexes
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);

-- Complex query with CTE
WITH active_users AS (
    SELECT * FROM users 
    WHERE last_login > NOW() - INTERVAL '30 days'
)
SELECT name, email FROM active_users ORDER BY name;
```

### MongoDB Operations
```javascript
// Insert document
db.users.insertOne({
    name: "John Doe",
    email: "john@example.com",
    tags: ["active", "premium"],
    created_at: new Date()
});

// Aggregation pipeline
db.orders.aggregate([
    { $match: { status: "completed" } },
    { $group: { _id: "$user_id", total: { $sum: "$amount" } } },
    { $sort: { total: -1 } },
    { $limit: 10 }
]);
```

### Vector Search (Pinecone)
```python
import pinecone

# Initialize
pinecone.init(api_key="your-api-key")
index = pinecone.Index("example-index")

# Upsert vectors
index.upsert([
    ("id1", [0.1, 0.2, 0.3], {"metadata": "value"}),
    ("id2", [0.4, 0.5, 0.6], {"metadata": "value2"})
])

# Query
results = index.query(
    vector=[0.1, 0.2, 0.3],
    top_k=10,
    include_metadata=True
)
```

### Redis Caching
```python
import redis

r = redis.Redis(host='localhost', port=6379, db=0)

# Set with expiration
r.setex('key', 3600, 'value')

# Get
value = r.get('key')

# Hash operations
r.hset('user:1', mapping={'name': 'John', 'age': 30})
```

## 📊 Performance Best Practices

### Query Optimization
- Use appropriate indexes
- Avoid SELECT *
- Limit result sets
- Use prepared statements
- Analyze execution plans

### Indexing Strategy
- Index frequently queried columns
- Use covering indexes
- Maintain index statistics
- Remove unused indexes
- Monitor index usage

### Connection Management
- Use connection pooling
- Set appropriate timeouts
- Monitor connection counts
- Handle connection errors
- Close connections properly

### Caching
- Cache frequently accessed data
- Set appropriate TTLs
- Implement cache invalidation
- Use Redis for distributed caching
- Monitor cache hit rates

## 🔐 Security Best Practices

### Access Control
- Principle of least privilege
- Role-based access
- Strong authentication
- Network isolation
- Audit logging

### Data Protection
- Encryption at rest
- Encryption in transit
- Sensitive data masking
- Regular backups
- Secure backup storage

### SQL Injection Prevention
- Use parameterized queries
- Input validation
- Escape user input
- Use ORMs properly
- Regular security audits

## 🔗 Related Topics

- [Programming](../programming/) - Database libraries
- [Infrastructure](../infrastructure/) - Database hosting
- [AI & ML](../ai_ml/) - Vector databases for AI
- [DevOps](../devops/) - Database automation
- [Security](../security/) - Database security

## 📚 Resources

### Documentation
- PostgreSQL docs
- MySQL reference manual
- MongoDB manual
- Redis documentation
- Vector database docs

### Learning Platforms
- Mode Analytics (SQL tutorial)
- MongoDB University
- PostgreSQL Tutorial
- Use The Index, Luke

### Books
- "Database Internals"
- "Designing Data-Intensive Applications"
- "High Performance MySQL"
- "PostgreSQL: Up and Running"

## 🎓 Best Practices Summary

1. **Design**: Normalize appropriately, not excessively
2. **Indexing**: Index wisely, monitor usage
3. **Queries**: Write efficient, optimized queries
4. **Transactions**: Keep them short and simple
5. **Backup**: Regular, tested backups
6. **Monitoring**: Track performance metrics
7. **Security**: Encrypt and control access
8. **Scaling**: Plan for growth
9. **Documentation**: Document schema changes
10. **Testing**: Test on production-like data

## 📊 Monitoring Metrics

### Performance Metrics
- Query response time
- Throughput (QPS)
- Connection count
- Cache hit ratio
- Lock wait time

### Resource Metrics
- CPU utilization
- Memory usage
- Disk I/O
- Network bandwidth
- Storage capacity

### Health Metrics
- Replication lag
- Error rates
- Connection errors
- Slow queries
- Deadlocks

## 🚀 Advanced Topics

- Database replication
- High availability clusters
- Multi-master setups
- Cross-region deployment
- Database sharding
- Read replicas
- Connection pooling
- Query caching
- Materialized views
- Database triggers and stored procedures

# Docker Compose Stacks

Ready-to-use Docker Compose configurations for popular application stacks and development environments.

## 📚 What are Docker Compose Stacks?

Docker Compose stacks are pre-configured multi-container applications that provide:
- Development environments
- Complete application architectures
- Monitoring and logging solutions
- Database clusters
- Web application stacks

## 🎯 Available Stacks

### LAMP Stack (Linux, Apache, MySQL, PHP)
Classic web development stack:
```yaml
version: '3.8'
services:
  web:
    image: php:8.2-apache
    ports:
      - "80:80"
    volumes:
      - ./www:/var/www/html
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: app
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
```

### MEAN Stack (MongoDB, Express, Angular, Node.js)
Modern JavaScript stack:
```yaml
version: '3.8'
services:
  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
  
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      MONGODB_URI: mongodb://mongo:27017/app
    depends_on:
      - mongo
  
  frontend:
    build: ./frontend
    ports:
      - "4200:4200"
    depends_on:
      - backend

volumes:
  mongo_data:
```

### MERN Stack (MongoDB, Express, React, Node.js)
React-based JavaScript stack:
```yaml
version: '3.8'
services:
  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
  
  api:
    build: ./api
    ports:
      - "5000:5000"
    environment:
      MONGO_URL: mongodb://mongo:27017/app
      NODE_ENV: development
    depends_on:
      - mongo
  
  client:
    build: ./client
    ports:
      - "3000:3000"
    depends_on:
      - api
    stdin_open: true

volumes:
  mongo_data:
```

### ELK Stack (Elasticsearch, Logstash, Kibana)
Log aggregation and analysis:
```yaml
version: '3.8'
services:
  elasticsearch:
    image: elasticsearch:8.11.0
    environment:
      - discovery.type=single-node
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data
  
  logstash:
    image: logstash:8.11.0
    ports:
      - "5000:5000"
      - "9600:9600"
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch
  
  kibana:
    image: kibana:8.11.0
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

volumes:
  es_data:
```

### Prometheus + Grafana Stack
Monitoring and visualization:
```yaml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
  
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
  
  node-exporter:
    image: prom/node-exporter:latest
    ports:
      - "9100:9100"

volumes:
  prometheus_data:
  grafana_data:
```

### PostgreSQL + pgAdmin Stack
Database management:
```yaml
version: '3.8'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: admin
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  pgadmin:
    image: dpage/pgadmin4:latest
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@admin.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - postgres

volumes:
  postgres_data:
```

### Redis + RedisInsight Stack
Caching and data structure store:
```yaml
version: '3.8'
services:
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
  
  redis-insight:
    image: redislabs/redisinsight:latest
    ports:
      - "8001:8001"
    depends_on:
      - redis

volumes:
  redis_data:
```

### WordPress Stack
CMS platform:
```yaml
version: '3.8'
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: wordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db_data:/var/lib/mysql
  
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wp_data:/var/www/html
    depends_on:
      - db

volumes:
  db_data:
  wp_data:
```

### Nginx Reverse Proxy Stack
Load balancing and reverse proxy:
```yaml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certs:/etc/nginx/certs
    depends_on:
      - app1
      - app2
  
  app1:
    image: nginx:alpine
    expose:
      - "80"
  
  app2:
    image: nginx:alpine
    expose:
      - "80"
```

### AI/ML Development Stack
Machine learning development environment:
```yaml
version: '3.8'
services:
  jupyter:
    image: jupyter/tensorflow-notebook:latest
    ports:
      - "8888:8888"
    volumes:
      - ./notebooks:/home/jovyan/work
      - ./data:/home/jovyan/data
  
  mlflow:
    image: ghcr.io/mlflow/mlflow:latest
    ports:
      - "5000:5000"
    volumes:
      - mlflow_data:/mlflow
    command: mlflow server --host 0.0.0.0 --backend-store-uri /mlflow
  
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: mlflow
      POSTGRES_USER: mlflow
      POSTGRES_PASSWORD: mlflow
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  mlflow_data:
  postgres_data:
```

## 🚀 Quick Start

### Using a Stack

1. **Choose a stack** from above
2. **Create docker-compose.yml** in your project directory
3. **Start the stack**:
```bash
docker-compose up -d
```

4. **View logs**:
```bash
docker-compose logs -f
```

5. **Stop the stack**:
```bash
docker-compose down
```

### Customizing Stacks

1. **Copy the configuration** to your project
2. **Modify services** as needed
3. **Add environment variables**
4. **Configure volumes** for persistence
5. **Test thoroughly**

## 📊 Best Practices

### Configuration
- Use environment variables
- Externalize configuration
- Version your compose files
- Document customizations
- Use named volumes

### Security
- Don't use default passwords
- Use secrets management
- Limit network exposure
- Regular security updates
- Scan images for vulnerabilities

### Performance
- Set resource limits
- Use health checks
- Optimize image sizes
- Implement caching
- Monitor resource usage

### Development
- Use .env files
- Mount code volumes
- Hot-reload support
- Debug configurations
- Test data fixtures

## 🔧 Common Patterns

### Health Checks
```yaml
services:
  web:
    image: nginx:alpine
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Depends On with Conditions
```yaml
services:
  web:
    depends_on:
      db:
        condition: service_healthy
```

### Resource Limits
```yaml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

### Networks
```yaml
networks:
  frontend:
  backend:

services:
  web:
    networks:
      - frontend
  api:
    networks:
      - frontend
      - backend
  db:
    networks:
      - backend
```

## 📚 Resources

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Awesome Compose](https://github.com/docker/awesome-compose)
- [Docker Hub](https://hub.docker.com/)
- Community examples

## 🔗 Related Topics

- [Docker Basics](../../basics/)
- [Dockerfile Best Practices](../../dockerfile/)
- [Docker Compose Examples](../examples/)
- [Container Orchestration](../../../kubernetes/)

## 💡 Pro Tips

1. Use `.env` files for environment variables
2. Implement health checks
3. Use named volumes for data persistence
4. Set resource limits
5. Document your stack
6. Version control your configurations
7. Test stack startup order
8. Monitor container health

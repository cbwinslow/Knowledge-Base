# Examples & Scripts

Working code examples, automation scripts, and practical implementations across various domains.

## 📚 Contents

### [Automation](automation/)
Scripts for automating common tasks.

#### System Automation
- File organization scripts
- Backup automation
- Log rotation
- System maintenance
- Cleanup scripts
- Scheduled tasks
- Health checks

#### Development Automation
- Build automation
- Test automation
- Deployment scripts
- Release automation
- Code generation
- Database migrations
- Environment setup

#### DevOps Automation
- CI/CD pipelines
- Infrastructure provisioning
- Configuration management
- Monitoring setup
- Alert management
- Incident response
- Reporting automation

### [Deployment](deployment/)
Deployment scripts and configurations.

#### Application Deployment
- Blue-green deployment
- Canary releases
- Rolling updates
- Docker deployments
- Kubernetes manifests
- Serverless deployment
- Static site deployment

#### Infrastructure Deployment
- Terraform examples
- CloudFormation templates
- Ansible playbooks
- Pulumi programs
- Docker Compose stacks
- Kubernetes operators

#### Database Deployment
- Migration scripts
- Seed data scripts
- Backup scripts
- Replication setup
- Failover scripts
- Performance tuning

### [Monitoring](monitoring/)
Monitoring and observability scripts.

#### Metrics Collection
- Custom exporters
- Log aggregation
- Health check scripts
- Performance monitoring
- Resource tracking
- Alert scripts

#### Visualization
- Grafana dashboards
- Prometheus queries
- Custom dashboards
- Report generation
- Alerting rules

#### Analysis Scripts
- Log analysis
- Performance analysis
- Trend detection
- Anomaly detection
- Capacity planning

### [Data Processing](data_processing/)
Data manipulation and ETL scripts.

#### Data Extraction
- Web scraping
- API data fetching
- Database extraction
- File parsing
- Stream processing

#### Data Transformation
- Data cleaning
- Format conversion
- Aggregation
- Normalization
- Enrichment

#### Data Loading
- Database loading
- File writing
- API posting
- Stream output
- Batch processing

#### ETL Pipelines
- Complete ETL examples
- Incremental processing
- Error handling
- Monitoring integration
- Scheduling

### [API Examples](api_examples/)
Working API integration examples.

#### REST APIs
- CRUD operations
- Authentication
- Pagination
- Error handling
- Rate limiting
- Caching
- Webhooks

#### GraphQL APIs
- Query examples
- Mutation examples
- Subscription examples
- Error handling
- Batching
- Caching

#### Platform APIs
- GitHub API examples
- AWS API examples
- OpenAI API examples
- Stripe API examples
- Twilio API examples
- SendGrid API examples

## 🚀 Quick Start Examples

### Python Automation Script
```python
#!/usr/bin/env python3
"""
Automated file organizer
Organizes files in a directory by extension
"""
import os
import shutil
from pathlib import Path

def organize_files(directory):
    """Organize files by extension"""
    directory = Path(directory)
    
    for file_path in directory.iterdir():
        if file_path.is_file():
            # Get file extension
            extension = file_path.suffix[1:] or 'no_extension'
            
            # Create directory for extension
            target_dir = directory / extension
            target_dir.mkdir(exist_ok=True)
            
            # Move file
            shutil.move(str(file_path), str(target_dir / file_path.name))
            print(f"Moved {file_path.name} to {extension}/")

if __name__ == "__main__":
    organize_files("./downloads")
```

### Bash Backup Script
```bash
#!/bin/bash
# Automated backup script with rotation

BACKUP_DIR="/backups"
SOURCE_DIR="/data"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}.tar.gz"
RETENTION_DAYS=7

# Create backup
tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" "${SOURCE_DIR}"

# Verify backup
if [ $? -eq 0 ]; then
    echo "Backup created successfully: ${BACKUP_NAME}"
    
    # Remove old backups
    find "${BACKUP_DIR}" -name "backup_*.tar.gz" -mtime +${RETENTION_DAYS} -delete
    echo "Old backups removed (older than ${RETENTION_DAYS} days)"
else
    echo "Backup failed!"
    exit 1
fi
```

### Docker Deployment Script
```bash
#!/bin/bash
# Blue-green deployment script

set -e

# Configuration
APP_NAME="myapp"
BLUE_CONTAINER="${APP_NAME}_blue"
GREEN_CONTAINER="${APP_NAME}_green"
IMAGE="myapp:latest"
PORT=8080

# Determine current active container
ACTIVE=$(docker ps --filter "name=${BLUE_CONTAINER}" --filter "status=running" -q)
if [ -n "$ACTIVE" ]; then
    NEW_CONTAINER=$GREEN_CONTAINER
    OLD_CONTAINER=$BLUE_CONTAINER
else
    NEW_CONTAINER=$BLUE_CONTAINER
    OLD_CONTAINER=$GREEN_CONTAINER
fi

echo "Deploying to ${NEW_CONTAINER}..."

# Start new container
docker run -d --name ${NEW_CONTAINER} -p ${PORT}:80 ${IMAGE}

# Health check
sleep 5
if curl -f http://localhost:${PORT}/health; then
    echo "Health check passed"
    
    # Stop old container
    docker stop ${OLD_CONTAINER} 2>/dev/null || true
    docker rm ${OLD_CONTAINER} 2>/dev/null || true
    
    echo "Deployment successful!"
else
    echo "Health check failed, rolling back..."
    docker stop ${NEW_CONTAINER}
    docker rm ${NEW_CONTAINER}
    exit 1
fi
```

### Kubernetes Deployment
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
  labels:
    app: webapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: myapp:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: webapp-service
spec:
  type: LoadBalancer
  selector:
    app: webapp
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

### Python API Client
```python
"""
Generic API client with retry logic and error handling
"""
import requests
from typing import Optional, Dict, Any
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class APIClient:
    def __init__(self, base_url: str, api_key: str, timeout: int = 30):
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.session = requests.Session()
        
        # Configure retry strategy
        retry_strategy = Retry(
            total=3,
            backoff_factor=1,
            status_forcelist=[429, 500, 502, 503, 504],
            allowed_methods=["HEAD", "GET", "OPTIONS", "POST"]
        )
        adapter = HTTPAdapter(max_retries=retry_strategy)
        self.session.mount("http://", adapter)
        self.session.mount("https://", adapter)
        
        # Set headers
        self.session.headers.update({
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        })
    
    def get(self, endpoint: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """Make GET request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = self.session.get(url, params=params, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"GET request failed: {e}")
            raise
    
    def post(self, endpoint: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Make POST request"""
        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        try:
            response = self.session.post(url, json=data, timeout=self.timeout)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"POST request failed: {e}")
            raise

# Usage
client = APIClient("https://api.example.com", "your-api-key")
data = client.get("/users", params={"limit": 10})
```

### Terraform AWS Example
```hcl
# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "web-server"
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}
```

### Prometheus Monitoring Config
```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - alertmanager:9093

# Load rules
rule_files:
  - "alerts.yml"

# Scrape configurations
scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node exporter
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  # Application metrics
  - job_name: 'app'
    static_configs:
      - targets: ['app:8080']
    metrics_path: '/metrics'

# alerts.yml
groups:
  - name: example
    rules:
    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
        description: "Memory usage is above 90% for 5 minutes"
```

## 📊 Categories

### By Language
- Python scripts
- Bash scripts
- JavaScript/Node.js
- Go programs
- Rust programs
- PowerShell scripts

### By Domain
- DevOps automation
- Data processing
- API integration
- System administration
- Cloud operations
- Database management

### By Complexity
- Beginner examples
- Intermediate scripts
- Advanced implementations
- Production-ready code

## 🎯 Best Practices

### Script Development
1. **Error handling**: Handle all error cases
2. **Logging**: Comprehensive logging
3. **Configuration**: Externalize config
4. **Documentation**: Clear comments
5. **Testing**: Test thoroughly
6. **Idempotency**: Safe to rerun
7. **Security**: No hardcoded secrets

### Code Organization
```
project/
├── README.md
├── requirements.txt or package.json
├── .env.example
├── src/
│   ├── __init__.py
│   ├── main.py
│   └── utils.py
├── tests/
│   └── test_main.py
├── config/
│   └── config.yaml
└── docs/
    └── usage.md
```

## 🔗 Related Topics

- [Programming](../programming/) - Language guides
- [DevOps](../devops/) - Automation practices
- [Infrastructure](../infrastructure/) - Infrastructure code
- [Tips & Tricks](../tips_tricks_usage/) - Usage tips

## 📚 Additional Resources

- GitHub repositories
- Official documentation
- Community examples
- Video tutorials
- Blog posts
- Stack Overflow

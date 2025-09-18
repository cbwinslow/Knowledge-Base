#!/bin/bash

# AI Monitoring System Setup Script
# This script sets up a comprehensive AI-powered monitoring and audit system

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ] && [ -z "$SUDO_USER" ]; then
        error "Please run as root or with sudo"
        exit 1
    fi
    log "Running with sufficient privileges"
}

# Check system resources
check_resources() {
    log "Checking system resources..."
    
    # Check available RAM
    AVAILABLE_RAM=$(free -g | awk '/^Mem:/{print $7}')
    if [ "$AVAILABLE_RAM" -lt 16 ]; then
        warning "Recommended minimum RAM is 16GB, you have ${AVAILABLE_RAM}GB"
    else
        success "Sufficient RAM available: ${AVAILABLE_RAM}GB"
    fi
    
    # Check available disk space
    AVAILABLE_DISK=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [ "$AVAILABLE_DISK" -lt 20 ]; then
        warning "Recommended minimum disk space is 20GB, you have ${AVAILABLE_DISK}GB"
    else
        success "Sufficient disk space available: ${AVAILABLE_DISK}GB"
    fi
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    # Update package lists
    apt-get update
    
    # Install required packages
    apt-get install -y \
        docker.io \
        docker-compose \
        curl \
        wget \
        git \
        python3 \
        python3-pip \
        jq \
        net-tools \
        sysstat \
        htop \
        iotop \
        iftop
    
    success "Required packages installed"
}

# Setup Docker permissions
setup_docker() {
    log "Setting up Docker permissions..."
    
    # Add current user to docker group
    USER_NAME=$(logname 2>/dev/null || echo $SUDO_USER)
    if [ -n "$USER_NAME" ] && [ "$USER_NAME" != "root" ]; then
        usermod -aG docker "$USER_NAME"
        success "Added $USER_NAME to docker group"
    fi
    
    # Start Docker service
    systemctl start docker
    systemctl enable docker
    
    success "Docker setup complete"
}

# Create directory structure
create_directories() {
    log "Creating directory structure..."
    
    mkdir -p /opt/ai_monitoring/{prometheus,grafana,alertmanager,init-scripts,grafana/provisioning,dashboards}
    
    # Set permissions
    chmod -R 755 /opt/ai_monitoring
    chown -R root:root /opt/ai_monitoring
    
    success "Directory structure created"
}

# Deploy core monitoring stack
deploy_core_stack() {
    log "Deploying core monitoring stack..."
    
    # Copy configuration files
    cp -r /home/cbwinslow/ai_monitoring/* /opt/ai_monitoring/
    
    # Navigate to the directory
    cd /opt/ai_monitoring
    
    # Start the services
    docker-compose -f /home/cbwinslow/docker-compose.core.yml up -d
    
    success "Core monitoring stack deployed"
}

# Setup system logging
setup_system_logging() {
    log "Setting up system logging..."
    
    # Install auditd if not present
    if ! command -v auditctl &> /dev/null; then
        apt-get install -y auditd
    fi
    
    # Configure audit rules
    cat > /etc/audit/rules.d/ai-monitoring.rules << EOF
# AI Monitoring Audit Rules

# Monitor all system calls
-a always,exit -F arch=b64 -S execve,execveat -k system_exec
-a always,exit -F arch=b32 -S execve -k system_exec

# Monitor file access
-w /etc/passwd -p wa -k etc_changes
-w /etc/shadow -p wa -k etc_changes
-w /etc/group -p wa -k etc_changes

# Monitor network connections
-a always,exit -F arch=b64 -S connect,bind,accept,accept4 -k network
-a always,exit -F arch=b32 -S connect,bind,accept,accept4 -k network

# Monitor SSH access
-w /usr/sbin/sshd -p x -k ssh
-w /var/log/auth.log -p wa -k auth_log

# Monitor sudo usage
-w /usr/bin/sudo -p x -k sudo
-w /var/log/sudo-io -p wa -k sudo_log

# Monitor database access
-w /var/lib/postgresql -p wa -k database
EOF
    
    # Restart auditd to apply rules
    systemctl restart auditd
    
    success "System logging configured"
}

# Install AI services
install_ai_services() {
    log "Installing AI services..."
    
    # Create AI services directory
    mkdir -p /opt/ai_services
    
    # For now, we'll just create a placeholder script
    # In a full implementation, we would install LocalAI, Ollama, etc.
    cat > /opt/ai_services/install_ai.sh << 'EOF'
#!/bin/bash
# Placeholder script for AI service installation

echo "AI services installation placeholder"
echo "In a full implementation, this would install:"
echo "- LocalAI"
echo "- Ollama"
echo "- Qwen Coder"
echo "- Mistral/Mixtral models"
echo "- Sentence Transformers"
EOF
    
    chmod +x /opt/ai_services/install_ai.sh
    
    success "AI services placeholder created"
}

# Setup security monitoring
setup_security_monitoring() {
    log "Setting up security monitoring..."
    
    # Install Fail2Ban
    apt-get install -y fail2ban
    
    # Configure Fail2Ban for our services
    cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 3

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 10m

[grafana]
enabled = true
port = 3000
filter = grafana
logpath = /var/log/grafana/grafana.log
maxretry = 5

[postgresql]
enabled = true
port = 5432
filter = postgresql
logpath = /var/log/postgresql/postgresql-*.log
maxretry = 5
EOF
    
    # Restart Fail2Ban
    systemctl restart fail2ban
    
    success "Security monitoring configured"
}

# Create monitoring agents
create_monitoring_agents() {
    log "Creating monitoring agents..."
    
    # Create agents directory
    mkdir -p /opt/ai_agents/{system,security,healing,reporting}
    
    # Create a basic system monitoring agent
    cat > /opt/ai_agents/system/basic_monitor.py << 'EOF'
#!/usr/bin/env python3
"""
Basic System Monitoring Agent
"""

import psutil
import time
import json
import pika
import logging
from datetime import datetime

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SystemMonitorAgent:
    def __init__(self, rabbitmq_host='localhost'):
        self.rabbitmq_host = rabbitmq_host
        self.connection = None
        self.channel = None
        self.connect_to_rabbitmq()
    
    def connect_to_rabbitmq(self):
        """Connect to RabbitMQ"""
        try:
            self.connection = pika.BlockingConnection(
                pika.ConnectionParameters(self.rabbitmq_host)
            )
            self.channel = self.connection.channel()
            self.channel.queue_declare(queue='system_metrics', durable=True)
            logger.info("Connected to RabbitMQ")
        except Exception as e:
            logger.error(f"Failed to connect to RabbitMQ: {e}")
    
    def collect_metrics(self):
        """Collect system metrics"""
        metrics = {
            'timestamp': datetime.utcnow().isoformat(),
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory_percent': psutil.virtual_memory().percent,
            'disk_usage': psutil.disk_usage('/').percent,
            'network_io': dict(psutil.net_io_counters()._asdict()),
            'load_average': psutil.getloadavg()
        }
        return metrics
    
    def send_metrics(self, metrics):
        """Send metrics to RabbitMQ"""
        try:
            self.channel.basic_publish(
                exchange='',
                routing_key='system_metrics',
                body=json.dumps(metrics),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Make message persistent
                )
            )
            logger.info("Metrics sent to RabbitMQ")
        except Exception as e:
            logger.error(f"Failed to send metrics: {e}")
    
    def run(self):
        """Main monitoring loop"""
        logger.info("System Monitor Agent started")
        try:
            while True:
                metrics = self.collect_metrics()
                self.send_metrics(metrics)
                time.sleep(60)  # Collect every minute
        except KeyboardInterrupt:
            logger.info("Agent stopped by user")
        except Exception as e:
            logger.error(f"Agent error: {e}")
        finally:
            if self.connection and not self.connection.is_closed:
                self.connection.close()

if __name__ == "__main__":
    agent = SystemMonitorAgent()
    agent.run()
EOF
    
    # Install required Python packages
    pip3 install psutil pika
    
    success "Monitoring agents created"
}

# Setup log collection
setup_log_collection() {
    log "Setting up log collection..."
    
    # Install Filebeat for log shipping
    curl -L -O https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.15.0-amd64.deb
    dpkg -i filebeat-8.15.0-amd64.deb
    
    # Configure Filebeat to send logs to Graylog
    cat > /etc/filebeat/filebeat.yml << EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/*/*.log
  fields:
    system: ai_monitoring
  fields_under_root: true

output.logstash:
  hosts: ["localhost:5044"]

processors:
  - add_host_metadata: ~
  - add_cloud_metadata: ~
EOF
    
    # Enable and start Filebeat
    systemctl enable filebeat
    systemctl start filebeat
    
    success "Log collection configured"
}

# Create status checker
create_status_checker() {
    log "Creating status checker..."
    
    cat > /opt/ai_monitoring/check_status.sh << 'EOF'
#!/bin/bash
# AI Monitoring System Status Checker

echo "=== AI Monitoring System Status ==="
echo ""

# Check Docker services
echo "Docker Services Status:"
docker-compose -f /home/cbwinslow/docker-compose.core.yml ps
echo ""

# Check if services are responding
echo "Service Health Check:"
SERVICES=(
    "http://localhost:9090/api/v1/status/buildinfo|Prometheus"
    "http://localhost:3000/api/health|Grafana"
    "http://localhost:9200|OpenSearch"
    "http://localhost:9000/api/system/status|Graylog"
    "http://localhost:5672|Redis"
    "http://localhost:15672|RaabbitMQ Management"
)

for service in "${SERVICES[@]}"; do
    URL=$(echo $service | cut -d'|' -f1)
    NAME=$(echo $service | cut -d'|' -f2)
    
    if curl -s --connect-timeout 5 $URL > /dev/null; then
        echo "✅ $NAME: UP"
    else
        echo "❌ $NAME: DOWN"
    fi
done

echo ""
echo "=== System Resources ==="
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
EOF
    
    chmod +x /opt/ai_monitoring/check_status.sh
    
    success "Status checker created"
}

# Create main setup function
main() {
    log "Starting AI Monitoring System Setup"
    
    check_root
    check_resources
    create_directories
    setup_docker
    deploy_core_stack
    setup_system_logging
    install_ai_services
    setup_security_monitoring
    create_monitoring_agents
    setup_log_collection
    create_status_checker
    
    echo ""
    success "AI Monitoring System Setup Complete!"
    echo ""
    echo "Next steps:"
    echo "1. Check service status: /opt/ai_monitoring/check_status.sh"
    echo "2. Access Grafana at http://localhost:3000 (admin/secure_password_change_me)"
    echo "3. Access Graylog at http://localhost:9000 (admin/admin)"
    echo "4. Access OpenSearch at http://localhost:9200"
    echo "5. Access RabbitMQ Management at http://localhost:15672 (admin/secure_password_change_me)"
    echo ""
    echo "Important: Change default passwords in docker-compose.core.yml"
    echo "Important: Review and customize configuration files in /opt/ai_monitoring/"
}

# Run main function
main
#!/usr/bin/env bash
#===============================================================================
# ████████╗███████╗██████╗ ███████╗██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗
# ╚══██╔══╝██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║
#    ██║   █████╗  ██████╔╝█████╗  ██████╔╝███████║   ██║   ██║██║   ██║██╔██╗ ██║
#    ██║   ██╔══╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██║   ██║   ██║██║   ██║██║╚██╗██║
#    ██║   ███████╗██║  ██║███████╗██████╔╝██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║
#    ╚═╝   ╚══════╝╚═╝  ╚═╝╚══════╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
#===============================================================================
# File: create_terraform_config.sh
# Description: Create Terraform configuration for CBW setup using IaC principles
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Creating Terraform Configuration for CBW Setup${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

create_terraform_structure() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Terraform structure${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create directories
    mkdir -p /home/cbwinslow/cbw_terraform/{modules,environments/{dev,staging,prod},scripts}
    
    info "Created Terraform directory structure"
}

create_main_tf() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating main Terraform files${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_terraform/main.tf <<'EOF'
# CBW Infrastructure as Code - Main Configuration
# This file defines the overall infrastructure setup

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
  
  # Backend configuration for state management
  # Uncomment and configure for remote state
  # backend "s3" {
  #   bucket = "cbw-terraform-state"
  #   key    = "cbw-setup/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

# Provider configuration
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Local variables from configuration
locals {
  # Load configuration from variables
  server_hostname = var.server_hostname
  server_ip       = var.server_ip
  
  # Service ports (using non-conflicting ports)
  ports = {
    grafana           = 3001  # Changed from 3000
    prometheus        = 9091  # Changed from 9090
    postgresql        = 5433  # Changed from 5432
    cadvisor          = 8081  # Changed from 8080
    qdrant_http       = 6333
    qdrant_grpc       = 6334
    mongodb           = 27017
    opensearch        = 9200
    opensearch_monitoring = 9600
    rabbitmq          = 5672
    rabbitmq_management = 15672
    kong_proxy        = 8000
    kong_proxy_ssl    = 8443
    kong_admin        = 8001
    kong_admin_ssl    = 8444
    loki              = 3100
    dcgm_exporter     = 9400
  }
}

# Docker networks
resource "docker_network" "cbw_network" {
  name   = "cbw-network"
  driver = "bridge"
  
  ipam_config {
    subnet = "172.20.0.0/16"
  }
}

# Include modules for different service groups
module "databases" {
  source = "./modules/databases"
  
  network_id = docker_network.cbw_network.id
  ports      = local.ports
}

module "monitoring" {
  source = "./modules/monitoring"
  
  network_id = docker_network.cbw_network.id
  ports      = local.ports
}

module "api_gateway" {
  source = "./modules/api_gateway"
  
  network_id = docker_network.cbw_network.id
  ports      = local.ports
}

# Outputs
output "server_hostname" {
  value = local.server_hostname
}

output "service_endpoints" {
  value = {
    grafana      = "http://localhost:${local.ports.grafana}"
    prometheus   = "http://localhost:${local.ports.prometheus}"
    postgresql   = "localhost:${local.ports.postgresql}"
    qdrant       = "http://localhost:${local.ports.qdrant_http}"
    mongodb      = "localhost:${local.ports.mongodb}"
    opensearch   = "http://localhost:${local.ports.opensearch}"
    kong_proxy   = "http://localhost:${local.ports.kong_proxy}"
    kong_admin   = "http://localhost:${local.ports.kong_admin}"
    loki         = "http://localhost:${local.ports.loki}"
  }
  description = "Service endpoints for accessing various components"
}
EOF
    
    info "Created main.tf"
}

create_variables_tf() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating variables file${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_terraform/variables.tf <<'EOF'
# CBW Infrastructure Variables

variable "server_hostname" {
  description = "Server hostname"
  type        = string
  default     = "cbwserver"
}

variable "server_ip" {
  description = "Server IP address"
  type        = string
  default     = "192.168.4.117"
}

variable "region" {
  description = "Deployment region"
  type        = string
  default     = "local"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "development"
}

variable "docker_image_tag" {
  description = "Docker image tag to use"
  type        = string
  default     = "latest"
}
EOF
    
    info "Created variables.tf"
}

create_outputs_tf() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating outputs file${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_terraform/outputs.tf <<'EOF'
# CBW Infrastructure Outputs

output "infrastructure_summary" {
  value = {
    hostname    = var.server_hostname
    ip          = var.server_ip
    environment = var.environment
    region      = var.region
  }
  description = "Basic infrastructure information"
}

output "deployment_status" {
  value = "CBW infrastructure deployment completed successfully"
  description = "Deployment status message"
}
EOF
    
    info "Created outputs.tf"
}

create_databases_module() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating databases module${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_terraform/modules/databases
    
    cat > /home/cbwinslow/cbw_terraform/modules/databases/variables.tf <<'EOF'
variable "network_id" {
  description = "Docker network ID"
  type        = string
}

variable "ports" {
  description = "Service ports mapping"
  type        = map(number)
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/databases/main.tf <<'EOF'
# Databases Module

resource "docker_image" "postgres" {
  name = "postgres:16"
  
  provisioner "local-exec" {
    command = "echo 'Pulling PostgreSQL image...'"
  }
}

resource "docker_container" "postgres" {
  image = docker_image.postgres.name
  name  = "cbw-postgres"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 5432
    external = var.ports.postgresql
  }
  
  env = [
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_USER=postgres",
    "POSTGRES_DB=app"
  ]
  
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.postgres_data.name
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "postgres_data" {
  name = "cbw-postgres-data"
}

resource "docker_image" "qdrant" {
  name = "qdrant/qdrant:latest"
}

resource "docker_container" "qdrant" {
  image = docker_image.qdrant.name
  name  = "cbw-qdrant"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 6333
    external = var.ports.qdrant_http
  }
  
  ports {
    internal = 6334
    external = var.ports.qdrant_grpc
  }
  
  volumes {
    container_path = "/qdrant/storage"
    volume_name    = docker_volume.qdrant_data.name
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "qdrant_data" {
  name = "cbw-qdrant-data"
}

resource "docker_image" "mongodb" {
  name = "mongo:7"
}

resource "docker_container" "mongodb" {
  image = docker_image.mongodb.name
  name  = "cbw-mongodb"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 27017
    external = var.ports.mongodb
  }
  
  volumes {
    container_path = "/data/db"
    volume_name    = docker_volume.mongodb_data.name
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "mongodb_data" {
  name = "cbw-mongodb-data"
}

resource "docker_image" "opensearch" {
  name = "opensearchproject/opensearch:2.17.1"
}

resource "docker_container" "opensearch" {
  image = docker_image.opensearch.name
  name  = "cbw-opensearch"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 9200
    external = var.ports.opensearch
  }
  
  ports {
    internal = 9600
    external = var.ports.opensearch_monitoring
  }
  
  env = [
    "discovery.type=single-node",
    "bootstrap.memory_lock=true",
    "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
  ]
  
  volumes {
    container_path = "/usr/share/opensearch/data"
    volume_name    = docker_volume.opensearch_data.name
  }
  
  ulimit {
    name = "memlock"
    hard = -1
    soft = -1
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "opensearch_data" {
  name = "cbw-opensearch-data"
}

resource "docker_image" "rabbitmq" {
  name = "rabbitmq:3-management"
}

resource "docker_container" "rabbitmq" {
  image = docker_image.rabbitmq.name
  name  = "cbw-rabbitmq"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 5672
    external = var.ports.rabbitmq
  }
  
  ports {
    internal = 15672
    external = var.ports.rabbitmq_management
  }
  
  restart = "unless-stopped"
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/databases/outputs.tf <<'EOF'
output "database_containers" {
  value = {
    postgres = docker_container.postgres.name
    qdrant   = docker_container.qdrant.name
    mongodb  = docker_container.mongodb.name
    opensearch = docker_container.opensearch.name
    rabbitmq = docker_container.rabbitmq.name
  }
}

output "database_ports" {
  value = {
    postgresql = var.ports.postgresql
    qdrant_http = var.ports.qdrant_http
    qdrant_grpc = var.ports.qdrant_grpc
    mongodb    = var.ports.mongodb
    opensearch = var.ports.opensearch
    rabbitmq   = var.ports.rabbitmq
  }
}
EOF
    
    info "Created databases module"
}

create_monitoring_module() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating monitoring module${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_terraform/modules/monitoring
    
    cat > /home/cbwinslow/cbw_terraform/modules/monitoring/variables.tf <<'EOF'
variable "network_id" {
  description = "Docker network ID"
  type        = string
}

variable "ports" {
  description = "Service ports mapping"
  type        = map(number)
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/monitoring/main.tf <<'EOF'
# Monitoring Module

resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
}

resource "docker_container" "prometheus" {
  image = docker_image.prometheus.name
  name  = "cbw-prometheus"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 9090
    external = var.ports.prometheus
  }
  
  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = "/home/cbwinslow/cbw_terraform/configs/prometheus.yml"
    read_only      = true
  }
  
  restart = "unless-stopped"
}

resource "docker_image" "grafana" {
  name = "grafana/grafana:latest"
}

resource "docker_container" "grafana" {
  image = docker_image.grafana.name
  name  = "cbw-grafana"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 3000
    external = var.ports.grafana
  }
  
  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]
  
  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "grafana_data" {
  name = "cbw-grafana-data"
}

resource "docker_image" "loki" {
  name = "grafana/loki:2.9.8"
}

resource "docker_container" "loki" {
  image = docker_image.loki.name
  name  = "cbw-loki"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 3100
    external = var.ports.loki
  }
  
  command = ["-config.file=/etc/loki/local-config.yaml"]
  
  volumes {
    container_path = "/etc/loki/local-config.yaml"
    host_path      = "/home/cbwinslow/cbw_terraform/configs/loki-config.yaml"
    read_only      = true
  }
  
  restart = "unless-stopped"
}

resource "docker_image" "promtail" {
  name = "grafana/promtail:2.9.8"
}

resource "docker_container" "promtail" {
  image = docker_image.promtail.name
  name  = "cbw-promtail"
  
  networks_advanced {
    name = var.network_id
  }
  
  volumes {
    container_path = "/var/log"
    host_path      = "/var/log"
    read_only      = true
  }
  
  volumes {
    container_path = "/var/lib/docker/containers"
    host_path      = "/var/lib/docker/containers"
    read_only      = true
  }
  
  volumes {
    container_path = "/etc/promtail/config.yml"
    host_path      = "/home/cbwinslow/cbw_terraform/configs/promtail-config.yaml"
    read_only      = true
  }
  
  command = ["-config.file=/etc/promtail/config.yml"]
  
  restart = "unless-stopped"
}

resource "docker_image" "cadvisor" {
  name = "gcr.io/cadvisor/cadvisor:latest"
}

resource "docker_container" "cadvisor" {
  image = docker_image.cadvisor.name
  name  = "cbw-cadvisor"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 8080
    external = var.ports.cadvisor
  }
  
  privileged = true
  
  volumes {
    container_path = "/rootfs"
    host_path      = "/"
    read_only      = true
  }
  
  volumes {
    container_path = "/var/run"
    host_path      = "/var/run"
    read_only      = false
  }
  
  volumes {
    container_path = "/sys"
    host_path      = "/sys"
    read_only      = true
  }
  
  volumes {
    container_path = "/var/lib/docker"
    host_path      = "/var/lib/docker"
    read_only      = true
  }
  
  volumes {
    container_path = "/dev/disk"
    host_path      = "/dev/disk"
    read_only      = true
  }
  
  restart = "unless-stopped"
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/monitoring/outputs.tf <<'EOF'
output "monitoring_containers" {
  value = {
    prometheus = docker_container.prometheus.name
    grafana    = docker_container.grafana.name
    loki       = docker_container.loki.name
    promtail   = docker_container.promtail.name
    cadvisor   = docker_container.cadvisor.name
  }
}

output "monitoring_ports" {
  value = {
    prometheus = var.ports.prometheus
    grafana    = var.ports.grafana
    loki       = var.ports.loki
    cadvisor   = var.ports.cadvisor
  }
}
EOF
    
    info "Created monitoring module"
}

create_api_gateway_module() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating API gateway module${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_terraform/modules/api_gateway
    
    cat > /home/cbwinslow/cbw_terraform/modules/api_gateway/variables.tf <<'EOF'
variable "network_id" {
  description = "Docker network ID"
  type        = string
}

variable "ports" {
  description = "Service ports mapping"
  type        = map(number)
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/api_gateway/main.tf <<'EOF'
# API Gateway Module (Kong)

resource "docker_image" "kong_db" {
  name = "postgres:16"
}

resource "docker_container" "kong_db" {
  image = docker_image.kong_db.name
  name  = "cbw-kong-db"
  
  networks_advanced {
    name = var.network_id
  }
  
  env = [
    "POSTGRES_DB=kong",
    "POSTGRES_USER=kong",
    "POSTGRES_PASSWORD=kong"
  ]
  
  volumes {
    container_path = "/var/lib/postgresql/data"
    volume_name    = docker_volume.kong_db.name
  }
  
  restart = "unless-stopped"
}

resource "docker_volume" "kong_db" {
  name = "cbw-kong-db"
}

resource "docker_image" "kong" {
  name = "kong:3.7"
}

resource "docker_container" "kong_migration" {
  image = docker_image.kong.name
  name  = "cbw-kong-migration"
  
  networks_advanced {
    name = var.network_id
  }
  
  env = [
    "KONG_DATABASE=postgres",
    "KONG_PG_HOST=cbw-kong-db",
    "KONG_PG_USER=kong",
    "KONG_PG_PASSWORD=kong",
    "KONG_PASSWORD=admin"
  ]
  
  command = ["kong", "migrations", "bootstrap"]
  
  depends_on = [docker_container.kong_db]
  
  restart = "no"
}

resource "docker_container" "kong" {
  image = docker_image.kong.name
  name  = "cbw-kong"
  
  networks_advanced {
    name = var.network_id
  }
  
  ports {
    internal = 8000
    external = var.ports.kong_proxy
  }
  
  ports {
    internal = 8443
    external = var.ports.kong_proxy_ssl
  }
  
  ports {
    internal = 8001
    external = var.ports.kong_admin
  }
  
  ports {
    internal = 8444
    external = var.ports.kong_admin_ssl
  }
  
  env = [
    "KONG_DATABASE=postgres",
    "KONG_PG_HOST=cbw-kong-db",
    "KONG_PG_USER=kong",
    "KONG_PG_PASSWORD=kong",
    "KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl",
    "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl",
    "KONG_LOG_LEVEL=notice"
  ]
  
  depends_on = [docker_container.kong_migration]
  
  restart = "unless-stopped"
}
EOF
    
    cat > /home/cbwinslow/cbw_terraform/modules/api_gateway/outputs.tf <<'EOF'
output "kong_containers" {
  value = {
    database = docker_container.kong_db.name
    kong     = docker_container.kong.name
  }
}

output "kong_ports" {
  value = {
    proxy      = var.ports.kong_proxy
    proxy_ssl  = var.ports.kong_proxy_ssl
    admin      = var.ports.kong_admin
    admin_ssl  = var.ports.kong_admin_ssl
  }
}
EOF
    
    info "Created API gateway module"
}

create_config_files() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating configuration files${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_terraform/configs
    
    cat > /home/cbwinslow/cbw_terraform/configs/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
        
  - job_name: 'node'
    static_configs:
      - targets: ['cbw-cadvisor:8080']
EOF
    
    cat > /home/cbwinslow/cbw_terraform/configs/loki-config.yaml <<'EOF'
auth_enabled: false

server:
  http_listen_port: 3100
  
ingester:
  lifecycler:
    address: 127.0.0.1
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
EOF
    
    cat > /home/cbwinslow/cbw_terraform/configs/promtail-config.yaml <<'EOF'
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://cbw-loki:3100/loki/api/v1/push

scrape_configs:
  - job_name: system
    entry_parser: raw
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          __path__: /var/log/*log
EOF
    
    info "Created configuration files"
}

create_environment_configs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating environment configurations${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Development environment
    cat > /home/cbwinslow/cbw_terraform/environments/dev/terraform.tfvars <<'EOF'
# Development Environment Variables
server_hostname = "cbwserver-dev"
server_ip       = "192.168.4.117"
environment     = "development"
region          = "local"
docker_image_tag = "latest"
EOF
    
    # Staging environment
    cat > /home/cbwinslow/cbw_terraform/environments/staging/terraform.tfvars <<'EOF'
# Staging Environment Variables
server_hostname = "cbwserver-staging"
server_ip       = "192.168.4.118"
environment     = "staging"
region          = "local"
docker_image_tag = "stable"
EOF
    
    # Production environment
    cat > /home/cbwinslow/cbw_terraform/environments/prod/terraform.tfvars <<'EOF'
# Production Environment Variables
server_hostname = "cbwserver-prod"
server_ip       = "192.168.4.119"
environment     = "production"
region          = "local"
docker_image_tag = "production"
EOF
    
    info "Created environment configurations"
}

create_master_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating master configuration file${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_terraform/cbw_terraform_config.yml <<'EOF'
# CBW Terraform Infrastructure Configuration
# This file serves as the single source of truth for Terraform infrastructure settings

# Server Configuration
server:
  hostname: cbwserver
  ip: 192.168.4.117
  timezone: America/New_York
  locale: en_US.UTF-8

# Network Configuration
network:
  docker_network: cbw-network
  subnet: 172.20.0.0/16

# Docker Configuration
docker:
  socket: unix:///var/run/docker.sock
  version: latest

# Database Configuration
databases:
  postgresql:
    image: postgres:16
    version: 16
    databases:
      - name: app
        extensions:
          - vector
    users:
      - name: appuser
        password: apppass
  qdrant:
    image: qdrant/qdrant:latest
    version: latest
  mongodb:
    image: mongo:7
    version: 7
  opensearch:
    image: opensearchproject/opensearch:2.17.1
    version: 2.17.1
  rabbitmq:
    image: rabbitmq:3-management
    version: 3-management

# Monitoring Configuration
monitoring:
  prometheus:
    image: prom/prometheus:latest
    port: 9091  # Changed from 9090
    retention: 15d
  grafana:
    image: grafana/grafana:latest
    port: 3001  # Changed from 3000
    admin_user: admin
    admin_password: admin
  loki:
    image: grafana/loki:2.9.8
    port: 3100
  promtail:
    image: grafana/promtail:2.9.8
    port: 9080
  cadvisor:
    image: gcr.io/cadvisor/cadvisor:latest
    port: 8081  # Changed from 8080

# API Gateway Configuration
api_gateway:
  kong:
    image: kong:3.7
    version: 3.7
    proxy_port: 8000
    proxy_ssl_port: 8443
    admin_port: 8001
    admin_ssl_port: 8444

# Service Ports Mapping (Non-conflicting)
# This section defines all service ports to avoid conflicts
ports:
  grafana: 3001      # Changed from 3000
  prometheus: 9091   # Changed from 9090
  postgresql: 5433   # Changed from 5432
  cadvisor: 8081     # Changed from 8080
  qdrant_http: 6333
  qdrant_grpc: 6334
  mongodb: 27017
  opensearch: 9200
  opensearch_monitoring: 9600
  rabbitmq: 5672
  rabbitmq_management: 15672
  kong_proxy: 8000
  kong_proxy_ssl: 8443
  kong_admin: 8001
  kong_admin_ssl: 8444
  loki: 3100
  dcgm_exporter: 9400

# Environment Configuration
environments:
  development:
    server_hostname: cbwserver-dev
    server_ip: 192.168.4.117
    docker_image_tag: latest
  staging:
    server_hostname: cbwserver-staging
    server_ip: 192.168.4.118
    docker_image_tag: stable
  production:
    server_hostname: cbwserver-prod
    server_ip: 192.168.4.119
    docker_image_tag: production

# Volumes Configuration
volumes:
  postgres_data: cbw-postgres-data
  qdrant_data: cbw-qdrant-data
  mongodb_data: cbw-mongodb-data
  opensearch_data: cbw-opensearch-data
  grafana_data: cbw-grafana-data
  kong_db: cbw-kong-db
EOF
    
    info "Created master Terraform configuration file"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --create-all     Create all Terraform structure and configurations (default)"
    echo "  --create-structure  Create basic Terraform directory structure"
    echo "  --create-modules Create all modules"
    echo "  --create-configs Create configuration files"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --create-all"
    echo "  $0 --create-structure"
    echo "  $0 --create-modules"
}

main() {
    print_header
    
    # Parse arguments
    local create_structure=false
    local create_modules=false
    local create_configs=false
    
    if [[ $# -eq 0 ]]; then
        create_structure=true
        create_modules=true
        create_configs=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --create-all)
                    create_structure=true
                    create_modules=true
                    create_configs=true
                    shift
                    ;;
                --create-structure)
                    create_structure=true
                    shift
                    ;;
                --create-modules)
                    create_modules=true
                    shift
                    ;;
                --create-configs)
                    create_configs=true
                    shift
                    ;;
                --help|-h)
                    show_usage
                    exit 0
                    ;;
                *)
                    error "Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi
    
    # Execute requested actions
    if [[ "$create_structure" == true ]]; then
        create_terraform_structure
    fi
    
    if [[ "$create_modules" == true ]]; then
        create_main_tf
        create_variables_tf
        create_outputs_tf
        create_databases_module
        create_monitoring_module
        create_api_gateway_module
        create_environment_configs
    fi
    
    if [[ "$create_configs" == true ]]; then
        create_config_files
        create_master_config
    fi
    
    echo
    info "Terraform structure created successfully!"
    info "You can now use Terraform with:"
    echo "  cd /home/cbwinslow/cbw_terraform"
    echo "  terraform init"
    echo "  terraform plan"
    echo "  terraform apply"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
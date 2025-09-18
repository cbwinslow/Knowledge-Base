#!/usr/bin/env bash
#===============================================================================
# ██████╗ ██╗   ██╗██╗     ██╗███╗   ██╗███████╗
# ██╔══██╗██║   ██║██║     ██║████╗  ██║██╔════╝
# ██████╔╝██║   ██║██║     ██║██╔██╗ ██║█████╗  
# ██╔═══╝ ██║   ██║██║     ██║██║╚██╗██║██╔══╝  
# ██║     ╚██████╔╝███████╗██║██║ ╚████║███████╗
# ╚═╝      ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚══════╝
#===============================================================================
# File: create_pulumi_config.sh
# Description: Create Pulumi configuration for CBW setup using IaC principles
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
    echo -e "${BLUE}Creating Pulumi Configuration for CBW Setup${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

create_pulumi_structure() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Pulumi structure${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create directories
    mkdir -p /home/cbwinslow/cbw_pulumi/{src,config,environments/{dev,staging,prod}}
    
    info "Created Pulumi directory structure"
}

create_package_json() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating package.json${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/package.json <<'EOF'
{
  "name": "cbw-infrastructure",
  "version": "1.0.0",
  "description": "CBW Infrastructure as Code using Pulumi",
  "main": "index.ts",
  "scripts": {
    "build": "tsc",
    "deploy": "pulumi up",
    "destroy": "pulumi destroy",
    "preview": "pulumi preview"
  },
  "dependencies": {
    "@pulumi/pulumi": "^3.0.0",
    "@pulumi/docker": "^4.0.0"
  },
  "devDependencies": {
    "@types/node": "^18.0.0",
    "typescript": "^5.0.0"
  }
}
EOF
    
    info "Created package.json"
}

create_tsconfig() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating tsconfig.json${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "strict": true,
    "outDir": "bin",
    "target": "es2016",
    "module": "commonjs",
    "moduleResolution": "node",
    "sourceMap": true,
    "experimentalDecorators": true,
    "pretty": true,
    "noFallthroughCasesInSwitch": true,
    "noImplicitReturns": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": [
    "src"
  ]
}
EOF
    
    info "Created tsconfig.json"
}

create_pulumi_yaml() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Pulumi.yaml${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/Pulumi.yaml <<'EOF'
name: cbw-infrastructure
runtime: nodejs
description: CBW Infrastructure as Code using Pulumi
EOF
    
    info "Created Pulumi.yaml"
}

create_main_index_ts() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating main index.ts${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/src/index.ts <<'EOF'
import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";
import { DatabaseStack } from "./database";
import { MonitoringStack } from "./monitoring";
import { ApiGatewayStack } from "./apiGateway";

// Load configuration
const config = new pulumi.Config();
const serverHostname = config.get("serverHostname") || "cbwserver";
const serverIp = config.get("serverIp") || "192.168.4.117";
const environment = pulumi.getStack();

// Service ports configuration (using non-conflicting ports)
const ports = {
    grafana: 3001,      // Changed from 3000
    prometheus: 9091,   // Changed from 9090
    postgresql: 5433,   // Changed from 5432
    cadvisor: 8081,     // Changed from 8080
    qdrantHttp: 6333,
    qdrantGrpc: 6334,
    mongodb: 27017,
    opensearch: 9200,
    opensearchMonitoring: 9600,
    rabbitmq: 5672,
    rabbitmqManagement: 15672,
    kongProxy: 8000,
    kongProxySsl: 8443,
    kongAdmin: 8001,
    kongAdminSsl: 8444,
    loki: 3100,
    dcgmExporter: 9400
};

// Create Docker network
const network = new docker.Network("cbw-network", {
    name: "cbw-network",
    driver: "bridge",
    ipam: {
        configs: [{
            subnet: "172.21.0.0/16"
        }]
    }
});

// Create database stack
const databaseStack = new DatabaseStack("databases", {
    network: network,
    ports: ports
});

// Create monitoring stack
const monitoringStack = new MonitoringStack("monitoring", {
    network: network,
    ports: ports
});

// Create API gateway stack
const apiGatewayStack = new ApiGatewayStack("api-gateway", {
    network: network,
    ports: ports,
    databaseStack: databaseStack
});

// Export outputs
export const serverInfo = {
    hostname: serverHostname,
    ip: serverIp,
    environment: environment
};

export const serviceEndpoints = {
    grafana: pulumi.interpolate`http://localhost:${ports.grafana}`,
    prometheus: pulumi.interpolate`http://localhost:${ports.prometheus}`,
    postgresql: pulumi.interpolate`localhost:${ports.postgresql}`,
    qdrant: pulumi.interpolate`http://localhost:${ports.qdrantHttp}`,
    mongodb: pulumi.interpolate`localhost:${ports.mongodb}`,
    opensearch: pulumi.interpolate`http://localhost:${ports.opensearch}`,
    kongProxy: pulumi.interpolate`http://localhost:${ports.kongProxy}`,
    kongAdmin: pulumi.interpolate`http://localhost:${ports.kongAdmin}`,
    loki: pulumi.interpolate`http://localhost:${ports.loki}`
};

export const stackStatus = "CBW infrastructure deployment completed successfully";
EOF
    
    info "Created main index.ts"
}

create_database_stack() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating database stack${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/src/database.ts <<'EOF'
import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";

export interface DatabaseStackArgs {
    network: docker.Network;
    ports: any;
}

export class DatabaseStack extends pulumi.ComponentResource {
    public readonly postgresContainer: docker.Container;
    public readonly qdrantContainer: docker.Container;
    public readonly mongodbContainer: docker.Container;
    public readonly opensearchContainer: docker.Container;
    public readonly rabbitmqContainer: docker.Container;
    
    constructor(name: string, private args: DatabaseStackArgs, opts?: pulumi.ResourceOptions) {
        super("cbw:database:DatabaseStack", name, {}, opts);
        
        // PostgreSQL
        const postgresImage = new docker.RemoteImage("postgres-image", {
            name: "postgres:16"
        }, { parent: this });
        
        const postgresVolume = new docker.Volume("postgres-data", {
            name: "cbw-postgres-data"
        }, { parent: this });
        
        this.postgresContainer = new docker.Container("postgres", {
            image: postgresImage.name,
            name: "cbw-postgres",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 5432,
                external: args.ports.postgresql
            }],
            envs: [
                "POSTGRES_PASSWORD=postgres",
                "POSTGRES_USER=postgres",
                "POSTGRES_DB=app"
            ],
            volumes: [{
                containerPath: "/var/lib/postgresql/data",
                volumeName: postgresVolume.name
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // Qdrant
        const qdrantImage = new docker.RemoteImage("qdrant-image", {
            name: "qdrant/qdrant:latest"
        }, { parent: this });
        
        const qdrantVolume = new docker.Volume("qdrant-data", {
            name: "cbw-qdrant-data"
        }, { parent: this });
        
        this.qdrantContainer = new docker.Container("qdrant", {
            image: qdrantImage.name,
            name: "cbw-qdrant",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [
                {
                    internal: 6333,
                    external: args.ports.qdrantHttp
                },
                {
                    internal: 6334,
                    external: args.ports.qdrantGrpc
                }
            ],
            volumes: [{
                containerPath: "/qdrant/storage",
                volumeName: qdrantVolume.name
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // MongoDB
        const mongodbImage = new docker.RemoteImage("mongodb-image", {
            name: "mongo:7"
        }, { parent: this });
        
        const mongodbVolume = new docker.Volume("mongodb-data", {
            name: "cbw-mongodb-data"
        }, { parent: this });
        
        this.mongodbContainer = new docker.Container("mongodb", {
            image: mongodbImage.name,
            name: "cbw-mongodb",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 27017,
                external: args.ports.mongodb
            }],
            volumes: [{
                containerPath: "/data/db",
                volumeName: mongodbVolume.name
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // OpenSearch
        const opensearchImage = new docker.RemoteImage("opensearch-image", {
            name: "opensearchproject/opensearch:2.17.1"
        }, { parent: this });
        
        const opensearchVolume = new docker.Volume("opensearch-data", {
            name: "cbw-opensearch-data"
        }, { parent: this });
        
        this.opensearchContainer = new docker.Container("opensearch", {
            image: opensearchImage.name,
            name: "cbw-opensearch",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [
                {
                    internal: 9200,
                    external: args.ports.opensearch
                },
                {
                    internal: 9600,
                    external: args.ports.opensearchMonitoring
                }
            ],
            envs: [
                "discovery.type=single-node",
                "bootstrap.memory_lock=true",
                "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
            ],
            volumes: [{
                containerPath: "/usr/share/opensearch/data",
                volumeName: opensearchVolume.name
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // RabbitMQ
        const rabbitmqImage = new docker.RemoteImage("rabbitmq-image", {
            name: "rabbitmq:3-management"
        }, { parent: this });
        
        this.rabbitmqContainer = new docker.Container("rabbitmq", {
            image: rabbitmqImage.name,
            name: "cbw-rabbitmq",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [
                {
                    internal: 5672,
                    external: args.ports.rabbitmq
                },
                {
                    internal: 15672,
                    external: args.ports.rabbitmqManagement
                }
            ],
            restart: "unless-stopped"
        }, { parent: this });
        
        this.registerOutputs({
            postgresContainer: this.postgresContainer,
            qdrantContainer: this.qdrantContainer,
            mongodbContainer: this.mongodbContainer,
            opensearchContainer: this.opensearchContainer,
            rabbitmqContainer: this.rabbitmqContainer
        });
    }
}
EOF
    
    info "Created database stack"
}

create_monitoring_stack() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating monitoring stack${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/src/monitoring.ts <<'EOF'
import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";

export interface MonitoringStackArgs {
    network: docker.Network;
    ports: any;
}

export class MonitoringStack extends pulumi.ComponentResource {
    public readonly prometheusContainer: docker.Container;
    public readonly grafanaContainer: docker.Container;
    public readonly lokiContainer: docker.Container;
    public readonly promtailContainer: docker.Container;
    public readonly cadvisorContainer: docker.Container;
    
    constructor(name: string, private args: MonitoringStackArgs, opts?: pulumi.ResourceOptions) {
        super("cbw:monitoring:MonitoringStack", name, {}, opts);
        
        // Prometheus
        const prometheusImage = new docker.RemoteImage("prometheus-image", {
            name: "prom/prometheus:latest"
        }, { parent: this });
        
        this.prometheusContainer = new docker.Container("prometheus", {
            image: prometheusImage.name,
            name: "cbw-prometheus",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 9090,
                external: args.ports.prometheus
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // Grafana
        const grafanaImage = new docker.RemoteImage("grafana-image", {
            name: "grafana/grafana:latest"
        }, { parent: this });
        
        const grafanaVolume = new docker.Volume("grafana-data", {
            name: "cbw-grafana-data"
        }, { parent: this });
        
        this.grafanaContainer = new docker.Container("grafana", {
            image: grafanaImage.name,
            name: "cbw-grafana",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 3000,
                external: args.ports.grafana
            }],
            envs: [
                "GF_SECURITY_ADMIN_PASSWORD=admin"
            ],
            volumes: [{
                containerPath: "/var/lib/grafana",
                volumeName: grafanaVolume.name
            }],
            restart: "unless-stopped"
        }, { parent: this });
        
        // Loki
        const lokiImage = new docker.RemoteImage("loki-image", {
            name: "grafana/loki:2.9.8"
        }, { parent: this });
        
        this.lokiContainer = new docker.Container("loki", {
            image: lokiImage.name,
            name: "cbw-loki",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 3100,
                external: args.ports.loki
            }],
            command: ["-config.file=/etc/loki/local-config.yaml"],
            restart: "unless-stopped"
        }, { parent: this });
        
        // Promtail
        const promtailImage = new docker.RemoteImage("promtail-image", {
            name: "grafana/promtail:2.9.8"
        }, { parent: this });
        
        this.promtailContainer = new docker.Container("promtail", {
            image: promtailImage.name,
            name: "cbw-promtail",
            networksAdvanced: [{
                name: args.network.name
            }],
            volumes: [
                {
                    containerPath: "/var/log",
                    hostPath: "/var/log",
                    readOnly: true
                },
                {
                    containerPath: "/var/lib/docker/containers",
                    hostPath: "/var/lib/docker/containers",
                    readOnly: true
                }
            ],
            command: ["-config.file=/etc/promtail/config.yml"],
            restart: "unless-stopped"
        }, { parent: this });
        
        // cAdvisor
        const cadvisorImage = new docker.RemoteImage("cadvisor-image", {
            name: "gcr.io/cadvisor/cadvisor:latest"
        }, { parent: this });
        
        this.cadvisorContainer = new docker.Container("cadvisor", {
            image: cadvisorImage.name,
            name: "cbw-cadvisor",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [{
                internal: 8080,
                external: args.ports.cadvisor
            }],
            privileged: true,
            volumes: [
                {
                    containerPath: "/rootfs",
                    hostPath: "/",
                    readOnly: true
                },
                {
                    containerPath: "/var/run",
                    hostPath: "/var/run"
                },
                {
                    containerPath: "/sys",
                    hostPath: "/sys",
                    readOnly: true
                },
                {
                    containerPath: "/var/lib/docker",
                    hostPath: "/var/lib/docker",
                    readOnly: true
                },
                {
                    containerPath: "/dev/disk",
                    hostPath: "/dev/disk",
                    readOnly: true
                }
            ],
            restart: "unless-stopped"
        }, { parent: this });
        
        this.registerOutputs({
            prometheusContainer: this.prometheusContainer,
            grafanaContainer: this.grafanaContainer,
            lokiContainer: this.lokiContainer,
            promtailContainer: this.promtailContainer,
            cadvisorContainer: this.cadvisorContainer
        });
    }
}
EOF
    
    info "Created monitoring stack"
}

create_api_gateway_stack() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating API gateway stack${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/src/apiGateway.ts <<'EOF'
import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";
import { DatabaseStack } from "./database";

export interface ApiGatewayStackArgs {
    network: docker.Network;
    ports: any;
    databaseStack: DatabaseStack;
}

export class ApiGatewayStack extends pulumi.ComponentResource {
    public readonly kongDbContainer: docker.Container;
    public readonly kongContainer: docker.Container;
    
    constructor(name: string, private args: ApiGatewayStackArgs, opts?: pulumi.ResourceOptions) {
        super("cbw:api:ApiGatewayStack", name, {}, opts);
        
        // Kong Database
        const kongDbImage = new docker.RemoteImage("kong-db-image", {
            name: "postgres:16"
        }, { parent: this });
        
        const kongDbVolume = new docker.Volume("kong-db", {
            name: "cbw-kong-db"
        }, { parent: this });
        
        this.kongDbContainer = new docker.Container("kong-db", {
            image: kongDbImage.name,
            name: "cbw-kong-db",
            networksAdvanced: [{
                name: args.network.name
            }],
            envs: [
                "POSTGRES_DB=kong",
                "POSTGRES_USER=kong",
                "POSTGRES_PASSWORD=kong"
            ],
            volumes: [{
                containerPath: "/var/lib/postgresql/data",
                volumeName: kongDbVolume.name
            }],
            restart: "unless-stopped"
        }, { 
            parent: this,
            dependsOn: [args.databaseStack.postgresContainer]
        });
        
        // Kong Migration (run once)
        const kongImage = new docker.RemoteImage("kong-image", {
            name: "kong:3.7"
        }, { parent: this });
        
        const kongMigration = new docker.Container("kong-migration", {
            image: kongImage.name,
            name: "cbw-kong-migration",
            networksAdvanced: [{
                name: args.network.name
            }],
            envs: [
                "KONG_DATABASE=postgres",
                "KONG_PG_HOST=cbw-kong-db",
                "KONG_PG_USER=kong",
                "KONG_PG_PASSWORD=kong",
                "KONG_PASSWORD=admin"
            ],
            command: ["kong", "migrations", "bootstrap"],
            restart: "no"
        }, { 
            parent: this,
            dependsOn: [this.kongDbContainer]
        });
        
        // Kong
        this.kongContainer = new docker.Container("kong", {
            image: kongImage.name,
            name: "cbw-kong",
            networksAdvanced: [{
                name: args.network.name
            }],
            ports: [
                {
                    internal: 8000,
                    external: args.ports.kongProxy
                },
                {
                    internal: 8443,
                    external: args.ports.kongProxySsl
                },
                {
                    internal: 8001,
                    external: args.ports.kongAdmin
                },
                {
                    internal: 8444,
                    external: args.ports.kongAdminSsl
                }
            ],
            envs: [
                "KONG_DATABASE=postgres",
                "KONG_PG_HOST=cbw-kong-db",
                "KONG_PG_USER=kong",
                "KONG_PG_PASSWORD=kong",
                "KONG_PROXY_LISTEN=0.0.0.0:8000, 0.0.0.0:8443 ssl",
                "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl",
                "KONG_LOG_LEVEL=notice"
            ],
            restart: "unless-stopped"
        }, { 
            parent: this,
            dependsOn: [kongMigration]
        });
        
        this.registerOutputs({
            kongDbContainer: this.kongDbContainer,
            kongContainer: this.kongContainer
        });
    }
}
EOF
    
    info "Created API gateway stack"
}

create_environment_configs() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating environment configurations${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Development environment
    cat > /home/cbwinslow/cbw_pulumi/environments/dev/Pulumi.dev.yaml <<'EOF'
config:
  cbw-infrastructure:serverHostname: cbwserver-dev
  cbw-infrastructure:serverIp: 192.168.4.117
EOF
    
    # Staging environment
    cat > /home/cbwinslow/cbw_pulumi/environments/staging/Pulumi.staging.yaml <<'EOF'
config:
  cbw-infrastructure:serverHostname: cbwserver-staging
  cbw-infrastructure:serverIp: 192.168.4.118
EOF
    
    # Production environment
    cat > /home/cbwinslow/cbw_pulumi/environments/prod/Pulumi.prod.yaml <<'EOF'
config:
  cbw-infrastructure:serverHostname: cbwserver-prod
  cbw-infrastructure:serverIp: 192.168.4.119
EOF
    
    info "Created environment configurations"
}

create_master_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating master configuration file${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_pulumi/cbw_pulumi_config.yml <<'EOF'
# CBW Pulumi Infrastructure Configuration
# This file serves as the single source of truth for Pulumi infrastructure settings

# Project Configuration
project:
  name: cbw-infrastructure
  runtime: nodejs
  description: CBW Infrastructure as Code using Pulumi

# Server Configuration
server:
  hostname: cbwserver
  ip: 192.168.4.117
  timezone: America/New_York
  locale: en_US.UTF-8

# Network Configuration
network:
  docker_network: cbw-network
  subnet: 172.21.0.0/16

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
  staging:
    server_hostname: cbwserver-staging
    server_ip: 192.168.4.118
  production:
    server_hostname: cbwserver-prod
    server_ip: 192.168.4.119

# Volumes Configuration
volumes:
  postgres_data: cbw-postgres-data
  qdrant_data: cbw-qdrant-data
  mongodb_data: cbw-mongodb-data
  opensearch_data: cbw-opensearch-data
  grafana_data: cbw-grafana-data
  kong_db: cbw-kong-db
EOF
    
    info "Created master Pulumi configuration file"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --create-all     Create all Pulumi structure and configurations (default)"
    echo "  --create-structure  Create basic Pulumi directory structure"
    echo "  --create-stacks  Create all stacks"
    echo "  --create-configs Create configuration files"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --create-all"
    echo "  $0 --create-structure"
    echo "  $0 --create-stacks"
}

main() {
    print_header
    
    # Parse arguments
    local create_structure=false
    local create_stacks=false
    local create_configs=false
    
    if [[ $# -eq 0 ]]; then
        create_structure=true
        create_stacks=true
        create_configs=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --create-all)
                    create_structure=true
                    create_stacks=true
                    create_configs=true
                    shift
                    ;;
                --create-structure)
                    create_structure=true
                    shift
                    ;;
                --create-stacks)
                    create_stacks=true
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
        create_pulumi_structure
        create_package_json
        create_tsconfig
        create_pulumi_yaml
    fi
    
    if [[ "$create_stacks" == true ]]; then
        create_main_index_ts
        create_database_stack
        create_monitoring_stack
        create_api_gateway_stack
        create_environment_configs
    fi
    
    if [[ "$create_configs" == true ]]; then
        create_master_config
    fi
    
    echo
    info "Pulumi structure created successfully!"
    info "To use Pulumi, you'll need to:"
    echo "  1. Install Node.js and Pulumi CLI"
    echo "  2. cd /home/cbwinslow/cbw_pulumi"
    echo "  3. npm install"
    echo "  4. pulumi stack init dev"
    echo "  5. pulumi up"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
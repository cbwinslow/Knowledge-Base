#!/usr/bin/env bash
#===============================================================================
# ███╗   ███╗ █████╗ ██████╗ ██████╗  █████╗ ███████╗████████╗███████╗██████╗ 
# ████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
# ██╔████╔██║███████║██████╔╝██████╔╝███████║███████╗   ██║   █████╗  ██████╔╝
# ██║╚██╔╝██║██╔══██║██╔══██╗██╔══██╗██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
# ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║██║  ██║███████║   ██║   ███████╗██║  ██║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
#===============================================================================
# File: cbw_infrastructure_orchestrator.sh
# Description: Master orchestration script for CBW infrastructure using IaC
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
    echo -e "${BLUE}CBW Infrastructure Orchestration${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_infrastructure_status() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Infrastructure Status${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Check if Docker is running
    if command -v docker >/dev/null 2>&1 && systemctl is-active --quiet docker; then
        echo -e "${GREEN}Docker: ${NC}RUNNING"
        local container_count=$(docker ps -q | wc -l)
        echo -e "${GREEN}  Containers: ${NC}$container_count running"
    else
        echo -e "${YELLOW}Docker: ${NC}NOT RUNNING"
    fi
    
    # Check if services are running
    local services=("prometheus" "grafana-server" "postgresql")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            echo -e "${GREEN}$service: ${NC}RUNNING"
        else
            echo -e "${YELLOW}$service: ${NC}NOT RUNNING"
        fi
    done
    
    # Show available IaC tools
    echo
    echo -e "${BLUE}Available IaC Tools:${NC}"
    if command -v ansible-playbook >/dev/null 2>&1; then
        echo -e "${GREEN}  Ansible: ${NC}INSTALLED"
    else
        echo -e "${YELLOW}  Ansible: ${NC}NOT INSTALLED"
    fi
    
    if command -v terraform >/dev/null 2>&1; then
        echo -e "${GREEN}  Terraform: ${NC}INSTALLED"
    else
        echo -e "${YELLOW}  Terraform: ${NC}NOT INSTALLED"
    fi
    
    if command -v pulumi >/dev/null 2>&1; then
        echo -e "${GREEN}  Pulumi: ${NC}INSTALLED"
    else
        echo -e "${YELLOW}  Pulumi: ${NC}NOT INSTALLED"
    fi
}

show_infrastructure_options() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Infrastructure Deployment Options${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "1. Ansible (Recommended for configuration management)"
    echo "   Path: /home/cbwinslow/cbw_ansible"
    echo "   Benefits: Great for configuring existing systems, idempotent"
    echo
    echo "2. Terraform (Recommended for infrastructure provisioning)"
    echo "   Path: /home/cbwinslow/cbw_terraform"
    echo "   Benefits: Excellent for provisioning infrastructure, state management"
    echo
    echo "3. Pulumi (Recommended for modern cloud-native infrastructure)"
    echo "   Path: /home/cbwinslow/cbw_pulumi"
    echo "   Benefits: Programmatic infrastructure, multiple languages"
    echo
    echo "4. Traditional Bash Scripts (Already prepared)"
    echo "   Path: /home/cbwinslow/run_bare_metal_setup.sh"
    echo "   Benefits: Simple, direct, no additional dependencies"
}

deploy_with_ansible() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying with Ansible${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        error "Ansible is not installed"
        echo "To install Ansible:"
        echo "  sudo apt install ansible"
        return 1
    fi
    
    if [[ ! -d "/home/cbwinslow/cbw_ansible" ]]; then
        error "Ansible configuration not found"
        return 1
    fi
    
    cd /home/cbwinslow/cbw_ansible
    
    echo "Running Ansible playbook..."
    echo "This will configure your system with the CBW setup"
    
    # Dry run first
    echo "Performing dry run..."
    if ansible-playbook playbooks/cbw_setup.yml --check; then
        echo -e "${GREEN}Dry run successful${NC}"
        
        read -p "Do you want to proceed with actual deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting deployment..."
            ansible-playbook playbooks/cbw_setup.yml
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}Ansible deployment completed successfully${NC}"
                return 0
            else
                error "Ansible deployment failed"
                return 1
            fi
        else
            echo "Deployment cancelled"
            return 0
        fi
    else
        error "Ansible dry run failed"
        return 1
    fi
}

deploy_with_terraform() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying with Terraform${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if ! command -v terraform >/dev/null 2>&1; then
        error "Terraform is not installed"
        echo "To install Terraform:"
        echo "  wget -O terraform.zip https://releases.hashicorp.com/terraform/1.9.5/terraform_1.9.5_linux_amd64.zip"
        echo "  unzip terraform.zip"
        echo "  sudo mv terraform /usr/local/bin/"
        return 1
    fi
    
    if [[ ! -d "/home/cbwinslow/cbw_terraform" ]]; then
        error "Terraform configuration not found"
        return 1
    fi
    
    cd /home/cbwinslow/cbw_terraform
    
    echo "Initializing Terraform..."
    if terraform init; then
        echo -e "${GREEN}Terraform initialized successfully${NC}"
    else
        error "Terraform initialization failed"
        return 1
    fi
    
    echo "Planning infrastructure..."
    if terraform plan; then
        echo -e "${GREEN}Plan generated successfully${NC}"
        
        read -p "Do you want to proceed with actual deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting deployment..."
            terraform apply
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}Terraform deployment completed successfully${NC}"
                return 0
            else
                error "Terraform deployment failed"
                return 1
            fi
        else
            echo "Deployment cancelled"
            return 0
        fi
    else
        error "Terraform plan failed"
        return 1
    fi
}

deploy_with_pulumi() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying with Pulumi${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if ! command -v pulumi >/dev/null 2>&1; then
        error "Pulumi is not installed"
        echo "To install Pulumi:"
        echo "  curl -fsSL https://get.pulumi.com | sh"
        return 1
    fi
    
    if [[ ! -d "/home/cbwinslow/cbw_pulumi" ]]; then
        error "Pulumi configuration not found"
        return 1
    fi
    
    cd /home/cbwinslow/cbw_pulumi
    
    echo "Installing Node.js dependencies..."
    if npm install; then
        echo -e "${GREEN}Dependencies installed successfully${NC}"
    else
        error "Failed to install dependencies"
        return 1
    fi
    
    echo "Initializing Pulumi stack..."
    if pulumi stack init dev; then
        echo -e "${GREEN}Pulumi stack initialized successfully${NC}"
    else
        error "Pulumi stack initialization failed"
        return 1
    fi
    
    echo "Planning infrastructure..."
    if pulumi preview; then
        echo -e "${GREEN}Preview generated successfully${NC}"
        
        read -p "Do you want to proceed with actual deployment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Starting deployment..."
            pulumi up
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}Pulumi deployment completed successfully${NC}"
                return 0
            else
                error "Pulumi deployment failed"
                return 1
            fi
        else
            echo "Deployment cancelled"
            return 0
        fi
    else
        error "Pulumi preview failed"
        return 1
    fi
}

deploy_with_bash_scripts() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Deploying with Bash Scripts${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    if [[ ! -f "/home/cbwinslow/run_bare_metal_setup.sh" ]]; then
        error "Bash setup script not found"
        return 1
    fi
    
    echo "Running CBW bare metal setup..."
    echo "This will install all CBW services using the prepared bash scripts"
    
    read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Starting deployment..."
        /home/cbwinslow/run_bare_metal_setup.sh --full-install
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}Bash script deployment completed successfully${NC}"
            return 0
        else
            error "Bash script deployment failed"
            return 1
        fi
    else
        echo "Deployment cancelled"
        return 0
    fi
}

show_service_endpoints() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Service Endpoints${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "After deployment, services will be available at:"
    echo "  • Grafana: http://localhost:3001 (admin / admin)"
    echo "  • Prometheus: http://localhost:9091"
    echo "  • PostgreSQL: localhost:5433"
    echo "  • cAdvisor: http://localhost:8081"
    echo "  • Qdrant: 6333, 6334"
    echo "  • MongoDB: 27017"
    echo "  • OpenSearch: 9200, 9600"
    echo "  • RabbitMQ: 5672, 15672"
    echo "  • Kong: 8000, 8443, 8001, 8444"
    echo "  • Loki: 3100"
    echo "  • DCGM Exporter: 9400"
}

show_master_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Master Configuration Files${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "Centralized configuration files:"
    echo "  • Ansible: /home/cbwinslow/cbw_ansible/cbw_config.yml"
    echo "  • Terraform: /home/cbwinslow/cbw_terraform/cbw_terraform_config.yml"
    echo "  • Pulumi: /home/cbwinslow/cbw_pulumi/cbw_pulumi_config.yml"
    echo "  • Bash Scripts: /home/cbwinslow/server_setup.conf"
    
    echo
    echo "These files contain all service configurations and port mappings"
    echo "to prevent duplication and conflicts."
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --status         Show current infrastructure status"
    echo "  --options        Show deployment options"
    echo "  --ansible        Deploy using Ansible"
    echo "  --terraform      Deploy using Terraform"
    echo "  --pulumi         Deploy using Pulumi"
    echo "  --bash           Deploy using Bash scripts"
    echo "  --endpoints      Show service endpoints"
    echo "  --config         Show master configuration files"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --status"
    echo "  $0 --options"
    echo "  $0 --ansible"
    echo "  $0 --endpoints"
}

main() {
    print_header
    
    # Parse arguments
    if [[ $# -eq 0 ]]; then
        show_infrastructure_status
        echo
        show_infrastructure_options
        echo
        show_service_endpoints
        echo
        show_master_config
        return 0
    fi
    
    case $1 in
        --status)
            show_infrastructure_status
            ;;
        --options)
            show_infrastructure_options
            ;;
        --ansible)
            deploy_with_ansible
            ;;
        --terraform)
            deploy_with_terraform
            ;;
        --pulumi)
            deploy_with_pulumi
            ;;
        --bash)
            deploy_with_bash_scripts
            ;;
        --endpoints)
            show_service_endpoints
            ;;
        --config)
            show_master_config
            ;;
        --help|-h)
            show_usage
            ;;
        *)
            error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
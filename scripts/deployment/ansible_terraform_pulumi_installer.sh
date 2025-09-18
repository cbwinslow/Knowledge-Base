#!/usr/bin/env bash
#===============================================================================
# █████╗ ███╗   ██╗██████╗ ███████╗███╗   ██╗ █████╗ ███╗   ███╗███████╗    ████████╗██████╗  █████╗ ███╗   ██╗███████╗██████╗ 
# ██╔══██╗████╗  ██║██╔══██╗██╔════╝████╗  ██║██╔══██╗████╗ ████║██╔════╝    ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔══██╗
# ███████║██╔██╗ ██║██║  ██║█████╗  ██╔██╗ ██║███████║██╔████╔██║█████╗         ██║   ██████╔╝███████║██╔██╗ ██║█████╗  ██║  ██║
# ██╔══██║██║╚██╗██║██║  ██║██╔══╝  ██║╚██╗██║██╔══██║██║╚██╔╝██║██╔══╝         ██║   ██╔══██╗██╔══██║██║╚██╗██║██╔══╝  ██║  ██║
# ██║  ██║██║ ╚████║██████╔╝███████╗██║ ╚████║██║  ██║██║ ╚═╝ ██║███████╗       ██║   ██║  ██║██║  ██║██║ ╚████║███████╗██████╔╝
# ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═════╝ 
#===============================================================================
# File: ansible_terraform_pulumi_installer.sh
# Description: Ansible, Terraform, and Pulumi installation and configuration script
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/ansible_terraform_pulumi_installer.log"
TEMP_DIR="/tmp/ansible_terraform_pulumi"
ANSIBLE_CONFIG_DIR="$HOME/.ansible"
TERRAFORM_VERSION="1.9.5"
PULUMI_VERSION="3.131.0"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $*" | tee -a "$LOG_FILE" || true; }

# Utility functions
print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Ansible, Terraform, and Pulumi Installer - Infrastructure Automation Tools${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_section_header() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

print_divider() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

cleanup() {
    rm -rf "$TEMP_DIR"
    debug "Cleaned up temporary files"
}

trap cleanup EXIT

# Ansible installation functions
install_ansible() {
    print_section_header "Installing Ansible"
    
    # Detect OS and package manager
    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
        echo -e "${GREEN}Package Manager: ${NC}APT (Debian/Ubuntu)"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
        echo -e "${GREEN}Package Manager: ${NC}DNF (Fedora/RHEL)"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"
        echo -e "${GREEN}Package Manager: ${NC}YUM (CentOS/RHEL)"
    else
        error "Unsupported package manager"
        return 1
    fi
    
    # Install Ansible
    echo -e "${GREEN}Installing Ansible${NC}"
    
    case "$PKG_MANAGER" in
        apt)
            apt-get update
            apt-get install -y ansible
            ;;
        dnf)
            dnf install -y ansible
            ;;
        yum)
            yum install -y ansible
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Ansible installed${NC}"
    else
        error "Failed to install Ansible"
        return 1
    fi
    
    # Show Ansible version
    echo -e "${GREEN}Ansible Version: ${NC}$(ansible --version | head -1)"
    
    # Create Ansible configuration directory
    mkdir -p "$ANSIBLE_CONFIG_DIR"
    
    # Create basic Ansible configuration
    cat > "$ANSIBLE_CONFIG_DIR/ansible.cfg" <<EOF
[defaults]
inventory = ./inventory
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
    
    echo -e "${GREEN}Ansible configuration file created: ${NC}$ANSIBLE_CONFIG_DIR/ansible.cfg"
    
    # Create sample inventory
    mkdir -p "$ANSIBLE_CONFIG_DIR/inventory"
    cat > "$ANSIBLE_CONFIG_DIR/inventory/hosts" <<EOF
[local]
localhost ansible_connection=local

[webservers]
web1.example.com
web2.example.com

[dbservers]
db1.example.com

[all:vars]
ansible_user=ubuntu
EOF
    
    echo -e "${GREEN}Sample inventory created: ${NC}$ANSIBLE_CONFIG_DIR/inventory/hosts"
    
    # Create sample playbook
    mkdir -p "$ANSIBLE_CONFIG_DIR/playbooks"
    cat > "$ANSIBLE_CONFIG_DIR/playbooks/site.yml" <<'EOF'
---
- name: Site Setup
  hosts: all
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
      when: ansible_os_family == "Debian"
      
    - name: Install common packages
      package:
        name:
          - curl
          - wget
          - vim
          - git
        state: present
        
    - name: Ensure NTP is installed and running
      service:
        name: ntp
        state: started
        enabled: yes
      ignore_errors: yes
EOF
    
    echo -e "${GREEN}Sample playbook created: ${NC}$ANSIBLE_CONFIG_DIR/playbooks/site.yml"
    
    info "Ansible installation completed"
}

install_ansible_collections() {
    print_section_header "Installing Ansible Collections"
    
    # Check if Ansible is installed
    if ! command -v ansible-galaxy >/dev/null 2>&1; then
        error "Ansible is not installed"
        return 1
    fi
    
    # Install common collections
    local collections=(
        "community.general"
        "ansible.posix"
        "community.docker"
        "community.crypto"
        "community.mysql"
        "community.postgresql"
        "community.network"
    )
    
    echo -e "${GREEN}Installing Ansible collections${NC}"
    
    for collection in "${collections[@]}"; do
        echo -e "${GREEN}Installing collection: ${NC}$collection"
        ansible-galaxy collection install "$collection" --upgrade
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}SUCCESS: $collection installed${NC}"
        else
            error "Failed to install collection: $collection"
        fi
    done
    
    # Show installed collections
    echo
    echo -e "${GREEN}Installed collections:${NC}"
    ansible-galaxy collection list | sed "s/^/  /" || echo "  Unable to list collections"
    
    info "Ansible collections installation completed"
}

# Terraform installation functions
install_terraform() {
    print_section_header "Installing Terraform"
    
    # Check architecture
    local arch=$(uname -m)
    case "$arch" in
        x86_64)
            TF_ARCH="amd64"
            ;;
        aarch64|arm64)
            TF_ARCH="arm64"
            ;;
        *)
            error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    echo -e "${GREEN}Architecture: ${NC}$arch ($TF_ARCH)"
    echo -e "${GREEN}Target Version: ${NC}$TERRAFORM_VERSION"
    
    # Download Terraform
    echo -e "${GREEN}Downloading Terraform${NC}"
    local tf_url="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip"
    local tf_zip="$TEMP_DIR/terraform.zip"
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$tf_zip" "$tf_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$tf_zip" "$tf_url"
    else
        error "Neither wget nor curl is available"
        return 1
    fi
    
    if [[ $? -ne 0 ]] || [[ ! -f "$tf_zip" ]]; then
        error "Failed to download Terraform"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Terraform downloaded${NC}"
    
    # Extract Terraform
    echo -e "${GREEN}Extracting Terraform${NC}"
    unzip -o "$tf_zip" -d "$TEMP_DIR"
    
    if [[ $? -ne 0 ]]; then
        error "Failed to extract Terraform"
        return 1
    fi
    
    # Install Terraform
    echo -e "${GREEN}Installing Terraform${NC}"
    sudo install -m 0755 "$TEMP_DIR/terraform" /usr/local/bin/terraform
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Terraform installed${NC}"
    else
        error "Failed to install Terraform"
        return 1
    fi
    
    # Show Terraform version
    echo -e "${GREEN}Terraform Version: ${NC}$(terraform version | head -1)"
    
    # Create Terraform configuration directory
    local tf_config_dir="$HOME/.terraform.d"
    mkdir -p "$tf_config_dir/plugins"
    
    # Create sample Terraform configuration
    mkdir -p "$HOME/terraform_examples"
    cat > "$HOME/terraform_examples/main.tf" <<'EOF'
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "nginx" {
  image = docker_image.nginx.latest
  name  = "nginx-example"
  ports {
    internal = 80
    external = 8080
  }
}
EOF
    
    echo -e "${GREEN}Sample Terraform configuration created: ${NC}$HOME/terraform_examples/main.tf"
    
    info "Terraform installation completed"
}

# Pulumi installation functions
install_pulumi() {
    print_section_header "Installing Pulumi"
    
    echo -e "${GREEN}Target Version: ${NC}$PULUMI_VERSION"
    
    # Download Pulumi installer
    echo -e "${GREEN}Downloading Pulumi installer${NC}"
    local pulumi_url="https://get.pulumi.com/releases/sdk/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz"
    local pulumi_tar="$TEMP_DIR/pulumi.tar.gz"
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$pulumi_tar" "$pulumi_url"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$pulumi_tar" "$pulumi_url"
    else
        error "Neither wget nor curl is available"
        return 1
    fi
    
    if [[ $? -ne 0 ]] || [[ ! -f "$pulumi_tar" ]]; then
        error "Failed to download Pulumi"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Pulumi installer downloaded${NC}"
    
    # Extract Pulumi
    echo -e "${GREEN}Extracting Pulumi${NC}"
    mkdir -p "$TEMP_DIR/pulumi_extract"
    tar -xzf "$pulumi_tar" -C "$TEMP_DIR/pulumi_extract"
    
    if [[ $? -ne 0 ]]; then
        error "Failed to extract Pulumi"
        return 1
    fi
    
    # Install Pulumi
    echo -e "${GREEN}Installing Pulumi${NC}"
    sudo "$TEMP_DIR/pulumi_extract/pulumi/install.sh" --non-interactive
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Pulumi installed${NC}"
    else
        error "Failed to install Pulumi"
        return 1
    fi
    
    # Show Pulumi version
    echo -e "${GREEN}Pulumi Version: ${NC}$(~/.pulumi/bin/pulumi version 2>/dev/null || echo 'Unknown')"
    
    # Add to PATH if not already there
    if ! echo "$PATH" | grep -q "~/.pulumi/bin"; then
        echo 'export PATH=$PATH:~/.pulumi/bin' >> ~/.bashrc
        export PATH=$PATH:~/.pulumi/bin
        echo -e "${GREEN}Pulumi added to PATH${NC}"
    fi
    
    # Create sample Pulumi project
    mkdir -p "$HOME/pulumi_examples"
    cat > "$HOME/pulumi_examples/Pulumi.yaml" <<EOF
name: example
runtime: nodejs
description: A minimal AWS TypeScript Pulumi program
EOF
    
    echo -e "${GREEN}Sample Pulumi project created: ${NC}$HOME/pulumi_examples/"
    
    info "Pulumi installation completed"
}

# Docker integration functions
install_docker_integration() {
    print_section_header "Installing Docker Integration Tools"
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        warn "Docker is not installed"
        echo -e "${YELLOW}To install Docker:${NC}"
        echo "  Ubuntu/Debian: sudo apt install docker.io"
        echo "  CentOS/RHEL: sudo yum install docker"
        echo
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    else
        echo -e "${GREEN}Docker: ${NC}INSTALLED ($(docker --version | head -1))"
    fi
    
    # Install Docker SDK for Python (for Ansible Docker modules)
    echo -e "${GREEN}Installing Docker SDK for Python${NC}"
    
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install docker
    elif command -v pip >/dev/null 2>&1; then
        pip install docker
    else
        # Install pip first
        if command -v apt >/dev/null 2>&1; then
            apt-get install -y python3-pip
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y python3-pip
        elif command -v yum >/dev/null 2>&1; then
            yum install -y python3-pip
        fi
        
        # Now install Docker SDK
        pip3 install docker
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Docker SDK for Python installed${NC}"
    else
        error "Failed to install Docker SDK for Python"
        return 1
    fi
    
    # Install Docker Compose (if not already installed)
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${GREEN}Installing Docker Compose${NC}"
        
        if command -v apt >/dev/null 2>&1; then
            apt-get install -y docker-compose
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y docker-compose
        elif command -v yum >/dev/null 2>&1; then
            yum install -y docker-compose
        fi
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}SUCCESS: Docker Compose installed${NC}"
        else
            # Try installing via pip
            pip3 install docker-compose
            
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}SUCCESS: Docker Compose installed via pip${NC}"
            else
                error "Failed to install Docker Compose"
                return 1
            fi
        fi
    else
        echo -e "${GREEN}Docker Compose: ${NC}ALREADY INSTALLED ($(docker-compose --version | head -1))"
    fi
    
    info "Docker integration tools installation completed"
}

show_infrastructure_status() {
    print_section_header "Infrastructure Tools Status"
    
    # Check Ansible
    if command -v ansible >/dev/null 2>&1; then
        echo -e "${GREEN}Ansible: ${NC}INSTALLED ($(ansible --version | head -1))"
        
        # Show configuration
        if [[ -f "$ANSIBLE_CONFIG_DIR/ansible.cfg" ]]; then
            echo -e "${GREEN}  Config: ${NC}$ANSIBLE_CONFIG_DIR/ansible.cfg"
        fi
        
        # Show installed collections
        local collections_count=$(ansible-galaxy collection list 2>/dev/null | wc -l)
        if [[ $collections_count -gt 0 ]]; then
            echo -e "${GREEN}  Collections: ${NC}$collections_count installed"
        fi
    else
        echo -e "${YELLOW}Ansible: ${NC}NOT INSTALLED"
    fi
    
    # Check Terraform
    if command -v terraform >/dev/null 2>&1; then
        echo -e "${GREEN}Terraform: ${NC}INSTALLED ($(terraform version | head -1))"
    else
        echo -e "${YELLOW}Terraform: ${NC}NOT INSTALLED"
    fi
    
    # Check Pulumi
    if command -v pulumi >/dev/null 2>&1; then
        echo -e "${GREEN}Pulumi: ${NC}INSTALLED ($(pulumi version 2>/dev/null || echo 'Unknown'))"
    else
        echo -e "${YELLOW}Pulumi: ${NC}NOT INSTALLED"
    fi
    
    # Check Docker integration
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Docker: ${NC}INSTALLED ($(docker --version | head -1))"
        
        if command -v docker-compose >/dev/null 2>&1; then
            echo -e "${GREEN}  Docker Compose: ${NC}INSTALLED ($(docker-compose --version | head -1))"
        else
            echo -e "${YELLOW}  Docker Compose: ${NC}NOT INSTALLED"
        fi
        
        # Check Python Docker SDK
        if python3 -c "import docker" 2>/dev/null; then
            echo -e "${GREEN}  Python Docker SDK: ${NC}INSTALLED"
        else
            echo -e "${YELLOW}  Python Docker SDK: ${NC}NOT INSTALLED"
        fi
    else
        echo -e "${YELLOW}Docker: ${NC}NOT INSTALLED"
    fi
    
    info "Infrastructure tools status check completed"
}

create_sample_projects() {
    print_section_header "Creating Sample Projects"
    
    # Create Ansible project structure
    mkdir -p "$HOME/infrastructure/ansible/{playbooks,roles,inventories,group_vars,host_vars}"
    
    # Create basic Ansible inventory
    cat > "$HOME/infrastructure/ansible/inventories/development.ini" <<EOF
[webservers]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[dbservers]
db1 ansible_host=192.168.1.20

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_rsa
EOF
    
    # Create Ansible playbook
    cat > "$HOME/infrastructure/ansible/playbooks/webserver.yml" <<'EOF'
---
- name: Configure Web Servers
  hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes
      when: ansible_os_family == "Debian"
      
    - name: Start nginx service
      service:
        name: nginx
        state: started
        enabled: yes
        
    - name: Copy nginx config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx
      
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
EOF
    
    # Create Terraform project
    mkdir -p "$HOME/infrastructure/terraform/aws"
    
    cat > "$HOME/infrastructure/terraform/aws/main.tf" <<'EOF'
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "web" {
  ami           = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = "t3.micro"
  
  tags = {
    Name = "WebServer"
  }
}
EOF
    
    # Create Pulumi project
    mkdir -p "$HOME/infrastructure/pulumi/aws"
    
    cat > "$HOME/infrastructure/pulumi/aws/Pulumi.yaml" <<EOF
name: aws-infrastructure
runtime: nodejs
description: AWS infrastructure with Pulumi
EOF
    
    echo -e "${GREEN}SUCCESS: Sample infrastructure projects created${NC}"
    echo -e "${GREEN}Projects directory: ${NC}$HOME/infrastructure/"
    
    info "Sample projects creation completed"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  install-ansible              Install Ansible"
    echo "  install-ansible-collections  Install Ansible collections"
    echo "  install-terraform            Install Terraform"
    echo "  install-pulumi               Install Pulumi"
    echo "  install-docker               Install Docker integration tools"
    echo "  install-all                  Install all tools"
    echo "  status                       Show infrastructure tools status"
    echo "  sample-projects              Create sample infrastructure projects"
    echo "  help                         Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install-ansible"
    echo "  $0 install-ansible-collections"
    echo "  $0 install-terraform"
    echo "  $0 install-pulumi"
    echo "  $0 install-docker"
    echo "  $0 install-all"
    echo "  $0 status"
    echo "  $0 sample-projects"
}

# Main execution
main() {
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        install-ansible)
            install_ansible
            ;;
        install-ansible-collections)
            install_ansible_collections
            ;;
        install-terraform)
            install_terraform
            ;;
        install-pulumi)
            install_pulumi
            ;;
        install-docker)
            install_docker_integration
            ;;
        install-all)
            install_ansible
            install_terraform
            install_pulumi
            install_docker_integration
            ;;
        status)
            show_infrastructure_status
            ;;
        sample-projects)
            create_sample_projects
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
#!/usr/bin/env bash
#===============================================================================
# ███████╗██╗   ██╗███████╗████████╗███████╗██████╗      ████████╗ ██████╗  ██████╗ ██╗     ███████╗
# ██╔════╝██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗     ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
# ███████╗██║   ██║███████╗   ██║   █████╗  ██████╔╝        ██║   ██║   ██║██║   ██║██║     ███████╗
# ╚════██║██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗        ██║   ██║   ██║██║   ██║██║     ╚════██║
# ███████║╚██████╔╝███████║   ██║   ███████╗██║  ██║        ██║   ╚██████╔╝╚██████╔╝███████╗███████║
# ╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝        ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
#===============================================================================
# File: system_tools_launcher.sh
# Description: Unified launcher for all system management tools
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
TOOLS_DIR="/home/cbwinslow/system_tools"
LOG_FILE="/tmp/system_tools_launcher.log"

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

# Utility functions
print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}System Tools Launcher - Unified Management Interface${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_menu() {
    echo -e "${BLUE}Available Tools:${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo "  1) Port Manager          - Port checking and management"
    echo "  2) System Status         - Comprehensive system health check"
    echo "  3) Log Manager           - Log viewing, searching, and analysis"
    echo "  4) Vector DB Tool        - Vector database management and search"
    echo "  5) Nextcloud Setup       - Install and configure Nextcloud"
    echo "  6) Podman Playground     - Container management playground"
    echo "  7) AI App Config         - Configure AI applications (Ollama, GPT4All, etc.)"
    echo "  8) Password Manager      - Install and configure Bitwarden/Vaultwarden"
    echo "  9) Infrastructure Setup   - Install Ansible, Terraform/Pulumi"
    echo "  0) Quit"
    echo
}

check_tools() {
    if [[ ! -d "$TOOLS_DIR" ]]; then
        error "System tools directory not found: $TOOLS_DIR"
        exit 1
    fi
    
    local missing_tools=()
    
    # Check required tools
    if [[ ! -f "$TOOLS_DIR/port_manager.sh" ]]; then
        missing_tools+=("port_manager.sh")
    fi
    
    if [[ ! -f "$TOOLS_DIR/system_status.sh" ]]; then
        missing_tools+=("system_status.sh")
    fi
    
    if [[ ! -f "$TOOLS_DIR/log_manager.sh" ]]; then
        missing_tools+=("log_manager.sh")
    fi
    
    if [[ ! -f "$TOOLS_DIR/vector_db_tool.sh" ]]; then
        missing_tools+=("vector_db_tool.sh")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing tools: ${missing_tools[*]}"
        return 1
    fi
    
    # Make sure all tools are executable
    find "$TOOLS_DIR" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    
    info "All tools checked and ready"
    return 0
}

run_port_manager() {
    if [[ -f "$TOOLS_DIR/port_manager.sh" ]]; then
        clear
        "$TOOLS_DIR/port_manager.sh" "$@"
    else
        error "Port manager not found"
    fi
}

run_system_status() {
    if [[ -f "$TOOLS_DIR/system_status.sh" ]]; then
        clear
        "$TOOLS_DIR/system_status.sh" "$@"
    else
        error "System status checker not found"
    fi
}

run_log_manager() {
    if [[ -f "$TOOLS_DIR/log_manager.sh" ]]; then
        clear
        "$TOOLS_DIR/log_manager.sh" "$@"
    else
        error "Log manager not found"
    fi
}

run_vector_db_tool() {
    if [[ -f "$TOOLS_DIR/vector_db_tool.sh" ]]; then
        clear
        "$TOOLS_DIR/vector_db_tool.sh" "$@"
    else
        error "Vector database tool not found"
    fi
}

run_nextcloud_setup() {
    echo -e "${BLUE}Nextcloud Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Installing Nextcloud via Docker${NC}"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        echo "Please install Docker first:"
        echo "  sudo apt install docker.io"
        return 1
    fi
    
    # Create Nextcloud data directory
    sudo mkdir -p /var/lib/nextcloud
    
    # Run Nextcloud container
    echo -e "${GREEN}Starting Nextcloud container${NC}"
    docker run -d \
        --name nextcloud \
        -p 8080:80 \
        -v /var/lib/nextcloud:/var/www/html \
        nextcloud:latest
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Nextcloud is running${NC}"
        echo -e "${GREEN}Access Nextcloud at: http://localhost:8080${NC}"
        echo -e "${YELLOW}Initial setup will take a few minutes${NC}"
    else
        error "Failed to start Nextcloud container"
        return 1
    fi
    
    info "Nextcloud setup initiated"
}

run_podman_playground() {
    echo -e "${BLUE}Podman Playground Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Installing Podman${NC}"
    
    # Install Podman
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y podman podman-docker
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y podman
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y podman
    else
        error "Unsupported package manager"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Podman installed${NC}"
    
    # Create podman alias for docker
    echo -e "${GREEN}Creating Docker compatibility aliases${NC}"
    echo "alias docker=podman" >> ~/.bashrc
    echo "alias docker-compose='podman-compose'" >> ~/.bashrc
    
    # Install podman-compose
    echo -e "${GREEN}Installing podman-compose${NC}"
    sudo pip3 install podman-compose
    
    echo -e "${GREEN}SUCCESS: Podman playground ready${NC}"
    echo -e "${GREEN}Use 'podman' command just like 'docker'${NC}"
    
    info "Podman playground setup completed"
}

run_ai_app_config() {
    echo -e "${BLUE}AI Application Configuration${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Configuring AI applications${NC}"
    
    # Configure Ollama
    if command -v ollama >/dev/null 2>&1; then
        echo -e "${GREEN}Ollama found, configuring${NC}"
        
        # Create config directory
        mkdir -p ~/.config/ollama
        
        # Set up default configuration
        cat > ~/.config/ollama/config.json <<EOF
{
  "host": "0.0.0.0",
  "port": 11434,
  "origins": ["*"]
}
EOF
        
        echo -e "${GREEN}Ollama configuration updated${NC}"
        
        # Pull a default model
        echo -e "${GREEN}Pulling default model (llama3.2)${NC}"
        ollama pull llama3.2 &
    else
        echo -e "${YELLOW}Ollama not found${NC}"
    fi
    
    # Configure GPT4All (placeholder)
    echo -e "${GREEN}Setting up GPT4All configuration${NC}"
    mkdir -p ~/.config/gpt4all
    
    # Configure AnythingLLM (placeholder)
    echo -e "${GREEN}Setting up AnythingLLM configuration${NC}"
    mkdir -p ~/.config/anythingllm
    
    echo -e "${GREEN}AI application configuration completed${NC}"
    echo -e "${YELLOW}Models will download in background${NC}"
    
    info "AI application configuration initiated"
}

run_password_manager() {
    echo -e "${BLUE}Password Manager Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Setting up Vaultwarden (Bitwarden compatible)${NC}"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        echo "Please install Docker first:"
        echo "  sudo apt install docker.io"
        return 1
    fi
    
    # Create Vaultwarden data directory
    sudo mkdir -p /var/lib/vaultwarden
    
    # Generate encryption key
    ENCRYPTION_KEY=$(openssl rand -base64 48)
    
    # Run Vaultwarden container
    echo -e "${GREEN}Starting Vaultwarden container${NC}"
    docker run -d \
        --name vaultwarden \
        -e WEBSOCKET_ENABLED=true \
        -e SIGNUPS_ALLOWED=true \
        -e ADMIN_TOKEN=$(openssl rand -base64 32) \
        -e ROCKET_PORT=80 \
        -v /var/lib/vaultwarden:/data/ \
        -p 8081:80 \
        -p 3012:3012 \
        vaultwarden/server:latest
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Vaultwarden is running${NC}"
        echo -e "${GREEN}Access Vaultwarden at: http://localhost:8081${NC}"
        echo -e "${GREEN}Admin panel: http://localhost:8081/admin (token in logs)${NC}"
        echo -e "${YELLOW}Note: You have a Bitwarden subscription, so you can also use the official Bitwarden server${NC}"
    else
        error "Failed to start Vaultwarden container"
        return 1
    fi
    
    info "Vaultwarden setup initiated"
}

run_infrastructure_setup() {
    echo -e "${BLUE}Infrastructure Tools Setup${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo -e "${GREEN}Installing Ansible${NC}"
    
    # Install Ansible
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y ansible
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y ansible
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y ansible
    else
        error "Unsupported package manager"
        return 1
    fi
    
    echo -e "${GREEN}SUCCESS: Ansible installed${NC}"
    echo "Ansible version: $(ansible --version | head -1)"
    
    # Install Terraform
    echo -e "${GREEN}Installing Terraform${NC}"
    
    # Download and install Terraform
    TERRAFORM_VERSION="1.9.5"
    wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    sudo unzip /tmp/terraform.zip -d /usr/local/bin/
    rm /tmp/terraform.zip
    
    echo -e "${GREEN}SUCCESS: Terraform installed${NC}"
    echo "Terraform version: $(terraform version | head -1)"
    
    # Install Pulumi (optional)
    echo -e "${GREEN}Installing Pulumi${NC}"
    curl -fsSL https://get.pulumi.com | sh
    
    echo -e "${GREEN}SUCCESS: Pulumi installed${NC}"
    echo "Pulumi version: $(~/.pulumi/bin/pulumi version)"
    
    # Add to PATH
    echo 'export PATH=$PATH:~/.pulumi/bin' >> ~/.bashrc
    
    echo -e "${GREEN}Infrastructure tools setup completed${NC}"
    info "Ansible, Terraform, and Pulumi are ready to use"
}

show_help() {
    echo "Usage: $0 [TOOL] [OPTIONS]"
    echo
    echo "Tools:"
    echo "  port-manager     Run Port Manager"
    echo "  system-status    Run System Status Checker"
    echo "  log-manager      Run Log Manager"
    echo "  vector-db        Run Vector Database Tool"
    echo "  nextcloud        Install Nextcloud"
    echo "  podman           Set up Podman Playground"
    echo "  ai-config        Configure AI Applications"
    echo "  password-manager Install Password Manager"
    echo "  infrastructure   Install Infrastructure Tools"
    echo "  interactive      Interactive menu (default)"
    echo "  help             Show this help message"
    echo
    echo "Examples:"
    echo "  $0 interactive"
    echo "  $0 port-manager list"
    echo "  $0 system-status --all"
    echo "  $0 log-manager search \"error\""
    echo "  $0 vector-db status"
}

# Main execution
main() {
    local mode=${1:-"interactive"}
    
    case "$mode" in
        port-manager)
            shift
            run_port_manager "$@"
            ;;
        system-status)
            shift
            run_system_status "$@"
            ;;
        log-manager)
            shift
            run_log_manager "$@"
            ;;
        vector-db)
            shift
            run_vector_db_tool "$@"
            ;;
        nextcloud)
            run_nextcloud_setup
            ;;
        podman)
            run_podman_playground
            ;;
        ai-config)
            run_ai_app_config
            ;;
        password-manager)
            run_password_manager
            ;;
        infrastructure)
            run_infrastructure_setup
            ;;
        interactive)
            check_tools
            
            while true; do
                print_header
                print_menu
                
                echo -n "Select an option (0-9): "
                read -r choice
                
                case $choice in
                    1)
                        run_port_manager
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    2)
                        run_system_status
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    3)
                        run_log_manager
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    4)
                        run_vector_db_tool
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    5)
                        run_nextcloud_setup
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    6)
                        run_podman_playground
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    7)
                        run_ai_app_config
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    8)
                        run_password_manager
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    9)
                        run_infrastructure_setup
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                    0)
                        echo -e "${GREEN}Goodbye!${NC}"
                        exit 0
                        ;;
                    *)
                        echo -e "${RED}Invalid option. Please select 0-9.${NC}"
                        echo
                        echo "Press Enter to continue..."
                        read -r
                        ;;
                esac
            done
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $mode${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
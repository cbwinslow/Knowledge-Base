#!/usr/bin/env bash
#===============================================================================
# ██████╗  ██████╗ ██████╗  █████╗ ███╗   ██╗ ██████╗     ██████╗ ██╗      █████╗ ███╗   ██╗ ██████╗ 
# ██╔══██╗██╔═══██╗██╔══██╗██╔══██╗████╗  ██║██╔════╝     ██╔══██╗██║     ██╔══██╗████╗  ██║██╔════╝ 
# ██████╔╝██║   ██║██║  ██║███████║██╔██╗ ██║██║  ███╗    ██████╔╝██║     ███████║██╔██╗ ██║██║  ███╗
# ██╔═══╝ ██║   ██║██║  ██║██╔══██║██║╚██╗██║██║   ██║    ██╔═══╝ ██║     ██╔══██║██║╚██╗██║██║   ██║
# ██║     ╚██████╔╝██████╔╝██║  ██║██║ ╚████║╚██████╔╝    ██║     ███████╗██║  ██║██║ ╚████║╚██████╔╝
# ╚═╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝ 
#===============================================================================
# File: podman_playground_installer.sh
# Description: Podman installation and playground setup script
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/podman_playground_installer.log"
TEMP_DIR="/tmp/podman_playground"
PLAYGROUND_DIR="$HOME/podman_playground"

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
    echo -e "${BLUE}Podman Playground Installer - Container Management Environment${NC}"
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

# Podman installation functions
install_podman() {
    print_section_header "Installing Podman"
    
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
    
    # Install Podman
    echo -e "${GREEN}Installing Podman${NC}"
    
    case "$PKG_MANAGER" in
        apt)
            apt-get update
            apt-get install -y podman podman-docker
            ;;
        dnf)
            dnf install -y podman podman-docker
            ;;
        yum)
            yum install -y podman podman-docker
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Podman installed${NC}"
    else
        error "Failed to install Podman"
        return 1
    fi
    
    # Show Podman version
    echo -e "${GREEN}Podman Version: ${NC}$(podman --version | head -1)"
    
    # Enable Podman socket for Docker compatibility
    if systemctl list-unit-files | grep -q podman.socket; then
        systemctl enable --now podman.socket
        echo -e "${GREEN}Podman Socket: ${NC}ENABLED"
    fi
    
    info "Podman installation completed"
}

install_podman_compose() {
    print_section_header "Installing Podman Compose"
    
    # Check if pip is available
    if command -v pip3 >/dev/null 2>&1; then
        echo -e "${GREEN}Installing podman-compose via pip${NC}"
        pip3 install podman-compose
    elif command -v pip >/dev/null 2>&1; then
        echo -e "${GREEN}Installing podman-compose via pip${NC}"
        pip install podman-compose
    else
        # Install pip first
        echo -e "${GREEN}Installing pip first${NC}"
        if command -v apt >/dev/null 2>&1; then
            apt-get install -y python3-pip
        elif command -v dnf >/dev/null 2>&1; then
            dnf install -y python3-pip
        elif command -v yum >/dev/null 2>&1; then
            yum install -y python3-pip
        fi
        
        # Now install podman-compose
        pip3 install podman-compose
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: podman-compose installed${NC}"
        echo -e "${GREEN}podman-compose Version: ${NC}$(podman-compose --version 2>/dev/null || echo 'Unknown')"
    else
        error "Failed to install podman-compose"
        return 1
    fi
    
    info "Podman Compose installation completed"
}

install_buildah() {
    print_section_header "Installing Buildah"
    
    # Install Buildah
    echo -e "${GREEN}Installing Buildah${NC}"
    
    if command -v apt >/dev/null 2>&1; then
        apt-get install -y buildah
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y buildah
    elif command -v yum >/dev/null 2>&1; then
        yum install -y buildah
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Buildah installed${NC}"
        echo -e "${GREEN}Buildah Version: ${NC}$(buildah --version | head -1)"
    else
        error "Failed to install Buildah"
        return 1
    fi
    
    info "Buildah installation completed"
}

install_skopeo() {
    print_section_header "Installing Skopeo"
    
    # Install Skopeo
    echo -e "${GREEN}Installing Skopeo${NC}"
    
    if command -v apt >/dev/null 2>&1; then
        apt-get install -y skopeo
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y skopeo
    elif command -v yum >/dev/null 2>&1; then
        yum install -y skopeo
    fi
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Skopeo installed${NC}"
        echo -e "${GREEN}Skopeo Version: ${NC}$(skopeo --version | head -1)"
    else
        error "Failed to install Skopeo"
        return 1
    fi
    
    info "Skopeo installation completed"
}

configure_aliases() {
    print_section_header "Configuring Docker Compatibility Aliases"
    
    # Create aliases for Docker compatibility
    local bashrc_file="$HOME/.bashrc"
    local zshrc_file="$HOME/.zshrc"
    
    # Docker compatibility aliases
    local aliases='
# Podman Docker compatibility aliases
alias docker=podman
alias docker-compose="podman-compose"
alias docker-machine="podman-machine"
'
    
    # Add to bashrc if it exists
    if [[ -f "$bashrc_file" ]]; then
        echo "$aliases" >> "$bashrc_file"
        echo -e "${GREEN}Aliases added to: ${NC}$bashrc_file"
    fi
    
    # Add to zshrc if it exists
    if [[ -f "$zshrc_file" ]]; then
        echo "$aliases" >> "$zshrc_file"
        echo -e "${GREEN}Aliases added to: ${NC}$zshrc_file"
    fi
    
    # Also add to current session
    eval "$aliases"
    
    echo -e "${GREEN}SUCCESS: Docker compatibility aliases configured${NC}"
    echo -e "${YELLOW}Note: Start a new shell or run 'source ~/.bashrc' to use aliases${NC}"
    
    info "Docker compatibility aliases configured"
}

create_playground_structure() {
    print_section_header "Creating Podman Playground Structure"
    
    # Create playground directory
    mkdir -p "$PLAYGROUND_DIR"
    mkdir -p "$PLAYGROUND_DIR/examples"
    mkdir -p "$PLAYGROUND_DIR/projects"
    mkdir -p "$PLAYGROUND_DIR/scratch"
    
    # Create example Dockerfile
    cat > "$PLAYGROUND_DIR/examples/Dockerfile" <<'EOF'
FROM docker.io/library/alpine:latest

LABEL maintainer="Podman Playground User"
LABEL description="Simple Alpine container for testing"

RUN apk add --no-cache \
    curl \
    wget \
    vim \
    git

WORKDIR /app
COPY . .

CMD ["sh"]
EOF
    
    # Create example docker-compose.yml
    cat > "$PLAYGROUND_DIR/examples/docker-compose.yml" <<'EOF'
version: '3.8'

services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro
    restart: unless-stopped
    
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    volumes:
      - .:/app
      - /app/node_modules
    command: npm run dev
EOF
    
    # Create simple HTML for nginx
    mkdir -p "$PLAYGROUND_DIR/examples/html"
    cat > "$PLAYGROUND_DIR/examples/html/index.html" <<'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Podman Playground</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f0f0f0; }
        .container { max-width: 800px; margin: 0 auto; background: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .tip { background: #e8f4fd; border-left: 4px solid #3498db; padding: 15px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Welcome to Podman Playground!</h1>
        <p>This is a simple example served by Nginx container.</p>
        
        <div class="tip">
            <strong>Tip:</strong> Try these commands in your playground:
            <ul>
                <li><code>podman run -d -p 8080:80 nginx:alpine</code></li>
                <li><code>podman ps</code></li>
                <li><code>podman logs &lt;container_id&gt;</code></li>
                <li><code>podman stop &lt;container_id&gt;</code></li>
            </ul>
        </div>
        
        <h2>Getting Started</h2>
        <ol>
            <li>Navigate to the examples directory: <code>cd $HOME/podman_playground/examples</code></li>
            <li>Build the example container: <code>podman build -t myapp .</code></li>
            <li>Run the container: <code>podman run -d -p 8081:80 myapp</code></li>
            <li>Access it at: <a href="http://localhost:8081">http://localhost:8081</a></li>
        </ol>
    </div>
</body>
</html>
EOF
    
    # Create README
    cat > "$PLAYGROUND_DIR/README.md" <<'EOF'
# Podman Playground

This is your personal Podman playground environment. Here you can experiment with containers, build images, and test containerized applications.

## Directory Structure

- `examples/` - Sample Dockerfiles and compose files
- `projects/` - Your container projects
- `scratch/` - Temporary experiments

## Useful Commands

### Basic Podman Commands
```bash
# Run a container
podman run -d -p 8080:80 nginx:alpine

# List running containers
podman ps

# Stop a container
podman stop <container_id>

# View logs
podman logs <container_id>
```

### Building Images
```bash
# Build from Dockerfile
podman build -t myimage .

# Tag an image
podman tag myimage myrepo/myimage:v1.0

# Push to registry
podman push myrepo/myimage:v1.0
```

### Podman Compose
```bash
# Start services
podman-compose up -d

# Stop services
podman-compose down

# View logs
podman-compose logs
```

## Docker Compatibility

Thanks to the aliases configured, you can also use Docker commands:
```bash
docker run -d -p 8080:80 nginx:alpine
docker ps
docker stop <container_id>
```

Have fun experimenting!
EOF
    
    echo -e "${GREEN}SUCCESS: Podman playground structure created${NC}"
    echo -e "${GREEN}Playground directory: ${NC}$PLAYGROUND_DIR"
    
    info "Podman playground structure created"
}

show_podman_status() {
    print_section_header "Podman Status"
    
    # Check if Podman is installed
    if command -v podman >/dev/null 2>&1; then
        echo -e "${GREEN}Podman: ${NC}INSTALLED ($(podman --version | head -1))"
        
        # Show info
        echo -e "${GREEN}Info: ${NC}"
        podman info --format "table {{.Host.OS}},{{.Host.Arch}},{{.Store.GraphDriverName}}" 2>/dev/null | sed "s/^/  /" || echo "  Unable to retrieve info"
        
        # Show running containers
        local container_count=$(podman ps -q | wc -l)
        echo -e "${GREEN}Running Containers: ${NC}$container_count"
        if [[ $container_count -gt 0 ]]; then
            echo -e "  $(podman ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 | head -5 | sed "s/^/  /")"
            if [[ $container_count -gt 5 ]]; then
                echo -e "  ${YELLOW}... and $((container_count - 5)) more${NC}"
            fi
        fi
    else
        echo -e "${RED}Podman: ${NC}NOT INSTALLED"
    fi
    
    # Check podman-compose
    if command -v podman-compose >/dev/null 2>&1; then
        echo -e "${GREEN}podman-compose: ${NC}INSTALLED ($(podman-compose --version 2>/dev/null || echo 'Unknown'))"
    else
        echo -e "${YELLOW}podman-compose: ${NC}NOT INSTALLED"
    fi
    
    # Check Buildah
    if command -v buildah >/dev/null 2>&1; then
        echo -e "${GREEN}Buildah: ${NC}INSTALLED ($(buildah --version | head -1))"
    else
        echo -e "${YELLOW}Buildah: ${NC}NOT INSTALLED"
    fi
    
    # Check Skopeo
    if command -v skopeo >/dev/null 2>&1; then
        echo -e "${GREEN}Skopeo: ${NC}INSTALLED ($(skopeo --version | head -1))"
    else
        echo -e "${YELLOW}Skopeo: ${NC}NOT INSTALLED"
    fi
    
    # Show playground directory
    if [[ -d "$PLAYGROUND_DIR" ]]; then
        echo -e "${GREEN}Playground Directory: ${NC}$PLAYGROUND_DIR"
        echo -e "${GREEN}Playground Size: ${NC}$(du -sh "$PLAYGROUND_DIR" 2>/dev/null | cut -f1 || echo 'Unknown')"
    fi
    
    info "Podman status check completed"
}

run_example_container() {
    print_section_header "Running Example Container"
    
    # Check if Podman is installed
    if ! command -v podman >/dev/null 2>&1; then
        error "Podman is not installed"
        return 1
    fi
    
    echo -e "${GREEN}Starting example Nginx container${NC}"
    
    # Run a simple container
    podman run -d \
        --name podman_playground_example \
        -p 8082:80 \
        docker.io/library/nginx:alpine
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Example container started${NC}"
        echo -e "${GREEN}Access at: ${NC}http://localhost:8082"
        
        # Show container info
        echo
        echo -e "${GREEN}Container Info:${NC}"
        podman ps --filter "name=podman_playground_example" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | sed "s/^/  /"
    else
        error "Failed to start example container"
        return 1
    fi
    
    info "Example container started"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  install          Install all Podman tools"
    echo "  install-podman   Install Podman only"
    echo "  install-compose  Install podman-compose"
    echo "  install-buildah  Install Buildah"
    echo "  install-skopeo   Install Skopeo"
    echo "  configure        Configure Docker compatibility aliases"
    echo "  playground       Create playground structure"
    echo "  status           Show Podman status"
    echo "  example          Run example container"
    echo "  help             Show this help message"
    echo
    echo "Examples:"
    echo "  $0 install"
    echo "  $0 install-podman"
    echo "  $0 install-compose"
    echo "  $0 configure"
    echo "  $0 playground"
    echo "  $0 status"
    echo "  $0 example"
}

# Main execution
main() {
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        install)
            install_podman
            install_podman_compose
            install_buildah
            install_skopeo
            configure_aliases
            create_playground_structure
            ;;
        install-podman)
            install_podman
            ;;
        install-compose)
            install_podman_compose
            ;;
        install-buildah)
            install_buildah
            ;;
        install-skopeo)
            install_skopeo
            ;;
        configure)
            configure_aliases
            ;;
        playground)
            create_playground_structure
            ;;
        status)
            show_podman_status
            ;;
        example)
            run_example_container
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
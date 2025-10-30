#!/usr/bin/env bash
#
# Deploy Knowledge Base to Dell Server
#
# This script deploys the knowledge base to a Dell server running
# in your cloudcurio environment.
#

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Load configuration
if [[ -f "$REPO_ROOT/.deploy_config" ]]; then
    source "$REPO_ROOT/.deploy_config"
else
    log_warn "No .deploy_config found, using defaults"
fi

# Dell Server Configuration
DELL_SERVER="${DELL_SERVER:-your-dell-server.local}"
DELL_USER="${DELL_USER:-${USER}}"
DELL_PATH="${DELL_PATH:-/opt/knowledge-base}"
DELL_PORT="${DELL_PORT:-22}"

# Docker configuration
USE_DOCKER="${USE_DOCKER:-true}"
DOCKER_COMPOSE_FILE="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Knowledge Base to Dell server

Options:
    -h, --help              Show this help message
    -s, --server SERVER     Dell server hostname
    -u, --user USER         SSH user (default: current user)
    -p, --path PATH         Remote deployment path
    --port PORT             SSH port (default: 22)
    --no-docker             Don't use Docker deployment
    --dry-run               Show what would be done without doing it

Examples:
    $0 -s dell.cloudcurio.local
    $0 --server 192.168.1.100 --user admin
    $0 --dry-run

EOF
    exit 1
}

# Parse arguments
DRY_RUN=false
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -s|--server)
            DELL_SERVER="$2"
            shift 2
            ;;
        -u|--user)
            DELL_USER="$2"
            shift 2
            ;;
        -p|--path)
            DELL_PATH="$2"
            shift 2
            ;;
        --port)
            DELL_PORT="$2"
            shift 2
            ;;
        --no-docker)
            USE_DOCKER=false
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            ;;
    esac
done

# Main deployment
main() {
    log_info "Starting deployment to Dell server..."
    log_info "Server: $DELL_SERVER"
    log_info "User: $DELL_USER"
    log_info "Path: $DELL_PATH"
    
    # Check SSH connectivity
    log_info "Testing SSH connection..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would test SSH connection"
    else
        if ! ssh -p "$DELL_PORT" -o ConnectTimeout=5 "$DELL_USER@$DELL_SERVER" "echo 'Connection successful'" &>/dev/null; then
            log_error "Cannot connect to $DELL_SERVER"
            log_error "Please check server address and SSH configuration"
            exit 1
        fi
        log_success "SSH connection successful"
    fi
    
    # Create remote directory
    log_info "Creating remote directory..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would create $DELL_PATH on remote server"
    else
        ssh -p "$DELL_PORT" "$DELL_USER@$DELL_SERVER" "mkdir -p $DELL_PATH"
        log_success "Remote directory ready"
    fi
    
    # Sync files
    log_info "Syncing files to Dell server..."
    
    local rsync_cmd="rsync -avz --delete \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='.env' \
        --exclude='logs/*' \
        --exclude='.DS_Store' \
        -e 'ssh -p $DELL_PORT' \
        $REPO_ROOT/ \
        $DELL_USER@$DELL_SERVER:$DELL_PATH/"
    
    if $DRY_RUN; then
        log_info "[DRY RUN] Would run: $rsync_cmd"
    else
        if $rsync_cmd; then
            log_success "Files synced successfully"
        else
            log_error "File sync failed"
            exit 1
        fi
    fi
    
    # Deploy with Docker
    if [[ "$USE_DOCKER" == "true" ]]; then
        log_info "Deploying with Docker Compose..."
        
        if $DRY_RUN; then
            log_info "[DRY RUN] Would deploy Docker services"
        else
            ssh -p "$DELL_PORT" "$DELL_USER@$DELL_SERVER" << 'ENDSSH'
                cd /opt/knowledge-base
                
                # Check if docker-compose exists
                if [[ ! -f docker-compose.yml ]]; then
                    echo "No docker-compose.yml found, skipping Docker deployment"
                    exit 0
                fi
                
                # Pull latest images
                echo "Pulling Docker images..."
                docker-compose pull
                
                # Start services
                echo "Starting services..."
                docker-compose up -d
                
                # Show status
                echo "Service status:"
                docker-compose ps
ENDSSH
            log_success "Docker services deployed"
        fi
    fi
    
    # Set up systemd service (optional)
    if [[ -f "$REPO_ROOT/scripts/deployment/knowledge-base.service" ]]; then
        log_info "Setting up systemd service..."
        
        if $DRY_RUN; then
            log_info "[DRY RUN] Would install systemd service"
        else
            ssh -p "$DELL_PORT" "$DELL_USER@$DELL_SERVER" << ENDSSH
                sudo cp $DELL_PATH/scripts/deployment/knowledge-base.service /etc/systemd/system/
                sudo systemctl daemon-reload
                sudo systemctl enable knowledge-base
                sudo systemctl restart knowledge-base
ENDSSH
            log_success "Systemd service installed"
        fi
    fi
    
    # Run post-deployment script if it exists
    if [[ -f "$REPO_ROOT/scripts/deployment/post-deploy.sh" ]]; then
        log_info "Running post-deployment script..."
        
        if $DRY_RUN; then
            log_info "[DRY RUN] Would run post-deployment script"
        else
            ssh -p "$DELL_PORT" "$DELL_USER@$DELL_SERVER" "cd $DELL_PATH && bash scripts/deployment/post-deploy.sh"
            log_success "Post-deployment completed"
        fi
    fi
    
    # Show deployment summary
    log_success "Deployment completed successfully!"
    echo ""
    log_info "Summary:"
    log_info "  Server: $DELL_SERVER"
    log_info "  Path: $DELL_PATH"
    log_info "  Docker: $USE_DOCKER"
    echo ""
    log_info "Access your knowledge base at:"
    log_info "  SSH: ssh -p $DELL_PORT $DELL_USER@$DELL_SERVER"
    log_info "  Path: $DELL_PATH"
    
    if [[ "$USE_DOCKER" == "true" ]]; then
        log_info "  Logs: ssh $DELL_USER@$DELL_SERVER 'cd $DELL_PATH && docker-compose logs -f'"
    fi
}

# Save configuration
save_config() {
    cat > "$REPO_ROOT/.deploy_config" << EOF
# Dell Server Deployment Configuration
# Generated: $(date)

DELL_SERVER="$DELL_SERVER"
DELL_USER="$DELL_USER"
DELL_PATH="$DELL_PATH"
DELL_PORT="$DELL_PORT"
USE_DOCKER="$USE_DOCKER"
EOF
    
    log_info "Configuration saved to .deploy_config"
}

# Run main
main

# Offer to save configuration
if [[ "$DRY_RUN" == "false" ]]; then
    echo ""
    read -p "Save this configuration for future deployments? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        save_config
    fi
fi

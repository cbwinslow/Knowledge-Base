#!/usr/bin/env bash
#
# Deploy Knowledge Base to Cloudflare Pages
#
# This script automates deployment to Cloudflare Pages with
# proper configuration and optimization.
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
NC='\033[0m'

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

# Configuration
PROJECT_NAME="${CF_PROJECT_NAME:-knowledge-base}"
BRANCH="${CF_BRANCH:-main}"
BUILD_COMMAND="${CF_BUILD_COMMAND:-npm run build}"
BUILD_DIR="${CF_BUILD_DIR:-out}"

# Usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Knowledge Base to Cloudflare Pages

Options:
    -h, --help              Show this help message
    -p, --project NAME      Cloudflare project name
    -b, --branch BRANCH     Git branch to deploy (default: main)
    --build-cmd CMD         Build command
    --build-dir DIR         Build output directory
    --direct                Use Wrangler for direct deployment
    --dry-run               Show what would be done

Examples:
    $0                                    # Deploy main branch
    $0 --branch develop                   # Deploy develop branch
    $0 --direct                          # Direct deploy with Wrangler

Configuration:
    Set these environment variables for defaults:
    - CF_PROJECT_NAME
    - CF_BRANCH
    - CF_BUILD_COMMAND
    - CF_BUILD_DIR
    - CLOUDFLARE_API_TOKEN (for direct deploy)

EOF
    exit 1
}

# Parse arguments
DRY_RUN=false
DIRECT_DEPLOY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -b|--branch)
            BRANCH="$2"
            shift 2
            ;;
        --build-cmd)
            BUILD_COMMAND="$2"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --direct)
            DIRECT_DEPLOY=true
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

# Check if we're in a git repository
check_git() {
    if [[ ! -d "$REPO_ROOT/.git" ]]; then
        log_error "Not a git repository: $REPO_ROOT"
        exit 1
    fi
}

# Check for uncommitted changes
check_uncommitted() {
    if [[ -n $(git -C "$REPO_ROOT" status -s) ]]; then
        log_warn "You have uncommitted changes"
        git -C "$REPO_ROOT" status -s
        echo ""
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Deploy via Git (automatic Cloudflare Pages deployment)
deploy_via_git() {
    log_info "Deploying via Git push to $BRANCH branch..."
    
    cd "$REPO_ROOT"
    
    # Commit any changes
    if [[ -n $(git status -s) ]]; then
        log_info "Committing changes..."
        if $DRY_RUN; then
            log_info "[DRY RUN] Would commit and push"
        else
            git add .
            git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M:%S')"
        fi
    fi
    
    # Push to branch
    log_info "Pushing to origin/$BRANCH..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would run: git push origin $BRANCH"
    else
        if git push origin "$BRANCH"; then
            log_success "Pushed to GitHub"
        else
            log_error "Failed to push to GitHub"
            exit 1
        fi
    fi
    
    log_success "Deployment initiated!"
    log_info "Cloudflare Pages will automatically build and deploy"
    log_info "Check status at: https://dash.cloudflare.com/pages"
}

# Direct deployment via Wrangler
deploy_via_wrangler() {
    log_info "Deploying directly via Wrangler..."
    
    # Check if wrangler is installed
    if ! command -v wrangler &> /dev/null; then
        log_error "Wrangler CLI not found"
        log_info "Install with: npm install -g wrangler"
        exit 1
    fi
    
    # Check for API token
    if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log_error "CLOUDFLARE_API_TOKEN not set"
        log_info "Get token from: https://dash.cloudflare.com/profile/api-tokens"
        exit 1
    fi
    
    cd "$REPO_ROOT"
    
    # Create wrangler.toml if it doesn't exist
    if [[ ! -f "wrangler.toml" ]]; then
        log_info "Creating wrangler.toml..."
        cat > wrangler.toml << EOF
name = "$PROJECT_NAME"
compatibility_date = "$(date +%Y-%m-%d)"

[site]
bucket = "$BUILD_DIR"
EOF
    fi
    
    # Build the site
    log_info "Building site..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would run: $BUILD_COMMAND"
    else
        if [[ -n "$BUILD_COMMAND" ]]; then
            eval "$BUILD_COMMAND"
        fi
    fi
    
    # Deploy
    log_info "Deploying to Cloudflare Pages..."
    if $DRY_RUN; then
        log_info "[DRY RUN] Would run: wrangler pages deploy $BUILD_DIR --project-name=$PROJECT_NAME"
    else
        wrangler pages deploy "$BUILD_DIR" --project-name="$PROJECT_NAME"
    fi
    
    log_success "Direct deployment completed!"
}

# Create Cloudflare Pages configuration
create_pages_config() {
    log_info "Creating Cloudflare Pages configuration..."
    
    cat > "$REPO_ROOT/.cloudflare-pages.json" << EOF
{
  "project_name": "$PROJECT_NAME",
  "production_branch": "$BRANCH",
  "build_config": {
    "build_command": "$BUILD_COMMAND",
    "destination_dir": "$BUILD_DIR",
    "root_dir": ""
  },
  "preview_deployment_setting": "all",
  "deployment_configs": {
    "preview": {},
    "production": {}
  }
}
EOF
    
    log_success "Configuration saved to .cloudflare-pages.json"
}

# Main deployment flow
main() {
    log_info "Knowledge Base Cloudflare Deployment"
    log_info "Project: $PROJECT_NAME"
    log_info "Branch: $BRANCH"
    echo ""
    
    # Pre-flight checks
    check_git
    
    if [[ "$DRY_RUN" == "false" ]]; then
        check_uncommitted
    fi
    
    # Create configuration file
    create_pages_config
    
    # Choose deployment method
    if [[ "$DIRECT_DEPLOY" == "true" ]]; then
        deploy_via_wrangler
    else
        deploy_via_git
    fi
    
    echo ""
    log_success "Deployment process complete!"
    echo ""
    log_info "Next steps:"
    log_info "1. Visit https://dash.cloudflare.com/pages"
    log_info "2. Check deployment status for project: $PROJECT_NAME"
    log_info "3. Configure custom domain (optional)"
    echo ""
    log_info "Deployment URL will be:"
    log_info "  https://$PROJECT_NAME.pages.dev"
}

# Show help for first-time setup
show_setup_help() {
    cat << 'EOF'

First-time Cloudflare Pages Setup:

1. Create Cloudflare account: https://dash.cloudflare.com/sign-up

2. Connect GitHub repository:
   - Go to: https://dash.cloudflare.com/pages
   - Click "Create a project"
   - Connect to GitHub
   - Select this repository

3. Configure build settings:
   - Framework preset: None (or Next.js if applicable)
   - Build command: (leave empty or set as needed)
   - Build output directory: public or out
   - Root directory: (leave empty)

4. Set environment variables (if needed):
   - OPENAI_API_KEY (for AI features)
   - Any other required variables

5. Deploy!

For automatic deployments, just push to your main branch.
For manual deployments, use this script.

EOF
}

# Check if this is first run
if [[ ! -f "$REPO_ROOT/.cloudflare-pages.json" ]] && [[ "$DRY_RUN" == "false" ]]; then
    log_info "First-time setup detected"
    show_setup_help
    echo ""
    read -p "Have you completed Cloudflare Pages setup? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Please complete setup first, then run this script again"
        exit 0
    fi
fi

# Run main
main

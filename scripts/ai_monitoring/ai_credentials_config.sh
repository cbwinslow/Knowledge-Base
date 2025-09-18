#!/usr/bin/env bash
#===============================================================================
# █████╗ ██╗ ██████╗     ██████╗██████╗  █████╗ ███████╗████████╗███████╗██████╗ 
# ██╔══██╗██║██╔════╝    ██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
# ███████║██║██║         ██║     ██████╔╝███████║███████╗   ██║   █████╗  ██████╔╝
# ██╔══██║██║██║         ██║     ██╔══██╗██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
# ██║  ██║██║╚██████╗    ╚██████╗██║  ██║██║  ██║███████║   ██║   ███████╗██║  ██║
# ╚═╝  ╚═╝╚═╝ ╚═════╝     ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
#===============================================================================
# File: ai_credentials_config.sh
# Description: AI application credentials configuration script
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/ai_credentials_config.log"
TEMP_DIR="/tmp/ai_credentials_config"
CONFIG_DIR="$HOME/.config/ai_apps"
CREDS_FILE="$CONFIG_DIR/credentials.conf"

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
    echo -e "${BLUE}AI Application Credentials Configuration${NC}"
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

create_config_dir() {
    mkdir -p "$CONFIG_DIR"
    chmod 700 "$CONFIG_DIR"
}

# AI application configuration functions
configure_ollama() {
    local api_key=${1:-""}
    local base_url=${2:-"http://localhost:11434"}
    
    print_section_header "Configuring Ollama"
    
    # Check if Ollama is installed
    if ! command -v ollama >/dev/null 2>&1; then
        warn "Ollama is not installed"
        echo -e "${YELLOW}To install Ollama:${NC}"
        echo "  curl -fsSL https://ollama.com/install.sh | sh"
        echo
        read -p "Continue configuration anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 1
        fi
    else
        echo -e "${GREEN}Ollama: ${NC}INSTALLED ($(ollama --version | head -1))"
    fi
    
    # Create Ollama config
    mkdir -p "$CONFIG_DIR/ollama"
    
    cat > "$CONFIG_DIR/ollama/config.json" <<EOF
{
  "host": "0.0.0.0",
  "port": 11434,
  "origins": ["*"],
  "api_key": "$api_key"
}
EOF
    
    # Set environment variables
    cat >> "$CONFIG_DIR/ollama/env.sh" <<EOF
export OLLAMA_HOST="$base_url"
export OLLAMA_API_KEY="$api_key"
EOF
    
    echo -e "${GREEN}SUCCESS: Ollama configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/ollama/config.json"
    echo -e "${GREEN}Environment: ${NC}$CONFIG_DIR/ollama/env.sh"
    
    # Source the environment
    source "$CONFIG_DIR/ollama/env.sh"
    
    info "Ollama configuration completed"
}

configure_gpt4all() {
    local api_key=${1:-""}
    
    print_section_header "Configuring GPT4All"
    
    # Create GPT4All config directory
    mkdir -p "$CONFIG_DIR/gpt4all"
    
    # Create config file
    cat > "$CONFIG_DIR/gpt4all/config.json" <<EOF
{
  "api_key": "$api_key",
  "model_path": "$HOME/.cache/gpt4all",
  "download_models": true,
  "auto_update": true
}
EOF
    
    echo -e "${GREEN}SUCCESS: GPT4All configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/gpt4all/config.json"
    
    info "GPT4All configuration completed"
}

configure_anythingllm() {
    local api_key=${1:-""}
    local server_url=${2:-"http://localhost:3001"}
    
    print_section_header "Configuring AnythingLLM"
    
    # Create AnythingLLM config directory
    mkdir -p "$CONFIG_DIR/anythingllm"
    
    # Create config file
    cat > "$CONFIG_DIR/anythingllm/config.json" <<EOF
{
  "server_url": "$server_url",
  "api_key": "$api_key",
  "workspace": "default",
  "auto_embed": true,
  "chunk_size": 1000,
  "chunk_overlap": 200
}
EOF
    
    echo -e "${GREEN}SUCCESS: AnythingLLM configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/anythingllm/config.json"
    
    info "AnythingLLM configuration completed"
}

configure_lm_studio() {
    local api_key=${1:-""}
    local base_url=${2:-"http://localhost:1234"}
    
    print_section_header "Configuring LM Studio"
    
    # Create LM Studio config directory
    mkdir -p "$CONFIG_DIR/lm-studio"
    
    # Create config file
    cat > "$CONFIG_DIR/lm-studio/config.json" <<EOF
{
  "base_url": "$base_url",
  "api_key": "$api_key",
  "model": "gguf",
  "temperature": 0.7,
  "max_tokens": 2048
}
EOF
    
    echo -e "${GREEN}SUCCESS: LM Studio configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/lm-studio/config.json"
    
    info "LM Studio configuration completed"
}

configure_openai() {
    local api_key=${1:-""}
    local organization=${2:-""}
    local project=${3:-""}
    
    print_section_header "Configuring OpenAI"
    
    # Create OpenAI config directory
    mkdir -p "$CONFIG_DIR/openai"
    
    # Create config file
    cat > "$CONFIG_DIR/openai/config.json" <<EOF
{
  "api_key": "$api_key",
  "organization": "$organization",
  "project": "$project",
  "base_url": "https://api.openai.com/v1",
  "timeout": 30,
  "max_retries": 3
}
EOF
    
    # Create environment file
    cat > "$CONFIG_DIR/openai/env.sh" <<EOF
export OPENAI_API_KEY="$api_key"
export OPENAI_ORGANIZATION="$organization"
export OPENAI_PROJECT="$project"
EOF
    
    echo -e "${GREEN}SUCCESS: OpenAI configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/openai/config.json"
    echo -e "${GREEN}Environment: ${NC}$CONFIG_DIR/openai/env.sh"
    
    info "OpenAI configuration completed"
}

configure_anthropic() {
    local api_key=${1:-""}
    
    print_section_header "Configuring Anthropic (Claude)"
    
    # Create Anthropic config directory
    mkdir -p "$CONFIG_DIR/anthropic"
    
    # Create config file
    cat > "$CONFIG_DIR/anthropic/config.json" <<EOF
{
  "api_key": "$api_key",
  "api_url": "https://api.anthropic.com/v1",
  "api_version": "2023-06-01",
  "timeout": 30,
  "max_retries": 3
}
EOF
    
    # Create environment file
    cat > "$CONFIG_DIR/anthropic/env.sh" <<EOF
export ANTHROPIC_API_KEY="$api_key"
EOF
    
    echo -e "${GREEN}SUCCESS: Anthropic configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/anthropic/config.json"
    echo -e "${GREEN}Environment: ${NC}$CONFIG_DIR/anthropic/env.sh"
    
    info "Anthropic configuration completed"
}

configure_google_ai() {
    local api_key=${1:-""}
    
    print_section_header "Configuring Google AI (Gemini)"
    
    # Create Google AI config directory
    mkdir -p "$CONFIG_DIR/google-ai"
    
    # Create config file
    cat > "$CONFIG_DIR/google-ai/config.json" <<EOF
{
  "api_key": "$api_key",
  "api_url": "https://generativelanguage.googleapis.com/v1beta",
  "timeout": 30,
  "max_retries": 3
}
EOF
    
    # Create environment file
    cat > "$CONFIG_DIR/google-ai/env.sh" <<EOF
export GOOGLE_API_KEY="$api_key"
EOF
    
    echo -e "${GREEN}SUCCESS: Google AI configured${NC}"
    echo -e "${GREEN}Config file: ${NC}$CONFIG_DIR/google-ai/config.json"
    echo -e "${GREEN}Environment: ${NC}$CONFIG_DIR/google-ai/env.sh"
    
    info "Google AI configuration completed"
}

show_config_status() {
    print_section_header "AI Application Configuration Status"
    
    # Check each application configuration
    local apps=("ollama" "gpt4all" "anythingllm" "lm-studio" "openai" "anthropic" "google-ai")
    
    for app in "${apps[@]}"; do
        if [[ -d "$CONFIG_DIR/$app" ]]; then
            echo -e "${GREEN}$app: ${NC}CONFIGURED"
            if [[ -f "$CONFIG_DIR/$app/config.json" ]]; then
                echo -e "  ${GREEN}Config: ${NC}$CONFIG_DIR/$app/config.json"
            fi
            if [[ -f "$CONFIG_DIR/$app/env.sh" ]]; then
                echo -e "  ${GREEN}Env: ${NC}$CONFIG_DIR/$app/env.sh"
            fi
        else
            echo -e "${YELLOW}$app: ${NC}NOT CONFIGURED"
        fi
        echo
    done
    
    info "Configuration status check completed"
}

download_sample_models() {
    print_section_header "Downloading Sample Models"
    
    # Check if Ollama is installed and running
    if command -v ollama >/dev/null 2>&1; then
        echo -e "${GREEN}Downloading sample models for Ollama${NC}"
        
        # Download a small model for testing
        echo -e "${GREEN}Pulling llama3.2 (smallest model)${NC}"
        timeout 300 ollama pull llama3.2 &
        OLLAMA_PID=$!
        
        # Show progress
        echo -e "${YELLOW}Download in progress... (this may take a few minutes)${NC}"
        wait $OLLAMA_PID
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}SUCCESS: llama3.2 model downloaded${NC}"
        else
            echo -e "${YELLOW}Model download may still be in progress in background${NC}"
        fi
    else
        echo -e "${YELLOW}Ollama not installed, skipping model downloads${NC}"
    fi
    
    info "Sample model download process initiated"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  ollama [api_key] [base_url]          Configure Ollama"
    echo "  gpt4all [api_key]                     Configure GPT4All"
    echo "  anythingllm [api_key] [server_url]    Configure AnythingLLM"
    echo "  lm-studio [api_key] [base_url]        Configure LM Studio"
    echo "  openai [api_key] [org] [project]      Configure OpenAI"
    echo "  anthropic [api_key]                   Configure Anthropic"
    echo "  google-ai [api_key]                   Configure Google AI"
    echo "  status                                Show configuration status"
    echo "  download-models                       Download sample models"
    echo "  help                                  Show this help message"
    echo
    echo "Examples:"
    echo "  $0 ollama sk-1234567890abcdef http://localhost:11434"
    echo "  $0 openai sk-1234567890abcdef org-12345 proj-12345"
    echo "  $0 status"
    echo "  $0 download-models"
}

# Main execution
main() {
    create_config_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        ollama)
            local api_key="${2:-}"
            local base_url="${3:-http://localhost:11434}"
            configure_ollama "$api_key" "$base_url"
            ;;
        gpt4all)
            local api_key="${2:-}"
            configure_gpt4all "$api_key"
            ;;
        anythingllm)
            local api_key="${2:-}"
            local server_url="${3:-http://localhost:3001}"
            configure_anythingllm "$api_key" "$server_url"
            ;;
        lm-studio)
            local api_key="${2:-}"
            local base_url="${3:-http://localhost:1234}"
            configure_lm_studio "$api_key" "$base_url"
            ;;
        openai)
            local api_key="${2:-}"
            local organization="${3:-}"
            local project="${4:-}"
            configure_openai "$api_key" "$organization" "$project"
            ;;
        anthropic)
            local api_key="${2:-}"
            configure_anthropic "$api_key"
            ;;
        google-ai)
            local api_key="${2:-}"
            configure_google_ai "$api_key"
            ;;
        status)
            show_config_status
            ;;
        download-models)
            download_sample_models
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
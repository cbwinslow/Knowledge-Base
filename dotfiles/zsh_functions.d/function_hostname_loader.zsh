#!/bin/zsh

# =============================================================================
# HOSTNAME-SPECIFIC FUNCTION LOADER
# =============================================================================
# This file loads functions based on the current hostname
# =============================================================================

# Get current hostname
readonly CURRENT_HOST=$(hostname)

# =============================================================================
# HOMELAB SERVER FUNCTIONS (cbwhpz)
# =============================================================================
_load_homelab_functions() {
    # Load homelab-specific functions
    local homelab_functions=(
        "function_docker_management.zsh"
        "function_k8s_tools.zsh"
        "function_backup_tools.zsh"
        "function_monitoring.zsh"
        "function_network_tools.zsh"
        "function_server_maintenance.zsh"
    )
    
    for func_file in "${homelab_functions[@]}"; do
        if [[ -f "$HOME/.zsh_functions.d/homelab/$func_file" ]]; then
            source "$HOME/.zsh_functions.d/homelab/$func_file"
        fi
    done
}

# =============================================================================
# WORKSTATION FUNCTIONS (cbwlnxdell, cbwdellr720, fedora, etc.)
# =============================================================================
_load_workstation_functions() {
    # Load workstation-specific functions
    local workstation_functions=(
        "function_development_tools.zsh"
        "function_git_helpers.zsh"
        "function_productivity.zsh"
        "function_env_bitwarden.zsh"
    )
    
    for func_file in "${workstation_functions[@]}"; do
        if [[ -f "$HOME/.zsh_functions.d/$func_file" ]]; then
            source "$HOME/.zsh_functions.d/$func_file"
        fi
    done
}

# =============================================================================
# SHARED FUNCTIONS (all machines)
# =============================================================================
_load_shared_functions() {
    # Load shared functions for all machines
    local shared_functions=(
        "function_memory_tools.zsh"
        "function_security_scans.zsh"
        "function_take.zsh"
        "cleanup_functions.zsh"
        "display_shell_helpers.zsh"
    )
    
    for func_file in "${shared_functions[@]}"; do
        if [[ -f "$HOME/.zsh_functions.d/$func_file" ]]; then
            source "$HOME/.zsh_functions.d/$func_file"
        fi
    done
}

# =============================================================================
# MAIN LOADER
# =============================================================================
case "$CURRENT_HOST" in
    "cbwhpz")
        echo "🏠 Loading homelab server functions for $CURRENT_HOST..."
        _load_homelab_functions
        _load_shared_functions
        ;;
    "cbwdellr720")
        echo "💻 Loading workstation functions for $CURRENT_HOST..."
        _load_workstation_functions
        _load_shared_functions
        ;;
    "cbwlnxdell")
        echo "💻 Loading workstation functions for $CURRENT_HOST..."
        _load_workstation_functions
        _load_shared_functions
        ;;
    "fedora")
        echo "💻 Loading workstation functions for $CURRENT_HOST..."
        _load_workstation_functions
        _load_shared_functions
        ;;
    *)
        echo "🔧 Loading default functions for unknown host: $CURRENT_HOST..."
        _load_shared_functions
        ;;
esac
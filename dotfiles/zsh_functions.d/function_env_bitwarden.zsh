#!/bin/zsh

# =============================================================================
# BITWARDEN ENVIRONMENT MANAGEMENT FUNCTIONS
# =============================================================================
# Author: cbwinslow
# Description: Functions for populating .env files from Bitwarden vault
# Requirements: bw (Bitwarden CLI), fzf, jq
# =============================================================================

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Print colored output
_print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
_print_success() { echo -e "${GREEN}✅ $1${NC}"; }
_print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
_print_error() { echo -e "${RED}❌ $1${NC}"; }

# Check if required dependencies are installed
_check_dependencies() {
    local missing_deps=()
    
    for cmd in bw fzf jq; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        _print_error "Missing required dependencies: ${missing_deps[*]}"
        _print_info "Install with: sudo dnf install ${missing_deps[*]}"
        return 1
    fi
    
    return 0
}

# Check Bitwarden login status
_check_bw_login() {
    if ! bw status >/dev/null 2>&1; then
        _print_error "Not logged into Bitwarden CLI"
        _print_info "Please run: bw login"
        return 1
    fi
    
    # Check if vault is locked
    if bw status | grep -q "locked"; then
        _print_warning "Bitwarden vault is locked"
        _print_info "Please run: bw unlock"
        return 1
    fi
    
    return 0
}

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

# Populate .env file from .env.example using Bitwarden fuzzy lookup
# Usage: env_from_bw [env_example_file] [output_env_file]
# Example: env_from_bw .env.example .env
env_from_bw() {
    local env_example="${1:-.env.example}"
    local env_file="${2:-.env}"
    local processed_count=0
    local skipped_count=0
    
    # Validate inputs
    if [[ ! -f "$env_example" ]]; then
        _print_error "Environment example file '$env_example' not found"
        return 1
    fi
    
    # Check dependencies
    if ! _check_dependencies; then
        return 1
    fi
    
    # Check Bitwarden status
    if ! _check_bw_login; then
        return 1
    fi
    
    _print_info "Populating .env file from $env_example..."
    
    # Create backup of existing .env file
    if [[ -f "$env_file" ]]; then
        cp "$env_file" "${env_file}.backup.$(date +%Y%m%d_%H%M%S)"
        _print_info "Created backup of existing .env file"
    fi
    
    # Create/clear the output file
    > "$env_file"
    
    # Process each line in the example file
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip comments and empty lines
        if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "${line// }" ]]; then
            echo "$line" >> "$env_file"
            continue
        fi
        
        # Extract variable name and placeholder value
        if [[ "$line" =~ ^[[:space:]]*([^=]+)=(.*)$ ]]; then
            local var_name="${match[1]// /}"  # Remove spaces
            local placeholder="${match[2]}"
            
            # Check if placeholder looks like it needs replacement
            if [[ "$placeholder" =~ ^[\"\']?(your_|change_|placeholder|example|xxx|test|dummy|replace_me) ]]; then
                _print_info "Looking up secret for: $var_name"
                
                # Search for relevant Bitwarden items
                local search_results=$(bw list items --search "$var_name" 2>/dev/null | jq -r '.[] | "\(.name)|\(.id)|\(.type)"' 2>/dev/null || true)
                
                if [[ -n "$search_results" ]]; then
                    # Use fzf to select the right item
                    local bw_item=$(echo "$search_results" | fzf \
                        --prompt="Select Bitwarden item for $var_name: " \
                        --height=40% \
                        --border \
                        --header="Tab: toggle | Enter: select | Esc: cancel")
                    
                    if [[ -n "$bw_item" ]]; then
                        local item_id=$(echo "$bw_item" | cut -d'|' -f2)
                        local item_name=$(echo "$bw_item" | cut -d'|' -f1)
                        
                        # Get the password/secret from the selected item
                        local secret=$(bw get password "$item_id" 2>/dev/null)
                        
                        if [[ -n "$secret" ]]; then
                            _print_success "Found secret for $var_name from '$item_name'"
                            # Preserve quotes if original had them
                            if [[ "$placeholder" =~ ^\" ]]; then
                                echo "$var_name=\"$secret\"" >> "$env_file"
                            elif [[ "$placeholder" =~ ^\' ]]; then
                                echo "$var_name='$secret'" >> "$env_file"
                            else
                                echo "$var_name=$secret" >> "$env_file"
                            fi
                            ((processed_count++))
                        else
                            _print_warning "Could not retrieve secret for $var_name, keeping placeholder"
                            echo "$line" >> "$env_file"
                            ((skipped_count++))
                        fi
                    else
                        _print_warning "No Bitwarden item selected for $var_name, keeping placeholder"
                        echo "$line" >> "$env_file"
                        ((skipped_count++))
                    fi
                else
                    _print_warning "No Bitwarden items found for $var_name, keeping placeholder"
                    echo "$line" >> "$env_file"
                    ((skipped_count++))
                fi
            else
                # Keep as-is (doesn't look like a placeholder)
                echo "$line" >> "$env_file"
            fi
        else
            # Keep malformed lines as-is
            echo "$line" >> "$env_file"
        fi
    done < "$env_example"
    
    _print_success "Environment file '$env_file' populated successfully!"
    _print_info "Processed: $processed_count variables, Skipped: $skipped_count variables"
    _print_warning "Please review the file and ensure all secrets are correct"
}

# Fuzzy search Bitwarden items and display details
# Usage: bw_search [query]
bw_search() {
    local query="${1:-}"
    
    if ! _check_dependencies; then
        return 1
    fi
    
    if ! _check_bw_login; then
        return 1
    fi
    
    local item=$(bw list items --search "$query" 2>/dev/null | jq -r '.[] | "\(.name) (\(.type)) - \(.id)"' 2>/dev/null | fzf \
        --prompt="Bitwarden Search: " \
        --height=40% \
        --border \
        --header="Tab: toggle | Enter: view details | Esc: cancel")
    
    if [[ -n "$item" ]]; then
        local item_id="${item##* - }"
        echo "Item details:"
        bw get item "$item_id" 2>/dev/null | jq '.' 2>/dev/null
    fi
}

# Get password from selected Bitwarden item
# Usage: bw_get [query]
bw_get() {
    local query="${1:-}"
    
    if ! _check_dependencies; then
        return 1
    fi
    
    if ! _check_bw_login; then
        return 1
    fi
    
    local item=$(bw list items --search "$query" 2>/dev/null | jq -r '.[] | "\(.name)|\(.id)"' 2>/dev/null | fzf \
        --prompt="Select item: " \
        --height=40% \
        --border)
    
    if [[ -n "$item" ]]; then
        local item_id="${item##*|}"
        local item_name="${item%|*}"
        local secret=$(bw get password "$item_id" 2>/dev/null)
        
        if [[ -n "$secret" ]]; then
            echo "$secret"
            # Copy to clipboard if available
            if command -v wl-copy >/dev/null 2>&1; then
                echo "$secret" | wl-copy
                _print_info "Password copied to clipboard"
            elif command -v xclip >/dev/null 2>&1; then
                echo "$secret" | xclip -selection clipboard
                _print_info "Password copied to clipboard"
            fi
        else
            _print_error "Could not retrieve password for '$item_name'"
            return 1
        fi
    fi
}

# Internal helper: select Bitwarden item via search/fzf
_bw_select_item() {
    local query="$1"
    local items_json=$(bw list items --search "$query" 2>/dev/null) || return 1
    local entries=$(echo "$items_json" | jq -r '.[] | "\(.name)|\(.id)"' 2>/dev/null)
    if [[ -z "$entries" ]]; then
        _print_error "No Bitwarden items matched '$query'"
        return 1
    fi
    local selection
    local entry_count
    entry_count=$(printf '%s\n' "$entries" | grep -c .)
    if (( entry_count == 1 )) || ! command -v fzf >/dev/null 2>&1; then
        selection="$entries"
    else
        selection=$(printf '%s\n' "$entries" | fzf \
            --prompt="Bitwarden item: " \
            --height=40% \
            --border \
            --header="Select an item for $query")
    fi
    if [[ -z "$selection" ]]; then
        _print_warning "Selection cancelled"
        return 1
    fi
    echo "$selection"
}

_bw_extract_secret() {
    local item_json="$1"
    local key_name="$2"
    local field="${3:-auto}"
    local value=""

    case "$field" in
        password)
            value=$(echo "$item_json" | jq -r '.login.password // empty')
            ;;
        username)
            value=$(echo "$item_json" | jq -r '.login.username // empty')
            ;;
        notes)
            value=$(echo "$item_json" | jq -r '.notes // .note // empty')
            ;;
        totp)
            return 3  # handled separately
            ;;
        field:*)
            local custom="${field#field:}"
            value=$(echo "$item_json" | jq -r --arg name "$custom" '.fields[]? | select(.name==$name) | .value' 2>/dev/null | head -n1)
            ;;
        *)
            value=$(echo "$item_json" | jq -r --arg name "$key_name" '.fields[]? | select(.name==$name) | .value' 2>/dev/null | head -n1)
            if [[ -z "$value" || "$value" == "null" ]]; then
                value=$(echo "$item_json" | jq -r '.login.password // empty')
            fi
            if [[ -z "$value" || "$value" == "null" ]]; then
                value=$(echo "$item_json" | jq -r '.login.username // empty')
            fi
            if [[ -z "$value" || "$value" == "null" ]]; then
                value=$(echo "$item_json" | jq -r '.notes // .note // empty')
            fi
            ;;
    esac

    echo "$value"
}

_bw_lookup_value() {
    local key_name="$1"
    local field="${2:-auto}"

    if [[ -z "$key_name" ]]; then
        _print_error "Usage: bw_lookup <KEY_NAME> [field]"
        return 1
    fi
    if ! _check_dependencies || ! _check_bw_login; then
        return 1
    fi

    local selection item_id item_json value
    selection=$(_bw_select_item "$key_name") || return 1
    item_id="${selection##*|}"

    if [[ "$field" == "totp" ]]; then
        value=$(bw get totp "$item_id" 2>/dev/null)
    else
        item_json=$(bw get item "$item_id" 2>/dev/null)
        [[ -n "$item_json" ]] || { _print_error "Unable to fetch Bitwarden item data"; return 1; }
        value=$(_bw_extract_secret "$item_json" "$key_name" "$field")
        if [[ $? -eq 3 ]]; then
            value=$(bw get totp "$item_id" 2>/dev/null)
        fi
    fi

    if [[ -z "$value" || "$value" == "null" ]]; then
        _print_error "No value found for '$key_name' (field: $field)"
        return 1
    fi

    echo "$value"
}

bw_lookup() {
    local key_name="$1"
    local field="${2:-auto}"
    _bw_lookup_value "$key_name" "$field"
}

bw_env() {
    local key_name="$1"
    local field="${2:-auto}"
    local value
    value=$(_bw_lookup_value "$key_name" "$field") || return 1
    export "$key_name"="$value"
    _print_success "Exported $key_name into current shell"
}

# List all environment variables that look like placeholders
# Usage: env_placeholders [env_file]
env_placeholders() {
    local env_file="${1:-.env.example}"
    
    if [[ ! -f "$env_file" ]]; then
        _print_error "File '$env_file' not found"
        return 1
    fi
    
    _print_info "Placeholder variables in $env_file:"
    grep -E "(your_|change_|placeholder|example|xxx|test|dummy|replace_me)" "$env_file" | cut -d'=' -f1
}

# =============================================================================
# ALIASES
# =============================================================================

# Create aliases for easier access
alias efb='env_from_bw'
alias bws='bw_search'
alias bwg='bw_get'
alias bwl='bw_lookup'
alias bwe='bw_env'
alias ep='env_placeholders'

# =============================================================================
# INITIALIZATION
# =============================================================================

# Print availability message
if [[ -n "$ZSH_VERSION" ]]; then
    _print_info "Bitwarden environment functions loaded"
    _print_info "Available commands: env_from_bw, bw_search, bw_get, bw_lookup, bw_env, env_placeholders"
    _print_info "Aliases: efb, bws, bwg, bwl, bwe, ep"
fi

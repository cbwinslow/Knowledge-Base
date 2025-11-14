# ==============================================================================
# FILENAME: function_shell_doctor.zsh
#
# PURPOSE:
#   Provides quick audits for the interactive shell environment to ensure core
#   directories, files, binaries, and PATH entries are configured correctly.
# ==============================================================================

shell_doctor() {
    local -a required_dirs=(
        "$HOME/zsh_aliases.d"
        "$HOME/zsh_functions.d"
        "$HOME/zsh_secrets.d"
        "$HOME/Knowledge-Base/dotfiles"
        "${CBW_AI_CONFIG_ARCHIVE:-$HOME/Knowledge-Base/dotfiles/ai_configs}"
    )
    local -a required_files=(
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.zsh_profile"
        "$HOME/.zsh_history"
    )
    local -a required_bins=(bw fzf jq rg zoxide bun uv uvx python3 pip pipx)
    local -a path_targets=(
        "$HOME/.local/bin"
        "$HOME/bin"
        "$HOME/tools/bin"
        "$HOME/toolsets/bin"
        "$HOME/agents/bin"
        "$HOME/cbw-agents/bin"
        "$HOME/opencode/bin"
        "$HOME/opencode/node_modules/.bin"
    )
    local missing=0

    echo "=== Shell Doctor :: Directories ==="
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            printf '  ✅ %s\n' "$dir"
        else
            printf '  ⚠️  Missing directory: %s\n' "$dir"
            ((missing++))
        fi
    done

    echo "=== Shell Doctor :: Files ==="
    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            printf '  ✅ %s\n' "$file"
        else
            printf '  ⚠️  Missing file: %s\n' "$file"
            ((missing++))
        fi
    done

    echo "=== Shell Doctor :: Commands ==="
    for bin in "${required_bins[@]}"; do
        if command -v "$bin" >/dev/null 2>&1; then
            printf '  ✅ %s\n' "$bin"
        else
            printf '  ⚠️  Missing command: %s\n' "$bin"
            ((missing++))
        fi
    done

    echo "=== Shell Doctor :: Runtime Versions ==="
    typeset -A version_checks=(
        python3 "--version"
        pip "--version"
        pipx "--version"
        uv "--version"
        uvx "--version"
        bun "--version"
        node "--version"
    )
    for bin cmd in ${(kv)version_checks}; do
        if command -v "$bin" >/dev/null 2>&1; then
            local version_output
            version_output=$("$bin" ${cmd} 2>&1 | head -n1)
            printf '  ✅ %-7s %s\n' "$bin" "$version_output"
        else
            printf '  ⚠️  %-7s not installed\n' "$bin"
            ((missing++))
        fi
    done

    echo "=== Shell Doctor :: PATH entries ==="
    for target in "${path_targets[@]}"; do
        if [[ ":$PATH:" == *":$target:"* ]]; then
            printf '  ✅ %s\n' "$target"
        else
            printf '  ⚠️  Not in PATH: %s\n' "$target"
            ((missing++))
        fi
    done

    if typeset -p CBW_AI_COMMANDS >/dev/null 2>&1; then
        echo "=== Shell Doctor :: AI Agents ==="
        for agent cmd in ${(kv)CBW_AI_COMMANDS}; do
            local label="${CBW_AI_LABELS[$agent]:-$agent}"
            if command -v "${cmd%% *}" >/dev/null 2>&1; then
                printf '  ✅ %-14s (%s)\n' "$label" "$cmd"
            else
                printf '  ⚠️  %-14s missing command: %s\n' "$label" "$cmd"
                ((missing++))
            fi
        done
    fi

    echo "=== Shell Doctor :: Alias sanity ==="
    local -a critical_aliases=(opencode aitools tl cheat lookup save recall scratch bwlookup orsearch)
    for alias_name in "${critical_aliases[@]}"; do
        if alias "$alias_name" >/dev/null 2>&1; then
            printf '  ✅ alias %s\n' "$alias_name"
        else
            printf '  ⚠️  alias %s undefined\n' "$alias_name"
            ((missing++))
        fi
    done

    echo "=== Shell Doctor :: Git / Remote status ==="
    if command -v git >/dev/null 2>&1; then
        local gh_status gl_status
        if command -v gh >/dev/null 2>&1; then
            gh auth status >/dev/null 2>&1 && gh_status="✅ gh auth" || gh_status="⚠️ gh auth"
            printf '  %s\n' "$gh_status"
        fi
        if command -v glab >/dev/null 2>&1; then
            glab auth status >/dev/null 2>&1 && gl_status="✅ glab auth" || gl_status="⚠️ glab auth"
            printf '  %s\n' "$gl_status"
        fi
        git --version >/dev/null 2>&1 && printf '  ✅ git available: %s\n' "$(git --version)"
        if [[ -d "$KB_ROOT" ]]; then
            git -C "$KB_ROOT" remote -v >/dev/null 2>&1 \
                && printf '  ✅ KB remotes configured\n' \
                || { printf '  ⚠️  Unable to list KB remotes\n'; ((missing++)); }
        fi
    else
        printf '  ⚠️  git not installed\n'
        ((missing++))
    fi

    if [[ -f "$HOME/.zsh_functions.json" ]]; then
        echo "=== Shell Doctor :: Documentation index ==="
        jq -r '.functions | keys[]' "$HOME/.zsh_functions.json" >/dev/null 2>&1 \
            && printf '  ✅ ~/.zsh_functions.json is readable\n' \
            || { printf '  ⚠️  Unable to read ~/.zsh_functions.json\n'; ((missing++)); }
    fi

    if (( missing == 0 )); then
        echo "Shell Doctor: all checks passed ✅"
    else
        printf 'Shell Doctor: %d issues detected ⚠️\n' "$missing"
        return 1
    fi
}

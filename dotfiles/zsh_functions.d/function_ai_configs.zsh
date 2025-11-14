# ==============================================================================
# FILENAME: function_ai_configs.zsh
#
# PURPOSE:
#   Snapshot, restore, and list configuration sets for AI IDEs and coding tools
#   (Zed, VS Code, Neovim, etc.) so they can be versioned alongside dotfiles.
# ==============================================================================

typeset -gA CBW_AI_CONFIGS=(
    zed        "$HOME/.config/zed"
    vscode     "$HOME/.config/Code/User"
    vscodium   "$HOME/.config/VSCodium/User"
    cursor     "$HOME/.config/Cursor/User"
    neovim     "$HOME/.config/nvim"
    helix      "$HOME/.config/helix"
    zed_json   "$HOME/zed_settings.json"
)

ai_config_root() {
    echo "${CBW_AI_CONFIG_ARCHIVE:-$HOME/Knowledge-Base/dotfiles/ai_configs}"
}

ai_config_list() {
    local root="$(ai_config_root)"
    mkdir -p "$root"
    ls "$root"
}

ai_config_save() {
    local tool="$1"
    local label="${2:-current}"
    [[ -n "$tool" ]] || { echo "Usage: ai_config_save <tool> [label]" >&2; return 1; }
    local src="${CBW_AI_CONFIGS[$tool]}"
    [[ -n "$src" ]] || { echo "Unknown tool '$tool'. Use ai_config_list or inspect CBW_AI_CONFIGS." >&2; return 1; }
    if [[ ! -e "$src" ]]; then
        echo "Source path not found: $src" >&2
        return 1
    fi
    local dest="$(ai_config_root)/$tool/$label"
    mkdir -p "$dest"
    rsync -a --delete "$src"/ "$dest"/ 2>/dev/null || rsync -a "$src" "$dest"/
    echo "Saved $tool config to $dest"
}

ai_config_recall() {
    local tool="$1"
    local label="${2:-current}"
    [[ -n "$tool" ]] || { echo "Usage: ai_config_recall <tool> [label]" >&2; return 1; }
    local src="$(ai_config_root)/$tool/$label"
    local dest="${CBW_AI_CONFIGS[$tool]}"
    [[ -d "$src" || -f "$src" ]] || { echo "Snapshot not found: $src" >&2; return 1; }
    [[ -n "$dest" ]] || { echo "Unknown tool mapping for '$tool'." >&2; return 1; }
    mkdir -p "$(dirname "$dest")"
    rsync -a --delete "$src"/ "$dest"/ 2>/dev/null || rsync -a "$src" "$dest"
    echo "Restored $tool config from $src"
}

ai_config_snap() {
    local tool="$1"
    [[ -n "$tool" ]] || { echo "Usage: ai_config_snap <tool>" >&2; return 1; }
    local stamp
    stamp="$(date +%Y%m%d_%H%M%S)"
    ai_config_save "$tool" "$stamp"
    ln -sfn "$stamp" "$(ai_config_root)/$tool/latest"
    echo "Snapshot created: $tool -> $stamp"
}

ai_config_open() {
    local tool="$1"
    local target="${CBW_AI_CONFIGS[$tool]}"
    [[ -n "$tool" && -n "$target" ]] || { echo "Usage: ai_config_open <tool>" >&2; return 1; }
    if [[ -d "$target" ]]; then
        cd "$target" && pwd
    elif [[ -f "$target" ]]; then
        "${EDITOR:-nano}" "$target"
    else
        echo "No config found for $tool at $target" >&2
        return 1
    fi
}

if [[ -n "$ZSH_VERSION" ]]; then
    alias aiconfigs='ai_config_list'
    alias aiconfigsave='ai_config_save'
    alias aiconfigrecall='ai_config_recall'
    alias aiconfigsnap='ai_config_snap'
    alias aiconfigedit='ai_config_open'
fi

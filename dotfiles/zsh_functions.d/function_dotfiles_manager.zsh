# ==============================================================================
# FILENAME: function_dotfiles_manager.zsh
#
# PURPOSE:
#   Helper wrappers for managing dotfiles with yadm and syncing to Knowledge-Base.
# ==============================================================================

_ensure_yadm() {
    command -v yadm >/dev/null 2>&1 && return 0
    echo "yadm command not found. Install yadm to manage dotfiles." >&2
    return 1
}

dotfiles_status() {
    _ensure_yadm || return 1
    yadm status "$@"
}

dotfiles_diff() {
    _ensure_yadm || return 1
    yadm diff "$@"
}

dotfiles_pull() {
    _ensure_yadm || return 1
    yadm pull --rebase "$@"
}

dotfiles_push() {
    _ensure_yadm || return 1
    local msg="${*:-chore: update dotfiles}"
    yadm add -u
    yadm commit -m "$msg"
    yadm push
}

dotfiles_sync_kb() {
    local script="${KB_ROOT:-$HOME/Knowledge-Base}/scripts/documentation/sync_zsh_configs.sh"
    [[ -x "$script" ]] || { echo "Sync script not found or not executable at $script" >&2; return 1; }
    "$script"
}

dotfiles_audit() {
    dotfiles_status
    dotfiles_diff
    shell_doctor
}

if [[ -n "$ZSH_VERSION" ]]; then
    alias dots='dotfiles_status'
    alias dotdiff='dotfiles_diff'
    alias dotpull='dotfiles_pull'
    alias dotpush='dotfiles_push'
    alias dotsync='dotfiles_sync_kb'
    alias dotaudit='dotfiles_audit'
fi

#!/usr/bin/env bash
set -euo pipefail

KB_ROOT="${KB_ROOT:-$HOME/Knowledge-Base}"
SOURCE_HOME="${SOURCE_HOME:-$HOME}"
TARGET_DIR="$KB_ROOT/dotfiles"

log() {
    printf '[kb-sync] %s\n' "$*"
}

rsync_dir() {
    local src="$1"
    local dest="$2"
    if [[ -d "$src" ]]; then
        mkdir -p "$dest"
        rsync -av --delete "$src"/ "$dest"/ >/dev/null
        log "Synced directory: $src -> $dest"
    else
        log "Skipped missing directory: $src"
    fi
}

rsync_file() {
    local src="$1"
    local dest_dir="$2"
    if [[ -f "$src" ]]; then
        mkdir -p "$dest_dir"
        rsync -av "$src" "$dest_dir"/ >/dev/null
        log "Synced file: $src"
    else
        log "Skipped missing file: $src"
    fi
}

log "Syncing Zsh configuration into $TARGET_DIR"

rsync_file "$SOURCE_HOME/.zshrc" "$TARGET_DIR"
rsync_file "$SOURCE_HOME/.zprofile" "$TARGET_DIR"
rsync_file "$SOURCE_HOME/.zsh_profile" "$TARGET_DIR"

rsync_dir "$SOURCE_HOME/zsh_aliases.d" "$TARGET_DIR/zsh_aliases.d"
rsync_dir "$SOURCE_HOME/zsh_functions.d" "$TARGET_DIR/zsh_functions.d"

mkdir -p "$TARGET_DIR/zsh_secrets.d"
if [[ -n "${SKIP_SECRET_PLACEHOLDER:-}" ]]; then
    log "SKIP_SECRET_PLACEHOLDER set; not touching zsh_secrets.d README"
else
    cat > "$TARGET_DIR/zsh_secrets.d/README.md" <<'EOF'
# Secrets Placeholder

Secret material stays on the workstation under ~/zsh_secrets.d and is not committed
to the repository. Use Bitwarden or another vault to store sensitive data securely.
EOF
    log "Ensured placeholder at $TARGET_DIR/zsh_secrets.d/README.md"
fi

if [[ -f "$SOURCE_HOME/.zsh_history" ]]; then
    mkdir -p "$TARGET_DIR"
    tail -n 200 "$SOURCE_HOME/.zsh_history" > "$TARGET_DIR/.zsh_history.sample"
    log "Captured last 200 history entries to .zsh_history.sample"
fi

log "Sync complete. Review changes with 'git status'."

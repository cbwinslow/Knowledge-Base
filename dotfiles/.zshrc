# =============================================================================
# cbwinslow :: Ordered Zsh configuration
# =============================================================================

setopt EXTENDED_GLOB AUTO_CD AUTO_PUSHD
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY INC_APPEND_HISTORY
setopt HIST_FIND_NO_DUPS PROMPT_SUBST
setopt CORRECT GLOB_DOTS

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
export HISTFILE HISTSIZE SAVEHIST

export KB_ROOT="${KB_ROOT:-$HOME/Knowledge-Base}"
export KB_RAG_SCRIPT="${KB_RAG_SCRIPT:-$KB_ROOT/scripts/documentation/rag_knowledge_base.py}"
export KB_RAG_PERSIST="${KB_RAG_PERSIST:-$KB_ROOT/chroma_db}"
export KB_RAG_RESULTS="${KB_RAG_RESULTS:-5}"
export CRAWL4AI_CACHE="${CRAWL4AI_CACHE:-$HOME/.cache/crawl4ai}"
export YADM_DIR="${YADM_DIR:-$HOME/.local/share/yadm/repo.git}"
export YADM_WORKTREE="${YADM_WORKTREE:-$YADM_DIR/worktree}"
export CBW_AI_CONFIG_ARCHIVE="${CBW_AI_CONFIG_ARCHIVE:-$KB_ROOT/dotfiles/ai_configs}"
export OPENROUTER_MODEL="${OPENROUTER_MODEL:-google/gemma-7b-it}"
export OPENROUTER_SUMMARY_MODEL="${OPENROUTER_SUMMARY_MODEL:-meta-llama/llama-3.1-8b-instruct}"
export OLLAMA_FORMAT_MODEL="${OLLAMA_FORMAT_MODEL:-llama3.2}"
export CBW_OBS_ROOT="${CBW_OBS_ROOT:-$HOME/logs/observability}"
export CBW_OBS_LOG="${CBW_OBS_LOG:-$CBW_OBS_ROOT/events.log}"
mkdir -p "$CRAWL4AI_CACHE"
mkdir -p "$CBW_AI_CONFIG_ARCHIVE"
mkdir -p "$CBW_OBS_ROOT"
touch "$CBW_OBS_LOG"
autoload -Uz colors add-zsh-hook
colors
zmodload zsh/complist

typeset -U path fpath
path=(
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/dotbins"
    "$HOME/tools/bin"
    "$HOME/toolsets/bin"
    "$HOME/agents/bin"
    "$HOME/cbw-agents/bin"
    "$HOME/opencode/bin"
    "$HOME/opencode/node_modules/.bin"
    "$HOME/Knowledge-Base/scripts"
    "/usr/local/bin"
    "/usr/local/go/bin"
    $path
)

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
mkdir -p "$ZSH_CACHE_DIR"
export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump-$ZSH_VERSION"
export ZSH_DISABLE_COMPFIX=true

if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
fi
[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select=2
bindkey '^[[Z' reverse-menu-complete

export EDITOR="${EDITOR:-nano}"
export BROWSER="${BROWSER:-firefox}"
export TERM="${TERM:-xterm-256color}"

# Workspace shortcuts for quick lookup/finding commands
typeset -A CBW_WORKSPACES=(
    dotfiles        "$HOME/dotfiles"
    agents          "$HOME/agents"
    cbw_agents      "$HOME/cbw-agents"
    tools           "$HOME/tools"
    toolsets        "$HOME/toolsets"
    knowledge       "$KB_ROOT"
    docs            "$HOME/docs"
    yadm            "$YADM_WORKTREE"
    configs         "$HOME/configs"
    mcp             "$HOME/mcp"
    mcps            "$HOME/mcp-workspace"
)
for nick dir in ${(kv)CBW_WORKSPACES}; do
    [[ -d "$dir" ]] && hash -d "$nick"="$dir"
done

: "${CBW_NOTES_DIR:=$HOME/notes}"
export CBW_SCRATCHPAD_FILE="${CBW_NOTES_DIR}/scratchpad.md"
export CBW_EMAIL_PAD="${CBW_NOTES_DIR}/email-drafts.md"

# ----------------------------------------------------------------------------- 
# Helper utility to source alias/function bundles without duplication
# -----------------------------------------------------------------------------
typeset -gA __CBW_SOURCED_FILES
_cbw_source_dir() {
    local dir="$1"; shift
    [[ -d "$dir" ]] || return 0
    local -a globs=("$@")
    (( $#globs == 0 )) && globs=('*.zsh' '*.sh')
    for glob in "${globs[@]}"; do
        for file in "$dir"/$glob(N); do
            [[ -n "$file" ]] || continue
            [[ -n "${__CBW_SOURCED_FILES[$file]}" ]] && continue
            source "$file"
            __CBW_SOURCED_FILES[$file]=1
        done
    done
}

# asdf (language/runtime manager)
if [[ -s "$HOME/.asdf/asdf.sh" ]]; then
    source "$HOME/.asdf/asdf.sh"
    [[ -d "$HOME/.asdf/completions" ]] && fpath=("$HOME/.asdf/completions" $fpath)
fi

export CBW_ZSH_DOC_INDEX="$HOME/.zsh_functions.json"

# Oh My Zsh core configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
export skip_global_compinit=1
plugins=(
    zsh-autosuggestions
    zsh-syntax-highlighting
    history-substring-search
    colored-man-pages
    command-not-found
    git git-extras github
    docker docker-compose kubectl helm
    npm node yarn bun nvm
    python pip pyenv
    golang
    aws terraform
    brew
    sudo
    extract
    web-search
    copyfile copypath
    jsontools urltools
    systemadmin
)
source "$ZSH/oh-my-zsh.sh"

# Fuzzy finder and navigation enhancements
if command -v fzf >/dev/null 2>&1; then
    if command -v rg >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND=${FZF_DEFAULT_COMMAND:-'rg --files --hidden --follow --glob "!.git/*" 2>/dev/null'}
    elif command -v fd >/dev/null 2>&1; then
        export FZF_DEFAULT_COMMAND=${FZF_DEFAULT_COMMAND:-'fd --type f --hidden --follow --exclude .git'}
    else
        export FZF_DEFAULT_COMMAND=${FZF_DEFAULT_COMMAND:-'find . -type f 2>/dev/null'}
    fi
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    if command -v fd >/dev/null 2>&1; then
        export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
    else
        export FZF_ALT_C_COMMAND='find . -type d 2>/dev/null'
    fi
    for candidate in "$HOME/.fzf.zsh" /usr/share/fzf/key-bindings.zsh /usr/share/fzf/completion.zsh; do
        [[ -f "$candidate" ]] && source "$candidate"
    done
    _cbw_source_dir "$HOME/zsh_functions.d" "function_fzf-cd-widget.zsh"
fi

# Directory jumping powered by zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd j)"
fi

# Custom alias collections
_cbw_source_dir "$HOME/zsh_aliases.d" "*.zsh" "*.sh"

# Secrets (loaded last so they can override anything else)
_cbw_source_dir "$HOME/zsh_secrets.d" "*.zsh" "*.sh"

# Core function suites, lookup helpers, and AI tool integrations
_cbw_source_dir "$HOME/zsh_functions.d" "cleanup_functions.zsh" "function_*.zsh" "show_my_tools.zsh" "sys_diagnostics.zsh"
_cbw_source_dir "$HOME/zsh_functions.d/homelab" "*.zsh"

# OpenCode + AI coding helpers
alias opencode='opencode'
alias aitools='show_my_tools'
alias yd='yadm'
alias ydot='yadm'

# TLDR & cheatsheet helpers
if command -v tldr >/dev/null 2>&1; then
    alias tl='tldr --color=always'
fi

openrouter_search() {
    [[ -x "$HOME/tools/openrouter_lookup.py" ]] || { echo "openrouter_lookup.py not found in ~/tools" >&2; return 1; }
    python3 "$HOME/tools/openrouter_lookup.py" "$@"
}
alias orsearch='openrouter_search'

cbw_cheatsheet() {
    local topic="$*"
    [[ -z "$topic" ]] && { echo "Usage: cbw_cheatsheet <command/topic>" >&2; return 1; }
    command -v curl >/dev/null 2>&1 || { echo "curl is required for cbw_cheatsheet" >&2; return 1; }
    local encoded="${topic// /+}"
    curl -s "https://cht.sh/${encoded}"
}
alias cheat='cbw_cheatsheet'

# Knowledge, lookup, and scratch-pad utilities
cbw_lookup() {
    command -v rg >/dev/null 2>&1 || { echo "cbw_lookup requires ripgrep (rg)" >&2; return 1; }
    local query="$*"
    [[ -z "$query" ]] && { echo "Usage: cbw_lookup <search-term>" >&2; return 1; }
    local -a roots=()
    for dir in "$HOME/Knowledge-Base" "$HOME/docs" "$HOME/dotfiles" "$HOME/tools" "$HOME/toolsets"; do
        [[ -d "$dir" ]] && roots+=("$dir")
    done
    (( ${#roots[@]} == 0 )) && { echo "No lookup directories configured" >&2; return 1; }
    rg --hidden --follow --smart-case --glob '!.git' --heading --line-number "$query" "${roots[@]}"
}
alias lookup='cbw_lookup'

cbw_save_note() {
    mkdir -p "$(dirname "$CBW_SCRATCHPAD_FILE")"
    local content
    if [[ -t 0 ]]; then
        content="$*"
    else
        content="$(cat)"
    fi
    [[ -z "$content" ]] && { echo "Usage: cbw_save_note <text> or pipe content into cbw_save_note" >&2; return 1; }
    printf "### %s\n%s\n\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')" "$content" >> "$CBW_SCRATCHPAD_FILE"
    echo "Saved note to $CBW_SCRATCHPAD_FILE"
}
alias save='cbw_save_note'

cbw_recall_note() {
    command -v rg >/dev/null 2>&1 || { echo "cbw_recall_note requires ripgrep (rg)" >&2; return 1; }
    [[ -f "$CBW_SCRATCHPAD_FILE" ]] || { echo "Scratchpad not found at $CBW_SCRATCHPAD_FILE" >&2; return 1; }
    local query="$*"
    [[ -z "$query" ]] && { echo "Usage: cbw_recall_note <search-term>" >&2; return 1; }
    rg --smart-case --context 2 "$query" "$CBW_SCRATCHPAD_FILE"
}
alias recall='cbw_recall_note'

scratchpad() {
    mkdir -p "$(dirname "$CBW_SCRATCHPAD_FILE")"
    "${EDITOR:-nano}" "$CBW_SCRATCHPAD_FILE"
}
alias scratch='scratchpad'

cbw_email_pad() {
    mkdir -p "$(dirname "$CBW_EMAIL_PAD")"
    "${EDITOR:-nano}" "$CBW_EMAIL_PAD"
}
alias emailpad='cbw_email_pad'

# Documentation utilities
alias funcs='zsh_functions_summary'
alias docscheck='zsh_check_docs'
alias zsh_help='zsh_man'

_cbw_doc_function_list() {
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cbw"
    local cache_file="$cache_dir/zsh_functions_list"
    mkdir -p "$cache_dir"
    if [[ -f "$CBW_ZSH_DOC_INDEX" && -n "$CBW_ZSH_DOC_INDEX" ]] && command -v jq >/dev/null 2>&1; then
        if [[ ! -f "$cache_file" || "$CBW_ZSH_DOC_INDEX" -nt "$cache_file" ]]; then
            jq -r '.functions | keys[]' "$CBW_ZSH_DOC_INDEX" 2>/dev/null > "$cache_file" || true
        fi
        cat "$cache_file"
    fi
}

_cbw_complete_doc_functions() {
    local -a entries
    entries=($(_cbw_doc_function_list))
    _describe 'documented functions' entries
}
autoload -Uz compinit
if [[ -z "$_CBW_COMPINIT_DONE" ]]; then
    compinit -u -d "$ZSH_COMPDUMP"
    _CBW_COMPINIT_DONE=1
fi
compdef _cbw_complete_doc_functions zsh_help zsh_man

# Bitwarden helper aliases
alias bwlookup='bw_lookup'
alias bwexport='bw_env'

# MCP + documentation helpers
export MCP_GATEWAY_ROOT="$HOME/mcp-gateway"
export MCP_GATEWAY_CONFIG="$MCP_GATEWAY_ROOT/config.json"
context7_docs() {
    local doc_root="$HOME/Knowledge-Base/documentation/top_100"
    [[ -d "$doc_root" ]] || { echo "Context7 documentation cache not found at $doc_root" >&2; return 1; }
    if command -v fzf >/dev/null 2>&1; then
        local file
        if command -v rg >/dev/null 2>&1; then
            file=$(rg --files "$doc_root" | fzf --prompt="context7 docs> " --height=40% --border) || return 1
        else
            file=$(find "$doc_root" -type f | fzf --prompt="context7 docs> " --height=40% --border) || return 1
        fi
        ${PAGER:-less} "$file"
    else
        ${PAGER:-less} "$doc_root/README.md"
    fi
}
alias ctx7docs='context7_docs'

mcp_context7() {
    (cd "$MCP_GATEWAY_ROOT" && bun x -y @upstash/context7-mcp@latest "$@")
}
alias mcpctx7='mcp_context7'

# Shell health visibility
alias shellcheckup='shell_doctor'

# Keep PATH clean and export final state
export PATH="${(j/:/)path}"

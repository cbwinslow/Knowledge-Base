# ==============================================================================
# FILENAME: function_ai_agents.zsh
#
# PURPOSE:
#   Centralizes AI agent/tool launchers plus crawl/RAG helpers for the shell.
# ==============================================================================

typeset -gA CBW_AI_COMMANDS=(
    crewai         "crewai"
    codex          "codex"
    gemini         "gemini"
    qwen_code      "qwen-code"
    opencode       "opencode"
    forgecode      "forgecode"
    cline          "cline"
    copilot        "gh copilot"
    zed            "zed"
    crawl4ai       "crawl4ai"
)

typeset -gA CBW_AI_LABELS=(
    crewai         "CrewAI"
    codex          "Codex"
    gemini         "Gemini CLI"
    qwen_code      "Qwen-Code"
    opencode       "OpenCode"
    forgecode      "ForgeCode"
    cline          "Cline"
    copilot        "GitHub Copilot"
    zed            "Zed"
    crawl4ai       "Crawl4AI"
)

typeset -gA CBW_AI_WORKSPACES=(
    crewai         "$HOME/cbw-agents/crews"
    codex          "$HOME/cbw-agents/tools"
    gemini         "$HOME/opencode"
    qwen_code      "$HOME/tools"
    opencode       "$HOME/opencode"
    forgecode      "$HOME/tools"
    cline          "$HOME/.config/cline"
    copilot        "$HOME/.config/gh"
    zed            "$HOME/.config/zed"
    crawl4ai       "$HOME/Knowledge-Base/agents"
)

_cbw_ai_cmd_bin() {
    echo "${1%% *}"
}

ai_agent_available() {
    local cmd="$1"
    local bin=$(_cbw_ai_cmd_bin "$cmd")
    command -v "$bin" >/dev/null 2>&1
}

ai_agents_status() {
    printf "%-14s %-12s %s\n" "Agent" "Status" "Command"
    printf "%-14s %-12s %s\n" "-----" "------" "-------"
    for agent cmd in ${(kv)CBW_AI_COMMANDS}; do
        local label=${CBW_AI_LABELS[$agent]:-$agent}
        if ai_agent_available "$cmd"; then
            printf "%-14s %-12s %s\n" "$label" "✅ ready" "$cmd"
        else
            printf "%-14s %-12s %s\n" "$label" "⚠️ missing" "$cmd"
        fi
    done
}

ai_agent_launch() {
    local agent="$1"; shift || true
    if [[ -z "$agent" ]]; then
        echo "Usage: ai_agent_launch <agent> [args]" >&2
        echo "Run 'aiagents' to see available agents." >&2
        return 1
    fi
    local cmd="${CBW_AI_COMMANDS[$agent]}"
    if [[ -z "$cmd" ]]; then
        echo "Unknown agent '$agent'." >&2
        return 1
    fi
    if ! ai_agent_available "$cmd"; then
        echo "Command for '$agent' not found on PATH: $cmd" >&2
        return 1
    fi
    echo "→ Launching ${CBW_AI_LABELS[$agent]:-$agent} ($cmd $*)"
    eval "$cmd" "$@"
}

ai_agent_workspace() {
    local agent="$1"
    if [[ -z "$agent" ]]; then
        echo "Usage: ai_agent_workspace <agent>" >&2
        return 1
    fi
    local dir="${CBW_AI_WORKSPACES[$agent]}"
    if [[ -z "$dir" || ! -d "$dir" ]]; then
        echo "Workspace for '$agent' not found (expected at $dir)" >&2
        return 1
    fi
    cd "$dir" || return
    pwd
}

# Crawl4AI helpers ------------------------------------------------------------

crawl4ai_crawl() {
    command -v crawl4ai >/dev/null 2>&1 || { echo "crawl4ai CLI not installed." >&2; return 1; }
    local url="$1"; shift
    local depth="${1:-1}"
    local output="${2:-$CRAWL4AI_CACHE/$(date +%Y%m%d_%H%M%S)}"
    [[ -z "$url" ]] && { echo "Usage: crawl4ai_crawl <url> [depth] [output_dir]" >&2; return 1; }
    mkdir -p "$output"
    echo "→ Crawling $url (depth=$depth) into $output"
    crawl4ai crawl --url "$url" --depth "$depth" --output "$output" "$@"
}

# RAG / Knowledge Base helpers -----------------------------------------------

rag_vectorize() {
    local directory="${1:-}"
    local kb_root="${KB_ROOT:-$HOME/Knowledge-Base}"
    local script="${KB_RAG_SCRIPT:-$kb_root/scripts/documentation/rag_knowledge_base.py}"
    [[ -f "$script" ]] || { echo "RAG script not found at $script" >&2; return 1; }
    python3 "$script" index --kb-path "$kb_root" --persist-dir "${KB_RAG_PERSIST:-$kb_root/chroma_db}" ${directory:+--directory "$directory"}
}

rag_query() {
    local query="$*"
    local kb_root="${KB_ROOT:-$HOME/Knowledge-Base}"
    local script="${KB_RAG_SCRIPT:-$kb_root/scripts/documentation/rag_knowledge_base.py}"
    [[ -n "$query" ]] || { echo "Usage: rag_query <question>" >&2; return 1; }
    python3 "$script" search --kb-path "$kb_root" --persist-dir "${KB_RAG_PERSIST:-$kb_root/chroma_db}" --query "$query" --results "${KB_RAG_RESULTS:-5}"
}

rag_stats() {
    local kb_root="${KB_ROOT:-$HOME/Knowledge-Base}"
    local script="${KB_RAG_SCRIPT:-$kb_root/scripts/documentation/rag_knowledge_base.py}"
    python3 "$script" stats --kb-path "$kb_root" --persist-dir "${KB_RAG_PERSIST:-$kb_root/chroma_db}"
}

# Convenience aliases when sourced stand-alone
if [[ -n "$ZSH_VERSION" ]]; then
    alias aiagents='ai_agents_status'
    alias aia='ai_agent_launch'
    alias aiws='ai_agent_workspace'
    alias ragindex='rag_vectorize'
    alias ragsearch='rag_query'
    alias ragstats='rag_stats'
    alias crawlweb='crawl4ai_crawl'
fi

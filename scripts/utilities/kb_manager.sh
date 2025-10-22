#!/bin/bash
# Knowledge Base Manager Script
# Helper script to manage AI agents, dotfiles, and configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Usage function
usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
  memory <name> <content>        - Save an AI memory
  rule <name> <content>          - Save an AI rule
  dotfile <shell> <type> <file>  - Save a dotfile
  docker <name> <type> <file>    - Save Docker config
  mcp <name> <file>              - Save MCP server config
  crew <name> <file>             - Save CrewAI crew config
  search <query>                 - Search through stored content
  list <category>                - List items in category
  recall <path>                  - Display content from path
  help                           - Show this help message

Examples:
  $0 memory "python_tips" "Remember to use virtual environments"
  $0 rule "code_quality" "Always write tests for new functions"
  $0 dotfile bash aliases ~/.bash_aliases
  $0 search "docker"
  $0 list memories
  $0 recall ai_agents/memories/python_tips_20251022_140000.md

EOF
    exit 1
}

# Save AI memory
save_memory() {
    local name="$1"
    local content="$2"
    
    if [ -z "$name" ] || [ -z "$content" ]; then
        print_error "Memory name and content are required"
        exit 1
    fi
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename="${REPO_ROOT}/ai_agents/memories/${name}_${timestamp}.md"
    
    cat > "$filename" << EOF
# ${name}

**Date:** $(date +%Y-%m-%d)
**Time:** $(date +%H:%M:%S)
**Agent:** Manual Entry

## Content

${content}

## Tags

- manual
EOF
    
    print_success "Memory saved to: $filename"
}

# Save AI rule
save_rule() {
    local name="$1"
    local content="$2"
    
    if [ -z "$name" ] || [ -z "$content" ]; then
        print_error "Rule name and content are required"
        exit 1
    fi
    
    local filename="${REPO_ROOT}/ai_agents/rules/${name}.md"
    
    cat > "$filename" << EOF
# ${name}

**Priority:** Medium
**Applies To:** All agents
**Last Updated:** $(date +%Y-%m-%d)

## Rule

${content}
EOF
    
    print_success "Rule saved to: $filename"
}

# Save dotfile
save_dotfile() {
    local shell="$1"
    local type="$2"
    local source_file="$3"
    
    if [ -z "$shell" ] || [ -z "$type" ] || [ -z "$source_file" ]; then
        print_error "Shell, type, and source file are required"
        exit 1
    fi
    
    if [ ! -f "$source_file" ]; then
        print_error "Source file not found: $source_file"
        exit 1
    fi
    
    local filename="${REPO_ROOT}/dotfiles/${shell}/${shell}_${type}"
    
    cp "$source_file" "$filename"
    print_success "Dotfile saved to: $filename"
}

# Search through stored content
search_content() {
    local query="$1"
    
    if [ -z "$query" ]; then
        print_error "Search query is required"
        exit 1
    fi
    
    print_info "Searching for: $query"
    echo ""
    
    find "${REPO_ROOT}" -type f \( -name "*.md" -o -name "*.yml" -o -name "*.yaml" -o -name "*.json" \) \
        -not -path "*/projects/*" \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -exec grep -l -i "$query" {} \; | while read file; do
        echo -e "${GREEN}File:${NC} $file"
        grep -i -n --color=always "$query" "$file" | head -3
        echo ""
    done
}

# List items in a category
list_items() {
    local category="$1"
    
    case "$category" in
        memories)
            print_info "AI Agent Memories:"
            ls -1 "${REPO_ROOT}/ai_agents/memories/" 2>/dev/null || print_warning "No memories found"
            ;;
        rules)
            print_info "AI Agent Rules:"
            ls -1 "${REPO_ROOT}/ai_agents/rules/" 2>/dev/null || print_warning "No rules found"
            ;;
        crews)
            print_info "CrewAI Crews:"
            ls -1 "${REPO_ROOT}/ai_agents/crews/" 2>/dev/null || print_warning "No crews found"
            ;;
        dotfiles)
            print_info "Dotfiles:"
            find "${REPO_ROOT}/dotfiles" -type f -not -name ".gitkeep" 2>/dev/null || print_warning "No dotfiles found"
            ;;
        docker)
            print_info "Docker Configurations:"
            find "${REPO_ROOT}/docker_configs" -type f -not -name "*.md" 2>/dev/null || print_warning "No docker configs found"
            ;;
        mcp)
            print_info "MCP Servers:"
            ls -1 "${REPO_ROOT}/mcp_servers/" 2>/dev/null || print_warning "No MCP servers found"
            ;;
        *)
            print_error "Unknown category: $category"
            echo "Valid categories: memories, rules, crews, dotfiles, docker, mcp"
            exit 1
            ;;
    esac
}

# Recall content
recall_content() {
    local path="$1"
    
    if [ -z "$path" ]; then
        print_error "Path is required"
        exit 1
    fi
    
    local full_path="${REPO_ROOT}/${path}"
    
    if [ ! -f "$full_path" ]; then
        print_error "File not found: $full_path"
        exit 1
    fi
    
    print_info "Content of: $path"
    echo ""
    cat "$full_path"
}

# Main script logic
main() {
    if [ $# -lt 1 ]; then
        usage
    fi
    
    local command="$1"
    shift
    
    case "$command" in
        memory)
            save_memory "$@"
            ;;
        rule)
            save_rule "$@"
            ;;
        dotfile)
            save_dotfile "$@"
            ;;
        search)
            search_content "$@"
            ;;
        list)
            list_items "$@"
            ;;
        recall)
            recall_content "$@"
            ;;
        help|--help|-h)
            usage
            ;;
        *)
            print_error "Unknown command: $command"
            usage
            ;;
    esac
}

main "$@"

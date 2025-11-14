#!/bin/bash
# Knowledge Base Management System
# Provides functions to interact with the RAG knowledge base

# Configuration
KB_PATH="/home/cbwinslow/Knowledge-Base"
RAG_SCRIPT="$KB_PATH/scripts/documentation/simple_rag_knowledge_base.py"
TOC_SCRIPT="$KB_PATH/scripts/documentation/dynamic_toc.py"
RAG_DB_DIR="$KB_PATH/simple_rag_db"
BOOKMARKS_FILE="$HOME/.kb_bookmarks"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure scripts are executable
chmod +x "$RAG_SCRIPT" "$TOC_SCRIPT" 2>/dev/null

# Helper function for colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Helper function to confirm actions
confirm() {
    local message=$1
    local default=${2:-n}
    local response
    
    read -p "$message [y/N]: " response
    response=${response:-$default}
    
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Initialize knowledge base
kb_init() {
    print_status $BLUE "🚀 Initializing Knowledge Base..."
    
    # Create directories
    mkdir -p "$RAG_DB_DIR"
    mkdir -p "$(dirname "$BOOKMARKS_FILE")"
    
    # Create bookmarks file if it doesn't exist
    if [[ ! -f "$BOOKMARKS_FILE" ]]; then
        touch "$BOOKMARKS_FILE"
        print_status $GREEN "✅ Created bookmarks file: $BOOKMARKS_FILE"
    fi
    
    # Index the knowledge base
    print_status $YELLOW "📚 Indexing knowledge base (this may take a moment)..."
    cd "$KB_PATH/scripts/documentation"
    python3 "$RAG_SCRIPT" index
    
    if [[ $? -eq 0 ]]; then
        print_status $GREEN "✅ Knowledge base initialized successfully!"
        kb_stats
    else
        print_status $RED "❌ Failed to initialize knowledge base"
        return 1
    fi
}

# Search the knowledge base
kb_search() {
    local query="$1"
    local results="${2:-5}"
    local category="${3:-}"
    
    if [[ -z "$query" ]]; then
        print_status $RED "❌ Please provide a search query"
        echo "Usage: kb_search <query> [results] [category]"
        return 1
    fi
    
    print_status $BLUE "🔍 Searching for: $query"
    
    cd "$KB_PATH/scripts/documentation"
    if [[ -n "$category" ]]; then
        python3 "$RAG_SCRIPT" search --query "$query" --results "$results" --category "$category"
    else
        python3 "$RAG_SCRIPT" search --query "$query" --results "$results"
    fi
}

# Add a document to the knowledge base
kb_add() {
    local file_path="$1"
    local description="$2"
    
    if [[ -z "$file_path" ]]; then
        print_status $RED "❌ Please provide a file path"
        echo "Usage: kb_add <file_path> [description]"
        return 1
    fi
    
    # Convert relative path to absolute
    if [[ ! "$file_path" = /* ]]; then
        file_path="$(pwd)/$file_path"
    fi
    
    if [[ ! -f "$file_path" ]]; then
        print_status $RED "❌ File not found: $file_path"
        return 1
    fi
    
    # Copy file to knowledge base if not already there
    local kb_file_path="$KB_PATH/documents/$(basename "$file_path")"
    mkdir -p "$KB_PATH/documents"
    
    if [[ "$file_path" != "$kb_file_path" ]]; then
        cp "$file_path" "$kb_file_path"
        print_status $GREEN "✅ Added file to knowledge base: $kb_file_path"
    fi
    
    # Re-index the knowledge base
    print_status $YELLOW "🔄 Re-indexing knowledge base..."
    cd "$KB_PATH/scripts/documentation"
    python3 "$RAG_SCRIPT" index --directory documents
    
    if [[ -n "$description" ]]; then
        # Add description to a metadata file
        echo "$(basename "$file_path")|$description" >> "$KB_PATH/.file_descriptions"
        print_status $GREEN "📝 Added description for $(basename "$file_path")"
    fi
    
    print_status $GREEN "✅ Document added successfully!"
}

# Remove a document from the knowledge base
kb_remove() {
    local file_pattern="$1"
    
    if [[ -z "$file_pattern" ]]; then
        print_status $RED "❌ Please provide a file pattern or name"
        echo "Usage: kb_remove <file_pattern>"
        return 1
    fi
    
    # Find matching files
    local matching_files=$(find "$KB_PATH" -name "*$file_pattern*" -type f | grep -v ".git" | grep -v "simple_rag_db")
    
    if [[ -z "$matching_files" ]]; then
        print_status $RED "❌ No files found matching: $file_pattern"
        return 1
    fi
    
    print_status $YELLOW "📋 Found matching files:"
    echo "$matching_files" | nl
    
    if confirm "❓ Remove these files?"; then
        echo "$matching_files" | while read -r file; do
            rm -f "$file"
            print_status $GREEN "🗑️  Removed: $file"
        done
        
        # Re-index knowledge base
        print_status $YELLOW "🔄 Re-indexing knowledge base..."
        cd "$KB_PATH/scripts/documentation"
        python3 "$RAG_SCRIPT" index
        print_status $GREEN "✅ Documents removed and knowledge base updated!"
    else
        print_status $BLUE "❌ Operation cancelled"
    fi
}

# Lookup a document by name or pattern
kb_lookup() {
    local pattern="$1"
    
    if [[ -z "$pattern" ]]; then
        print_status $RED "❌ Please provide a search pattern"
        echo "Usage: kb_lookup <pattern>"
        return 1
    fi
    
    print_status $BLUE "🔍 Looking up documents matching: $pattern"
    
    # Search in knowledge base
    local found_files=$(find "$KB_PATH" -name "*$pattern*" -type f | grep -v ".git" | grep -v "simple_rag_db" | head -20)
    
    if [[ -z "$found_files" ]]; then
        print_status $RED "❌ No documents found matching: $pattern"
        return 1
    fi
    
    print_status $GREEN "📋 Found documents:"
    echo "$found_files" | while read -r file; do
        local relative_path=$(echo "$file" | sed "s|$KB_PATH/||")
        local size=$(du -h "$file" | cut -f1)
        local modified=$(stat -c %y "$file" | cut -d' ' -f1,2 | cut -d'.' -f1)
        echo -e "  ${CYAN}📄 $relative_path${NC} ($size, modified: $modified)"
    done
}

# Save a bookmark
kb_bookmark() {
    local file_path="$1"
    local note="$2"
    
    if [[ -z "$file_path" ]]; then
        print_status $RED "❌ Please provide a file path"
        echo "Usage: kb_bookmark <file_path> [note]"
        return 1
    fi
    
    # Convert to relative path if it's in KB
    if [[ "$file_path" == "$KB_PATH"* ]]; then
        file_path=$(echo "$file_path" | sed "s|$KB_PATH/||")
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp|$file_path|$note" >> "$BOOKMARKS_FILE"
    
    print_status $GREEN "🔖 Bookmarked: $file_path"
    if [[ -n "$note" ]]; then
        print_status $BLUE "📝 Note: $note"
    fi
}

# List bookmarks
kb_bookmarks() {
    if [[ ! -f "$BOOKMARKS_FILE" ]] || [[ ! -s "$BOOKMARKS_FILE" ]]; then
        print_status $YELLOW "📚 No bookmarks found"
        return 0
    fi
    
    print_status $BLUE "🔖 Your bookmarks:"
    echo ""
    
    local count=1
    while IFS='|' read -r timestamp path note; do
        echo -e "${CYAN}$count.${NC} $timestamp"
        echo -e "   📄 $path"
        if [[ -n "$note" ]]; then
            echo -e "   📝 $note"
        fi
        echo ""
        ((count++))
    done < "$BOOKMARKS_FILE"
}

# Remove bookmark
kb_unbookmark() {
    local bookmark_num="$1"
    
    if [[ -z "$bookmark_num" ]]; then
        print_status $RED "❌ Please provide bookmark number"
        echo "Usage: kb_unbookmark <bookmark_number>"
        return 1
    fi
    
    if [[ ! -f "$BOOKMARKS_FILE" ]]; then
        print_status $RED "❌ No bookmarks file found"
        return 1
    fi
    
    # Create temporary file without the specified bookmark
    local temp_file=$(mktemp)
    local current_line=0
    local found=false
    
    while IFS= read -r line; do
        ((current_line++))
        if [[ "$current_line" -ne "$bookmark_num" ]]; then
            echo "$line" >> "$temp_file"
        else
            found=true
        fi
    done < "$BOOKMARKS_FILE"
    
    if [[ "$found" == true ]]; then
        mv "$temp_file" "$BOOKMARKS_FILE"
        print_status $GREEN "🗑️  Removed bookmark #$bookmark_num"
    else
        rm -f "$temp_file"
        print_status $RED "❌ Bookmark #$bookmark_num not found"
        return 1
    fi
}

# Copy a file from knowledge base
kb_copy() {
    local source="$1"
    local destination="$2"
    
    if [[ -z "$source" ]]; then
        print_status $RED "❌ Please provide source file"
        echo "Usage: kb_copy <source> [destination]"
        return 1
    fi
    
    # Find the file
    local full_path=$(find "$KB_PATH" -name "*$source*" -type f | grep -v ".git" | grep -v "simple_rag_db" | head -1)
    
    if [[ -z "$full_path" ]]; then
        print_status $RED "❌ File not found: $source"
        return 1
    fi
    
    if [[ -z "$destination" ]]; then
        destination=$(basename "$full_path")
    fi
    
    cp "$full_path" "$destination"
    print_status $GREEN "📋 Copied $(basename "$full_path") to $destination"
}

# Open a document from knowledge base
kb_open() {
    local file_pattern="$1"
    
    if [[ -z "$file_pattern" ]]; then
        print_status $RED "❌ Please provide a file pattern"
        echo "Usage: kb_open <file_pattern>"
        return 1
    fi
    
    # Find the file
    local full_path=$(find "$KB_PATH" -name "*$file_pattern*" -type f | grep -v ".git" | grep -v "simple_rag_db" | head -1)
    
    if [[ -z "$full_path" ]]; then
        print_status $RED "❌ File not found: $file_pattern"
        return 1
    fi
    
    # Determine how to open the file
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$full_path" 2>/dev/null &
    elif command -v open >/dev/null 2>&1; then
        open "$full_path" 2>/dev/null &
    elif [[ -n "$EDITOR" ]]; then
        $EDITOR "$full_path"
    else
        # Try to open with less for text files
        if file "$full_path" | grep -q "text"; then
            less "$full_path"
        else
            print_status $RED "❌ Cannot open file: no suitable application found"
            return 1
        fi
    fi
    
    print_status $GREEN "📂 Opened: $(basename "$full_path")"
}

# Show knowledge base statistics
kb_stats() {
    print_status $BLUE "📊 Knowledge Base Statistics:"
    echo ""
    
    cd "$KB_PATH/scripts/documentation"
    python3 "$RAG_SCRIPT" stats
    
    echo ""
    print_status $BLUE "📂 Directory sizes:"
    du -sh "$KB_PATH"/* 2>/dev/null | sort -hr | head -10 | while read -r line; do
        echo "  $line"
    done
    
    echo ""
    if [[ -f "$BOOKMARKS_FILE" ]]; then
        local bookmark_count=$(wc -l < "$BOOKMARKS_FILE")
        print_status $PURPLE "🔖 Bookmarks: $bookmark_count"
    fi
}

# Update/rebuild the knowledge base index
kb_update() {
    print_status $YELLOW "🔄 Updating knowledge base index..."
    
    cd "$KB_PATH/scripts/documentation"
    python3 "$RAG_SCRIPT" rebuild
    
    if [[ $? -eq 0 ]]; then
        print_status $GREEN "✅ Knowledge base updated successfully!"
        kb_stats
    else
        print_status $RED "❌ Failed to update knowledge base"
        return 1
    fi
}

# Generate table of contents
kb_toc() {
    print_status $YELLOW "📚 Generating table of contents..."
    
    cd "$KB_PATH/scripts/documentation"
    python3 "$TOC_SCRIPT"
    
    if [[ $? -eq 0 ]]; then
        print_status $GREEN "✅ Table of contents generated: $KB_PATH/TABLE_OF_CONTENTS.md"
    else
        print_status $RED "❌ Failed to generate table of contents"
        return 1
    fi
}

# Show help
kb_help() {
    echo -e "${BLUE}📚 Knowledge Base Management System${NC}"
    echo ""
    echo "Available commands:"
    echo ""
    echo -e "${GREEN}Initialization:${NC}"
    echo "  kb_init                    - Initialize the knowledge base"
    echo "  kb_update                  - Rebuild the search index"
    echo "  kb_toc                     - Generate table of contents"
    echo ""
    echo -e "${GREEN}Search & Lookup:${NC}"
    echo "  kb_search <query> [n]      - Search knowledge base"
    echo "  kb_lookup <pattern>        - Find documents by name"
    echo ""
    echo -e "${GREEN}Document Management:${NC}"
    echo "  kb_add <file> [desc]       - Add document to KB"
    echo "  kb_remove <pattern>        - Remove documents from KB"
    echo "  kb_copy <source> [dest]    - Copy file from KB"
    echo "  kb_open <pattern>          - Open document from KB"
    echo ""
    echo -e "${GREEN}Bookmarks:${NC}"
    echo "  kb_bookmark <file> [note]  - Save a bookmark"
    echo "  kb_bookmarks               - List all bookmarks"
    echo "  kb_unbookmark <num>        - Remove bookmark"
    echo ""
    echo -e "${GREEN}Information:${NC}"
    echo "  kb_stats                   - Show KB statistics"
    echo "  kb_help                    - Show this help"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  kb_search 'docker compose' 10"
    echo "  kb_add ./my-doc.md 'Important config'"
    echo "  kb_bookmark 'docker-compose.yml' 'Production config'"
    echo "  kb_open 'README.md'"
}

# Auto-completion for kb functions
_kb_complete() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    commands="init search add remove lookup copy open bookmark bookmarks unbookmark stats update toc help"
    
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=( $(compgen -W "${commands}" -- ${cur}) )
    elif [[ ${COMP_CWORD} -eq 2 ]]; then
        case "${prev}" in
            kb_search|kb_lookup|kb_remove|kb_copy|kb_open)
                # Complete with file names
                local files=$(find "$KB_PATH" -maxdepth 3 -type f -name "*.md" -o -name "*.txt" -o -name "*.py" -o -name "*.sh" -o -name "*.yaml" -o -name "*.yml" 2>/dev/null | xargs -n1 basename 2>/dev/null | sort | uniq)
                COMPREPLY=( $(compgen -W "${files}" -- ${cur}) )
                ;;
            kb_add)
                # Complete with files in current directory
                COMPREPLY=( $(compgen -f -- ${cur}) )
                ;;
            kb_unbookmark)
                # Complete with bookmark numbers
                if [[ -f "$BOOKMARKS_FILE" ]]; then
                    local nums=$(wc -l < "$BOOKMARKS_FILE" 2>/dev/null)
                    COMPREPLY=( $(compgen -W "$(seq 1 $nums)" -- ${cur}) )
                fi
                ;;
        esac
    fi
}

# Register auto-completion
complete -F _kb_complete kb_search kb_lookup kb_remove kb_copy kb_open kb_add kb_bookmark kb_unbookmark

# Create aliases for convenience
alias kbs='kb_search'
alias kbl='kb_lookup'
alias kba='kb_add'
alias kbr='kb_remove'
alias kbc='kb_copy'
alias kbo='kb_open'
alias kbb='kb_bookmark'
alias kbu='kb_unbookmark'
alias kbs='kb_stats'
alias kbh='kb_help'

# Welcome message
if [[ -f "$RAG_DB_DIR/documents.json" ]]; then
    print_status $GREEN "📚 Knowledge Base System Ready!"
    echo "Type 'kb_help' for available commands"
fi
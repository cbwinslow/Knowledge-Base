# File: function_zsh_functions_summary.zsh
# Description: Generate a simple summary of all available zsh functions.
# Author: foomanchu8008
# Date: 2025-10-24
# License: MIT
# Debug mode: set to 1 to enable debugging output, 0 to disable
: ${DEBUG_FUNCTIONS_SUMMARY:=0}

zsh_functions_summary() {
    [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Starting zsh_functions_summary function"
    
    echo "=== ZSH FUNCTIONS SUMMARY ==="
    echo ""
    
    # Count total function files
    local function_files=($(find ~/.zsh_functions.d/ -name "*.zsh" -type f))
    local total_files=${#function_files[@]}
    
    [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Found $total_files function files"
    
    echo "Total function files: $total_files"
    echo ""
    
    # Load documented functions from JSON
    local documented_list=()
    if [[ -f "$HOME/.zsh_functions.json" ]]; then
        documented_list=($(jq -r '.functions | keys | .[]' "$HOME/.zsh_functions.json" 2>/dev/null))
        [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Found ${#documented_list[@]} documented functions: ${documented_list[*]}"
    else
        [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: .zsh_functions.json not found"
    fi
    local documented_count=${#documented_list[@]}
    
    echo "Documented functions: $documented_count"
    echo ""
    
    # Simple list by file
    echo "=== FUNCTIONS BY FILE ==="
    for file in "${function_files[@]}"; do
        local basename=$(basename "$file")
        local func_name="${basename#function_}"
        func_name="${func_name%.zsh}"
        
        [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Processing file: $basename, func_name: $func_name"
        
        # For cleanup_functions.zsh, we need special handling
        if [[ "$basename" == "cleanup_functions.zsh" ]]; then
            echo "File: $basename"
            echo "  Multi-function file containing:"
            
            # Debug: Check if the file exists and has content
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Looking inside cleanup_functions.zsh"
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: File exists: $([ -f "$file" ] && echo "yes" || echo "no")"
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: File size: $(stat -c%s "$file") bytes"
            
            # Check for function definitions in the file
            local temp_file=$(mktemp)
            grep -E "^ *[a-zA-Z_][a-zA-Z0-9_]*\\(\\) *{" "$file" | sed 's/ *() *{.*//' | sed 's/^ *//' | sed 's/ *$//' > "$temp_file"
            
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Function extraction command output saved to temp file: $temp_file"
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Content of temp file: [$(cat "$temp_file")]"
            [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Number of lines in temp file: $(wc -l < "$temp_file")"
            
            while IFS= read -r func; do
                [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Processing func from cleanup file: '$func'"
                if [[ -n "$func" ]]; then
                    local func_status="❌"
                    for doc_func in "${documented_list[@]}"; do
                        if [[ "$doc_func" == "$func" ]]; then
                            func_status="✅"
                            break
                        fi
                    done
                    echo "    $func_status $func"
                else
                    [[ $DEBUG_FUNCTIONS_SUMMARY -eq 1 ]] && echo "DEBUG: Skipping empty function name"
                fi
            done < "$temp_file"
            
            rm "$temp_file"
        else
            # Single function per file
            local func_status="❌"
            for doc_func in "${documented_list[@]}"; do
                if [[ "$doc_func" == "$func_name" ]]; then
                    func_status="✅"
                    break
                fi
            done
            echo "File: $basename -> Function: $func_status $func_name"
        fi
    done
    
    echo ""
    echo "=== DOCUMENTATION ==="
    echo "Use 'zsh_man <function_name>' to see documentation for a specific function"
    echo "Use 'zsh_add_man <function_name> <description> <usage> [dependencies]' to add documentation"
}
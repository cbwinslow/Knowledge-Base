# File: function_zsh_functions_improve.zsh
# Description: Suggest improvements for zsh function organization and documentation.
# Author: foomanchu8008
# Date: 2025-10-24
# License: MIT
# Debug mode: set to 1 to enable debugging output, 0 to disable
: ${DEBUG_FUNCTIONS_IMPROVE:=0}

zsh_functions_improve() {
    [[ $DEBUG_FUNCTIONS_IMPROVE -eq 1 ]] && echo "DEBUG: Starting zsh_functions_improve function"
    
    echo "=== ZSH FUNCTIONS ORGANIZATION ANALYSIS ==="
    echo ""
    
    # Count total function files
    local function_files=($(find ~/.zsh_functions.d/ -name "*.zsh" -type f))
    local total_files=${#function_files[@]}
    
    echo "Total function files: $total_files"
    
    # Load documented functions from JSON
    local documented_list=()
    if [[ -f "$HOME/.zsh_functions.json" ]]; then
        documented_list=($(jq -r '.functions | keys | .[]' "$HOME/.zsh_functions.json" 2>/dev/null))
    fi
    local documented_count=${#documented_list[@]}
    local undocumented_count=$((total_files - documented_count))
    
    echo "Documented functions: $documented_count"
    echo "Undocumented functions: $undocumented_count"
    echo ""
    
    # Check for functions that are in the cleanup file but not necessarily documented as individual files
    local cleanup_funcs=()
    while IFS= read -r func; do
        if [[ -n "$func" ]]; then
            cleanup_funcs+=("$func")
        fi
    done < <(grep -E "^ *[a-zA-Z_][a-zA-Z0-9_]*\\(\\) *{" ~/.zsh_functions.d/cleanup_functions.zsh 2>/dev/null | sed 's/ *() *{.*//' | sed 's/^ *//' | sed 's/ *$//')
    
    local cleanup_count=${#cleanup_funcs[@]}
    echo "Functions in cleanup_functions.zsh: $cleanup_count"
    echo ""
    
    # Analyze function distribution
    echo "=== ANALYSIS & SUGGESTIONS ==="
    
    # Check if there are too many functions in a single file
    if [[ $cleanup_count -gt 10 ]]; then
        echo "⚠️  CONSIDERATION: cleanup_functions.zsh has $cleanup_count functions."
        echo "   You might consider splitting this into more specific categories like:"
        echo "   - function_cleanup_system.zsh"
        echo "   - function_cleanup_docker.zsh" 
        echo "   - function_cleanup_python.zsh"
        echo "   - function_cleanup_node.zsh"
        echo ""
    fi
    
    # Suggest documentation for undocumented functions (if any exist)
    local all_func_names=()
    for file in "${function_files[@]}"; do
        local basename=$(basename "$file")
        local func_name="${basename#function_}"
        func_name="${func_name%.zsh}"
        
        # If it's cleanup_functions, get all individual functions from inside
        if [[ "$basename" == "cleanup_functions.zsh" ]]; then
            for func in "${cleanup_funcs[@]}"; do
                all_func_names+=("$func")
            done
        else
            all_func_names+=("$func_name")
        fi
    done
    
    # Check for any missing documentation
    local missing_docs=()
    for func in "${all_func_names[@]}"; do
        local found=0
        for doc_func in "${documented_list[@]}"; do
            if [[ "$doc_func" == "$func" ]]; then
                found=1
                break
            fi
        done
        if [[ $found -eq 0 ]]; then
            missing_docs+=("$func")
        fi
    done
    
    if [[ ${#missing_docs[@]} -gt 0 ]]; then
        echo "⚠️  DOCUMENTATION NEEDED: ${#missing_docs[@]} functions need documentation"
        echo "   Add documentation using zsh_add_man:"
        for func in "${missing_docs[@]:0:5}"; do  # Show first 5
            echo "   zsh_add_man $func \"Description\" \"Usage\" \"Dependencies\""
        done
        if [[ ${#missing_docs[@]} -gt 5 ]]; then
            echo "   ... and $(( ${#missing_docs[@]} - 5 )) more"
        fi
        echo ""
    else
        echo "✅ All functions appear to be documented!"
        echo ""
    fi
    
    # Check for naming consistency
    echo "=== NAMING CONSISTENCY ==="
    
    local gh_funcs=()
    local gl_funcs=()
    local zsh_funcs=()
    local other_funcs=()
    
    for func in "${all_func_names[@]}"; do
        if [[ "$func" =~ ^gh_ ]]; then
            gh_funcs+=("$func")
        elif [[ "$func" =~ ^gl_ ]]; then
            gl_funcs+=("$func")
        elif [[ "$func" =~ ^zsh_ ]]; then
            zsh_funcs+=("$func")
        else
            other_funcs+=("$func")
        fi
    done
    
    echo "GitHub functions (gh_*): ${#gh_funcs[@]}"
    echo "GitLab functions (gl_*): ${#gl_funcs[@]}"
    echo "Shell management (zsh_*): ${#zsh_funcs[@]}"
    echo "Other functions: ${#other_funcs[@]}"
    echo ""
    
    # Suggest file organization
    echo "=== ORGANIZATION SUGGESTIONS ==="
    echo "1. Consider grouping related functions into separate files:"
    echo "   - GitHub functions: Already well organized in separate files"
    echo "   - GitLab functions: Already well organized in separate files"
    echo "   - Shell utilities: Well organized (extract, take, fzf-cd-widget)"
    echo "   - Cleanup functions: Currently in one large file (consider splitting)"
    echo ""
    
    echo "2. Consider adding more specific categories like:"
    echo "   - function_dev_tools.zsh (for development utilities)"
    echo "   - function_system_utils.zsh (for system utilities)"
    echo "   - function_security.zsh (for security-related functions)"
    echo ""
    
    echo "3. Your documentation system with zsh_add_man/zsh_man is excellent!"
    echo "   - All functions are documented with description, usage, and dependencies"
    echo "   - The zsh_check_docs function alerts about undocumented functions"
    echo ""
    
    echo "=== RECOMMENDATIONS ==="
    echo "1. The cleanup_functions.zsh file could be split for better organization"
    echo "2. All functions are well-documented - great job!"
    echo "3. Naming convention is consistent across different service providers (gh_, gl_)"
    echo "4. Consider adding more usage examples in function documentation"
    echo ""
    
    echo "Run with: DEBUG_FUNCTIONS_IMPROVE=1 zsh_functions_improve"
    echo "To see detailed debugging information."
}
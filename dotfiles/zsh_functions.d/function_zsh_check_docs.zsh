# File: function_zsh_check_docs.zsh
# Description: Check for undocumented functions and alert the user.
# Author: foomanchu8008
# Date: 2025-10-21
# License: MIT

zsh_check_docs() {
    local all_functions=()
    local documented_functions=()
    local undocumented_functions=()

    # Get all function names from .zsh_functions.d/
    for file in "$HOME/.zsh_functions.d"/*.zsh; do
        if [ -f "$file" ]; then
            # Use awk to find function definitions more reliably
            # It looks for lines ending with '{' that are not comments or shebangs
            local found_funcs=$(awk '/^[[:space:]]*#/{next} /^#!/{next} /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)?[[:space:]]*\{/{print $1}' "$file" | sed 's/()//g')
            while IFS= read -r func_name; do
                if [ -n "$func_name" ]; then
                    all_functions+=("$func_name")
                fi
            done <<< "$found_funcs"
        fi
    done

    # Get all documented function names from .zsh_functions.json
    documented_functions=($(jq -r '.functions | keys[]' "$HOME/.zsh_functions.json"))

    # Compare the lists
    for func_name in "${all_functions[@]}"; do
        local found="false"
        for doc_func_name in "${documented_functions[@]}"; do
            if [[ "$func_name" == "$doc_func_name" ]]; then
                found="true"
                break
            fi
        done
        if [[ "$found" == "false" ]]; then
            undocumented_functions+=("$func_name")
        fi
    done

    if [ ${#undocumented_functions[@]} -gt 0 ]; then
        echo "\n--- UNDOCUMENTED FUNCTIONS ALERT ---"
        echo "The following functions in your .zsh_functions.d/ directory are missing documentation:"
        for func_name in "${undocumented_functions[@]}"; do
            echo "  - $func_name"
        done
        echo "\nPlease add documentation for these functions using 'zsh_add_man':"
        echo "  Example: zsh_add_man <function_name> \"Description here\" \"Usage example\" [dependencies]"
        echo "------------------------------------"
    fi
}

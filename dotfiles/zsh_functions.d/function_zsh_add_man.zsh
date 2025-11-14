# File: function_zsh_add_man.zsh
# Description: Add documentation for a new function.
# Author: foomanchu8008
# Date: 2025-10-21
# License: MIT

zsh_add_man() {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: zsh_add_man <function_name> <description> <usage> [dependencies]"
        return 1
    fi

    local func_name=$1
    local description=$2
    local usage=$3
    local dependencies=${4:-"None"}

    local new_doc=$(jq --arg fn "$func_name" \
                         --arg desc "$description" \
                         --arg usage "$usage" \
                         --arg deps "$dependencies" \
                         '.functions += {($fn): {"description": $desc, "usage": $usage, "dependencies": $deps}}' \
                         "$HOME/.zsh_functions.json")

    echo "$new_doc" > "$HOME/.zsh_functions.json"
    echo "Documentation for '$func_name' added."
}

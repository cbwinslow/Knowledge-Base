# ==============================================================================
# FILENAME: function_zsh_remove_man.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Removes the documentation for a Zsh function from
#   ~/.zsh_functions.json.
#
# SUMMARY:
#   This script defines a function that deletes the documentation entry for a
#   specified Zsh function from the JSON documentation file.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: zsh_remove_man
#
# DESCRIPTION:
#   This function takes a function name as an argument and removes its
#   corresponding entry from the ~/.zsh_functions.json file using `jq`.
#
# USAGE:
#   zsh_remove_man <function_name>
#
# PARAMETERS:
#   $1 (function_name): The name of the Zsh function whose documentation is to
#                       be removed.
#
# INPUTS:
#   - ~/.zsh_functions.json: The JSON file containing function documentation.
#
# OUTPUTS:
#   A message confirming the removal of the function's documentation.
#
# ==============================================================================
zsh_remove_man() {
    # Check if a function name is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: zsh_remove_man <function_name>"
        return 1
    fi

    # Assign the first argument to the 'func_name' variable.
    local func_name=$1

    # Use `jq` to delete the entry for the specified function from the JSON file.
    # del(.functions."$func_name"): delete the key corresponding to the function name.
    local updated_doc=$(jq "del(.functions.\"$func_name\")" "$HOME/.zsh_functions.json")

    # Overwrite the .zsh_functions.json file with the updated content.
    echo "$updated_doc" > "$HOME/.zsh_functions.json"
    # Print a confirmation message.
    echo "Documentation for '$func_name' removed."
}
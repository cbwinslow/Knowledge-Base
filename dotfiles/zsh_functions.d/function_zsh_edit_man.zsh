# ==============================================================================
# FILENAME: function_zsh_edit_man.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Edits the documentation for an existing Zsh function stored in
#   ~/.zsh_functions.json.
#
# SUMMARY:
#   This script defines a function that allows users to update specific fields
#   (e.g., description, usage) of a function's documentation within the JSON
#   documentation file.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: zsh_edit_man
#
# DESCRIPTION:
#   This function takes a function name, a field to update (e.g., "description",
#   "usage"), and the new value for that field. It uses `jq` to modify the
#   ~/.zsh_functions.json file accordingly.
#
# USAGE:
#   zsh_edit_man <function_name> <field> <new_value>
#
# PARAMETERS:
#   $1 (function_name): The name of the function whose documentation is to be edited.
#   $2 (field): The specific field within the function's documentation to update.
#   $3 (new_value): The new value to set for the specified field.
#
# INPUTS:
#   - ~/.zsh_functions.json: The JSON file containing function documentation.
#
# OUTPUTS:
#   A message confirming the update of the function's documentation.
#
# ==============================================================================
zsh_edit_man() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: zsh_edit_man <function_name> <field> <new_value>"
        return 1
    fi

    # Assign the first argument to the 'func_name' variable.
    local func_name=$1
    # Assign the second argument to the 'field' variable.
    local field=$2
    # Assign the third argument to the 'new_value' variable.
    local new_value=$3

    # Use `jq` to update the specified field for the given function in the JSON file.
    # --arg: pass shell variables as `jq` arguments.
    # .functions."$fn" | ."$field" = $value: navigate to the function, then update the field.
    local updated_doc=$(jq --arg fn "$func_name" \
                             --arg field "$field" \
                             --arg value "$new_value" \
                             '.functions."$fn" | ."$field" = $value'
                             "$HOME/.zsh_functions.json")

    # Overwrite the .zsh_functions.json file with the updated content.
    echo "$updated_doc" > "$HOME/.zsh_functions.json"
    # Print a confirmation message.
    echo "Documentation for '$func_name' updated."
}
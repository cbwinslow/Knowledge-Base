# ==============================================================================
# FILENAME: function_zsh_man.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Displays the documentation for a Zsh function in a man-page-like format.
#
# SUMMARY:
#   This script defines a function that retrieves documentation for a specified
#   Zsh function from the ~/.zsh_functions.json file and presents it in a
#   readable format, including name, description, usage, and dependencies.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: zsh_man
#
# DESCRIPTION:
#   This function takes a function name as an argument, retrieves its
#   documentation from ~/.zsh_functions.json, and prints it to the console.
#   If the function is not found in the documentation, an error message is
#   displayed.
#
# USAGE:
#   zsh_man <function_name>
#
# PARAMETERS:
#   $1 (function_name): The name of the Zsh function whose documentation is to
#                       be displayed.
#
# INPUTS:
#   - ~/.zsh_functions.json: The JSON file containing function documentation.
#
# OUTPUTS:
#   The formatted documentation for the specified function, or an error message.
#
# ==============================================================================
zsh_man() {
    # Check if a function name is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: zsh_man <function_name>"
        return 1
    fi

    # Assign the first argument to the 'func_name' variable.
    local func_name=$1
    # Retrieve the documentation for the specified function from the JSON file using `jq`.
    local doc=$(jq ".functions.\"$func_name\"" "$HOME/.zsh_functions.json")

    # Check if the function documentation was found.
    if [ "$doc" = "null" ]; then
        # If not found, print an error message and return.
        echo "Function '$func_name' not found in documentation."
        return 1
    fi

    # Extract the description from the documentation.
    local description=$(echo "$doc" | jq -r '.description')
    # Extract the usage from the documentation.
    local usage=$(echo "$doc" | jq -r '.usage')
    # Extract the dependencies from the documentation.
    local dependencies=$(echo "$doc" | jq -r '.dependencies')

    # Print the function name.
    echo "\nNAME"
    echo "    ${func_name}"
    # Print the description.
    echo "\nDESCRIPTION"
    echo "${description}"
    # If usage information exists, print it.
    if [ "$usage" != "null" ]; then
        echo "\nUSAGE"
        echo "${usage}"
    fi
    # If dependencies information exists, print it.
    if [ "$dependencies" != "null" ]; then
        echo "\nDEPENDENCIES"
        echo "${dependencies}"
    fi
}
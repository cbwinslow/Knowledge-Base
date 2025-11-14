# ==============================================================================
# FILENAME: function_gh_create_gist.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates a new Gist on GitHub.
#
# SUMMARY:
#   This script defines a function that creates a new Gist from a local file,
#   with an optional description and privacy setting.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_create_gist
#
# DESCRIPTION:
#   This function creates a new GitHub Gist from a file. It takes the filename,
#   a description, and an optional third argument to make the Gist public.
#
# USAGE:
#   gh_create_gist <filename> <description> [public]
#
# PARAMETERS:
#   $1 (filename): The path to the file to be uploaded as a Gist.
#   $2 (description): A description for the Gist.
#   $3 (public): Optional. If set to "true", the Gist will be public.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API.
#
# ==============================================================================
gh_create_gist() {
    # Check if the required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_create_gist <filename> <description> [public]"
        return 1
    fi

    # Assign the first argument to the 'filename' variable.
    local filename=$1
    # Assign the second argument to the 'description' variable.
    local description=$2
    # Set the default privacy setting to private.
    local public_gist="false"
    # If the third argument is "true", set the Gist to public.
    if [ "$3" = "true" ]; then
        public_gist="true"
    fi

    # Check if the specified file exists.
    if [ ! -f "$filename" ]; then
        # If the file does not exist, print an error message and return.
        echo "Error: File '$filename' not found."
        return 1
    fi

    # Read the content of the file into a variable.
    local file_content=$(cat "$filename")
    # Get the base name of the file.
    local base_filename=$(basename "$filename")

    # Create a JSON payload with the Gist description, privacy setting, and file content.
    local json_payload=$(printf '{"description": "%s", "public": %s, "files": {"%s": {"content": "%s"}}}' \
                                "$description" "$public_gist" "$base_filename" "$file_content")

    # Send a POST request to the GitHub API to create the Gist.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for creating Gists.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Authorization: token $GITHUB_PAT" \
         -d "$json_payload" \
         https://api.github.com/gists | jq '.'
}
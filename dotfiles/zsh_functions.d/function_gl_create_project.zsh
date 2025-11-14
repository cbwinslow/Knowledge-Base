# ==============================================================================
# FILENAME: function_gl_create_project.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates a new project in GitLab.
#
# SUMMARY:
#   This script defines a function that creates a new project in GitLab using
#   the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_create_project
#
# DESCRIPTION:
#   This function sends a POST request to the GitLab API to create a project.
#   It requires the project name as an argument, and can optionally include a
#   description for the project.
#
# USAGE:
#   gl_create_project <name> [description]
#
# PARAMETERS:
#   $1 (name): The name of the new project.
#   $2 (description): Optional. The description of the project.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API.
#
# ==============================================================================
gl_create_project() {
    # Check if the project name is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gl_create_project <name> [description]"
        return 1
    fi
    # Assign the first argument to the 'name' variable.
    local name=$1
    # Assign the second argument to the 'description' variable, or an empty string if it is not provided.
    local description=${2:-""}
    # Create a JSON payload with the project name and description.
    local json_payload=$(printf '{"name":"%s", "description":"%s"}' "$name" "$description")
    # Send a POST request to the GitLab API to create the project.
    # -s: silent mode
    # -X POST: use the POST HTTP method
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for creating projects.
    # The response is piped to `jq` for pretty-printing.
    curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_PAT" -d "$json_payload" https://gitlab.com/api/v4/projects | jq '.'
}

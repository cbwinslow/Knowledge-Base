# ==============================================================================
# FILENAME: function_gl_create_issue.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates a new issue in a GitLab project.
#
# SUMMARY:
#   This script defines a function that creates a new issue in a GitLab project
#   using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_create_issue
#
# DESCRIPTION:
#   This function sends a POST request to the GitLab API to create an issue.
#   It requires the project ID and issue title as arguments, and can optionally
#   include a description for the issue.
#
# USAGE:
#   gl_create_issue <project_id> <title> [description]
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project.
#   $2 (title): The title of the issue.
#   $3 (description): Optional. The description of the issue.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API.
#
# ==============================================================================
gl_create_issue() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gl_create_issue <project_id> <title> [description]"
        return 1
    fi
    # Assign the first argument to the 'project_id' variable.
    local project_id=$1
    # Assign the second argument to the 'title' variable.
    local title=$2
    # Assign the third argument to the 'description' variable, or an empty string if it is not provided.
    local description=${3:-""}
    # Create a JSON payload with the issue title and description.
    local json_payload=$(printf '{"title":"%s", "description":"%s"}' "$title" "$description")
    # Send a POST request to the GitLab API to create the issue.
    # -s: silent mode
    # -X POST: use the POST HTTP method
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for creating issues in the specified project.
    # The response is piped to `jq` for pretty-printing.
    curl -s -X POST --header "PRIVATE-TOKEN: $GITLAB_PAT" -d "$json_payload" https://gitlab.com/api/v4/projects/$project_id/issues | jq '.'
}

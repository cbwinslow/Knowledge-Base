# ==============================================================================
# FILENAME: function_gl_close_issue.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Closes an issue in a GitLab project.
#
# SUMMARY:
#   This script defines a function that closes a specified issue in a GitLab
#   project using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_close_issue
#
# DESCRIPTION:
#   This function sends a PUT request to the GitLab API to close an issue.
#   It requires the project ID and the issue IID (internal ID) as arguments.
#
# USAGE:
#   gl_close_issue <project_id> <issue_iid>
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project.
#   $2 (issue_iid): The internal ID of the issue to close.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API.
#
# ==============================================================================
gl_close_issue() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gl_close_issue <project_id> <issue_iid>"
        return 1
    fi
    # Assign the first argument to the 'project_id' variable.
    local project_id=$1
    # Assign the second argument to the 'issue_iid' variable.
    local issue_iid=$2
    # Create a JSON payload to set the state of the issue to 'closed'.
    local json_payload=$(printf '{"state_event":"close"}')
    # Send a PUT request to the GitLab API to close the issue.
    # -s: silent mode
    # -X PUT: use the PUT HTTP method
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for the specified issue.
    # The response is piped to `jq` for pretty-printing.
    curl -s -X PUT --header "PRIVATE-TOKEN: $GITLAB_PAT" -d "$json_payload" https://gitlab.com/api/v4/projects/$project_id/issues/$issue_iid | jq '.'
}

# ==============================================================================
# FILENAME: function_gl_get_issue.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a single issue from a GitLab project.
#
# SUMMARY:
#   This script defines a function that fetches the details of a specified
#   issue from a GitLab project using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_get_issue
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve a specific
#   issue. It requires the project ID and the issue IID (internal ID) as
#   arguments.
#
# USAGE:
#   gl_get_issue <project_id> <issue_iid>
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project.
#   $2 (issue_iid): The internal ID of the issue to retrieve.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API containing the issue details.
#
# ==============================================================================
gl_get_issue() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gl_get_issue <project_id> <issue_iid>"
        return 1
    fi
    # Send a GET request to the GitLab API to retrieve the issue.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for the specified issue.
    # The response is piped to `jq` for pretty-printing.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/projects/$1/issues/$2 | jq '.'
}

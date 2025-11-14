# ==============================================================================
# FILENAME: function_gl_list_issues.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Lists issues for a specified GitLab project.
#
# SUMMARY:
#   This script defines a function that fetches a list of issues from a GitLab
#   project using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_list_issues
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve a list of
#   issues for a given project. It requires the project ID as an argument.
#
# USAGE:
#   gl_list_issues <project_id>
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of issue IIDs, titles, states, and web URLs, formatted as JSON.
#
# ==============================================================================
gl_list_issues() {
    # Check if the project ID is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gl_list_issues <project_id>"
        return 1
    fi
    # Send a GET request to the GitLab API to retrieve a list of issues.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for listing issues in the specified project.
    # The response is piped to `jq` to extract the iid, title, state, and web_url for each issue.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/projects/$1/issues | jq '.[] | {iid, title, state, web_url}'
}

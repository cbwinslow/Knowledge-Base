# ==============================================================================
# FILENAME: function_gl_get_repos.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a list of the authenticated user's GitLab repositories (projects).
#
# SUMMARY:
#   This script defines a function that fetches a list of GitLab projects owned
#   by the authenticated user using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_get_repos
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve a list of
#   projects owned by the authenticated user. It then extracts the full path
#   with namespace for each project.
#
# USAGE:
#   gl_get_repos
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of full paths with namespaces of the user's projects, formatted as JSON.
#
# ==============================================================================
gl_get_repos() {
    # Send a GET request to the GitLab API to retrieve a list of projects.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for listing owned projects.
    # The response is piped to `jq` to extract the path_with_namespace for each project.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/projects?owned=true | jq '.[] | .path_with_namespace'
}

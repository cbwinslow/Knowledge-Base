# ==============================================================================
# FILENAME: function_gl_list_projects.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Lists the authenticated user's GitLab projects.
#
# SUMMARY:
#   This script defines a function that fetches a list of GitLab projects owned
#   by the authenticated user using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_list_projects
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve a list of
#   projects owned by the authenticated user. It then extracts the ID, name,
#   and web URL for each project.
#
# USAGE:
#   gl_list_projects
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of project IDs, names, and web URLs, formatted as JSON.
#
# ==============================================================================
gl_list_projects() {
    # Send a GET request to the GitLab API to retrieve a list of projects.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for listing owned projects.
    # The response is piped to `jq` to extract the id, name, and web_url for each project.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/projects?owned=true | jq '.[] | {id, name, web_url}'
}

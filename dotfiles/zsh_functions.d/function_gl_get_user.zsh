# ==============================================================================
# FILENAME: function_gl_get_user.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves the authenticated user's GitLab profile information.
#
# SUMMARY:
#   This script defines a function that fetches the GitLab profile details of
#   the authenticated user using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_get_user
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve the profile
#   information of the authenticated user.
#
# USAGE:
#   gl_get_user
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API containing the user's profile details.
#
# ==============================================================================
gl_get_user() {
    # Send a GET request to the GitLab API to retrieve user information.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for the authenticated user.
    # The response is piped to `jq` for pretty-printing.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/user | jq '.'
}

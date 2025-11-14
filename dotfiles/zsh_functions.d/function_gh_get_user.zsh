# ==============================================================================
# FILENAME: function_gh_get_user.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves the authenticated user's GitHub profile information.
#
# SUMMARY:
#   This script defines a function that fetches the GitHub profile details of
#   the authenticated user using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_get_user
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve the profile
#   information of the authenticated user.
#
# USAGE:
#   gh_get_user
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API containing the user's profile details.
#
# ==============================================================================
gh_get_user() {
    # Send a GET request to the GitHub API to retrieve user information.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for the authenticated user.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/user | jq '.'
}

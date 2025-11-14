# ==============================================================================
# FILENAME: function_gh_list_gists.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Lists the authenticated user's GitHub Gists.
#
# SUMMARY:
#   This script defines a function that fetches a list of GitHub Gists owned
#   by the authenticated user using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_list_gists
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a list of
#   Gists for the authenticated user. It then extracts the ID, description, and
#   HTML URL for each Gist.
#
# USAGE:
#   gh_list_gists
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of Gist IDs, descriptions, and HTML URLs, formatted as JSON.
#
# ==============================================================================
gh_list_gists() {
    # Send a GET request to the GitHub API to retrieve a list of Gists.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for listing user Gists.
    # The response is piped to `jq` to extract the id, description, and html_url for each Gist.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/gists | jq '.[] | {id, description, html_url}'
}

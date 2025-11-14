# ==============================================================================
# FILENAME: function_gh_get_repos.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a list of the authenticated user's GitHub repositories.
#
# SUMMARY:
#   This script defines a function that fetches a list of GitHub repositories
#   owned by the authenticated user using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_get_repos
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a list of
#   repositories for the authenticated user. It fetches up to 100 repositories
#   per page.
#
# USAGE:
#   gh_get_repos
#
# PARAMETERS:
#   None
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of full names of the user's repositories, formatted as JSON.
#
# ==============================================================================
gh_get_repos() {
    # Send a GET request to the GitHub API to retrieve a list of repositories.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for listing user repositories, with a limit of 100 per page.
    # The response is piped to `jq` to extract the full name of each repository.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/user/repos?per_page=100 | jq '.[] | .full_name'
}

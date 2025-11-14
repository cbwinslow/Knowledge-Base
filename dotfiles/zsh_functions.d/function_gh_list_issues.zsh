# ==============================================================================
# FILENAME: function_gh_list_issues.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Lists issues for a specified GitHub repository.
#
# SUMMARY:
#   This script defines a function that fetches a list of issues from a GitHub
#   repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_list_issues
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a list of
#   issues for a given repository. It requires the repository owner and
#   repository name as arguments.
#
# USAGE:
#   gh_list_issues <owner> <repo>
#
# PARAMETERS:
#   $1 (owner): The owner of the GitHub repository.
#   $2 (repo): The name of the GitHub repository.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   A list of issue numbers, titles, states, and HTML URLs, formatted as JSON.
#
# ==============================================================================
gh_list_issues() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_list_issues <owner> <repo>"
        return 1
    fi
    # Send a GET request to the GitHub API to retrieve a list of issues.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for listing issues in the specified repository.
    # The response is piped to `jq` to extract the number, title, state, and html_url for each issue.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/$1/$2/issues | jq '.[] | {number, title, state, html_url}'
}

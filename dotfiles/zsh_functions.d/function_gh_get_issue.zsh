# ==============================================================================
# FILENAME: function_gh_get_issue.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a single issue from a GitHub repository.
#
# SUMMARY:
#   This script defines a function that fetches the details of a specified
#   issue from a GitHub repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_get_issue
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a specific
#   issue. It requires the repository owner, repository name, and issue number
#   as arguments.
#
# USAGE:
#   gh_get_issue <owner> <repo> <issue_number>
#
# PARAMETERS:
#   $1 (owner): The owner of the GitHub repository.
#   $2 (repo): The name of the GitHub repository.
#   $3 (issue_number): The number of the issue to retrieve.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API containing the issue details.
#
# ==============================================================================
gh_get_issue() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_get_issue <owner> <repo> <issue_number>"
        return 1
    fi
    # Send a GET request to the GitHub API to retrieve the issue.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for the specified issue.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/$1/$2/issues/$3 | jq '.'
}

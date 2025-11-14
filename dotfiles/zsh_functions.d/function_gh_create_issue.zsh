# ==============================================================================
# FILENAME: function_gh_create_issue.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates an issue in a GitHub repository.
#
# SUMMARY:
#   This script defines a function that creates a new issue in a GitHub
#   repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_create_issue
#
# DESCRIPTION:
#   This function sends a POST request to the GitHub API to create an issue.
#   It requires the repository owner, repository name, and issue title as
#   arguments, and can optionally include a body for the issue.
#
# USAGE:
#   gh_create_issue <owner> <repo> <title> [body]
#
# PARAMETERS:
#   $1 (owner): The owner of the GitHub repository.
#   $2 (repo): The name of the GitHub repository.
#   $3 (title): The title of the issue.
#   $4 (body): Optional. The body of the issue.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API.
#
# ==============================================================================
gh_create_issue() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_create_issue <owner> <repo> <title> [body]"
        return 1
    fi
    # Assign the first argument to the 'owner' variable.
    local owner=$1
    # Assign the second argument to the 'repo' variable.
    local repo=$2
    # Assign the third argument to the 'title' variable.
    local title=$3
    # Assign the fourth argument to the 'body' variable, or an empty string if it is not provided.
    local body=${4:-""}
    # Create a JSON payload with the issue title and body.
    local json_payload=$(printf '{"title":"%s", "body":"%s"}' "$title" "$body")
    # Send a POST request to the GitHub API to create the issue.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for creating issues in the specified repository.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Authorization: token $GITHUB_PAT" -d "$json_payload" https://api.github.com/repos/$owner/$repo/issues | jq '.'
}

# ==============================================================================
# FILENAME: function_gh_create_repo.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates a new GitHub repository.
#
# SUMMARY:
#   This script defines a function that creates a new GitHub repository using
#   the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_create_repo
#
# DESCRIPTION:
#   This function sends a POST request to the GitHub API to create a new
#   repository. It requires the repository name as an argument.
#
# USAGE:
#   gh_create_repo <repo_name>
#
# PARAMETERS:
#   $1 (repo_name): The name of the new repository.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API.
#
# ==============================================================================
gh_create_repo() {
    # Check if the repository name is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gh_create_repo <repo_name>"
        return 1
    fi
    # Create a JSON payload with the repository name.
    # The name is taken from the first argument ($1).
    local json_payload=$(printf '{"name":"%s"}' "$1")
    # Send a POST request to the GitHub API to create the repository.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for creating user repositories.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Authorization: token $GITHUB_PAT" -d "$json_payload" https://api.github.com/user/repos | jq '.'
}

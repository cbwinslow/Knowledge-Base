# ==============================================================================
# FILENAME: function_gh_get_gist.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves the content of a specific GitHub Gist.
#
# SUMMARY:
#   This script defines a function that fetches the content of a specified
#   GitHub Gist using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_get_gist
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve the content
#   of a Gist. It requires the Gist ID as an argument.
#
# USAGE:
#   gh_get_gist <gist_id>
#
# PARAMETERS:
#   $1 (gist_id): The ID of the Gist to retrieve.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The content of the Gist file(s).
#
# ==============================================================================
gh_get_gist() {
    # Check if the Gist ID is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gh_get_gist <gist_id>"
        return 1
    fi
    # Send a GET request to the GitHub API to retrieve the Gist.
    # -s: silent mode
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for the specified Gist.
    # The response is piped to `jq` to extract the content of the files within the Gist.
    curl -s -H "Authorization: token $GITHUB_PAT" https://api.github.com/gists/$1 | jq '.files | .[] | .content'
}

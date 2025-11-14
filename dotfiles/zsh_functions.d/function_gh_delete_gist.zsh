# ==============================================================================
# FILENAME: function_gh_delete_gist.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Deletes a GitHub Gist.
#
# SUMMARY:
#   This script defines a function that deletes a specified GitHub Gist using
#   the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_delete_gist
#
# DESCRIPTION:
#   This function sends a DELETE request to the GitHub API to delete a Gist.
#   It requires the Gist ID as an argument.
#
# USAGE:
#   gh_delete_gist <gist_id>
#
# PARAMETERS:
#   $1 (gist_id): The ID of the Gist to delete.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   A message indicating that the Gist has been deleted.
#
# ==============================================================================
gh_delete_gist() {
    # Check if the Gist ID is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gh_delete_gist <gist_id>"
        return 1
    fi
    # Send a DELETE request to the GitHub API to delete the Gist.
    # -s: silent mode
    # -X DELETE: use the DELETE HTTP method
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for the specified Gist.
    curl -s -X DELETE -H "Authorization: token $GITHUB_PAT" https://api.github.com/gists/$1
    # Print a message indicating that the Gist has been deleted.
    echo "Gist $1 deleted."
}

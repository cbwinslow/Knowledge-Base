# ==============================================================================
# FILENAME: function_gh_get_project.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a single project from a GitHub repository.
#
# SUMMARY:
#   This script defines a function that fetches the details of a specified
#   project from a GitHub repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_get_project
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a specific
#   project. It requires the repository owner, repository name, and project ID
#   as arguments.
#
# USAGE:
#   gh_get_project <owner> <repo> <project_id>
#
# PARAMETERS:
#   $1 (owner): The owner of the GitHub repository.
#   $2 (repo): The name of the GitHub repository.
#   $3 (project_id): The ID of the project to retrieve.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API containing the project details.
#
# ==============================================================================
gh_get_project() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_get_project <owner> <repo> <project_id>"
        return 1
    fi
    # Send a GET request to the GitHub API to retrieve the project.
    # -s: silent mode
    # -H "Accept: application/vnd.github.inertia-preview+json": required header for the Projects API
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for the specified project.
    # The response is piped to `jq` for pretty-printing.
    curl -s -H "Accept: application/vnd.github.inertia-preview+json" -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/$1/$2/projects/$3 | jq '.'
}

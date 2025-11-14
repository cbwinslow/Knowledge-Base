# ==============================================================================
# FILENAME: function_gh_list_projects.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Lists projects for a specified GitHub repository.
#
# SUMMARY:
#   This script defines a function that fetches a list of projects from a GitHub
#   repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_list_projects
#
# DESCRIPTION:
#   This function sends a GET request to the GitHub API to retrieve a list of
#   projects for a given repository. It requires the repository owner and
#   repository name as arguments.
#
# USAGE:
#   gh_list_projects <owner> <repo>
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
#   A list of project IDs, names, states, and HTML URLs, formatted as JSON.
#
# ==============================================================================
gh_list_projects() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_list_projects <owner> <repo>"
        return 1
    fi
    # Send a GET request to the GitHub API to retrieve a list of projects.
    # -s: silent mode
    # -H "Accept: application/vnd.github.inertia-preview+json": required header for the Projects API
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # The URL is the API endpoint for listing projects in the specified repository.
    # The response is piped to `jq` to extract the id, name, state, and html_url for each project.
    curl -s -H "Accept: application/vnd.github.inertia-preview+json" -H "Authorization: token $GITHUB_PAT" https://api.github.com/repos/$1/$2/projects | jq '.[] | {id, name, state, html_url}'
}

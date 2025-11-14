# ==============================================================================
# FILENAME: function_gh_close_project.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Closes a project in a GitHub repository.
#
# SUMMARY:
#   This script defines a function that closes a specified project in a GitHub
#   repository using the GitHub API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gh_close_project
#
# DESCRIPTION:
#   This function sends a PATCH request to the GitHub API to close a project.
#   It requires the repository owner, repository name, and project ID as
#   arguments.
#
# USAGE:
#   gh_close_project <owner> <repo> <project_id>
#
# PARAMETERS:
#   $1 (owner): The owner of the GitHub repository.
#   $2 (repo): The name of the GitHub repository.
#   $3 (project_id): The ID of the project to close.
#
# INPUTS:
#   - A GitHub Personal Access Token (PAT) stored in the GITHUB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitHub API.
#
# ==============================================================================
gh_close_project() {
    # Check if all required arguments are provided.
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        # If not all arguments are provided, print a usage message and return.
        echo "Usage: gh_close_project <owner> <repo> <project_id>"
        return 1
    fi
    # Assign the first argument to the 'owner' variable.
    local owner=$1
    # Assign the second argument to the 'repo' variable.
    local repo=$2
    # Assign the third argument to the 'project_id' variable.
    local project_id=$3
    # Create a JSON payload to set the state of the project to 'closed'.
    local json_payload=$(printf '{"state":"closed"}')
    # Send a PATCH request to the GitHub API to close the project.
    # -s: silent mode
    # -X PATCH: use the PATCH HTTP method
    # -H "Accept: application/vnd.github.inertia-preview+json": required header for the Projects API
    # -H "Authorization: token $GITHUB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for the specified project.
    # The response is piped to `jq` for pretty-printing.
    curl -s -X PATCH -H "Accept: application/vnd.github.inertia-preview+json" -H "Authorization: token $GITHUB_PAT" -d "$json_payload" https://api.github.com/repos/$owner/$repo/projects/$project_id | jq '.'
}

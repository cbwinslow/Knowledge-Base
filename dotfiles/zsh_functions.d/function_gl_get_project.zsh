# ==============================================================================
# FILENAME: function_gl_get_project.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Retrieves a single project from GitLab.
#
# SUMMARY:
#   This script defines a function that fetches the details of a specified
#   project from GitLab using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_get_project
#
# DESCRIPTION:
#   This function sends a GET request to the GitLab API to retrieve a specific
#   project. It requires the project ID as an argument.
#
# USAGE:
#   gl_get_project <project_id>
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project to retrieve.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API containing the project details.
#
# ==============================================================================
gl_get_project() {
    # Check if the project ID is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gl_get_project <project_id>"
        return 1
    fi
    # Send a GET request to the GitLab API to retrieve the project.
    # -s: silent mode
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # The URL is the API endpoint for the specified project.
    # The response is piped to `jq` for pretty-printing.
    curl -s --header "PRIVATE-TOKEN: $GITLAB_PAT" https://gitlab.com/api/v4/projects/$1 | jq '.'
}

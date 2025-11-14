# ==============================================================================
# FILENAME: function_gl_close_project.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Archives a GitLab project, effectively "closing" it.
#
# SUMMARY:
#   This script defines a function that archives a specified GitLab project
#   using the GitLab API.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: gl_close_project
#
# DESCRIPTION:
#   This function sends a PUT request to the GitLab API to archive a project.
#   Archiving a project is equivalent to closing it in the context of GitLab.
#   It requires the project ID as an argument.
#
# USAGE:
#   gl_close_project <project_id>
#
# PARAMETERS:
#   $1 (project_id): The ID of the GitLab project to archive.
#
# INPUTS:
#   - A GitLab Personal Access Token (PAT) stored in the GITLAB_PAT
#     environment variable.
#
# OUTPUTS:
#   The JSON response from the GitLab API.
#
# ==============================================================================
gl_close_project() {
    # Check if the project ID is provided.
    if [ -z "$1" ]; then
        # If not provided, print a usage message and return.
        echo "Usage: gl_close_project <project_id>"
        return 1
    fi
    # Assign the first argument to the 'project_id' variable.
    local project_id=$1
    # Create a JSON payload to set the 'archived' state to true.
    local json_payload=$(printf '{"archived":true}')
    # Send a PUT request to the GitLab API to archive the project.
    # -s: silent mode
    # -X PUT: use the PUT HTTP method
    # --header "PRIVATE-TOKEN: $GITLAB_PAT": add the authorization header
    # -d "$json_payload": send the JSON payload
    # The URL is the API endpoint for the specified project.
    # The response is piped to `jq` for pretty-printing.
    curl -s -X PUT --header "PRIVATE-TOKEN: $GITLAB_PAT" -d "$json_payload" https://gitlab.com/api/v4/projects/$project_id | jq '.'
}

# ==============================================================================
# File:         function_gl_create_repo.zsh
# Author:       foomanchu8008
# Date:         2025-10-25
#
# Description:  This script creates a new repository on GitLab and sets the
#               upstream for the current branch to the newly created repo.
#
# Parameters:   None
#
# Usage:        gl_create_repo
#
# Input:        None
#
# Output:       The script will output the results of the `git push` command.
#
# License:      MIT
#
# Change Log:
#   - 2025-10-25: Initial creation of the script.
#
# ==============================================================================

gl_create_repo() {
    git push --set-upstream git@gitlab.com:cbwinslow/$(git rev-parse --show-toplevel | xargs basename).git $(git rev-parse --abbrev-ref HEAD)
}

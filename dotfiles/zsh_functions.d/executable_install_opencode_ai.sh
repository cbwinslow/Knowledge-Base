#!/bin/zsh
# ==============================================================================
# FILENAME: install_opencode_ai.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the Opencode-AI CLI using npm.
#
# SUMMARY:
#   This script defines a function to ensure the Opencode-AI CLI is installed
#   and accessible, checking for Node.js/npm and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_opencode_ai_core.sh"

# ==============================================================================
# FUNCTION: install_opencode_ai
#
# DESCRIPTION:
#   This function calls the shared core logic to install the Opencode-AI CLI.
#   It then refreshes the current Zsh shell session to make the `opencode-ai`
#   command immediately available.
#
# USAGE:
#   install_opencode_ai
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Messages indicating installation progress and success/failure from the core script.
#   - Refreshes the current Zsh shell session.
#
# ==============================================================================
install_opencode_ai() {
    _install_opencode_ai_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'opencode' command."
    else
        echo "Error: Opencode-AI CLI core installation failed."
        return 1
    fi
}

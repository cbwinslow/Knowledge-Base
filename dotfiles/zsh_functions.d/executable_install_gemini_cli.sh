#!/bin/zsh
# ==============================================================================
# FILENAME: install_gemini_cli.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the Google Gemini CLI using npm.
#
# SUMMARY:
#   This script defines a function to ensure the Gemini CLI is installed
#   and accessible, checking for Node.js/npm and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_gemini_cli_core.sh"

# ==============================================================================
# FUNCTION: install_gemini_cli
#
# DESCRIPTION:
#   This function calls the shared core logic to install the Google Gemini CLI.
#   It then refreshes the current Zsh shell session to make the `gemini`
#   command immediately available.
#
# USAGE:
#   install_gemini_cli
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
install_gemini_cli() {
    _install_gemini_cli_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'gemini' command (or 'gcli' alias)."
    else
        echo "Error: Gemini CLI core installation failed."
        return 1
    fi
}

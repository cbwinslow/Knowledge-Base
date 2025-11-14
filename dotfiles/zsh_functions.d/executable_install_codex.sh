#!/bin/zsh
# ==============================================================================
# FILENAME: install_codex.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the OpenAI Codex CLI using npm.
#
# SUMMARY:
#   This script defines a function to ensure the OpenAI Codex CLI is installed
#   and accessible, checking for Node.js/npm and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_codex_core.sh"

# ==============================================================================
# FUNCTION: install_codex
#
# DESCRIPTION:
#   This function calls the shared core logic to install the OpenAI Codex CLI.
#   It then refreshes the current Zsh shell session to make the `codex`
#   command immediately available.
#
# USAGE:
#   install_codex
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
# NOTE:
#   Requires the OPENAI_API_KEY environment variable to be set.
#   Example: `export OPENAI_API_KEY="your-api-key-here"
#
# ==============================================================================
install_codex() {
    _install_codex_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'codex' command."
        echo "Remember to set your OPENAI_API_KEY environment variable:"
        echo "  export OPENAI_API_KEY=\"your-api-key-here\""
    else
        echo "Error: OpenAI Codex CLI core installation failed."
        return 1
    fi
}

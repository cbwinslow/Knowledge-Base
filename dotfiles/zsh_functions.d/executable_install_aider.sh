#!/bin/zsh
# ==============================================================================
# FILENAME: install_aider.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the Aider CLI using pip.
#
# SUMMARY:
#   This script defines a function to ensure the Aider CLI is installed
#   and accessible, checking for Python/pip and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/dotfiles/scripts/shared/install_aider_core.sh"

# ==============================================================================
# FUNCTION: install_aider
#
# DESCRIPTION:
#   This function calls the shared core logic to install the Aider CLI.
#   It then refreshes the current Zsh shell session to make the `aider`
#   command immediately available.
#
# USAGE:
#   install_aider
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
#   Requires Python 3.8-3.13. Also requires the OPENAI_API_KEY environment
#   variable to be set for Aider to function correctly.
#   Example: `export OPENAI_API_KEY="your-api-key-here"`
#
# ==============================================================================
install_aider() {
    _install_aider_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'aider' command."
        echo "Remember to configure your OpenAI API key for Aider."
        echo "  export OPENAI_API_KEY=\"your-api-key-here\""
    else
        echo "Error: Aider CLI core installation failed."
        return 1
    fi
}

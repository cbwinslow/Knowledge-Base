#!/bin/zsh
# ==============================================================================
# FILENAME: install_forgecode.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the ForgeCode CLI using npm.
#
# SUMMARY:
#   This script defines a function to ensure the ForgeCode CLI is installed
#   and accessible, checking for Node.js/npm and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_forgecode_core.sh"

# ==============================================================================
# FUNCTION: install_forgecode
#
# DESCRIPTION:
#   This function calls the shared core logic to install the ForgeCode CLI.
#   It then refreshes the current Zsh shell session to make the `forge`
#   command immediately available.
#
# USAGE:
#   install_forgecode
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
#   ForgeCode requires authentication after installation. Refer to the official
#   ForgeCode documentation for details on how to authenticate (e.g., OAuth,
#   API keys for other providers).
#
# ==============================================================================
install_forgecode() {
    _install_forgecode_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'forge' command."
        echo "Remember to authenticate ForgeCode after installation."
        echo "Refer to the ForgeCode documentation for authentication options."
    else
        echo "Error: ForgeCode CLI core installation failed."
        return 1
    fi
}

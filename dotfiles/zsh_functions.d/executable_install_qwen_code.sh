#!/bin/zsh
# ==============================================================================
# FILENAME: install_qwen_code.sh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs or updates the Qwen Code CLI using npm.
#
# SUMMARY:
#   This script defines a function to ensure the Qwen Code CLI is installed
#   and accessible, checking for Node.js/npm and refreshing the shell.
#
# ==============================================================================

# Source the shared core installation logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_qwen_code_core.sh"

# ==============================================================================
# FUNCTION: install_qwen_code
#
# DESCRIPTION:
#   This function calls the shared core logic to install the Qwen Code CLI.
#   It then refreshes the current Zsh shell session to make the `qwen-code`
#   command immediately available.
#
# USAGE:
#   install_qwen_code
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
install_qwen_code() {
    _install_qwen_code_core
    if [ $? -eq 0 ]; then
        source ~/.zshrc
        echo "You can now use the 'qwen' command."
    else
        echo "Error: Qwen Code CLI core installation failed."
        return 1
    fi
}

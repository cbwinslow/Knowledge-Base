#!/bin/zsh
# ==============================================================================
# FILENAME: install_go.zsh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-05
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs the latest stable version of Go (Go-lang) on a Linux x64 system.
#
# SUMMARY:
#   This script defines a Zsh function that sources the shared core logic
#   for Go installation and executes it. It's the shell-specific entry point
#   for installing Go.
#
# ==============================================================================

# Source the shared core logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_go_core.sh"

# ==============================================================================
# FUNCTION: install_go
#
# DESCRIPTION:
#   This function calls the shared core logic to install Go-lang.
#
# USAGE:
#   install_go
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Installation status messages.
#   - Instructions for user to update their shell configuration.
#
# ==============================================================================
install_go() {
    _install_go_core
}

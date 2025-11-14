#!/bin/zsh
# ==============================================================================
# FILENAME: install_ollama.zsh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-05
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Installs Ollama, a lightweight, extensible framework for running LLMs locally.
#
# SUMMARY:
#   This script defines a Zsh function that sources the shared core logic
#   for Ollama installation and executes it. It's the shell-specific entry point
#   for installing Ollama.
#
# ==============================================================================

# Source the shared core logic
source "${HOME}/.local/share/chezmoi/scripts/shared/install_ollama_core.sh"

# ==============================================================================
# FUNCTION: install_ollama
#
# DESCRIPTION:
#   This function calls the shared core logic to install Ollama.
#
# USAGE:
#   install_ollama
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Installation status messages.
#
# ==============================================================================
install_ollama() {
    _install_ollama_core
}

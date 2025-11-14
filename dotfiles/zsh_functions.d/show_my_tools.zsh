#!/bin/zsh
# ==============================================================================
# FILENAME: show_my_tools.zsh
#
# AUTHOR: Gemini (Modified by foomanchu8008)
# DATE: 2025-11-04
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Displays a summary of AI coding terminal tools and provides interactive
#   access to their documentation.
#
# SUMMARY:
#   This script defines a Zsh function that sources the shared core logic
#   for `show_my_tools` and executes it. It's the shell-specific entry point
#   for the tool display and documentation browser.
#
# ==============================================================================

# Source the shared core logic
source "${HOME}/.local/share/chezmoi/scripts/shared/show_my_tools_core.sh"

# ==============================================================================
# FUNCTION: show_my_tools
#
# DESCRIPTION:
#   This function calls the shared core logic to display a list of AI coding
#   terminal tool aliases and their descriptions. It also provides an
#   interactive menu to browse relevant documentation files.
#
# USAGE:
#   show_my_tools
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   - Formatted list of aliases and their descriptions.
#   - Interactive menu for documentation browsing.
#
# ==============================================================================
show_my_tools() {
    _show_my_tools_core
}

# ==============================================================================
# FILENAME: function_fzf-cd-widget.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   A widget that uses `fzf` to interactively select a directory and then
#   changes the current working directory to the selected directory.
#
# SUMMARY:
#   This script defines a function that provides a convenient way to navigate
#   the file system by using the fuzzy finder `fzf` to select a directory.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: fzf-cd-widget
#
# DESCRIPTION:
#   This function uses `find` to list all directories in the current directory,
#   pipes them to `fzf` for interactive selection, and then `cd`s into the
#   selected directory.
#
# USAGE:
#   fzf-cd-widget
#   (This function is intended to be bound to a key combination in .zshrc)
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   Changes the current working directory.
#
# ==============================================================================
fzf-cd-widget() {
    # Declare a local variable to store the selected directory.
    local selected_dir
    # Use `find` to list all directories, then pipe to `fzf`.
    # `fzf` will display the list of directories and allow the user to select one.
    # The `--preview` option shows a tree view of the selected directory.
    selected_dir=$(find * -type d -print | fzf --preview 'tree -C {}')
    # If a directory was selected (i.e., the variable is not empty),
    # then change the current directory to the selected directory.
    if [[ -n $selected_dir ]]; then
        cd $selected_dir
    fi
}

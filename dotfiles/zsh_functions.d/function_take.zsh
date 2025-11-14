# ==============================================================================
# FILENAME: function_take.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   Creates a new directory and immediately changes the current working
#   directory into it.
#
# SUMMARY:
#   This script defines a convenient function `take` that combines the
#   functionality of `mkdir -p` and `cd` into a single command.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: take
#
# DESCRIPTION:
#   This function takes a single argument, which is the name of the directory
#   to create. It first creates the directory (and any necessary parent
#   directories) using `mkdir -p`, and then changes the current working
#   directory to the newly created directory.
#
# USAGE:
#   take <directory_name>
#
# PARAMETERS:
#   $1 (directory_name): The name of the directory to create and change into.
#
# INPUTS:
#   None
#
# OUTPUTS:
#   Changes the current working directory.
#
# ==============================================================================
take () {
    # Create the directory specified by the first argument.
    # -p: create parent directories if they don't exist, and don't error if the directory already exists.
    mkdir -p $1
    # Change the current working directory to the newly created directory.
    cd $1
}

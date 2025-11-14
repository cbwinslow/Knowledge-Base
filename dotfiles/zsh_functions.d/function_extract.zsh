# ==============================================================================
# FILENAME: function_extract.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function
#
# PURPOSE:
#   A convenient function to extract various types of archive files.
#
# SUMMARY:
#   This script defines a function called `extract` that can be used to extract
#   a variety of archive formats, including .tar.bz2, .tar.gz, .bz2, .rar,
#   .gz, .tar, .tbz2, .tgz, .zip, .Z, and .7z.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: extract
#
# DESCRIPTION:
#   This function takes a single argument, the name of an archive file, and
#   extracts it using the appropriate command based on the file extension.
#
# USAGE:
#   extract <archive_file>
#
# PARAMETERS:
#   $1: The path to the archive file to be extracted.
#
# INPUTS:
#   An archive file.
#
# OUTPUTS:
#   The extracted files from the archive.
#
# ==============================================================================
extract () {
    # Check if the provided argument is a file.
    if [ -f $1 ] ;
    then
        # If it is a file, use a case statement to determine the file type and
        # use the appropriate extraction command.
        case $1 in
            *.tar.bz2)   tar xvjf $1     ;; # For .tar.bz2 files, use tar with xvjf flags.
            *.tar.gz)    tar xvzf $1     ;; # For .tar.gz files, use tar with xvzf flags.
            *.bz2)       bunzip2 $1      ;; # For .bz2 files, use bunzip2.
            *.rar)       unrar x $1      ;; # For .rar files, use unrar.
            *.gz)        gunzip $1       ;; # For .gz files, use gunzip.
            *.tar)       tar xvf $1      ;; # For .tar files, use tar with xvf flags.
            *.tbz2)      tar xvjf $1     ;; # For .tbz2 files, use tar with xvjf flags.
            *.tgz)       tar xvzf $1     ;; # For .tgz files, use tar with xvzf flags.
            *.zip)       unzip $1        ;; # For .zip files, use unzip.
            *.Z)         uncompress $1   ;; # For .Z files, use uncompress.
            *.7z)        7z x $1         ;; # For .7z files, use 7z.
            *)           echo "'$1' cannot be extracted via >extract<" ;; # If the file type is not recognized, print an error message.
        esac
    else
        # If the provided argument is not a file, print an error message.
        echo "'$1' is not a valid file"
    fi
}

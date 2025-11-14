# ==============================================================================
# FILENAME: cleanup_functions.zsh
#
# AUTHOR: foomanchu8008
# DATE: 2025-10-25
#
# TYPE: Zsh Function Library
#
# PURPOSE:
#   Provides a suite of functions for cleaning up various system resources
#   to free up disk space.
#
# SUMMARY:
#   This script contains functions to clean up Docker resources, package manager
#   caches (pip, npm, yarn, pnpm), system logs, download directories, and more.
#
# ==============================================================================

# ==============================================================================
# FUNCTION: disk_usage
#
# DESCRIPTION:
#   Displays the top 20 largest directories in the user's home directory.
#
# USAGE:
#   disk_usage
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A list of the top 20 largest directories and their sizes.
#
# ==============================================================================
disk_usage() {
    # Display a header for the disk usage report.
    echo "=== Disk Usage (Top 20 largest directories) ==="
    # Calculate disk usage of directories in the home directory, one level deep.
    # -h: human-readable format
    # --max-depth=1: only look at top-level directories in the home directory
    # 2>/dev/null: suppress error messages (e.g., for directories with restricted access)
    # sort -hr: sort in human-readable reverse order (largest first)
    # head -20: display only the top 20 results
    du -h /home/foomanchu8008 --max-depth=1 2>/dev/null | sort -hr | head -20
}

# ==============================================================================
# FUNCTION: docker_clean
#
# DESCRIPTION:
#   Cleans up unused Docker resources, including containers, images, volumes,
#   and networks.
#
# USAGE:
#   docker_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the Docker cleanup is complete.
#
# ==============================================================================
docker_clean() {
    # Display a header for the Docker cleanup process.
    echo "=== Cleaning Docker resources ==="
    # Prune unused Docker system resources (e.g., stopped containers, dangling images).
    # -f: force removal without prompting for confirmation.
    docker system prune -f
    # Prune unused Docker volumes.
    docker volume prune -f
    # Prune unused Docker networks.
    docker network prune -f
    # Prune the Docker build cache.
    docker builder prune -f
    # Display a message indicating that the cleanup is complete.
    echo "Docker cleanup complete."
}

# ==============================================================================
# FUNCTION: pip_clean
#
# DESCRIPTION:
#   Cleans the cache for pip and pipx.
#
# USAGE:
#   pip_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the pip cache cleanup is complete.
#
# ==============================================================================
pip_clean() {
    # Display a header for the pip cache cleanup process.
    echo "=== Cleaning Python pip cache ==="
    # Purge the pip cache.
    # 2>/dev/null: suppress error messages if pip is not installed or there is no cache.
    # || echo ...: if the command fails, print a message.
    pip cache purge 2>/dev/null || echo "pip cache purge not available or no cache to clean"
    # Purge the pipx cache.
    pipx run pip cache purge 2>/dev/null || echo "pipx cache not available or no cache to clean"
}

# ==============================================================================
# FUNCTION: node_clean
#
# DESCRIPTION:
#   Cleans the caches for npm, yarn, and pnpm.
#
# USAGE:
#   node_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the Node.js cache cleanup is complete.
#
# ==============================================================================
node_clean() {
    # Display a header for the Node.js cache cleanup process.
    echo "=== Cleaning Node.js caches ==="
    # Clean the npm cache.
    # --force: required for npm to clear the cache.
    npm cache clean --force 2>/dev/null || echo "npm not available or no cache to clean"
    # Clean the yarn cache.
    yarn cache clean 2>/dev/null || echo "yarn not available or no cache to clean"
    # Prune the pnpm store.
    pnpm store prune 2>/dev/null || echo "pnpm not available or no store to prune"
}

# ==============================================================================
# FUNCTION: system_clean
#
# DESCRIPTION:
#   Cleans system logs and the APT cache (for Debian-based systems).
#
# USAGE:
#   system_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the system cleanup is complete.
#
# ==============================================================================
system_clean() {
    # Display a header for the system log cleanup process.
    echo "=== Cleaning system logs ==="
    # Vacuum the systemd journal to remove old log entries.
    # --vacuum-time=7d: remove entries older than 7 days.
    sudo journalctl --vacuum-time=7d 2>/dev/null || echo "sudo access required for journal cleanup"
    # Vacuum the systemd journal to limit the total size of the journal.
    # --vacuum-size=500M: limit the journal to 500MB.
    sudo journalctl --vacuum-size=500M 2>/dev/null || echo "sudo access required for journal cleanup"
    # Check if the 'apt' command is available.
    if command -v apt &> /dev/null;
    then
        # Remove unused packages.
        sudo apt autoremove -y 2>/dev/null || echo "sudo access required for apt autoremove"
        # Clean the local repository of retrieved package files.
        sudo apt autoclean 2>/dev/null || echo "sudo access required for apt autoclean"
    fi
}

# ==============================================================================
# FUNCTION: downloads_clean
#
# DESCRIPTION:
#   Cleans the Downloads directory of old archive files, but only if the
#   extracted directory exists.
#
# USAGE:
#   downloads_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the Downloads directory cleanup is complete.
#
# ==============================================================================
downloads_clean() {
    # Display a header for the Downloads directory cleanup process.
    echo "=== Cleaning Downloads directory ==="
    # Find archive files in the Downloads directory and process the first 20.
    find ~/Downloads -type f -name "*.zip" -o -name "*.tar.gz" -o -name "*.tar.xz" -o -name "*.rar" -o -name "*.deb" -o -name "*.rpm" | head -20 | while read file;
    do
        # Get the directory name of the file.
        dir_name=$(dirname "$file")
        # Get the base name of the file without the extension.
        base_name=$(basename "$file" | sed 's/\.\(zip\|tar\.gz\|tar\.xz\|rar\|deb\|rpm\)$//')
        # Check if a directory with the same name as the archive exists.
        if [ -d "$dir_name/$base_name" ] || [ -d "$dir_name/${base_name%.tar*}" ]; then
            # If the directory exists, delete the archive file.
            echo "Deleting $file (extracted directory found)"
            rm "$file"
        fi
    done
}

# ==============================================================================
# FUNCTION: cache_clean
#
# DESCRIPTION:
#   Cleans various cache directories, including ~/.cache, /tmp, and /var/tmp.
#   Also cleans the zsh history file if it is larger than 1MB.
#
# USAGE:
#   cache_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the cache cleanup is complete.
#
# ==============================================================================
cache_clean() {
    # Display a header for the cache cleanup process.
    echo "=== Cleaning cache directories ==="
    # Check if the ~/.cache directory exists.
    if [ -d "$HOME/.cache" ]; then
        # Delete temporary files from the cache directory.
        find ~/.cache -type f -name "*.tmp" -delete 2>/dev/null
        # Delete cache files from the cache directory.
        find ~/.cache -type f -name "*.cache" -delete 2>/dev/null
        # Remove all thumbnails from the cache.
        rm -rf ~/.cache/thumbnails/* 2>/dev/null
        # Remove all temporary files from the cache.
        rm -rf ~/.cache/temp/* 2>/dev/null
    fi
    
    # Remove all files from the /tmp directory.
    rm -rf /tmp/* 2>/dev/null
    # Remove all files from the /var/tmp directory.
    rm -rf /var/tmp/* 2>/dev/null
    
    # Check if the zsh history file exists and is larger than 1MB.
    if [ -f "$HOME/.zsh_history" ] && [ $(stat -f%z "$HOME/.zsh_history" 2>/dev/null || stat -c%s "$HOME/.zsh_history" 2>/dev/null) -gt 1048576 ]; then
        # If the file is too large, truncate it to the last 1000 lines.
        echo "Cleaning large zsh history file"
        tail -n 1000 "$HOME/.zsh_history" > "$HOME/.zsh_history.tmp" && mv "$HOME/.zsh_history.tmp" "$HOME/.zsh_history"
    fi
}

# ==============================================================================
# FUNCTION: ide_clean
#
# DESCRIPTION:
#   Cleans the caches for VS Code and JetBrains IDEs.
#
# USAGE:
#   ide_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the IDE cache cleanup is complete.
#
# ==============================================================================
ide_clean() {
    # Display a header for the IDE cache cleanup process.
    echo "=== Cleaning IDE caches ==="
    # Remove the VS Code extensions cache.
    rm -rf ~/.vscode/extensionsCache 2>/dev/null
    # Remove the VS Code workspace storage.
    rm -rf ~/.vscode/workspaceStorage 2>/dev/null
    # Remove the VS Code file cache.
    rm -rf ~/.vscode/fileCache 2>/dev/null
    
    # Remove the JetBrains cache.
    rm -rf ~/Library/Caches/JetBrains/* 2>/dev/null || rm -rf ~/.cache/JetBrains/* 2>/dev/null
    # Remove the VS Code cached data.
    rm -rf ~/.config/Code/CachedData/* 2>/dev/null
}

# ==============================================================================
# FUNCTION: git_clean
#
# DESCRIPTION:
#   Cleans Git repositories by running garbage collection.
#
# USAGE:
#   git_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the Git repository cleanup is complete.
#
# ==============================================================================
git_clean() {
    # Display a header for the Git repository cleanup process.
    echo "=== Cleaning Git repositories ==="
    # Find all .git directories in the specified project directories.
    find ~/projects ~/dev ~/code -type d -name ".git" -path "*/.git" 2>/dev/null | head -30 | while read gitdir;
    do
        # Get the parent directory of the .git directory.
        repo=$(dirname "$gitdir")
        # Display a message indicating which repository is being cleaned.
        echo "Cleaning Git repository: $repo"
        # Change to the repository directory and run garbage collection.
        # --aggressive: more thorough garbage collection.
        # --prune=now: remove old, unreachable objects immediately.
        (cd "$repo" && git gc --aggressive --prune=now 2>/dev/null)
    done
}

# ==============================================================================
# FUNCTION: space_clean
#
# DESCRIPTION:
#   A comprehensive cleanup function that runs all of the other cleanup
#   functions in this file.
#
# USAGE:
#   space_clean
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A summary of the disk space before and after the cleanup.
#
# ==============================================================================
space_clean() {
    # Display a header for the comprehensive cleanup process.
    echo "=== Starting comprehensive cleanup ==="
    # Display the disk space usage of the home directory before the cleanup.
    echo "Before cleanup:"
    df -h ~
    echo ""
    
    # Run all of the cleanup functions.
    docker_clean
    system_clean
    pip_clean
    node_clean
    downloads_clean
    cache_clean
    ide_clean
    git_clean
    
    # Display the disk space usage of the home directory after the cleanup.
    echo ""
    echo "After cleanup:"
    df -h ~
    echo "Comprehensive cleanup complete!"
}

# ==============================================================================
# FUNCTION: find_large_dirs
#
# DESCRIPTION:
#   Finds directories larger than 1GB in the user's home directory.
#
# USAGE:
#   find_large_dirs
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A list of directories larger than 1GB and their sizes.
#
# ==============================================================================
find_large_dirs() {
    # Display a header for the large directory search process.
    echo "=== Finding large directories (1GB+) ==="
    # Find all directories in the home directory and calculate their size.
    # -exec du -sh {} +: execute du -sh on the found directories.
    # awk '$1 ~ /[0-9]+G$/ && $1+0 > 1 {print $0}': filter for directories larger than 1GB.
    # sort -hr: sort in human-readable reverse order (largest first).
    find /home/foomanchu8008 -type d -exec du -sh {} + 2>/dev/null |
    awk '$1 ~ /[0-9]+G$/ && $1+0 > 1 {print $0}' | sort -hr
}

# ==============================================================================
# FUNCTION: remove_old_files
#
# DESCRIPTION:
#   Safely removes old files from the Downloads and Documents directories.
#
# USAGE:
#   remove_old_files
#
# PARAMETERS:
#   None
#
# INPUTS:
#   None
#
# OUTPUTS:
#   A message indicating that the old file removal is complete.
#
# ==============================================================================
remove_old_files() {
    # Display a header for the old file removal process.
    echo "=== Removing files older than 30 days from safe directories ==="
    # Find and delete files in the Downloads directory older than 30 days.
    find ~/Downloads -mindepth 1 -type f -mtime +30 -delete 2>/dev/null
    # Find and delete .tmp files in the Documents directory older than 90 days.
    find ~/Documents -mindepth 1 -type f -mtime +90 -name "*.tmp" -delete 2>/dev/null
    # Find and delete .log files in the Documents directory older than 90 days.
    find ~/Documents -mindepth 1 -type f -mtime +90 -name "*.log" -delete 2>/dev/null
    
    # Display a message indicating that the removal is complete.
    echo "Old file removal complete."
}

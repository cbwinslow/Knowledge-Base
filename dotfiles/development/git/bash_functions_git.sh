#!/bin/bash
# Git Functions - Template
# Category: Version Control
# Description: Functions for managing Git repositories and workflows
# Usage: Source this file in your .bashrc or .zshrc
# Author: Knowledge Base Team
# Last Updated: 2025-11-01

# =============================================================================
# Branch Management
# =============================================================================

# Function: git_current_branch
# Description: Get the name of the current Git branch
# Usage: git_current_branch
# Returns: Current branch name
git_current_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}

# Function: git_create_branch
# Description: Create and checkout a new Git branch
# Usage: git_create_branch <branch_name>
# Arguments:
#   $1 - New branch name
# Returns: 0 on success, 1 on failure
# Example: git_create_branch feature/new-feature
git_create_branch() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Branch name required"
        echo "Usage: git_create_branch <branch_name>"
        return 1
    fi
    
    local branch_name="$1"
    
    echo "Creating and checking out branch: $branch_name"
    git checkout -b "$branch_name"
}

# Function: git_delete_branch
# Description: Delete a local Git branch
# Usage: git_delete_branch <branch_name>
# Arguments:
#   $1 - Branch name to delete
# Returns: 0 on success, 1 on failure
# Example: git_delete_branch feature/old-feature
git_delete_branch() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Branch name required"
        echo "Usage: git_delete_branch <branch_name>"
        return 1
    fi
    
    local branch_name="$1"
    
    echo "Deleting branch: $branch_name"
    git branch -d "$branch_name"
}

# Function: git_delete_branch_force
# Description: Force delete a local Git branch
# Usage: git_delete_branch_force <branch_name>
# Arguments:
#   $1 - Branch name to delete
# Returns: 0 on success, 1 on failure
# Example: git_delete_branch_force feature/abandoned
git_delete_branch_force() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Branch name required"
        echo "Usage: git_delete_branch_force <branch_name>"
        return 1
    fi
    
    local branch_name="$1"
    
    echo "Force deleting branch: $branch_name"
    git branch -D "$branch_name"
}

# Function: git_list_branches
# Description: List all local Git branches
# Usage: git_list_branches
# Returns: List of local branches
git_list_branches() {
    git branch -v
}

# Function: git_list_remote_branches
# Description: List all remote Git branches
# Usage: git_list_remote_branches
# Returns: List of remote branches
git_list_remote_branches() {
    git branch -r -v
}

# Function: git_cleanup_merged_branches
# Description: Delete all local branches that have been merged
# Usage: git_cleanup_merged_branches
# Returns: 0 on success
git_cleanup_merged_branches() {
    local current_branch=$(git_current_branch)
    
    echo "Current branch: $current_branch"
    echo "Finding merged branches..."
    
    git branch --merged | grep -v "\*" | grep -v "master" | grep -v "main" | grep -v "develop" | while read -r branch; do
        echo "Deleting merged branch: $branch"
        git branch -d "$branch"
    done
    
    echo "Cleanup complete!"
}

# =============================================================================
# Commit Management
# =============================================================================

# Function: git_commit_quick
# Description: Quick commit with message
# Usage: git_commit_quick <message>
# Arguments:
#   $1 - Commit message
# Returns: 0 on success, 1 on failure
# Example: git_commit_quick "Fix bug in authentication"
git_commit_quick() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Commit message required"
        echo "Usage: git_commit_quick <message>"
        return 1
    fi
    
    local message="$1"
    
    git add -A
    git commit -m "$message"
}

# Function: git_amend_commit
# Description: Amend the last commit
# Usage: git_amend_commit [message]
# Arguments:
#   $1 - Optional new commit message
# Returns: 0 on success, 1 on failure
# Example: git_amend_commit "Updated commit message"
git_amend_commit() {
    if [[ $# -gt 0 ]]; then
        git commit --amend -m "$1"
    else
        git commit --amend --no-edit
    fi
}

# Function: git_list_recent_commits
# Description: List recent commits with one-line format
# Usage: git_list_recent_commits [count]
# Arguments:
#   $1 - Number of commits to show (default: 10)
# Returns: List of recent commits
# Example: git_list_recent_commits 20
git_list_recent_commits() {
    local count="${1:-10}"
    
    git log --oneline -n "$count"
}

# Function: git_show_commit
# Description: Show details of a specific commit
# Usage: git_show_commit <commit_hash>
# Arguments:
#   $1 - Commit hash
# Returns: Commit details
# Example: git_show_commit abc1234
git_show_commit() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Commit hash required"
        echo "Usage: git_show_commit <commit_hash>"
        return 1
    fi
    
    local commit="$1"
    
    git show "$commit"
}

# =============================================================================
# Status and Diff
# =============================================================================

# Function: git_status_short
# Description: Show Git status in short format
# Usage: git_status_short
# Returns: Short status output
git_status_short() {
    git status -s
}

# Function: git_diff_staged
# Description: Show diff of staged changes
# Usage: git_diff_staged
# Returns: Diff of staged changes
git_diff_staged() {
    git diff --cached
}

# Function: git_diff_unstaged
# Description: Show diff of unstaged changes
# Usage: git_diff_unstaged
# Returns: Diff of unstaged changes
git_diff_unstaged() {
    git diff
}

# Function: git_show_changed_files
# Description: List files changed in last commit
# Usage: git_show_changed_files
# Returns: List of changed files
git_show_changed_files() {
    git diff-tree --no-commit-id --name-only -r HEAD
}

# =============================================================================
# Stash Management
# =============================================================================

# Function: git_stash_save
# Description: Stash changes with a message
# Usage: git_stash_save <message>
# Arguments:
#   $1 - Stash message
# Returns: 0 on success
# Example: git_stash_save "Work in progress on feature X"
git_stash_save() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Stash message required"
        echo "Usage: git_stash_save <message>"
        return 1
    fi
    
    local message="$1"
    
    git stash save "$message"
}

# Function: git_stash_list
# Description: List all stashes
# Usage: git_stash_list
# Returns: List of stashes
git_stash_list() {
    git stash list
}

# Function: git_stash_pop
# Description: Apply and remove most recent stash
# Usage: git_stash_pop
# Returns: 0 on success
git_stash_pop() {
    git stash pop
}

# Function: git_stash_apply
# Description: Apply most recent stash without removing it
# Usage: git_stash_apply [stash_id]
# Arguments:
#   $1 - Optional stash ID (e.g., stash@{0})
# Returns: 0 on success
# Example: git_stash_apply stash@{1}
git_stash_apply() {
    if [[ $# -gt 0 ]]; then
        git stash apply "$1"
    else
        git stash apply
    fi
}

# =============================================================================
# Remote Management
# =============================================================================

# Function: git_list_remotes
# Description: List all remote repositories
# Usage: git_list_remotes
# Returns: List of remotes with URLs
git_list_remotes() {
    git remote -v
}

# Function: git_add_remote
# Description: Add a new remote repository
# Usage: git_add_remote <name> <url>
# Arguments:
#   $1 - Remote name
#   $2 - Remote URL
# Returns: 0 on success, 1 on failure
# Example: git_add_remote upstream https://github.com/user/repo.git
git_add_remote() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Remote name and URL required"
        echo "Usage: git_add_remote <name> <url>"
        return 1
    fi
    
    local name="$1"
    local url="$2"
    
    echo "Adding remote '$name': $url"
    git remote add "$name" "$url"
}

# Function: git_remove_remote
# Description: Remove a remote repository
# Usage: git_remove_remote <name>
# Arguments:
#   $1 - Remote name
# Returns: 0 on success, 1 on failure
# Example: git_remove_remote upstream
git_remove_remote() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Remote name required"
        echo "Usage: git_remove_remote <name>"
        return 1
    fi
    
    local name="$1"
    
    echo "Removing remote: $name"
    git remote remove "$name"
}

# Function: git_fetch_all
# Description: Fetch from all remotes
# Usage: git_fetch_all
# Returns: 0 on success
git_fetch_all() {
    echo "Fetching from all remotes..."
    git fetch --all
}

# Function: git_pull_rebase
# Description: Pull with rebase instead of merge
# Usage: git_pull_rebase
# Returns: 0 on success
git_pull_rebase() {
    git pull --rebase
}

# =============================================================================
# Tag Management
# =============================================================================

# Function: git_list_tags
# Description: List all Git tags
# Usage: git_list_tags
# Returns: List of tags
git_list_tags() {
    git tag -l
}

# Function: git_create_tag
# Description: Create a new annotated tag
# Usage: git_create_tag <tag_name> <message>
# Arguments:
#   $1 - Tag name
#   $2 - Tag message
# Returns: 0 on success, 1 on failure
# Example: git_create_tag v1.0.0 "Release version 1.0.0"
git_create_tag() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Tag name and message required"
        echo "Usage: git_create_tag <tag_name> <message>"
        return 1
    fi
    
    local tag_name="$1"
    local message="$2"
    
    echo "Creating tag: $tag_name"
    git tag -a "$tag_name" -m "$message"
}

# Function: git_delete_tag
# Description: Delete a local tag
# Usage: git_delete_tag <tag_name>
# Arguments:
#   $1 - Tag name
# Returns: 0 on success, 1 on failure
# Example: git_delete_tag v1.0.0
git_delete_tag() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Tag name required"
        echo "Usage: git_delete_tag <tag_name>"
        return 1
    fi
    
    local tag_name="$1"
    
    echo "Deleting tag: $tag_name"
    git tag -d "$tag_name"
}

# Function: git_push_tags
# Description: Push all tags to remote
# Usage: git_push_tags
# Returns: 0 on success
git_push_tags() {
    echo "Pushing all tags to remote..."
    git push --tags
}

# =============================================================================
# Utility Functions
# =============================================================================

# Function: git_undo_last_commit
# Description: Undo last commit but keep changes
# Usage: git_undo_last_commit
# Returns: 0 on success
git_undo_last_commit() {
    echo "Undoing last commit (keeping changes)..."
    git reset --soft HEAD~1
}

# Function: git_discard_changes
# Description: Discard all uncommitted changes
# Usage: git_discard_changes
# Returns: 0 on success
git_discard_changes() {
    echo "WARNING: This will discard all uncommitted changes!"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git reset --hard HEAD
        git clean -fd
        echo "All changes discarded"
    else
        echo "Operation cancelled"
    fi
}

# Function: git_clone_quick
# Description: Clone a repository with minimal depth
# Usage: git_clone_quick <url> [directory]
# Arguments:
#   $1 - Repository URL
#   $2 - Optional target directory
# Returns: 0 on success, 1 on failure
# Example: git_clone_quick https://github.com/user/repo.git myrepo
git_clone_quick() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Repository URL required"
        echo "Usage: git_clone_quick <url> [directory]"
        return 1
    fi
    
    local url="$1"
    local directory="${2:-}"
    
    if [[ -n "$directory" ]]; then
        git clone --depth 1 "$url" "$directory"
    else
        git clone --depth 1 "$url"
    fi
}

# Function: git_repo_size
# Description: Show the size of the Git repository
# Usage: git_repo_size
# Returns: Repository size
git_repo_size() {
    echo "Calculating repository size..."
    du -sh .git
}

# Git Aliases

# Status and info
alias gs='git status'
alias gss='git status -s'
alias gb='git branch'
alias gba='git branch -a'
alias gl='git log --oneline'
alias gla='git log --oneline --all --graph'

# Add and commit
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -m'
alias gca='git commit -am'
alias gcamend='git commit --amend'

# Push and pull
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gplr='git pull --rebase'

# Branch operations
alias gco='git checkout'
alias gcb='git checkout -b'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gm='git merge'

# Diff
alias gd='git diff'
alias gds='git diff --staged'
alias gdh='git diff HEAD'

# Stash
alias gst='git stash'
alias gsta='git stash apply'
alias gstp='git stash pop'
alias gstl='git stash list'

# Remote
alias gr='git remote -v'
alias gf='git fetch'
alias gfa='git fetch --all'

# Cleanup
alias gclean='git clean -fd'
alias greset='git reset --hard HEAD'

# Log
alias glog='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
alias glast='git log -1 HEAD --stat'

# Misc
alias gshow='git show'
alias gtag='git tag'
alias gcount='git rev-list --count HEAD'

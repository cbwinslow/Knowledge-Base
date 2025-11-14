#!/bin/zsh

# =============================================================================
# ALIASES CONFIGURATION
# =============================================================================
# This file contains aliases for all frequently used commands
# =============================================================================

# =============================================================================
# NAVIGATION ALIASES
# =============================================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -ltr'
alias lh='ls -lh'

# =============================================================================
# GIT ALIASES
# =============================================================================
alias g='git'
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'
alias gclean='git clean -fd'
alias greset='git reset --hard HEAD'

# =============================================================================
# SYSTEM MANAGEMENT ALIASES
# =============================================================================
alias update='sudo dnf update -y'
alias upgrade='sudo dnf upgrade -y'
alias install='sudo dnf install -y'
alias remove='sudo dnf remove -y'
alias search='dnf search'
alias info='dnf info'
alias clean='sudo dnf clean all'

# =============================================================================
# DOCKER ALIASES
# =============================================================================
alias d='docker'
alias dc='docker-compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dr='docker run'
alias drmi='docker rmi'
alias drm='docker rm'
alias dstop='docker stop'
alias dstart='docker start'
alias dlogs='docker logs'

# =============================================================================
# NETWORKING ALIASES
# =============================================================================
alias myip='curl -s ifconfig.me'
alias localip='ip addr show | grep inet'
alias ports='netstat -tuln'
alias ping='ping -c 4'

# =============================================================================
# FILE OPERATIONS ALIASES
# =============================================================================
alias cp='cp -iv'
alias mv='mv -iv'
alias rm='rm -iv'
alias mkdir='mkdir -pv'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# =============================================================================
# EDITOR ALIASES
# =============================================================================
alias vi='vim'
alias nano='vim'
alias edit='$EDITOR'

# =============================================================================
# PROCESS MANAGEMENT ALIASES
# =============================================================================
alias ps='ps aux'
alias psg='ps aux | grep'
alias killall='killall -v'
alias top='htop'

# =============================================================================
# SECURITY ALIASES
# =============================================================================
alias bwlogin='bw login'
alias bwlogout='bw logout'
alias bwunlock='bw unlock'
alias bwlist='bw list items'

# =============================================================================
# ENVIRONMENT MANAGEMENT ALIASES
# =============================================================================
alias envload='source .env'
alias envshow='env | grep -E "^[A-Z_]" | sort'
alias envedit='$EDITOR .env'

# =============================================================================
# DEVELOPMENT ALIASES
# =============================================================================
alias py='python3'
alias pip='pip3'
alias node='nodejs'
alias npm='npm'
alias yarn='yarn'
alias serve='python3 -m http.server 8000'

# =============================================================================
# MONITORING ALIASES
# =============================================================================
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias uptime='uptime -p'

# =============================================================================
# QUICK ACCESS ALIASES
# =============================================================================
alias zshrc='$EDITOR ~/.zshrc'
alias zshalias='$EDITOR ~/zsh_aliases.d/aliases.zsh'
alias zshfunc='$EDITOR ~/.zsh_functions.d/'
alias reload='source ~/.zshrc'

# =============================================================================
# FUN ALIASES
# =============================================================================
alias weather='curl wttr.in'
alias starwars='telnet towel.blinkenlights.nl'
alias matrix='cmatrix'

# =============================================================================
# HOSTNAME-SPECIFIC ALIASES
# =============================================================================
if [[ $(hostname) == "cbwhpz" ]]; then
    # Homelab server specific aliases
    alias k='kubectl'
    alias tf='terraform'
    alias ansible-playbook='ansible-playbook -i inventory'
    alias backup='rsync -av --progress'
    alias monitor='glances'
elif [[ $(hostname) == "cbwdellr720" ]]; then
    # Dell workstation specific aliases
    alias code='code-insiders'
    alias docker-dev='docker-compose -f docker-compose.dev.yml'
elif [[ $(hostname) == "fedora" ]]; then
    # Current workstation specific aliases
    alias bwefb='env_from_bw'
    alias bws='bw_search'
    alias bwg='bw_get'
fi

echo "🚀 Aliases loaded for $(hostname)"
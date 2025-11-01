# Filesystem Structure and Naming Convention

## Purpose
This document defines the standard filesystem structure and naming conventions for organizing dotfiles, configurations, and scripts across all environments.

## Table of Contents
1. [Directory Structure Standards](#directory-structure-standards)
2. [File Naming Conventions](#file-naming-conventions)
3. [Installation Locations](#installation-locations)
4. [Symlink Strategy](#symlink-strategy)
5. [Environment-Specific Configurations](#environment-specific-configurations)

---

## Directory Structure Standards

### Repository Structure

```
Knowledge-Base/
├── dotfiles/                      # Configuration files and functions
│   ├── shells/                    # Shell configurations
│   │   ├── bash/
│   │   │   ├── bash.bashrc        # Main bash config
│   │   │   ├── bash_functions_*.sh
│   │   │   ├── bash_aliases_*.sh
│   │   │   └── bash_secrets.template
│   │   └── zsh/
│   │       ├── zsh.zshrc
│   │       ├── zsh_functions_*.sh
│   │       └── zsh_aliases_*.sh
│   │
│   ├── development/               # Development tools
│   │   ├── docker/
│   │   ├── git/
│   │   ├── kubernetes/
│   │   └── terraform/
│   │
│   ├── cloud/                     # Cloud providers
│   │   ├── aws/
│   │   ├── azure/
│   │   ├── gcp/
│   │   └── digitalocean/
│   │
│   ├── languages/                 # Programming languages
│   │   ├── python/
│   │   ├── nodejs/
│   │   ├── go/
│   │   └── rust/
│   │
│   └── templates/                 # Reusable templates
│       ├── functions/
│       ├── aliases/
│       └── snippets/
│
├── scripts/                       # Utility scripts
│   ├── utilities/
│   ├── deployment/
│   └── monitoring/
│
├── documentation/                 # Documentation
│   ├── examples/
│   └── how-to-guides/
│
└── projects/                      # Project-specific configs
```

### Home Directory Structure

```
~/
├── .config/                       # XDG config directory
│   ├── bash/
│   ├── zsh/
│   ├── git/
│   └── <tool>/
│
├── .local/                        # User-local files
│   ├── bin/                       # User scripts
│   ├── share/                     # Data files
│   └── state/                     # State files
│
├── .bashrc                        # Bash configuration
├── .zshrc                         # Zsh configuration
├── .bash_profile                  # Bash login config
├── .bash_functions_*              # Bash functions (symlinked)
├── .bash_aliases_*                # Bash aliases (symlinked)
├── .bash_secrets                  # Bash secrets (local, not in repo)
│
├── .gitconfig                     # Git configuration
├── .vimrc                         # Vim configuration
└── .tmux.conf                     # Tmux configuration
```

---

## File Naming Conventions

### Configuration Files

#### Format
```
<tool>.<config_type>
```

#### Examples
```
bash.bashrc          # Bash runtime config
zsh.zshrc            # Zsh runtime config
bash.bash_profile    # Bash login config
git.gitconfig        # Git configuration
vim.vimrc            # Vim configuration
tmux.conf            # Tmux configuration
ssh.config           # SSH configuration
```

#### When to Use
- Main configuration files for tools/applications
- Files that are typically stored in home directory
- Allows easy identification in repository

### Function Files

#### Format
```
<shell>_functions_<category>.sh
```

#### Examples
```
bash_functions_docker.sh
bash_functions_git.sh
bash_functions_kubernetes.sh
bash_functions_aws.sh
bash_functions_system.sh
zsh_functions_docker.sh
zsh_functions_git.sh
```

#### Structure Within File
```bash
#!/bin/bash
# <Category> Functions
# Description: Brief description
# Usage: Source this in .bashrc/.zshrc
# Last Updated: YYYY-MM-DD

# Function: function_name
# Description: What it does
# Usage: function_name <arg1> <arg2>
# Arguments:
#   $1 - Description
# Returns: What it returns
# Example: function_name value1 value2
function_name() {
    # Implementation
}
```

### Alias Files

#### Format
```
<shell>_aliases_<category>.sh
```

#### Examples
```
bash_aliases_docker.sh
bash_aliases_git.sh
bash_aliases_kubernetes.sh
bash_aliases_system.sh
zsh_aliases_docker.sh
```

#### Structure Within File
```bash
#!/bin/bash
# <Category> Aliases
# Last Updated: YYYY-MM-DD

# Docker containers
alias dps='docker ps'
alias dpsa='docker ps -a'

# Git operations
alias gs='git status'
alias ga='git add'
```

### Secret Files

#### Format
```
<shell>_secrets
<category>_secrets
<tool>_credentials
```

#### Examples
```
bash_secrets             # General bash secrets
zsh_secrets              # General zsh secrets
aws_credentials          # AWS credentials
gcp_credentials          # GCP credentials
docker_secrets           # Docker secrets
```

#### Template Format
```
<filename>.template
<filename>.example
```

#### Examples
```
bash_secrets.template
aws_credentials.example
docker_secrets.template
```

### Script Files

#### Format
```
<category>_<action>_<object>.sh
```

#### Examples
```
docker_cleanup_images.sh
git_backup_repos.sh
aws_start_instances.sh
system_backup_configs.sh
```

---

## Installation Locations

### XDG Base Directory Specification

#### Config Files
```
~/.config/<tool>/config
```

**Examples:**
```
~/.config/git/config
~/.config/nvim/init.vim
~/.config/alacritty/alacritty.yml
```

#### Data Files
```
~/.local/share/<tool>/
```

**Examples:**
```
~/.local/share/zsh/history
~/.local/share/applications/
```

#### Cache Files
```
~/.cache/<tool>/
```

**Examples:**
```
~/.cache/pip/
~/.cache/npm/
```

#### State Files
```
~/.local/state/<tool>/
```

**Examples:**
```
~/.local/state/nvim/
```

### Legacy Locations

When XDG is not supported:

```
~/.<tool>rc              # Configuration
~/.<tool>_history        # History
~/.<tool>/               # Tool directory
```

**Examples:**
```
~/.bashrc
~/.vimrc
~/.tmux.conf
~/.ssh/config
```

### System-Wide Locations

```
/etc/<tool>/             # System configs
/usr/local/bin/          # User-installed binaries
/usr/local/etc/          # User-installed configs
/opt/<tool>/             # Optional software
```

---

## Symlink Strategy

### Why Symlinks?

- Keep all dotfiles in version-controlled repository
- Files live in standard locations expected by tools
- Easy updates via git pull
- One source of truth

### Creating Symlinks

#### Basic Symlink
```bash
ln -sf ~/Knowledge-Base/dotfiles/shells/bash/bash.bashrc ~/.bashrc
```

#### Bulk Symlinks (Bash Example)
```bash
# Configuration file
ln -sf ~/Knowledge-Base/dotfiles/shells/bash/bash.bashrc ~/.bashrc

# Function files
ln -sf ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh ~/.bash_functions_docker
ln -sf ~/Knowledge-Base/dotfiles/development/git/bash_functions_git.sh ~/.bash_functions_git
ln -sf ~/Knowledge-Base/dotfiles/development/kubernetes/bash_functions_kubernetes.sh ~/.bash_functions_kubernetes

# Alias files
ln -sf ~/Knowledge-Base/dotfiles/development/docker/bash_aliases_docker.sh ~/.bash_aliases_docker
ln -sf ~/Knowledge-Base/dotfiles/development/git/bash_aliases_git.sh ~/.bash_aliases_git

# Add to .bashrc
echo 'source ~/.bash_functions_docker' >> ~/.bashrc
echo 'source ~/.bash_functions_git' >> ~/.bashrc
echo 'source ~/.bash_aliases_docker' >> ~/.bashrc
echo 'source ~/.bash_aliases_git' >> ~/.bashrc
```

### Installation Script Template

```bash
#!/bin/bash
# Dotfiles Installation Script

DOTFILES_DIR="$HOME/Knowledge-Base/dotfiles"

# Backup existing files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]] && [[ ! -L "$file" ]]; then
        cp "$file" "${file}.backup.$(date +%Y%m%d_%H%M%S)"
        echo "Backed up: $file"
    fi
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    backup_file "$target"
    ln -sf "$source" "$target"
    echo "Linked: $target -> $source"
}

# Bash setup
if [[ -n "$BASH_VERSION" ]]; then
    create_symlink "$DOTFILES_DIR/shells/bash/bash.bashrc" "$HOME/.bashrc"
    create_symlink "$DOTFILES_DIR/development/docker/bash_functions_docker.sh" "$HOME/.bash_functions_docker"
    create_symlink "$DOTFILES_DIR/development/git/bash_functions_git.sh" "$HOME/.bash_functions_git"
fi

# Zsh setup
if [[ -n "$ZSH_VERSION" ]]; then
    create_symlink "$DOTFILES_DIR/shells/zsh/zsh.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/development/docker/zsh_functions_docker.sh" "$HOME/.zsh_functions_docker"
    create_symlink "$DOTFILES_DIR/development/git/zsh_functions_git.sh" "$HOME/.zsh_functions_git"
fi

echo "Installation complete!"
```

---

## Environment-Specific Configurations

### Structure

```
~/
├── .bash_secrets_dev          # Development secrets
├── .bash_secrets_staging      # Staging secrets
├── .bash_secrets_prod         # Production secrets
└── .bashrc                    # Main config (sources appropriate secrets)
```

### Loading Logic

Add to `.bashrc` or `.zshrc`:

```bash
# Load environment-specific secrets
if [[ -n "$APP_ENV" ]]; then
    ENV_SECRETS="$HOME/.bash_secrets_${APP_ENV}"
    if [[ -f "$ENV_SECRETS" ]]; then
        source "$ENV_SECRETS"
    fi
elif [[ -f "$HOME/.bash_secrets" ]]; then
    # Default to local secrets
    source "$HOME/.bash_secrets"
fi
```

### Environment File Template

```bash
# .bash_secrets_prod.template
# Copy to .bash_secrets_prod and fill in values

# AWS Configuration
export AWS_PROFILE="production"
export AWS_REGION="us-east-1"
export AWS_DEFAULT_REGION="us-east-1"

# Database
export DB_HOST="prod-db.example.com"
export DB_PORT="5432"
export DB_NAME="myapp_prod"
export DB_USER="prod_user"
export DB_PASSWORD="changeme"

# Application
export APP_ENV="production"
export API_KEY="changeme"
export SECRET_KEY="changeme"
```

---

## Path Organization

### Script Locations

```
~/Knowledge-Base/
├── scripts/
│   ├── utilities/         # General utilities
│   ├── deployment/        # Deployment scripts
│   ├── monitoring/        # Monitoring scripts
│   └── backup/           # Backup scripts
```

### Adding to PATH

```bash
# Add to .bashrc or .zshrc
export PATH="$HOME/Knowledge-Base/scripts/utilities:$PATH"
export PATH="$HOME/.local/bin:$PATH"
```

---

## Backup Strategy

### What to Backup

**Include:**
- Configuration files (bashrc, zshrc, etc.)
- Function and alias files
- Custom scripts
- Template files

**Exclude:**
- Secret files (back up separately, encrypted)
- Cache files
- Temporary files
- Build artifacts

### Backup Locations

```
~/backups/
├── dotfiles_YYYYMMDD_HHMMSS.tar.gz
├── scripts_YYYYMMDD_HHMMSS.tar.gz
└── secrets_YYYYMMDD_HHMMSS.tar.gz.gpg  # Encrypted
```

---

## Cross-Platform Considerations

### Linux
```
~/.config/<tool>/
~/.local/share/<tool>/
~/.bashrc
~/.zshrc
```

### macOS
```
~/Library/Application Support/<Tool>/
~/.config/<tool>/          # Also supported
~/.bashrc
~/.zshrc
```

### Windows (WSL)
```
/mnt/c/Users/<username>/
~/.bashrc                  # WSL bash
~/.zshrc                   # WSL zsh
%USERPROFILE%\             # Windows home
```

### Windows (PowerShell)
```
$HOME\Documents\PowerShell\
$HOME\.config\powershell\
%APPDATA%\                 # Application data
```

---

## Best Practices

### 1. Consistent Naming
- Use underscores for multi-word names
- Include category/purpose in filename
- Use appropriate file extensions

### 2. Logical Organization
- Group by function/category
- Keep related files together
- Use README in each directory

### 3. Symlink Management
- Always use absolute paths
- Check existing files before linking
- Backup before replacing

### 4. Security
- Never commit secrets
- Use templates for secret files
- Set appropriate permissions (600 for secrets)

### 5. Documentation
- Document purpose of each directory
- Include usage examples
- Maintain README files

### 6. Version Control
- Commit frequently
- Use meaningful commit messages
- Track changes with git

---

## Quick Reference

### Create New Function File
```bash
# Template location
cp ~/Knowledge-Base/dotfiles/templates/functions/template.sh \
   ~/Knowledge-Base/dotfiles/development/tool/bash_functions_tool.sh

# Edit and customize
vim ~/Knowledge-Base/dotfiles/development/tool/bash_functions_tool.sh

# Symlink
ln -sf ~/Knowledge-Base/dotfiles/development/tool/bash_functions_tool.sh \
       ~/.bash_functions_tool

# Source in .bashrc
echo 'source ~/.bash_functions_tool' >> ~/.bashrc
source ~/.bashrc
```

### Create Environment Secrets
```bash
# Copy template
cp ~/Knowledge-Base/dotfiles/shells/bash/bash_secrets.template \
   ~/.bash_secrets_prod

# Set permissions
chmod 600 ~/.bash_secrets_prod

# Edit
vim ~/.bash_secrets_prod

# Load in .bashrc (add to file)
if [[ "$APP_ENV" == "production" ]]; then
    source ~/.bash_secrets_prod
fi
```

---

## Maintenance

### Regular Tasks

1. **Weekly**
   - Review and update functions
   - Check for unused aliases
   - Test in clean environment

2. **Monthly**
   - Update documentation
   - Review naming conventions
   - Clean up old backups

3. **Quarterly**
   - Major organization review
   - Update templates
   - Consolidate duplicates

---

**Last Updated:** 2025-11-01  
**Version:** 1.0.0

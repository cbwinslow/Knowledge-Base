# Dotfiles Management Rules

## Purpose
This document defines the standards, conventions, and best practices for managing dotfiles across all development and DevOps environments.

## Table of Contents
1. [Naming Conventions](#naming-conventions)
2. [File Organization](#file-organization)
3. [Function Standards](#function-standards)
4. [Security Guidelines](#security-guidelines)
5. [Documentation Requirements](#documentation-requirements)
6. [Version Control](#version-control)

---

## Naming Conventions

### Directory Names
- Use lowercase with hyphens for multi-word names
- Group by tool/technology category
- Examples: `cloud-providers`, `container-orchestration`, `version-control`

### File Names

#### Configuration Files
**Format:** `<tool>.<config_type>`
- Examples:
  - `bash.bashrc`
  - `zsh.zshrc`
  - `git.gitconfig`
  - `vim.vimrc`
  - `tmux.conf`

#### Function Files
**Format:** `<shell>_functions_<category>.sh`
- Examples:
  - `bash_functions_docker.sh`
  - `zsh_functions_kubernetes.sh`
  - `bash_functions_aws.sh`

#### Alias Files
**Format:** `<shell>_aliases_<category>.sh`
- Examples:
  - `bash_aliases_git.sh`
  - `zsh_aliases_system.sh`
  - `bash_aliases_network.sh`

#### Template Files
**Format:** `<filename>.template` or `<filename>.example`
- Use `.template` for files meant to be copied and customized
- Use `.example` for demonstration/reference files
- Examples:
  - `bash_secrets.template`
  - `aws_credentials.example`

### Function Names

#### Standard Format
**Pattern:** `<category>_<action>_<object>`

#### Category Prefixes
- `sys_` - System operations (file system, processes, users)
- `net_` - Network operations (connectivity, ports, DNS)
- `dev_` - Development tools (build, test, debug)
- `git_` - Git version control operations
- `docker_` - Docker container operations
- `k8s_` - Kubernetes orchestration
- `cloud_` - Cloud provider operations (general)
- `aws_` - Amazon Web Services specific
- `azure_` - Microsoft Azure specific
- `gcp_` - Google Cloud Platform specific
- `db_` - Database operations (general)
- `pg_` - PostgreSQL specific
- `mysql_` - MySQL specific
- `mongo_` - MongoDB specific
- `redis_` - Redis specific
- `tf_` - Terraform operations
- `kb_` - Knowledge base operations
- `log_` - Logging operations
- `mon_` - Monitoring operations

#### Action Verbs (Common)
- `list` - Display items
- `get` - Retrieve single item
- `create` - Create new item
- `delete` - Remove item
- `update` - Modify existing item
- `start` - Start service/container
- `stop` - Stop service/container
- `restart` - Restart service/container
- `status` - Check status
- `info` - Display information
- `search` - Search for items
- `backup` - Create backup
- `restore` - Restore from backup
- `deploy` - Deploy application
- `test` - Run tests
- `build` - Build artifact

#### Examples
```bash
# System operations
sys_list_processes
sys_kill_port
sys_backup_file
sys_get_disk_usage

# Git operations
git_create_branch
git_delete_merged_branches
git_list_recent_commits
git_update_submodules

# Docker operations
docker_start_container
docker_stop_all
docker_list_running
docker_cleanup_images

# Kubernetes operations
k8s_get_pods
k8s_delete_pod
k8s_list_services
k8s_restart_deployment

# AWS operations
aws_list_instances
aws_start_instance
aws_stop_instance
aws_get_bucket_size

# Database operations
db_backup_database
db_restore_database
pg_list_databases
mysql_create_user
```

### Alias Names

#### Format
**Pattern:** `<short_command>` or `<category><action>`

#### Guidelines
- Keep aliases short (2-6 characters preferred)
- Use common abbreviations
- Group related aliases with common prefix
- Document each alias inline

#### Examples
```bash
# Short commands
alias ll='ls -lah'
alias gs='git status'
alias dc='docker-compose'
alias k='kubectl'

# Categorized aliases
alias dps='docker ps'
alias dimg='docker images'
alias dcup='docker-compose up -d'
alias dcdown='docker-compose down'

alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kdp='kubectl describe pod'
```

---

## File Organization

### Directory Structure

```
dotfiles/
├── shells/              # Shell-specific configurations
│   ├── bash/
│   ├── zsh/
│   ├── fish/
│   └── powershell/
├── terminals/           # Terminal emulator configs
│   ├── alacritty/
│   ├── kitty/
│   ├── tmux/
│   └── wezterm/
├── editors/             # Text editor configurations
│   ├── vim/
│   ├── neovim/
│   ├── emacs/
│   └── vscode/
├── development/         # Development tools
│   ├── git/
│   ├── docker/
│   ├── kubernetes/
│   └── terraform/
├── languages/           # Programming language configs
│   ├── python/
│   ├── nodejs/
│   ├── go/
│   ├── rust/
│   └── java/
├── cloud/              # Cloud provider CLIs
│   ├── aws/
│   ├── azure/
│   ├── gcp/
│   └── digitalocean/
├── databases/          # Database client configs
│   ├── postgresql/
│   ├── mysql/
│   ├── mongodb/
│   └── redis/
├── monitoring/         # Monitoring tool configs
│   ├── prometheus/
│   ├── grafana/
│   └── elk/
└── templates/         # Reusable templates
    ├── functions/
    ├── aliases/
    └── snippets/
```

### Required Files Per Category

Each category directory should contain:

1. **README.md** - Documentation for that category
2. **<tool>.template** - Template configuration file
3. **<shell>_functions_<category>.sh** - Function definitions
4. **<shell>_aliases_<category>.sh** - Alias definitions
5. **.gitkeep** - Ensure directory is tracked if empty

---

## Function Standards

### Function Template

```bash
#!/bin/bash
# Function: <function_name>
# Description: <clear description of what function does>
# Usage: <function_name> <arg1> <arg2>
# Arguments:
#   $1 - <description of first argument>
#   $2 - <description of second argument>
# Returns: <what the function returns>
# Example: <function_name> example_value1 example_value2

<function_name>() {
    # Validate arguments
    if [[ $# -lt <required_args> ]]; then
        echo "Error: Insufficient arguments"
        echo "Usage: <function_name> <arg1> <arg2>"
        return 1
    fi
    
    # Assign arguments to meaningful variable names
    local arg1="$1"
    local arg2="$2"
    
    # Function logic
    # ...
    
    # Return appropriate exit code
    return 0
}
```

### Function Requirements

1. **Documentation Header**
   - Must include: function name, description, usage, arguments, returns, example
   - Should be clear enough for any team member to understand

2. **Argument Validation**
   - Validate number of arguments
   - Check for required arguments
   - Provide clear error messages

3. **Error Handling**
   - Check command exit codes
   - Provide meaningful error messages
   - Return appropriate exit codes (0 for success, non-zero for failure)

4. **Variable Naming**
   - Use descriptive names
   - Use local variables within functions
   - Follow shell script naming conventions (lowercase with underscores)

5. **Output**
   - Use consistent formatting
   - Provide feedback for long-running operations
   - Use colors for important messages (optional)

---

## Security Guidelines

### Secrets Management

1. **Never Commit Secrets**
   - No API keys, passwords, tokens, or credentials
   - Use `.gitignore` to exclude secret files
   - Use template files with `.example` or `.template` suffix

2. **Secret Files**
   - Name pattern: `*_secrets` or `*.credentials`
   - Must be in `.gitignore`
   - Provide `.example` version with dummy values

3. **Environment Variables**
   - Use environment variables for secrets
   - Document required variables in README
   - Provide example in template files

4. **Secret Scanning**
   - Repository has automated secret scanning enabled
   - All commits are scanned before merge
   - False positives should be documented

### File Permissions

1. **Configuration Files**
   - Should be readable: `644` (rw-r--r--)

2. **Secret Files**
   - Should be private: `600` (rw-------)
   - Never world-readable

3. **Script Files**
   - Should be executable: `755` (rwxr-xr-x)

---

## Documentation Requirements

### README.md (Per Category)

Each category directory must have a README.md with:

1. **Purpose** - What this category contains
2. **Installation** - How to install/use these configs
3. **Configuration** - How to customize for your needs
4. **Prerequisites** - Required software/dependencies
5. **Usage Examples** - Common use cases
6. **Troubleshooting** - Common issues and solutions

### Inline Documentation

1. **Comment Each Function**
   - Purpose, arguments, return values
   - Usage example

2. **Comment Complex Logic**
   - Explain why, not just what
   - Link to relevant documentation if applicable

3. **Document Dependencies**
   - External tools required
   - Minimum versions needed

---

## Version Control

### Commit Messages

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation changes
- `style` - Formatting changes
- `refactor` - Code restructuring
- `test` - Test additions/changes
- `chore` - Maintenance tasks

**Examples:**
```
feat(bash): add docker cleanup functions
fix(zsh): correct git branch display
docs(shells): update bash configuration guide
```

### Branch Naming

**Pattern:** `<type>/<description>`

**Examples:**
- `feature/add-kubernetes-functions`
- `fix/correct-aws-credentials-path`
- `docs/update-shell-readme`

### Pull Request Requirements

1. **Description** - Clear explanation of changes
2. **Testing** - How changes were tested
3. **Documentation** - Updated docs for new features
4. **Breaking Changes** - Clearly marked if applicable

---

## File System Standards

### Standard Locations

#### Linux/macOS
```
~/.config/<tool>/          # XDG config directory
~/.local/share/<tool>/     # XDG data directory
~/.<tool>rc                # Legacy config file
```

#### Windows
```
%APPDATA%\<tool>\          # Application data
%USERPROFILE%\.<tool>rc    # Config file
```

### Symlink Strategy

Use symlinks to maintain dotfiles in repository while having them in standard locations:

```bash
# Example for bash
ln -sf ~/Knowledge-Base/dotfiles/shells/bash/bash.bashrc ~/.bashrc
ln -sf ~/Knowledge-Base/dotfiles/shells/bash/bash_functions_docker.sh ~/.bash_functions_docker
```

### Installation Script

Each category should provide an `install.sh` script that:
1. Creates necessary directories
2. Creates symlinks to configs
3. Sets proper permissions
4. Validates installation

---

## Best Practices

### 1. Modularity
- Keep functions small and focused
- One responsibility per function
- Reusable across different contexts

### 2. Portability
- Check for command availability before use
- Handle different OS/distributions
- Provide fallbacks when possible

### 3. Performance
- Avoid unnecessary subshells
- Use built-in commands when possible
- Cache expensive operations

### 4. Maintainability
- Clear, consistent naming
- Comprehensive documentation
- Regular updates and testing

### 5. User Experience
- Provide helpful error messages
- Include usage examples
- Support common use cases

---

## Compliance Checklist

Before committing:

- [ ] Function names follow naming convention
- [ ] Files named according to standards
- [ ] Documentation headers complete
- [ ] No secrets in code
- [ ] Security guidelines followed
- [ ] README updated if needed
- [ ] Examples provided
- [ ] Tested in target environment
- [ ] Commit message follows format
- [ ] Code reviewed by peer (for significant changes)

---

## Enforcement

- Automated checks via GitHub Actions
- Secret scanning on all commits
- Linting for shell scripts
- Documentation validation
- Naming convention validation

---

## Resources

- [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [Git Best Practices](https://git-scm.com/book/en/v2/Distributed-Git-Contributing-to-a-Project)

---

## Updates

This document should be reviewed and updated quarterly or when significant changes are needed.

Last Updated: 2025-11-01
Version: 1.0.0

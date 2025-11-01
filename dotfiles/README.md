# Dotfiles Management System

A comprehensive, organized collection of configuration files, shell functions, and aliases for consistent development and DevOps environments across all systems.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Naming Conventions](#naming-conventions)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [Resources](#resources)

---

## Overview

This dotfiles repository provides:

- **Organized Configuration** - Structured by tool, function, and technology
- **Standardized Naming** - Consistent, predictable file and function names
- **Template System** - Ready-to-use templates for common configurations
- **Security First** - Built-in secret management and scanning
- **Cross-Platform** - Support for Linux, macOS, and Windows
- **Modular Design** - Load only what you need

### Key Features

✅ **Comprehensive Coverage** - Shells, editors, cloud tools, databases, and more  
✅ **Smart Organization** - Categorized by functional groups  
✅ **Best Practices** - Following industry standards and conventions  
✅ **Well Documented** - Every category includes detailed README  
✅ **Production Ready** - Tested configurations and functions  
✅ **DevOps Focused** - Optimized for cloud and container workflows  

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/cbwinslow/Knowledge-Base.git
cd Knowledge-Base/dotfiles
```

### 2. Install Shell Configurations

```bash
# Bash
ln -sf $(pwd)/shells/bash/bash.bashrc ~/.bashrc
source ~/.bashrc

# Zsh
ln -sf $(pwd)/shells/zsh/zsh.zshrc ~/.zshrc
source ~/.zshrc
```

### 3. Load Functions and Aliases

```bash
# Add to your .bashrc or .zshrc
source ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh
source ~/Knowledge-Base/dotfiles/development/git/bash_functions_git.sh
```

### 4. Customize for Your Environment

```bash
# Copy template and customize
cp shells/bash/bash_secrets.template ~/.bash_secrets
chmod 600 ~/.bash_secrets
# Edit with your values
nano ~/.bash_secrets
```

---

## Directory Structure

```
dotfiles/
├── shells/                    # Shell configurations
│   ├── bash/                  # Bash config, functions, aliases
│   ├── zsh/                   # Zsh config, functions, aliases
│   ├── fish/                  # Fish shell configurations
│   └── powershell/            # PowerShell configurations
│
├── terminals/                 # Terminal emulator configs
│   ├── alacritty/            # Alacritty terminal
│   ├── kitty/                # Kitty terminal
│   ├── tmux/                 # Tmux multiplexer
│   └── wezterm/              # WezTerm terminal
│
├── editors/                   # Text editor configurations
│   ├── vim/                  # Vim/Vi configurations
│   ├── neovim/               # Neovim configurations
│   ├── emacs/                # Emacs configurations
│   └── vscode/               # VS Code settings
│
├── development/              # Development tools
│   ├── git/                  # Git configuration and functions
│   ├── docker/               # Docker functions and aliases
│   ├── kubernetes/           # Kubernetes (kubectl) configs
│   └── terraform/            # Terraform configurations
│
├── languages/                # Programming language configs
│   ├── python/               # Python (pip, virtualenv, etc.)
│   ├── nodejs/               # Node.js and npm configs
│   ├── go/                   # Go language settings
│   ├── rust/                 # Rust and Cargo configs
│   └── java/                 # Java and Maven configs
│
├── cloud/                    # Cloud provider CLIs
│   ├── aws/                  # AWS CLI configurations
│   ├── azure/                # Azure CLI configurations
│   ├── gcp/                  # Google Cloud SDK configs
│   └── digitalocean/         # DigitalOcean CLI configs
│
├── databases/                # Database client configs
│   ├── postgresql/           # PostgreSQL client (psql)
│   ├── mysql/                # MySQL client
│   ├── mongodb/              # MongoDB client (mongosh)
│   └── redis/                # Redis CLI (redis-cli)
│
├── monitoring/               # Monitoring tool configs
│   ├── prometheus/           # Prometheus configs
│   ├── grafana/              # Grafana configurations
│   └── elk/                  # Elasticsearch, Logstash, Kibana
│
├── templates/                # Reusable templates
│   ├── functions/            # Function templates
│   ├── aliases/              # Alias templates
│   └── snippets/             # Code snippets
│
├── README.md                 # This file
├── RULES.md                  # Naming conventions and standards
└── ORGANIZATION_PLAN.md      # Detailed organization plan
```

---

## Naming Conventions

### Function Names

**Format:** `<category>_<action>_<object>`

**Examples:**
```bash
docker_start_container    # Docker: start a container
git_create_branch         # Git: create new branch
aws_list_instances        # AWS: list EC2 instances
k8s_get_pods             # Kubernetes: get pods
sys_backup_file          # System: backup a file
```

### File Names

**Configuration Files:** `<tool>.<config_type>`
```
bash.bashrc
zsh.zshrc
git.gitconfig
vim.vimrc
```

**Function Files:** `<shell>_functions_<category>.sh`
```
bash_functions_docker.sh
zsh_functions_git.sh
bash_functions_aws.sh
```

**Alias Files:** `<shell>_aliases_<category>.sh`
```
bash_aliases_kubernetes.sh
zsh_aliases_system.sh
```

### Category Prefixes

| Prefix | Category | Examples |
|--------|----------|----------|
| `sys_` | System operations | `sys_list_processes`, `sys_kill_port` |
| `net_` | Network operations | `net_test_connection`, `net_scan_ports` |
| `git_` | Git operations | `git_create_branch`, `git_cleanup` |
| `docker_` | Docker operations | `docker_cleanup`, `docker_logs` |
| `k8s_` | Kubernetes | `k8s_get_pods`, `k8s_restart_deployment` |
| `aws_` | AWS operations | `aws_list_instances`, `aws_get_logs` |
| `azure_` | Azure operations | `azure_list_vms`, `azure_get_logs` |
| `gcp_` | Google Cloud | `gcp_list_instances`, `gcp_ssh` |
| `db_` | Database (general) | `db_backup`, `db_restore` |
| `pg_` | PostgreSQL | `pg_list_databases`, `pg_create_user` |
| `tf_` | Terraform | `tf_plan`, `tf_apply` |
| `kb_` | Knowledge Base | `kb_add_file`, `kb_search` |

See [RULES.md](RULES.md) for complete naming standards and conventions.

---

## Installation

### Prerequisites

- Git
- Bash or Zsh shell
- (Optional) GNU Make for automated installation

### Full Installation

```bash
# Clone repository
git clone https://github.com/cbwinslow/Knowledge-Base.git
cd Knowledge-Base/dotfiles

# Run installation script (coming soon)
./install.sh
```

### Manual Installation

#### Bash Setup

```bash
# Backup existing configs
cp ~/.bashrc ~/.bashrc.backup

# Link configuration file
ln -sf $(pwd)/shells/bash/bash.bashrc ~/.bashrc

# Link function files
ln -sf $(pwd)/development/git/bash_functions_git.sh ~/.bash_functions_git
ln -sf $(pwd)/development/docker/bash_functions_docker.sh ~/.bash_functions_docker

# Source in your .bashrc
echo 'source ~/.bash_functions_git' >> ~/.bashrc
echo 'source ~/.bash_functions_docker' >> ~/.bashrc

# Reload
source ~/.bashrc
```

#### Zsh Setup

```bash
# Backup existing configs
cp ~/.zshrc ~/.zshrc.backup

# Link configuration file
ln -sf $(pwd)/shells/zsh/zsh.zshrc ~/.zshrc

# Link function files
ln -sf $(pwd)/development/git/zsh_functions_git.sh ~/.zsh_functions_git
ln -sf $(pwd)/development/docker/zsh_functions_docker.sh ~/.zsh_functions_docker

# Source in your .zshrc
echo 'source ~/.zsh_functions_git' >> ~/.zshrc
echo 'source ~/.zsh_functions_docker' >> ~/.zshrc

# Reload
source ~/.zshrc
```

### Selective Installation

Load only what you need:

```bash
# In your .bashrc or .zshrc
# Docker functions only
source ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh

# Kubernetes functions only
source ~/Knowledge-Base/dotfiles/development/kubernetes/bash_functions_kubernetes.sh

# AWS functions only
source ~/Knowledge-Base/dotfiles/cloud/aws/bash_functions_aws.sh
```

---

## Usage

### Working with Shells

#### Bash

```bash
# View available functions
grep "^[a-z_]*() {" shells/bash/bash_functions_*.sh

# Use template for new functions
cp templates/functions/bash_function.template my_new_function.sh
```

#### Zsh

```bash
# View available functions
grep "^[a-z_]*() {" shells/zsh/zsh_functions_*.sh

# Use KB functions
kb_add file.txt documentation    # Add file to knowledge base
kb_search "docker"                # Search knowledge base
```

### Development Tools

#### Git Functions

```bash
git_create_branch feature/new-feature
git_list_recent_commits 10
git_cleanup_merged_branches
```

#### Docker Functions

```bash
docker_start_container myapp
docker_list_running
docker_cleanup_images
docker_logs myapp
```

#### Kubernetes Functions

```bash
k8s_get_pods
k8s_describe_pod mypod-123
k8s_list_services
k8s_restart_deployment myapp
```

### Cloud Providers

#### AWS Functions

```bash
aws_list_instances
aws_start_instance i-1234567890abcdef0
aws_get_logs myloggroup
```

#### Azure Functions

```bash
azure_list_vms
azure_start_vm myvm
azure_get_logs myresourcegroup
```

#### GCP Functions

```bash
gcp_list_instances
gcp_ssh myinstance
gcp_get_logs myproject
```

### Database Functions

#### PostgreSQL

```bash
pg_list_databases
pg_create_database mydb
pg_backup mydb backup.sql
```

#### MySQL

```bash
mysql_list_databases
mysql_create_user myuser
mysql_backup mydb
```

---

## Configuration Management

### Using Templates

1. **Find Template**
   ```bash
   ls -la */*/*.template
   ```

2. **Copy and Customize**
   ```bash
   cp shells/bash/bash_secrets.template ~/.bash_secrets
   chmod 600 ~/.bash_secrets
   nano ~/.bash_secrets
   ```

3. **Source in Shell**
   ```bash
   echo 'source ~/.bash_secrets' >> ~/.bashrc
   source ~/.bashrc
   ```

### Secrets Management

**Never commit secrets!** Follow these guidelines:

1. Use `.template` or `.example` files as reference
2. Store actual secrets in files matching `*_secrets` pattern
3. These are automatically gitignored
4. Set appropriate permissions (600 for secret files)

```bash
# Create secret file from template
cp shells/bash/bash_secrets.template ~/.bash_secrets
chmod 600 ~/.bash_secrets

# Edit with your actual values
nano ~/.bash_secrets

# Source in your shell config
echo 'source ~/.bash_secrets' >> ~/.bashrc
```

### Environment-Specific Configs

Create environment-specific configurations:

```bash
# Development
~/.bash_secrets_dev

# Staging  
~/.bash_secrets_staging

# Production
~/.bash_secrets_prod

# Load based on environment
if [[ "$ENVIRONMENT" == "production" ]]; then
    source ~/.bash_secrets_prod
elif [[ "$ENVIRONMENT" == "staging" ]]; then
    source ~/.bash_secrets_staging
else
    source ~/.bash_secrets_dev
fi
```

---

## GitHub Actions Integration

### Save Dotfiles via Workflow

```bash
# Save bash function
gh workflow run save-dotfile.yml \
  -f shell="bash" \
  -f file_type="bash_functions_docker" \
  -f content="$(cat my_docker_functions.sh)"

# Save zsh aliases
gh workflow run save-dotfile.yml \
  -f shell="zsh" \
  -f file_type="zsh_aliases_git" \
  -f content="$(cat my_git_aliases.sh)"
```

---

## Contributing

### Before Contributing

1. Read [RULES.md](RULES.md) for conventions
2. Follow naming standards
3. Include documentation
4. Test your changes
5. No secrets in commits

### Contribution Workflow

```bash
# Create feature branch
git checkout -b feature/add-terraform-functions

# Make changes following conventions
# Add documentation
# Test thoroughly

# Commit with conventional commit message
git commit -m "feat(terraform): add terraform deployment functions"

# Push and create PR
git push origin feature/add-terraform-functions
```

### Pull Request Checklist

- [ ] Follows naming conventions
- [ ] Includes documentation
- [ ] No secrets in code
- [ ] Functions include examples
- [ ] README updated if needed
- [ ] Tested in target environment
- [ ] Conventional commit message

---

## Troubleshooting

### Common Issues

#### Functions Not Loading

```bash
# Check if file exists
ls -la ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh

# Verify sourcing in shell config
grep "bash_functions_docker" ~/.bashrc

# Reload shell
source ~/.bashrc
```

#### Permission Denied

```bash
# Make script executable
chmod +x script_name.sh

# Fix secret file permissions
chmod 600 ~/.bash_secrets
```

#### Symlink Issues

```bash
# Remove broken symlink
rm ~/.bashrc

# Create new symlink with absolute path
ln -sf /home/user/Knowledge-Base/dotfiles/shells/bash/bash.bashrc ~/.bashrc
```

---

## Standards and Best Practices

### Code Quality

- Follow [Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use ShellCheck for linting
- Include error handling
- Document all functions

### Security

- Never commit secrets
- Use secret scanning (automated in this repo)
- Set appropriate file permissions
- Use environment variables for sensitive data

### Documentation

- Each category has its own README
- Functions include usage examples
- Keep documentation up to date
- Link to external resources

---

## Resources

### Documentation
- [RULES.md](RULES.md) - Complete naming conventions and standards
- [ORGANIZATION_PLAN.md](ORGANIZATION_PLAN.md) - Detailed organization structure
- Category READMEs - Specific documentation for each tool/category

### External Resources
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [XDG Base Directory](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter

### Tools
- [Stow](https://www.gnu.org/software/stow/) - Symlink management
- [Chezmoi](https://www.chezmoi.io/) - Dotfiles manager
- [YADM](https://yadm.io/) - Yet Another Dotfiles Manager

---

## Support

For issues, questions, or contributions:

1. **Issues** - Open an issue in the GitHub repository
2. **Discussions** - Use GitHub Discussions for questions
3. **Pull Requests** - Submit PRs following contribution guidelines

---

## License

See [LICENSE](../LICENSE) file in repository root.

---

## Changelog

### Version 2.0.0 (2025-11-01)
- Complete reorganization by functional categories
- Added comprehensive naming conventions
- Created detailed RULES.md document
- Added templates for all major tools
- Improved documentation structure
- Added support for multiple cloud providers
- Enhanced security guidelines

### Version 1.0.0 (Previous)
- Basic bash and zsh configurations
- Simple function examples
- Basic GitHub Actions integration

---

**Last Updated:** 2025-11-01  
**Maintained By:** Knowledge Base Team  
**Version:** 2.0.0

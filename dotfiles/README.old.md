# Dotfiles

This directory stores shell configuration files, functions, aliases, and secrets.

## Structure

```
dotfiles/
├── bash/
│   ├── bashrc
│   ├── bash_profile
│   ├── bash_functions
│   ├── bash_aliases
│   └── bash_secrets.example
└── zsh/
    ├── zshrc
    ├── zprofile
    ├── zsh_functions
    ├── zsh_aliases
    └── zsh_secrets.example
```

## Usage

### Saving Dotfiles

Use the GitHub Actions workflow to save dotfiles:

```bash
gh workflow run save-dotfile.yml -f shell="bash" -f file_type="bashrc" -f content="$(cat ~/.bashrc)"
```

Or manually add files to the repository.

### Retrieving Dotfiles

1. Clone this repository
2. Copy or symlink the dotfiles to your home directory:

```bash
# Bash
ln -s $(pwd)/dotfiles/bash/bashrc ~/.bashrc
ln -s $(pwd)/dotfiles/bash/bash_functions ~/.bash_functions
ln -s $(pwd)/dotfiles/bash/bash_aliases ~/.bash_aliases

# Zsh
ln -s $(pwd)/dotfiles/zsh/zshrc ~/.zshrc
ln -s $(pwd)/dotfiles/zsh/zsh_functions ~/.zsh_functions
ln -s $(pwd)/dotfiles/zsh/zsh_aliases ~/.zsh_aliases
```

### Security Notes

- **Never commit actual secrets!** Use `*_secrets.example` files as templates
- Add actual secret files to `.gitignore`
- Use environment variables or secret management tools for sensitive data
- The `bash_secrets` and `zsh_secrets` files are gitignored by default

## File Descriptions

### bashrc / zshrc
Main shell configuration files that are sourced when starting a new shell session.

### bash_functions / zsh_functions
Reusable shell functions for common tasks.

### bash_aliases / zsh_aliases
Command aliases for shorter, more convenient commands.

### bash_secrets.example / zsh_secrets.example
Templates for storing environment variables and secrets (actual files should not be committed).

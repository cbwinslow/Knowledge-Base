# Shell Config Sync

This directory stores tracked copies of the interactive Zsh configuration so agents can audit or bootstrap new machines directly from the `Knowledge-Base` repository.

## Contents

- `.zshrc`, `.zprofile`, `.zsh_profile`, and sample `.zsh_history`
- Full mirrors of `~/zsh_aliases.d` and `~/zsh_functions.d`
- Placeholder `zsh_secrets.d/README.md` (real secrets stay outside the repo)

## Sync Workflow

1. Run `./scripts/documentation/sync_zsh_configs.sh` from `Knowledge-Base/` to copy the latest home-directory files into this folder.
2. Review the diff (`git status`, `git diff`) to confirm sensitive data is not exposed.
3. Commit and push to GitHub when satisfied (`git commit -am "chore: sync shell config"`).

> **Note:** The sync script intentionally skips actual secret material and only stores a stub README for `zsh_secrets.d`. Adjust the script if you need to version encrypted secrets.

## yadm Integration

Use `scripts/dotfiles/yadm_setup.sh` to bootstrap [yadm](https://yadm.io/) on any machine:

```bash
YADM_REMOTE=git@github.com:cbwinslow/dotfiles.git \
YADM_BRANCH=main \
./scripts/dotfiles/yadm_setup.sh
```

The script:

- Initializes yadm if needed and adds your GitHub remote.
- Sets the machine’s class (defaults to the short hostname) so host-specific files can use the `##CLASS` suffix (e.g., `.zshrc##CBW-LAPTOP`).
- Turns on `yadm.auto-alt` so alternates are applied automatically.

Afterward, manage dotfiles with standard git commands via yadm (`yadm status`, `yadm add`, `yadm commit`, `yadm push`).

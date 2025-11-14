# Repository Guidelines

## Project Structure & Module Organization
All contributor-facing scripts live in `zsh_functions.d/`, with each `function_*.zsh` file declaring a single Zsh function plus a short metadata banner. Multi-function utilities such as `cleanup_functions.zsh` group related helpers; specialized toolsets (backup, monitoring, networking) are nested under `homelab/`. Executable installers (`executable_install_*.sh`, `install_*.zsh`) provide entry points for adding external CLIs and should be kept idempotent so they can be sourced by `show_my_tools`.

## Build, Test, and Development Commands
- `zsh -n function_gh_create_repo.zsh` — fast syntax check before committing.
- `shellcheck -s bash -x cleanup_functions.zsh` — lint shared helpers; set `SHELLCHECK_OPTS="-S warning"` to mirror CI expectations.
- `./function_zsh_functions_summary.zsh && zsh_functions_summary` — prints discovered functions to validate naming and documentation coverage.

## Coding Style & Naming Conventions
Follow the existing header block format (filename, author, purpose, usage). Use four spaces for indentation, `snake_case` for functions, and uppercase for exported environment toggles (e.g., `DEBUG_FUNCTIONS_SUMMARY`). Prefer defensive checks (`[[ -f ... ]]`, `command -v jq`) before invoking external tools, and keep side effects behind descriptive helpers so they can be reused from other dotfile repos.

## Testing Guidelines
Prioritize lightweight validation over heavy frameworks: run `zsh_check_docs` to ensure every function has a matching entry in `~/.zsh_functions.json`, and use `zsh_functions_summary` to confirm multi-function files report status correctly. For scripts that touch external services (GitHub, GitLab, Bitwarden), stub commands via `NOOP=1` guards or wrap them with `if [[ -n "$TOKEN" ]]` to support dry runs. Document any manual test matrix directly in the file header.

## Commit & Pull Request Guidelines
Match the established Conventional Commit style (`feat:`, `fix:`, `chore:`) observed in `git log`. Commits should bundle a self-contained feature or refactor with updated docs/man pages when applicable. Pull requests must list the affected functions, mention any required secrets (without values), and include command transcripts or screenshots for destructive utilities such as `docker_clean`.

## Security & Configuration Tips
Keep tokens out of the repo; leverage `function_env_bitwarden.zsh` or OS keychains to load credentials on demand. When adding installers or scanners (`function_security_scans.zsh`), default to read-only operations unless the user passes an explicit `--apply` flag. Validate paths (`[[ "$target" == "$HOME/"* ]]`) before deleting files, and prefer logging intent with `echo "=== Step ==="` so automated summary tools can parse actions.

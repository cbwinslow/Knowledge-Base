# Shell Script Examples and Best Practices

This directory contains comprehensive examples of shell scripts demonstrating best practices, common patterns, error handling, and production-ready techniques.

## Contents

1. **basic-patterns.sh** - Fundamental shell script patterns
2. **error-handling.sh** - Comprehensive error handling examples
3. **logging.sh** - Logging and output management
4. **argument-parsing.sh** - Command-line argument parsing
5. **file-operations.sh** - Safe file and directory operations
6. **parallel-execution.sh** - Parallel command execution
7. **database-backup.sh** - Production database backup script
8. **deployment.sh** - Application deployment script
9. **monitoring.sh** - System monitoring script
10. **maintenance.sh** - Automated maintenance tasks

## Quick Reference

### Script Template

Every script should start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Script description
# Usage: script.sh [options]

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Main function
main() {
    log_info "Starting script..."
    # Your code here
    log_info "Script completed successfully"
}

# Run main function
main "$@"
```

### Common Options

```bash
set -e          # Exit on error
set -u          # Exit on undefined variable
set -o pipefail # Exit on pipe failure
set -x          # Debug mode (print commands)
```

### Error Handling Pattern

```bash
cleanup() {
    # Cleanup actions
    rm -f /tmp/tempfile
}

trap cleanup EXIT ERR

error_exit() {
    log_error "$1"
    exit "${2:-1}"
}
```

### Argument Parsing Pattern

```bash
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--file)
            FILE="$2"
            shift 2
            ;;
        *)
            error_exit "Unknown option: $1"
            ;;
    esac
done
```

## Best Practices

### 1. Always Use Strict Mode

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

### 2. Quote Variables

```bash
# Good
echo "$variable"
rm -f "$filename"

# Bad
echo $variable
rm -f $filename
```

### 3. Use Functions

```bash
# Good - modular and reusable
process_file() {
    local file=$1
    # Process the file
}

# Call the function
process_file "$filename"
```

### 4. Check Dependencies

```bash
check_dependencies() {
    local deps=(curl jq docker)
    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error_exit "Required command not found: $cmd"
        fi
    done
}
```

### 5. Validate Input

```bash
validate_file() {
    local file=$1
    
    if [[ ! -f "$file" ]]; then
        error_exit "File not found: $file"
    fi
    
    if [[ ! -r "$file" ]]; then
        error_exit "File not readable: $file"
    fi
}
```

### 6. Use Meaningful Names

```bash
# Good
readonly DATABASE_BACKUP_DIR="/var/backups/db"
readonly MAX_RETRY_COUNT=3

# Bad
readonly DIR="/var/backups/db"
readonly MAX=3
```

### 7. Document Functions

```bash
# Backup database to specified directory
# Arguments:
#   $1 - Database name
#   $2 - Backup directory
# Returns:
#   0 on success, 1 on failure
backup_database() {
    local db_name=$1
    local backup_dir=$2
    # Implementation
}
```

### 8. Handle Signals

```bash
cleanup() {
    log_info "Cleaning up..."
    # Cleanup actions
}

trap cleanup EXIT
trap 'error_exit "Script interrupted"' INT TERM
```

### 9. Use Arrays for Lists

```bash
# Good
declare -a servers=("web1" "web2" "web3")
for server in "${servers[@]}"; do
    echo "$server"
done

# Bad
servers="web1 web2 web3"
for server in $servers; do
    echo $server
done
```

### 10. Test Before Production

```bash
# Dry run mode
if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_info "Would execute: $command"
else
    $command
fi
```

## Common Patterns

### Retry Logic

```bash
retry() {
    local max_attempts=$1
    shift
    local cmd=("$@")
    local attempt=1
    
    until "${cmd[@]}"; do
        if (( attempt == max_attempts )); then
            return 1
        fi
        log_warn "Attempt $attempt failed, retrying..."
        ((attempt++))
        sleep 2
    done
}

# Usage
retry 3 curl -f https://api.example.com
```

### Progress Indicator

```bash
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    printf "\rProgress: %d%% [%d/%d]" "$percent" "$current" "$total"
}
```

### File Locking

```bash
acquire_lock() {
    local lockfile=$1
    local timeout=${2:-10}
    local waited=0
    
    while [[ -f "$lockfile" ]]; do
        if (( waited >= timeout )); then
            return 1
        fi
        sleep 1
        ((waited++))
    done
    
    echo $$ > "$lockfile"
}
```

### Configuration File Parsing

```bash
load_config() {
    local config_file=$1
    
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    else
        error_exit "Config file not found: $config_file"
    fi
}
```

## Testing Scripts

### shellcheck

```bash
# Install shellcheck
apt-get install shellcheck

# Run shellcheck
shellcheck script.sh
```

### BATS (Bash Automated Testing System)

```bash
# Install BATS
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# Create test file: test.bats
@test "function returns success" {
    run my_function
    [ "$status" -eq 0 ]
}

# Run tests
bats test.bats
```

## Debugging

```bash
# Enable debug mode
bash -x script.sh

# Or in script
set -x

# Selective debugging
set -x
# Commands to debug
set +x
```

## Performance Tips

1. Use built-in commands instead of external tools when possible
2. Avoid unnecessary subshells
3. Use `read` for file processing instead of `cat`
4. Use parameter expansion instead of `sed`/`awk` for simple tasks
5. Run parallel processes when possible

## Security Considerations

1. Never store passwords in scripts
2. Use environment variables or secure vaults for credentials
3. Sanitize user input
4. Use `shellcheck` to find security issues
5. Set appropriate file permissions (chmod 700 for scripts with secrets)
6. Avoid `eval` and command substitution with user input

## Additional Resources

- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [ShellCheck](https://www.shellcheck.net/)
- [Bash Reference Manual](https://www.gnu.org/software/bash/manual/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/)

#!/bin/bash

# Activity Logger Setup
# This script sets up automatic logging of command line activities

echo "=== Activity Logger Setup ==="
echo ""

# Create logs directory
LOGS_DIR="/home/cbwinslow/activity_logs"
mkdir -p $LOGS_DIR

echo "Creating activity logging system in: $LOGS_DIR"
echo ""

# Create the logging script
cat > $LOGS_DIR/activity_logger.sh << 'EOF'
#!/bin/bash

# Activity Logger
# Logs all commands executed in the terminal

LOG_FILE="/home/cbwinslow/activity_logs/activity_$(date +%Y-%m-%d).log"

# Function to log commands
log_command() {
    local command="$BASH_COMMAND"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $command" >> "$LOG_FILE"
}

# Set up the trap to capture commands
trap 'log_command' DEBUG

echo "Activity logging started. Logs will be saved to: $LOG_FILE"
EOF

chmod +x $LOGS_DIR/activity_logger.sh

# Create instructions for enabling logging
cat > $LOGS_DIR/README.md << 'EOF'
# Activity Logging System

## Overview
This system automatically logs all commands executed in your terminal sessions.

## Setup Instructions

To enable activity logging for your sessions, add the following line to your shell configuration file:

For bash, add to ~/.bashrc:
```bash
source /home/cbwinslow/activity_logs/activity_logger.sh
```

For zsh, add to ~/.zshrc:
```bash
source /home/cbwinslow/activity_logs/activity_logger.sh
```

## Usage

1. Add the source line to your shell configuration file:
   ```bash
   echo "source /home/cbwinslow/activity_logs/activity_logger.sh" >> ~/.bashrc
   ```

2. Either restart your terminal or run:
   ```bash
   source ~/.bashrc
   ```

3. All commands will now be automatically logged to daily log files in this directory.

## Log Files

Log files are named with the date in the format: activity_YYYY-MM-DD.log

Each log entry includes:
- Timestamp of when the command was executed
- The full command that was executed

## Important Notes

- Logs are appended to existing files for the same date
- Log files are created automatically when the logger is enabled
- The logger only captures commands, not their output
- Be careful with sensitive information in commands as they will be logged
EOF

echo "Activity logging system created in: $LOGS_DIR"
echo ""
echo "To enable logging:"
echo "1. Add 'source /home/cbwinslow/activity_logs/activity_logger.sh' to your ~/.bashrc"
echo "2. Run 'source ~/.bashrc' or restart your terminal"
echo ""
echo "Logs will be saved to daily files in $LOGS_DIR"
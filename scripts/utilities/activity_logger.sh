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

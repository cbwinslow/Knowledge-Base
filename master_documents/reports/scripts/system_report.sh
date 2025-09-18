#!/bin/bash

# System Report Script
# Generates a comprehensive report about the system

REPORT_DIR="/home/cbwinslow/Knowledge-Base/master_documents/reports"
REPORT_FILE="$REPORT_DIR/system_report.txt"

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Start writing the report
echo "=== SYSTEM REPORT ===" > "$REPORT_FILE"
echo "Generated on: " >> "$REPORT_FILE"
date >> "$REPORT_FILE"
echo "Hostname: " >> "$REPORT_FILE"
hostname >> "$REPORT_FILE"

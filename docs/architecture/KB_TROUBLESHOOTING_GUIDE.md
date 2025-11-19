# Knowledge Base System - Troubleshooting and Maintenance Guide

## Table of Contents
1. [Common Issues and Solutions](#common-issues-and-solutions)
2. [Performance Problems](#performance-problems)
3. [Data Corruption Issues](#data-corruption-issues)
4. [Installation and Setup Problems](#installation-and-setup-problems)
5. [Search and Index Issues](#search-and-index-issues)
6. [File System Problems](#file-system-problems)
7. [Shell Integration Issues](#shell-integration-issues)
8. [Maintenance Procedures](#maintenance-procedures)
9. [Backup and Recovery](#backup-and-recovery)
10. [Debugging Tools and Techniques](#debugging-tools-and-techniques)

---

## Common Issues and Solutions

### Issue: Command Not Found

**Symptoms**:
```bash
$ kb search "test"
bash: kb: command not found
```

**Causes**:
1. Shell integration not loaded
2. Script not executable
3. PATH not configured correctly

**Solutions**:

#### Solution 1: Load Shell Integration
```bash
# Load manually for current session
source /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh

# Add to .bashrc for permanent solution
echo 'source "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh"' >> ~/.bashrc
source ~/.bashrc
```

#### Solution 2: Use Full Path
```bash
# Use full path as fallback
/home/cbwinslow/Knowledge-Base/scripts/documentation/kb search "test"
```

#### Solution 3: Create Symlink
```bash
# Create symlink in local bin
mkdir -p ~/.local/bin
ln -s /home/cbwinslow/Knowledge-Base/scripts/documentation/kb ~/.local/bin/kb
export PATH="$HOME/.local/bin:$PATH"
```

**Verification**:
```bash
which kb
kb help
```

---

### Issue: Search Returns No Results

**Symptoms**:
```bash
$ kb_search "docker" 5
🔍 Searching for: docker
No results found
```

**Causes**:
1. Knowledge base not initialized
2. Index corrupted or outdated
3. Search terms too specific
4. Documents not indexed

**Solutions**:

#### Solution 1: Initialize Knowledge Base
```bash
kb_init
```

#### Solution 2: Rebuild Index
```bash
kb_update
```

#### Solution 3: Check Document Existence
```bash
# Verify documents exist
kb_lookup "docker"
find /home/cbwinslow/Knowledge-Base -name "*docker*" -type f
```

#### Solution 4: Try Broader Search Terms
```bash
# Try different variations
kb_search "container" 5
kb_search "compose" 5
kb_search "yaml" 5
```

**Debugging Steps**:
```bash
# Check index status
ls -la /home/cbwinslow/Knowledge-Base/simple_rag_db/
cat /home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json | jq '. | length'
```

---

### Issue: Permission Denied

**Symptoms**:
```bash
$ kb_init
bash: /home/cbwinslow/Knowledge-Base/scripts/documentation/kb: Permission denied
```

**Causes**:
1. Script not executable
2. File permission issues
3. Directory access problems

**Solutions**:

#### Solution 1: Make Scripts Executable
```bash
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/kb
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/*.py
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/*.sh
```

#### Solution 2: Check Directory Permissions
```bash
# Check KB directory permissions
ls -la /home/cbwinslow/Knowledge-Base/
ls -la /home/cbwinslow/Knowledge-Base/scripts/documentation/

# Fix if needed
chmod -R 755 /home/cbwinslow/Knowledge-Base/scripts/documentation/
```

#### Solution 3: Check Ownership
```bash
# Verify ownership
ls -la /home/cbwinslow/Knowledge-Base/

# Fix ownership if needed
sudo chown -R $USER:$USER /home/cbwinslow/Knowledge-Base/
```

---

## Performance Problems

### Issue: Slow Search Response

**Symptoms**:
- Search takes more than 5 seconds
- System becomes unresponsive during search
- High CPU usage during queries

**Diagnosis**:
```bash
# Time the search operation
time kb_search "test" 5

# Check system resources
top -p $(pgrep -f "simple_rag_knowledge_base.py")
df -h /home/cbwinslow/Knowledge-Base/
```

**Solutions**:

#### Solution 1: Optimize Index
```bash
# Rebuild index with current settings
kb_update

# Check vocabulary size
python3 /home/cbwinslow/Knowledge-Base/scripts/documentation/simple_rag_knowledge_base.py stats
```

#### Solution 2: Reduce Document Count
```bash
# Check what's being indexed
kb_stats

# Consider excluding large directories
echo "# Add to .kb_ignore" >> /home/cbwinslow/Knowledge-Base/.kb_ignore
echo "large_directory/" >> /home/cbwinslow/Knowledge-Base/.kb_ignore
echo "*.log" >> /home/cbwinslow/Knowledge-Base/.kb_ignore
```

#### Solution 3: Memory Optimization
```bash
# Check available memory
free -h

# Close other applications if memory is low
# Consider adding swap space if needed
```

---

### Issue: High Memory Usage

**Symptoms**:
- System slows down during indexing
- Out of memory errors
- Swap space usage increases

**Diagnosis**:
```bash
# Monitor memory usage
watch -n 1 'free -h'

# Check process memory
ps aux --sort=-%mem | head -10
```

**Solutions**:

#### Solution 1: Incremental Indexing
```bash
# Index specific directories instead of all
cd /home/cbwinslow/Knowledge-Base/scripts/documentation
python3 simple_rag_knowledge_base.py index --directory documentation
```

#### Solution 2: Exclude Large Files
```bash
# Find and exclude large files
find /home/cbwinslow/Knowledge-Base -type f -size +10M -ls

# Add to ignore patterns
echo "*.pdf" >> /home/cbwinslow/Knowledge-Base/.kb_ignore
echo "*.zip" >> /home/cbwinslow/Knowledge-Base/.kb_ignore
```

#### Solution 3: Limit Concurrent Operations
```bash
# Reduce system load during indexing
nice -n 19 kb_update
```

---

## Data Corruption Issues

### Issue: Index Corruption

**Symptoms**:
```bash
$ kb_search "test"
Error: JSON decode error
$ kb_stats
Error: Cannot read documents file
```

**Diagnosis**:
```bash
# Check index files
ls -la /home/cbwinslow/Knowledge-Base/simple_rag_db/
file /home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json
```

**Solutions**:

#### Solution 1: Backup and Rebuild
```bash
# Backup current index
cp -r /home/cbwinslow/Knowledge-Base/simple_rag_db ~/backup/kb-index-$(date +%Y%m%d)

# Rebuild from scratch
rm -rf /home/cbwinslow/Knowledge-Base/simple_rag_db/
kb_init
```

#### Solution 2: Validate JSON Files
```bash
# Check JSON validity
python3 -m json.tool /home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json > /dev/null
echo $?
# 0 = valid, 1 = invalid

# Fix if invalid
python3 -c "
import json
try:
    with open('/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json', 'r') as f:
        data = json.load(f)
    print('JSON is valid')
except:
    print('JSON is corrupted, rebuilding required')
"
```

#### Solution 3: Partial Recovery
```bash
# Try to recover partial data
python3 -c "
import json
import sys

try:
    with open('/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json', 'r') as f:
        content = f.read()
    
    # Try to find valid JSON portions
    lines = content.split('\n')
    valid_lines = []
    
    for line in lines:
        try:
            json.loads(line)
            valid_lines.append(line)
        except:
            continue
    
    print(f'Found {len(valid_lines)} valid lines out of {len(lines)}')
    
except Exception as e:
    print(f'Error: {e}')
"
```

---

### Issue: Bookmark File Corruption

**Symptoms**:
```bash
$ kb_bookmarks
Error: Cannot read bookmarks file
```

**Solutions**:

#### Solution 1: Recreate Bookmark File
```bash
# Backup corrupted file
cp ~/.kb_bookmarks ~/.kb_bookmarks.backup.$(date +%Y%m%d)

# Create new empty file
touch ~/.kb_bookmarks
echo "Bookmarks file reset to empty"
```

#### Solution 2: Manual Recovery
```bash
# Check file content
cat ~/.kb_bookmarks

# Fix format if needed (should be: timestamp|path|note)
# Example of correct format:
# 2025-11-12 14:45:40|README.md|Main documentation
```

---

## Installation and Setup Problems

### Issue: Python Dependencies Missing

**Symptoms**:
```bash
$ kb_init
ModuleNotFoundError: No module named 'xxx'
```

**Diagnosis**:
```bash
# Check Python version
python3 --version

# Check available modules
python3 -c "import sys; print(sys.path)"
```

**Solutions**:

#### Solution 1: Use Built-in Libraries Only
The system is designed to work with built-in Python libraries only. If you're getting dependency errors, ensure you're using the correct Python version.

#### Solution 2: Install Missing Modules (if needed)
```bash
# For Python 3.7+
pip3 install --user -r /home/cbwinslow/Knowledge-Base/scripts/documentation/requirements.txt
```

#### Solution 3: Check Python Path
```bash
# Ensure correct Python is being used
which python3
/usr/bin/python3 --version

# Update shebang lines if needed
sed -i '1s|.*|#!/usr/bin/env python3|' /home/cbwinslow/Knowledge-Base/scripts/documentation/*.py
```

---

### Issue: Shell Integration Not Working

**Symptoms**:
- Auto-completion not working
- Aliases not available
- Commands not found

**Diagnosis**:
```bash
# Check if shell config is loaded
grep -n "kb_shell_config" ~/.bashrc

# Check current shell
echo $SHELL
```

**Solutions**:

#### Solution 1: Reload Shell Configuration
```bash
# Reload bashrc
source ~/.bashrc

# Or start new shell
bash
```

#### Solution 2: Manual Integration
```bash
# Add to current session manually
source /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh
alias kb="/home/cbwinslow/Knowledge-Base/scripts/documentation/kb"
```

#### Solution 3: Zsh Support
```bash
# For zsh users
echo 'source "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh"' >> ~/.zshrc
source ~/.zshrc
```

---

## Search and Index Issues

### Issue: Poor Search Results

**Symptoms**:
- Irrelevant results appearing
- Important documents not found
- Low similarity scores

**Diagnosis**:
```bash
# Test with known content
kb_search "README" 10

# Check document content
kb_lookup "README.md"
head -20 /path/to/some/README.md
```

**Solutions**:

#### Solution 1: Improve Query Terms
```bash
# Use more specific terms
kb_search "docker compose configuration" 5

# Use multiple word searches
kb_search "python script automation" 5
```

#### Solution 2: Check Tokenization
```bash
# Test tokenization directly
python3 -c "
import sys
sys.path.append('/home/cbwinslow/Knowledge-Base/scripts/documentation')
from simple_rag_knowledge_base import SimpleRAGKnowledgeBase

rag = SimpleRAGKnowledgeBase()
tokens = rag._tokenize('docker compose configuration')
print('Tokens:', tokens)
"
```

#### Solution 3: Rebuild with Different Parameters
```bash
# Sometimes a fresh rebuild helps
kb_update
```

---

### Issue: Category Filtering Not Working

**Symptoms**:
```bash
$ kb_search "test" 5 scripts
No results found (but should find some)
```

**Diagnosis**:
```bash
# Check available categories
kb_stats

# Check document categories
python3 -c "
import json
with open('/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json', 'r') as f:
    docs = json.load(f)
    
categories = set()
for doc_id, doc_data in docs.items():
    category = doc_data.get('metadata', {}).get('category', 'unknown')
    categories.add(category)

print('Available categories:', sorted(categories))
"
```

**Solutions**:

#### Solution 1: Use Correct Category Names
```bash
# Use exact category names from stats
kb_search "test" 5 documentation
kb_search "test" 5 scripts
```

#### Solution 2: Search Without Category Filter
```bash
# Search all categories first
kb_search "test" 10
```

---

## File System Problems

### Issue: Disk Space Full

**Symptoms**:
```bash
$ kb_init
No space left on device
```

**Diagnosis**:
```bash
# Check disk usage
df -h /home/cbwinslow/Knowledge-Base/

# Check large files
du -sh /home/cbwinslow/Knowledge-Base/* | sort -hr | head -10
```

**Solutions**:

#### Solution 1: Clean Up
```bash
# Remove temporary files
find /home/cbwinslow/Knowledge-Base -name "*.tmp" -delete
find /home/cbwinslow/Knowledge-Base -name "*.log" -delete

# Clean old backups
find ~/backup -name "kb-*" -mtime +30 -delete
```

#### Solution 2: Move Knowledge Base
```bash
# Move to larger partition
sudo mv /home/cbwinslow/Knowledge-Base /mnt/large_partition/
ln -s /mnt/large_partition/Knowledge-Base /home/cbwinslow/Knowledge-Base
```

#### Solution 3: Compress Old Documents
```bash
# Compress large, rarely used files
find /home/cbwinslow/Knowledge-Base -name "*.pdf" -mtime +90 -exec gzip {} \;
find /home/cbwinslow/Knowledge-Base -name "*.log" -mtime +30 -exec gzip {} \;
```

---

### Issue: File Permission Problems

**Symptoms**:
```bash
$ kb_open "README.md"
Permission denied
```

**Solutions**:

#### Solution 1: Fix Permissions
```bash
# Fix directory permissions
find /home/cbwinslow/Knowledge-Base -type d -exec chmod 755 {} \;

# Fix file permissions
find /home/cbwinslow/Knowledge-Base -type f -exec chmod 644 {} \;

# Make scripts executable
find /home/cbwinslow/Knowledge-Base -name "*.sh" -exec chmod +x {} \;
find /home/cbwinslow/Knowledge-Base -name "*.py" -exec chmod +x {} \;
```

#### Solution 2: Fix Ownership
```bash
# Ensure correct ownership
sudo chown -R $USER:$USER /home/cbwinslow/Knowledge-Base/
```

---

## Shell Integration Issues

### Issue: Auto-completion Not Working

**Symptoms**:
- Tab completion doesn't show commands
- File completion not working

**Diagnosis**:
```bash
# Check if completion is loaded
complete -p | grep kb

# Check bash version
bash --version | head -1
```

**Solutions**:

#### Solution 1: Enable Completion
```bash
# Load completion manually
source /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh

# Test completion
complete -p | grep kb
```

#### Solution 2: Check Bash Completion Support
```bash
# Install bash-completion if missing
sudo apt-get install bash-completion  # Ubuntu/Debian
sudo yum install bash-completion      # CentOS/RHEL

# Add to bashrc
echo 'source /etc/bash_completion' >> ~/.bashrc
```

#### Solution 3: Manual Completion Setup
```bash
# Add completion manually
echo 'complete -F _kb_complete kb' >> ~/.bashrc
echo 'complete -F _kb_complete /home/cbwinslow/Knowledge-Base/scripts/documentation/kb' >> ~/.bashrc
source ~/.bashrc
```

---

### Issue: Aliases Not Working

**Symptoms**:
```bash
$ kbs "test"
bash: kbs: command not found
```

**Solutions**:

#### Solution 1: Load Aliases
```bash
# Source functions file
source /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh

# Check aliases
alias | grep kb
```

#### Solution 2: Add to Shell Configuration
```bash
# Add to bashrc
echo 'source "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh"' >> ~/.bashrc
source ~/.bashrc
```

---

## Maintenance Procedures

### Daily Maintenance

#### Health Check Script
```bash
#!/bin/bash
# kb_health_check.sh

echo "=== Knowledge Base Health Check ==="
echo "Date: $(date)"
echo ""

# Check basic functionality
echo "1. Basic command test:"
if command -v kb >/dev/null 2>&1; then
    echo "✅ KB command available"
else
    echo "❌ KB command not found"
fi

# Check index files
echo ""
echo "2. Index files:"
if [[ -f "/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json" ]]; then
    echo "✅ Documents index exists"
    doc_count=$(python3 -c "import json; print(len(json.load(open('/home/cbwinslow/Knowledge-Base/simple_rag_db/documents.json'))))" 2>/dev/null || echo "Error")
    echo "   Documents indexed: $doc_count"
else
    echo "❌ Documents index missing"
fi

# Test search
echo ""
echo "3. Search test:"
search_result=$(kb_search "test" 1 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "✅ Search functionality working"
else
    echo "❌ Search functionality broken"
fi

# Check disk space
echo ""
echo "4. Disk space:"
df -h /home/cbwinslow/Knowledge-Base/ | tail -1

# Check bookmarks
echo ""
echo "5. Bookmarks:"
if [[ -f "$HOME/.kb_bookmarks" ]]; then
    bookmark_count=$(wc -l < "$HOME/.kb_bookmarks")
    echo "✅ Bookmarks file exists ($bookmark_count bookmarks)"
else
    echo "❌ Bookmarks file missing"
fi

echo ""
echo "=== Health Check Complete ==="
```

#### Automated Health Check
```bash
# Make executable
chmod +x kb_health_check.sh

# Run daily (add to crontab)
crontab -e
# Add: 0 2 * * * /path/to/kb_health_check.sh >> ~/kb_health.log 2>&1
```

### Weekly Maintenance

#### Index Update
```bash
#!/bin/bash
# kb_weekly_maintenance.sh

echo "Starting weekly maintenance: $(date)"

# Update index
echo "Updating knowledge base index..."
kb_update

# Generate new TOC
echo "Generating table of contents..."
kb_toc

# Clean up temporary files
echo "Cleaning up temporary files..."
find /home/cbwinslow/Knowledge-Base -name "*.tmp" -delete
find /home/cbwinslow/Knowledge-Base -name "*.bak" -delete

# Check for large files
echo "Checking for large files..."
find /home/cbwinslow/Knowledge-Base -type f -size +50M -ls

echo "Weekly maintenance completed: $(date)"
```

### Monthly Maintenance

#### Deep Clean and Optimization
```bash
#!/bin/bash
# kb_monthly_maintenance.sh

echo "Starting monthly maintenance: $(date)"

# Full index rebuild
echo "Performing full index rebuild..."
rm -rf /home/cbwinslow/Knowledge-Base/simple_rag_db/
kb_init

# Compress old logs
echo "Compressing old logs..."
find /home/cbwinslow/Knowledge-Base -name "*.log" -mtime +30 -exec gzip {} \;

# Check for duplicate files
echo "Checking for duplicate files..."
find /home/cbwinslow/Knowledge-Base -type f -exec md5sum {} \; | sort | uniq -d -w32

# Backup critical files
echo "Creating backup..."
mkdir -p ~/backup/kb-$(date +%Y%m)
cp -r /home/cbwinslow/Knowledge-Base/simple_rag_db ~/backup/kb-$(date +%Y%m)/
cp ~/.kb_bookmarks ~/backup/kb-$(date +%Y%m)/

echo "Monthly maintenance completed: $(date)"
```

---

## Backup and Recovery

### Automated Backup Script
```bash
#!/bin/bash
# kb_backup.sh

BACKUP_DIR="$HOME/backups/knowledge-base"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

echo "Creating knowledge base backup..."

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup critical components
echo "Backing up index files..."
cp -r /home/cbwinslow/Knowledge-Base/simple_rag_db "$BACKUP_PATH/"

echo "Backing up configuration..."
cp /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_functions.sh "$BACKUP_PATH/"
cp /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh "$BACKUP_PATH/"

echo "Backing up bookmarks..."
cp ~/.kb_bookmarks "$BACKUP_PATH/" 2>/dev/null || echo "No bookmarks file found"

echo "Backing up TOC..."
cp /home/cbwinslow/Knowledge-Base/TABLE_OF_CONTENTS.md "$BACKUP_PATH/" 2>/dev/null

# Create backup info
echo "Creating backup info..."
cat > "$BACKUP_PATH/backup_info.txt" << EOF
Knowledge Base Backup
====================
Created: $(date)
KB Path: /home/cbwinslow/Knowledge-Base
Backup Type: Full

Components:
- Search Index: simple_rag_db/
- Configuration: kb_functions.sh, kb_shell_config.sh
- Bookmarks: .kb_bookmarks
- TOC: TABLE_OF_CONTENTS.md

Statistics:
$(kb_stats)
EOF

# Compress backup
echo "Compressing backup..."
cd "$BACKUP_DIR"
tar -czf "backup_$TIMESTAMP.tar.gz" "backup_$TIMESTAMP"
rm -rf "backup_$TIMESTAMP"

echo "Backup completed: $BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

# Clean old backups (keep last 10)
echo "Cleaning old backups..."
ls -t backup_*.tar.gz | tail -n +11 | xargs -r rm

echo "Backup process completed."
```

### Recovery Procedures

#### Full Recovery
```bash
#!/bin/bash
# kb_recovery.sh

BACKUP_FILE="$1"

if [[ -z "$BACKUP_FILE" ]]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

echo "Recovering from backup: $BACKUP_FILE"

# Extract backup
TEMP_DIR=$(mktemp -d)
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

BACKUP_CONTENTS=$(ls "$TEMP_DIR")
BACKUP_DIR="$TEMP_DIR/$BACKUP_CONTENTS"

# Stop any running KB processes
pkill -f "simple_rag_knowledge_base.py" 2>/dev/null

# Backup current state (just in case)
echo "Backing up current state..."
mv /home/cbwinslow/Knowledge-Base/simple_rag_db ~/backup/kb-current-$(date +%Y%m%d_%H%M%S) 2>/dev/null
cp ~/.kb_bookmarks ~/backup/kb-bookmarks-current-$(date +%Y%m%d_%H%M%S) 2>/dev/null

# Restore components
echo "Restoring search index..."
cp -r "$BACKUP_DIR/simple_rag_db" /home/cbwinslow/Knowledge-Base/

echo "Restoring configuration..."
cp "$BACKUP_DIR/kb_functions.sh" /home/cbwinslow/Knowledge-Base/scripts/documentation/
cp "$BACKUP_DIR/kb_shell_config.sh" /home/cbwinslow/Knowledge-Base/scripts/documentation/

echo "Restoring bookmarks..."
cp "$BACKUP_DIR/.kb_bookmarks" ~/ 2>/dev/null

echo "Restoring TOC..."
cp "$BACKUP_DIR/TABLE_OF_CONTENTS.md" /home/cbwinslow/Knowledge-Base/ 2>/dev/null

# Set permissions
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/kb
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/*.py
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/*.sh

# Test recovery
echo "Testing recovery..."
/home/cbwinslow/Knowledge-Base/scripts/documentation/kb stats

# Cleanup
rm -rf "$TEMP_DIR"

echo "Recovery completed successfully!"
```

---

## Debugging Tools and Techniques

### Debug Mode

#### Enable Debug Output
```bash
# Set debug environment variable
export KB_DEBUG=1

# Run commands with debug output
kb_search "test" 5

# Disable debug
unset KB_DEBUG
```

#### Add Debug Logging to Functions
```bash
# Add to kb_functions.sh
debug_log() {
    if [[ "${KB_DEBUG:-}" == "1" ]]; then
        echo "[DEBUG $(date '+%H:%M:%S')] $*" >&2
    fi
}

# Use in functions
kb_search() {
    debug_log "Starting search with query: $1"
    debug_log "Results requested: $2"
    debug_log "Category filter: $3"
    # ... rest of function
}
```

### Performance Profiling

#### Profile Search Performance
```bash
#!/bin/bash
# kb_profile.sh

QUERY="${1:-test}"
RESULTS="${2:-5}"

echo "Profiling search performance..."
echo "Query: $QUERY"
echo "Results: $RESULTS"
echo ""

# Time the search
time kb_search "$QUERY" "$RESULTS"

# Profile Python backend
echo ""
echo "Python profiling:"
cd /home/cbwinslow/Knowledge-Base/scripts/documentation
python3 -c "
import time
import sys
sys.path.append('.')
from simple_rag_knowledge_base import SimpleRAGKnowledgeBase

start_time = time.time()
rag = SimpleRAGKnowledgeBase()
load_time = time.time()

results = rag.search('$QUERY', $RESULTS)
search_time = time.time()

print(f'Load time: {load_time - start_time:.3f}s')
print(f'Search time: {search_time - load_time:.3f}s')
print(f'Total time: {search_time - start_time:.3f}s')
print(f'Results found: {len(results)}')
"
```

### Memory Profiling

#### Monitor Memory Usage
```bash
#!/bin/bash
# kb_memory_profile.sh

echo "Memory profiling for knowledge base..."

# Baseline memory
echo "Baseline memory usage:"
free -h

echo ""
echo "During indexing:"
python3 -c "
import psutil
import os
import time
sys.path.append('/home/cbwinslow/Knowledge-Base/scripts/documentation')
from simple_rag_knowledge_base import SimpleRAGKnowledgeBase

process = psutil.Process(os.getpid())
print(f'Initial memory: {process.memory_info().rss / 1024 / 1024:.1f} MB')

rag = SimpleRAGKnowledgeBase()
print(f'After loading: {process.memory_info().rss / 1024 / 1024:.1f} MB')

rag.index_directory()
print(f'After indexing: {process.memory_info().rss / 1024 / 1024:.1f} MB')
"

echo ""
echo "Current memory usage:"
free -h
```

### Log Analysis

#### Analyze Search Patterns
```bash
#!/bin/bash
# kb_analyze_usage.sh

LOG_FILE="$HOME/.kb_usage.log"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "No usage log found. Enable logging first:"
    echo "export KB_LOG_FILE=~/.kb_usage.log"
    exit 1
fi

echo "Knowledge Base Usage Analysis"
echo "============================"
echo ""

# Most common search terms
echo "Top 10 search terms:"
grep "SEARCH:" "$LOG_FILE" | awk '{print $3}' | sort | uniq -c | sort -nr | head -10

echo ""
echo "Most accessed files:"
grep "OPEN:" "$LOG_FILE" | awk '{print $3}' | sort | uniq -c | sort -nr | head -10

echo ""
echo "Command usage frequency:"
grep "COMMAND:" "$LOG_FILE" | awk '{print $3}' | sort | uniq -c | sort -nr

echo ""
echo "Activity by hour:"
grep "COMMAND:" "$LOG_FILE" | awk '{print substr($2,1,2)}' | sort | uniq -c | sort -n
```

### System Integration Tests

#### Comprehensive Test Suite
```bash
#!/bin/bash
# kb_test_suite.sh

echo "Knowledge Base Test Suite"
echo "========================"
echo ""

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo "Running test: $test_name"
    if eval "$test_command" >/dev/null 2>&1; then
        echo "✅ PASSED: $test_name"
        ((TESTS_PASSED++))
    else
        echo "❌ FAILED: $test_name"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Basic functionality tests
run_test "KB command available" "command -v kb"
run_test "Help command works" "kb help"
run_test "Stats command works" "kb_stats"
run_test "TOC generation works" "kb_toc"

# Search functionality tests
run_test "Basic search works" "kb_search 'test' 1"
run_test "File lookup works" "kb_lookup 'README'"

# Bookmark functionality tests
run_test "Bookmark creation works" "kb_bookmark 'README.md' 'Test bookmark'"
run_test "Bookmark listing works" "kb_bookmarks"
run_test "Bookmark removal works" "kb_unbookmark 1"

# File operations tests
TEST_FILE="/tmp/kb_test_$(date +%s).txt"
echo "Test content" > "$TEST_FILE"
run_test "File addition works" "kb_add '$TEST_FILE' 'Test file'"
run_test "File copy works" "kb_copy 'test content' '/tmp/kb_copy_test.txt'"
rm -f "$TEST_FILE" "/tmp/kb_copy_test.txt"

# Index operations tests
run_test "Index update works" "kb_update"

echo "Test Results:"
echo "============="
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo "Total:  $((TESTS_PASSED + TESTS_FAILED))"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "🎉 All tests passed!"
    exit 0
else
    echo "⚠️  Some tests failed. Check the output above."
    exit 1
fi
```

---

## Quick Reference Troubleshooting

| Problem | Quick Fix |
|---------|-----------|
| Command not found | `source /home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh` |
| No search results | `kb_update` |
| Permission denied | `chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/kb` |
| Slow performance | `kb_update` and check disk space |
| Index corruption | `rm -rf /home/cbwinslow/Knowledge-Base/simple_rag_db/ && kb_init` |
| Auto-completion not working | `source ~/.bashrc` |
| Bookmark issues | `rm ~/.kb_bookmarks && touch ~/.kb_bookmarks` |

---

## Emergency Procedures

### Complete System Reset
```bash
# Emergency reset - last resort
echo "⚠️  This will reset the entire knowledge base system!"
read -p "Are you sure? [y/N]: " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Stop processes
    pkill -f "simple_rag_knowledge_base.py"
    
    # Backup current state
    mv /home/cbwinslow/Knowledge-Base/simple_rag_db ~/backup/kb-emergency-$(date +%Y%m%d_%H%M%S) 2>/dev/null
    mv ~/.kb_bookmarks ~/backup/kb-bookmarks-emergency-$(date +%Y%m%d_%H%M%S) 2>/dev/null
    
    # Reset to initial state
    kb_init
    
    echo "System reset completed. Please reconfigure as needed."
fi
```

This comprehensive troubleshooting and maintenance guide provides solutions for common issues, preventive maintenance procedures, and debugging tools to keep your knowledge base system running smoothly.
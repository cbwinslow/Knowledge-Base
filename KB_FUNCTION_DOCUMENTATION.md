# Knowledge Base System - Complete Function Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Core Functions](#core-functions)
3. [Search Functions](#search-functions)
4. [Document Management Functions](#document-management-functions)
5. [Bookmark Functions](#bookmark-functions)
6. [Utility Functions](#utility-functions)
7. [Configuration and Constants](#configuration-and-constants)
8. [Helper Functions](#helper-functions)
9. [Auto-completion System](#auto-completion-system)
10. [Aliases and Shortcuts](#aliases-and-shortcuts)

---

## System Overview

The Knowledge Base (KB) Management System is a comprehensive bash-based toolset designed to provide intelligent search, organization, and management capabilities for large document collections. It combines TF-IDF vector search with traditional file management operations to create a powerful knowledge retrieval system.

### Key Features
- **Intelligent Search**: TF-IDF vector-based semantic search
- **Document Management**: Add, remove, copy, and organize documents
- **Bookmark System**: Save and manage important documents with notes
- **Statistics**: Track usage and storage metrics
- **Auto-completion**: Tab completion for all commands
- **Cross-platform**: Works on Linux, macOS, and Windows (WSL)

---

## Configuration and Constants

### Global Configuration Variables
```bash
KB_PATH="/home/cbwinslow/Knowledge-Base"           # Root directory of knowledge base
RAG_SCRIPT="$KB_PATH/scripts/documentation/simple_rag_knowledge_base.py"  # Search engine script
TOC_SCRIPT="$KB_PATH/scripts/documentation/dynamic_toc.py"              # TOC generator
RAG_DB_DIR="$KB_PATH/simple_rag_db"               # Database directory
BOOKMARKS_FILE="$HOME/.kb_bookmarks"               # User bookmarks file
```

### Color Scheme
```bash
RED='\033[0;31m'      # Error messages
GREEN='\033[0;32m'    # Success messages
YELLOW='\033[1;33m'   # Warning/progress messages
BLUE='\033[0;34m'     # Information messages
PURPLE='\033[0;35m'   # Bookmark messages
CYAN='\033[0;36m'     # File listings
NC='\033[0m'          # No Color (reset)
```

---

## Helper Functions

### `print_status(color, message)`
**Purpose**: Display colored output messages
**Parameters**:
- `color`: Color code variable (e.g., `$GREEN`, `$RED`)
- `message`: Message to display

**Usage**: Internal function used by all other functions for consistent output formatting

### `confirm(message, default)`
**Purpose**: Interactive confirmation prompt for destructive operations
**Parameters**:
- `message`: Confirmation message to display
- `default`: Default response (defaults to 'n')

**Returns**: 0 for yes, 1 for no

**Used by**: `kb_remove()`

---

## Core Functions

### `kb_init()`
**Purpose**: Initialize the knowledge base system
**Actions**:
1. Creates necessary directories (`$RAG_DB_DIR`, bookmarks directory)
2. Creates empty bookmarks file if needed
3. Runs full indexing of the knowledge base
4. Displays system statistics

**Usage**: `kb_init`

**Example Output**:
```
🚀 Initializing Knowledge Base...
✅ Created bookmarks file: /home/user/.kb_bookmarks
📚 Indexing knowledge base (this may take a moment)...
✅ Knowledge base initialized successfully!
```

---

## Search Functions

### `kb_search(query, results, category)`
**Purpose**: Perform intelligent search across all documents
**Parameters**:
- `query`: Search query string (required)
- `results`: Number of results to return (default: 5)
- `category`: Optional category filter

**Features**:
- TF-IDF vector similarity scoring
- Category-based filtering
- Ranked results with similarity scores
- Content snippets for each result

**Usage Examples**:
```bash
kb_search "docker compose" 10
kb_search "python scripts" 5 scripts
kb_search "configuration files"
```

**Output Format**:
```
🔍 Searching for: docker

Found 5 results for 'docker':

1. scripts/server_setup/docker-install.sh
   Category: scripts
   Similarity: 0.842
   Content: #!/bin/bash
   # Install Docker and Docker Compose...
```

### `kb_lookup(pattern)`
**Purpose**: Find documents by filename pattern (traditional file search)
**Parameters**:
- `pattern`: Filename pattern to match (required)

**Features**:
- Pattern-based filename matching
- File size and modification date display
- Relative path display
- Limited to 20 results to prevent flooding

**Usage Examples**:
```bash
kb_lookup "README.md"
kb_lookup "docker"
kb_lookup "*.py"
```

**Output Format**:
```
🔍 Looking up documents matching: README.md
📋 Found documents:
  📄 README.md (8.0K, modified: 2025-11-08 14:59:58)
  📄 docs/README.md (4.0K, modified: 2025-11-08 14:59:58)
```

---

## Document Management Functions

### `kb_add(file_path, description)`
**Purpose**: Add external documents to the knowledge base
**Parameters**:
- `file_path`: Path to file to add (required)
- `description`: Optional description for the file

**Actions**:
1. Validates file existence
2. Copies file to `$KB_PATH/documents/`
3. Re-indexes the knowledge base
4. Stores description in metadata file

**Usage Examples**:
```bash
kb_add ./important-config.yaml "Production configuration"
kb_add ~/Documents/project-notes.md
kb_add /tmp/backup-script.sh "Emergency backup script"
```

### `kb_remove(file_pattern)`
**Purpose**: Remove documents from the knowledge base
**Parameters**:
- `file_pattern`: Pattern matching files to remove (required)

**Safety Features**:
- Lists matching files before removal
- Requires confirmation before deletion
- Excludes `.git` and database directories
- Automatically re-indexes after removal

**Usage Examples**:
```bash
kb_remove "temp-file"
kb_remove "*.tmp"
kb_remove "old-config"
```

### `kb_copy(source, destination)`
**Purpose**: Copy files from knowledge base to external locations
**Parameters**:
- `source`: Source file pattern (required)
- `destination`: Destination path (optional, defaults to filename)

**Features**:
- Pattern matching for source files
- Copies first match found
- Supports relative and absolute destinations

**Usage Examples**:
```bash
kb_copy "docker-compose.yml" ./production/
kb_copy "config.yaml" ~/backup/
kb_copy "README.md"
```

### `kb_open(file_pattern)`
**Purpose**: Open documents using appropriate system applications
**Parameters**:
- `file_pattern`: Pattern matching file to open (required)

**Application Detection**:
1. `xdg-open` (Linux)
2. `open` (macOS)
3. `$EDITOR` environment variable
4. `less` for text files (fallback)

**Usage Examples**:
```bash
kb_open "README.md"
kb_open "config.yaml"
kb_open "documentation.pdf"
```

---

## Bookmark Functions

### `kb_bookmark(file_path, note)`
**Purpose**: Save bookmarks with optional notes
**Parameters**:
- `file_path`: Path to file to bookmark (required)
- `note`: Optional note/description

**Features**:
- Automatic path conversion (absolute to relative)
- Timestamp tracking
- Persistent storage in user home directory

**Usage Examples**:
```bash
kb_bookmark "README.md" "Main project documentation"
kb_bookmark "docker-compose.yml" "Production config"
kb_bookmark "scripts/backup.sh"
```

### `kb_bookmarks()`
**Purpose**: Display all saved bookmarks
**Parameters**: None

**Output Format**:
```
🔖 Your bookmarks:

1. 2025-11-12 14:45:40
   📄 README.md
   📝 Main project documentation

2. 2025-11-12 15:30:22
   📄 docker-compose.yml
   📝 Production config
```

### `kb_unbookmark(bookmark_num)`
**Purpose**: Remove bookmark by number
**Parameters**:
- `bookmark_num`: Bookmark number to remove (required)

**Safety Features**:
- Validates bookmark number exists
- Creates temporary backup during removal
- Preserves other bookmarks

**Usage Examples**:
```bash
kb_unbookmark 1
kb_unbookmark 3
```

---

## Utility Functions

### `kb_stats()`
**Purpose**: Display comprehensive knowledge base statistics
**Parameters**: None

**Information Displayed**:
- Document count and vocabulary size
- Category breakdown
- File type distribution
- Directory sizes (top 10)
- Bookmark count

**Usage**: `kb_stats`

### `kb_update()`
**Purpose**: Rebuild the entire search index
**Parameters**: None

**Actions**:
- Clears existing index
- Re-scans all documents
- Rebuilds TF-IDF vectors
- Updates statistics

**Usage**: `kb_update`

### `kb_toc()`
**Purpose**: Generate comprehensive table of contents
**Parameters**: None

**Output Files**:
- `dynamic_toc.json` (machine-readable)
- `TABLE_OF_CONTENTS.md` (human-readable)

**Usage**: `kb_toc`

### `kb_help()`
**Purpose**: Display comprehensive help documentation
**Parameters**: None

**Sections**:
- Initialization commands
- Search & lookup commands
- Document management commands
- Bookmark commands
- Information commands
- Usage examples

**Usage**: `kb_help`

---

## Auto-completion System

### `_kb_complete()`
**Purpose**: Provide tab completion for all KB commands
**Features**:
- Command completion for first argument
- File name completion for document operations
- Bookmark number completion for removal
- Pattern-based file suggestions

### `_kb_cli_complete()`
**Purpose**: Auto-completion for the standalone CLI tool
**Location**: `kb_shell_config.sh`

**Supported Commands**:
```bash
init search add remove lookup copy open bookmark bookmarks unbookmark stats update toc help
```

---

## Aliases and Shortcuts

### Command Aliases
```bash
alias kbs='kb_search'      # Search knowledge base
alias kbl='kb_lookup'       # Find documents by name
alias kba='kb_add'          # Add document to KB
alias kbr='kb_remove'       # Remove documents from KB
alias kbc='kb_copy'         # Copy file from KB
alias kbo='kb_open'         # Open document from KB
alias kbb='kb_bookmark'     # Save a bookmark
alias kbu='kb_unbookmark'   # Remove bookmark
alias kbs='kb_stats'        # Show KB statistics
alias kbh='kb_help'         # Show help
```

### Usage Examples
```bash
kbs "docker compose"       # Search for docker compose
kbl "README.md"            # Find README files
kba ./new-doc.md "Notes"   # Add new document
kbb "config.yaml" "Config" # Bookmark config file
kbs                        # Show statistics
```

---

## Error Handling

### Common Error Messages
- `❌ Please provide a search query` - Missing required parameter
- `❌ File not found: /path/to/file` - File doesn't exist
- `❌ No documents found matching: pattern` - No search results
- `❌ Cannot open file: no suitable application found` - No file handler

### Exit Codes
- `0` - Success
- `1` - General error (missing parameters, file not found, etc.)

### Safety Mechanisms
- Confirmation prompts for destructive operations
- Input validation for all parameters
- Graceful fallbacks for missing dependencies
- Temporary file handling for atomic operations

---

## Integration Points

### Shell Integration
The system integrates with bash shells through:
- Function sourcing in `.bashrc`
- Auto-completion registration
- Command aliases
- Welcome message display

### Python Backend Integration
- `simple_rag_knowledge_base.py` - Search engine
- `dynamic_toc.py` - Table of contents generator
- JSON-based communication between bash and Python

### File System Integration
- Works with any file type
- Preserves original file structure
- Supports symbolic links
- Handles special characters in filenames

---

## Performance Considerations

### Indexing Performance
- Initial indexing: O(n) where n = number of documents
- Search queries: O(m) where m = vocabulary size
- Memory usage: Proportional to vocabulary size

### Optimization Features
- Lazy loading of large files
- Caching of frequently accessed data
- Efficient file system operations
- Minimal external dependencies

---

## Security Considerations

### File Access
- Respects file permissions
- No privilege escalation
- Safe handling of special characters
- Input sanitization for shell injection prevention

### Data Privacy
- All data stored locally
- No external network connections
- User-specific bookmark storage
- No telemetry or data collection

---

## Troubleshooting

### Common Issues
1. **Command not found**: Check shell integration and PATH
2. **Permission denied**: Verify file permissions and script executability
3. **Python script errors**: Ensure Python 3 and required packages are installed
4. **Search not working**: Rebuild index with `kb_update`

### Debug Mode
Enable verbose output by setting:
```bash
export KB_DEBUG=1
```

This will provide detailed logging for all operations.
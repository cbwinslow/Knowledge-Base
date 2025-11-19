# Knowledge Base Setup Instructions

## 🚀 Quick Setup

### 1. Add to Your Shell

Add this line to your `~/.bashrc` (or `~/.zshrc` for Zsh):

```bash
# Knowledge Base Management
source "/home/cbwinslow/Knowledge-Base/scripts/documentation/kb_shell_config.sh"
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 2. Initialize Your Knowledge Base

```bash
kb init
```

This will:
- Index all documents in your knowledge base
- Create search database
- Set up bookmarks system

## 📚 Usage Examples

### Search Your Knowledge Base
```bash
# Search for docker-related content
kb search "docker compose"

# Get more results
kb search "python api" 10

# Search within specific category
kb search "kubernetes" 5 infrastructure
```

### Document Management
```bash
# Add a document to your knowledge base
kb add ./important-config.md "Production server configuration"

# Find documents by name
kb lookup "docker"

# Remove documents
kb remove "old-config"

# Copy a document from knowledge base
kb copy "docker-compose.yml" ./production-compose.yml

# Open a document
kb open "README.md"
```

### Bookmarks
```bash
# Bookmark important files
kb bookmark "docker-compose.yml" "Production setup"
kb bookmark "scripts/deploy.sh" "Deployment script"

# List all bookmarks
kb bookmarks

# Remove a bookmark
kb unbookmark 1
```

### Management
```bash
# Show statistics
kb stats

# Update search index
kb update

# Generate table of contents
kb toc

# Show help
kb help
```

## 🎯 Aliases (for convenience)

Once configured, you can use these shortcuts:

```bash
kbs    # kb search
kbl    # kb lookup  
kba    # kb add
kbr    # kb remove
kbc    # kb copy
kbo    # kb open
kbb    # kb bookmark
kbu    # kb unbookmark
kbs    # kb stats
kbh    # kb help
```

## 🔧 Advanced Usage

### Auto-completion

The system includes intelligent auto-completion. Try:
```bash
kb search <TAB>           # Complete with common search terms
kb lookup <TAB>           # Complete with file names
kb bookmark <TAB>        # Complete with file names
kb unbookmark <TAB>      # Complete with bookmark numbers
```

### Integration with Other Tools

```bash
# Search and pipe to other commands
kb search "api" | head -20

# Use in scripts
if kb search "critical error" | grep -q "database"; then
    echo "Found database errors in knowledge base"
fi

# Combine with find
kb lookup $(find . -name "*.md" | head -1)
```

### File Types Supported

The system automatically indexes:
- Markdown files (`.md`)
- Text files (`.txt`)
- Python scripts (`.py`)
- Shell scripts (`.sh`)
- YAML files (`.yaml`, `.yml`)
- JSON files (`.json`)
- PDF files (if pypdf is installed)
- Word documents (if python-docx is installed)

## 📁 File Locations

- **Knowledge Base**: `/home/cbwinslow/Knowledge-Base/`
- **Search Index**: `/home/cbwinslow/Knowledge-Base/simple_rag_db/`
- **Bookmarks**: `~/.kb_bookmarks`
- **Table of Contents**: `/home/cbwinslow/Knowledge-Base/TABLE_OF_CONTENTS.md`

## 🛠️ Troubleshooting

### Command Not Found
If you get "command not found" errors:
1. Make sure you added the config to your shell rc file
2. Reload your shell with `source ~/.bashrc`
3. Check that the files exist: `ls -la /home/cbwinslow/Knowledge-Base/scripts/documentation/`

### Search Not Working
If search returns no results:
1. Run `kb update` to rebuild the index
2. Check that files are text-based
3. Verify files are in the knowledge base directory

### Permission Issues
If you get permission errors:
```bash
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/kb
chmod +x /home/cbwinslow/Knowledge-Base/scripts/documentation/*.py
```

## 🔄 Maintenance

### Regular Updates
```bash
# Update search index weekly
kb update

# Generate new TOC monthly
kb toc

# Clean up old bookmarks (edit ~/.kb_bookmarks manually)
```

### Backup Your Knowledge Base
```bash
# Backup the entire knowledge base
tar -czf kb-backup-$(date +%Y%m%d).tar.gz /home/cbwinslow/Knowledge-Base/

# Backup just the search index and bookmarks
cp -r /home/cbwinslow/Knowledge-Base/simple_rag_db ~/.kb_bookmarks kb-data-backup/
```

## 🎉 Tips

1. **Use descriptive names** when adding documents
2. **Bookmark frequently accessed files** for quick access
3. **Use specific search terms** for better results
4. **Update the index** after adding many files
5. **Generate TOC** to get an overview of your knowledge base

## 📞 Getting Help

- Run `kb help` for command reference
- Check the table of contents: `kb toc` then open the generated file
- Look at the search index stats: `kb stats`
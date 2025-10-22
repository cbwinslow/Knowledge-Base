# Documentation Management System

This directory contains the comprehensive documentation management system for the Knowledge Base repository. The system automatically downloads, organizes, labels, and indexes documentation from various sources.

## Directory Structure

```
documentation/
├── ai_context/      # Documentation formatted for AI agent context
├── examples/        # Working code examples from repositories
├── scraped/         # Documentation scraped from various sources
├── top_100/         # Top 100 documentation results from context7 MCP
├── index.json       # Master index of all documentation
├── labels.json      # Auto-generated labels and categories
└── README.md        # This file
```

## Features

- **Automated Download**: Uses context7 MCP server and crawl4ai to download documentation
- **Smart Labeling**: Automatically categorizes and tags content
- **Example Collection**: Gathers working code examples from repositories
- **Searchable Index**: Creates searchable indices for quick access
- **AI Context Ready**: Formats documentation for AI agent consumption

## Management Scripts

All management scripts are located in `scripts/documentation/`:

### 1. Download Documentation

Downloads documentation from configured sources:

```bash
cd scripts/documentation
python3 download_documentation.py
```

This script:
- Downloads documentation using context7 MCP server
- Scrapes documentation from configured sources using crawl4ai
- Downloads working examples from GitHub repositories
- Organizes content into appropriate directories

### 2. Ingest Knowledge

Processes and indexes downloaded documentation:

```bash
cd scripts/documentation
python3 ingest_knowledge.py
```

This script:
- Scans all documentation directories
- Extracts metadata from files
- Auto-categorizes content
- Creates searchable indices

### 3. Ingest Examples

Processes code examples:

```bash
cd scripts/documentation
python3 ingest_examples.py
```

This script:
- Identifies code example files
- Detects programming languages
- Extracts tags and metadata
- Organizes by language and type

### 4. Label Content

Automatically labels and categorizes content:

```bash
cd scripts/documentation
python3 label_content.py
```

This script:
- Analyzes content quality
- Determines difficulty level
- Assigns categories and tags
- Estimates reading time

### 5. Manage Knowledge Base

Comprehensive management tool:

```bash
cd scripts/documentation

# Search the knowledge base
python3 manage_knowledge_base.py search "docker"

# Show statistics
python3 manage_knowledge_base.py stats

# List categories
python3 manage_knowledge_base.py list categories

# List tags
python3 manage_knowledge_base.py list tags

# Update index
python3 manage_knowledge_base.py update

# Clean up old files
python3 manage_knowledge_base.py cleanup --days 30

# Export metadata
python3 manage_knowledge_base.py export output.json

# Create backup
python3 manage_knowledge_base.py backup /path/to/backup

# Validate integrity
python3 manage_knowledge_base.py validate
```

## Configuration

Configuration is managed through YAML files in `scripts/documentation/`:

### documentation_config.yaml

Main configuration file containing:
- Output directory paths
- Download settings (concurrency, timeouts, retries)
- Crawl4AI settings
- Content filtering rules
- Labeling categories
- Context7 MCP server settings

### sources.yaml

Defines documentation sources:
- Official documentation sites
- Tutorial websites
- API documentation
- Framework documentation
- Database documentation
- GitHub repositories for examples
- Context7 search queries

## Installation

Install required dependencies:

```bash
cd scripts/documentation
pip3 install -r requirements.txt
```

## Usage Workflow

### Initial Setup

1. Install dependencies:
   ```bash
   pip3 install -r scripts/documentation/requirements.txt
   ```

2. Review and customize configuration:
   ```bash
   vim scripts/documentation/documentation_config.yaml
   vim scripts/documentation/sources.yaml
   ```

### Regular Operations

1. **Download new documentation**:
   ```bash
   cd scripts/documentation
   python3 download_documentation.py
   ```

2. **Process and index**:
   ```bash
   python3 ingest_knowledge.py
   python3 ingest_examples.py
   python3 label_content.py
   ```

3. **Search and use**:
   ```bash
   python3 manage_knowledge_base.py search "kubernetes"
   python3 manage_knowledge_base.py stats
   ```

### Maintenance

1. **Update index**:
   ```bash
   python3 manage_knowledge_base.py update
   ```

2. **Clean up old files**:
   ```bash
   python3 manage_knowledge_base.py cleanup --days 30
   ```

3. **Create backup**:
   ```bash
   python3 manage_knowledge_base.py backup ~/backups/
   ```

4. **Validate integrity**:
   ```bash
   python3 manage_knowledge_base.py validate
   ```

## AI Context Documents

The `ai_context/` directory contains documentation specifically formatted for AI agents:

- Structured in a way that's easy for AI to parse
- Includes metadata for context understanding
- Organized by topic and difficulty
- Contains working examples with explanations

## Examples Directory

The `examples/` directory contains:

- Working code examples from repositories
- Organized by programming language
- Tagged by framework and use case
- Includes metadata about each example

## Scraped Documentation

The `scraped/` directory contains:

- Documentation downloaded from official sources
- Organized by source (Python docs, Docker docs, etc.)
- Includes metadata files for each source
- Preserves original structure when possible

## Top 100 Results

The `top_100/` directory contains:

- Top 100 documentation results from context7 MCP server
- High-quality, relevant documentation
- Auto-labeled and categorized
- Regularly updated based on configured queries

## Index Format

The `index.json` file contains:

```json
{
  "generated_at": "2025-10-22T13:00:00Z",
  "total_items": 1500,
  "categories": {
    "tutorial": [...],
    "reference": [...],
    "examples": [...]
  },
  "tags": {
    "python": [...],
    "docker": [...],
    "api": [...]
  },
  "items": [
    {
      "file_path": "documentation/scraped/python/tutorial.md",
      "file_name": "tutorial.md",
      "category": "tutorial",
      "tags": ["python", "beginner"],
      "file_size": 12345,
      "created_at": "2025-10-22T13:00:00Z"
    }
  ]
}
```

## Labels Format

The `labels.json` file contains:

```json
{
  "generated_at": "2025-10-22T13:00:00Z",
  "total_items": 1500,
  "labels": [
    {
      "file_path": "documentation/scraped/python/tutorial.md",
      "categories": ["tutorial", "beginner"],
      "tags": ["python", "basic"],
      "quality_score": 85,
      "difficulty_level": "beginner",
      "estimated_read_time": 10
    }
  ]
}
```

## Troubleshooting

### Issue: Scripts fail to import modules

**Solution**: Install dependencies:
```bash
pip3 install -r scripts/documentation/requirements.txt
```

### Issue: Permission denied when creating directories

**Solution**: Ensure you have write permissions:
```bash
chmod -R u+w documentation/
```

### Issue: Crawl4ai fails to download

**Solution**: Check your internet connection and verify URLs in sources.yaml

### Issue: Index not updating

**Solution**: Manually update the index:
```bash
python3 manage_knowledge_base.py update
```

## Contributing

To add new documentation sources:

1. Edit `scripts/documentation/sources.yaml`
2. Add your source with appropriate metadata
3. Run the download script
4. Process the new content

## Best Practices

1. **Regular Updates**: Run download and ingest scripts weekly
2. **Backup**: Create backups before major updates
3. **Validation**: Run validation after significant changes
4. **Cleanup**: Remove old files periodically
5. **Review Labels**: Manually review auto-generated labels for accuracy

## Future Enhancements

- Integration with more MCP servers
- Enhanced AI context formatting
- Real-time documentation monitoring
- Automated quality scoring
- Multi-language support
- Interactive search interface

## License

Same as the main repository license.

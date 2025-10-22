# Documentation Management System - Quick Start Guide

This guide will help you get started with the documentation management system quickly.

## What This System Does

The documentation management system:
- Downloads documentation from 100+ sources using context7 MCP server and crawl4ai
- Scrapes documentation from official sources (Python, Docker, Kubernetes, etc.)
- Collects working code examples from repositories
- Automatically labels and categorizes all content
- Creates searchable indices for quick access
- Formats documentation for AI agent consumption

## Quick Setup (5 minutes)

### 1. Run Setup Script

```bash
cd scripts/documentation
./setup.sh
```

This will:
- Check Python and pip versions
- Offer to install dependencies
- Show next steps

### 2. Install Dependencies (Optional)

If you skipped installation during setup:

```bash
pip3 install -r requirements.txt
```

### 3. Verify Installation

```bash
python3 test_basic.py
```

You should see all tests pass ✓

## Basic Usage

### Download Documentation

```bash
cd scripts/documentation
python3 download_documentation.py
```

This downloads:
- Top 100 results from context7 MCP server
- Documentation from configured sources
- Working examples from repositories

**Time**: 5-30 minutes depending on sources

### Process Documentation

After downloading, process and index:

```bash
python3 ingest_knowledge.py
python3 ingest_examples.py
python3 label_content.py
```

**Time**: 1-5 minutes

### Search Documentation

```bash
# Search for specific topics
python3 manage_knowledge_base.py search "docker"
python3 manage_knowledge_base.py search "api" --category tutorial

# View statistics
python3 manage_knowledge_base.py stats

# List categories
python3 manage_knowledge_base.py list categories

# List tags
python3 manage_knowledge_base.py list tags
```

## Configuration

### Customize Sources

Edit `sources.yaml` to add/remove documentation sources:

```yaml
sources:
  - name: "Your Source Name"
    url: "https://your-source.com/docs"
    type: "official"
    priority: 1
    categories: ["category1", "category2"]
```

### Adjust Settings

Edit `documentation_config.yaml` to customize:
- Download concurrency and timeouts
- Crawl depth and behavior
- Content filters
- Labeling categories
- Output directories

## Common Tasks

### Update Documentation

```bash
cd scripts/documentation
python3 download_documentation.py
python3 manage_knowledge_base.py update
```

### Clean Up Old Files

```bash
python3 manage_knowledge_base.py cleanup --days 30
```

### Create Backup

```bash
python3 manage_knowledge_base.py backup ~/backups/
```

### Export Metadata

```bash
python3 manage_knowledge_base.py export output.json
```

### Validate System

```bash
python3 manage_knowledge_base.py validate
```

## Directory Structure

After setup, you'll have:

```
documentation/
├── ai_context/          # AI-formatted documentation
├── examples/            # Code examples
│   ├── examples_index.json
│   └── examples_summary.yaml
├── scraped/             # Scraped documentation
│   ├── python_official_docs/
│   ├── docker_docs/
│   └── ...
├── top_100/             # Top 100 from context7
├── index.json           # Master index
├── labels.json          # Auto-generated labels
└── README.md            # Full documentation
```

## Workflow Examples

### Daily Workflow

```bash
# Morning: Update documentation
cd scripts/documentation
python3 download_documentation.py
python3 manage_knowledge_base.py update

# During day: Search as needed
python3 manage_knowledge_base.py search "kubernetes deployment"
```

### Weekly Maintenance

```bash
# Check statistics
python3 manage_knowledge_base.py stats

# Clean up old files
python3 manage_knowledge_base.py cleanup --days 30

# Create backup
python3 manage_knowledge_base.py backup ~/backups/kb_$(date +%Y%m%d)

# Validate integrity
python3 manage_knowledge_base.py validate
```

### Adding New Sources

1. Edit `sources.yaml`:
   ```yaml
   sources:
     - name: "New Documentation"
       url: "https://example.com/docs"
       type: "official"
       priority: 1
       categories: ["web", "api"]
   ```

2. Download and process:
   ```bash
   python3 download_documentation.py
   python3 ingest_knowledge.py
   ```

## Troubleshooting

### Scripts won't run

```bash
# Install dependencies
pip3 install -r requirements.txt

# Make scripts executable
chmod +x *.py

# Run from correct directory
cd scripts/documentation
```

### No results in search

```bash
# Download documentation first
python3 download_documentation.py

# Process and index
python3 ingest_knowledge.py
python3 label_content.py
```

### Import errors

```bash
# Install missing dependencies
pip3 install -r requirements.txt

# Check Python version (needs 3.7+)
python3 --version
```

### Permission errors

```bash
# Fix permissions
chmod -R u+w ../../documentation/
chmod +x *.py
```

## Advanced Features

### Custom Queries for context7

Edit `sources.yaml`:

```yaml
context7_queries:
  - "Your custom query here"
  - "Another specific topic"
```

### Change Number of Results

Edit `documentation_config.yaml`:

```yaml
context7:
  enabled: true
  max_results: 200  # Change from 100 to 200
```

### Adjust Crawl Depth

Edit `documentation_config.yaml`:

```yaml
crawl4ai:
  max_depth: 5  # Increase from 3 to 5
  follow_links: true
```

### Filter Content

Edit `documentation_config.yaml`:

```yaml
filters:
  min_content_length: 500  # Increase minimum
  exclude_extensions:
    - .pdf
    - .zip
    - .your_extension
```

## Help and Documentation

- **Full Documentation**: See [documentation/README.md](../../documentation/README.md)
- **Script Details**: See [README.md](README.md)
- **Configuration Reference**: See `documentation_config.yaml` comments
- **Source Management**: See `sources.yaml` examples

## Getting Help

Run any script with `--help`:

```bash
python3 manage_knowledge_base.py --help
python3 manage_knowledge_base.py search --help
python3 manage_knowledge_base.py list --help
```

## Next Steps

1. ✅ Complete setup
2. ✅ Run test_basic.py
3. 📥 Download documentation
4. 🔍 Search and explore
5. ⚙️ Customize configuration
6. 🔄 Set up regular updates

Enjoy your comprehensive documentation management system!

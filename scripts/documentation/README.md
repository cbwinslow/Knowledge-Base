# Documentation Management Scripts

This directory contains Python scripts for managing the knowledge base documentation system.

## Scripts Overview

### 1. download_documentation.py

**Purpose**: Download documentation from various sources using context7 MCP server and crawl4ai.

**Features**:
- Downloads from context7 MCP server (top 100 results)
- Scrapes documentation using crawl4ai
- Downloads repository examples
- Organizes content into appropriate directories
- Creates metadata files for tracking

**Usage**:
```bash
python3 download_documentation.py
```

**Output**:
- Documentation in `documentation/scraped/`
- Examples in `documentation/examples/`
- Top 100 results in `documentation/top_100/`
- Index file in `documentation/index.json`

---

### 2. ingest_knowledge.py

**Purpose**: Process and index downloaded documentation.

**Features**:
- Scans all documentation directories
- Extracts metadata from files
- Auto-categorizes content (tutorial, reference, guide, etc.)
- Extracts tags based on content
- Creates searchable indices
- Generates summary reports

**Usage**:
```bash
python3 ingest_knowledge.py
```

**Output**:
- Updated `documentation/index.json`
- Summary in `documentation/knowledge_summary.yaml`

---

### 3. ingest_examples.py

**Purpose**: Process and organize code examples.

**Features**:
- Detects programming languages
- Identifies example files
- Extracts metadata and descriptions
- Organizes by language and tags
- Creates examples index

**Usage**:
```bash
python3 ingest_examples.py
```

**Output**:
- `documentation/examples/examples_index.json`
- `documentation/examples/examples_summary.yaml`

---

### 4. label_content.py

**Purpose**: Automatically label and categorize all content.

**Features**:
- Analyzes content quality
- Determines difficulty level
- Assigns categories and tags
- Estimates reading time
- Calculates quality scores

**Usage**:
```bash
python3 label_content.py
```

**Output**:
- `documentation/labels.json`
- `documentation/labels_summary.yaml`

---

### 5. manage_knowledge_base.py

**Purpose**: Comprehensive knowledge base management tool.

**Commands**:

#### Search
```bash
python3 manage_knowledge_base.py search "docker"
python3 manage_knowledge_base.py search "api" --category tutorial
python3 manage_knowledge_base.py search "python" --tags api web
```

#### Statistics
```bash
python3 manage_knowledge_base.py stats
```

#### List Categories/Tags
```bash
python3 manage_knowledge_base.py list categories
python3 manage_knowledge_base.py list tags
```

#### Update Index
```bash
python3 manage_knowledge_base.py update
```

#### Cleanup
```bash
python3 manage_knowledge_base.py cleanup --days 30
```

#### Export
```bash
python3 manage_knowledge_base.py export output.json
python3 manage_knowledge_base.py export output.yaml
```

#### Backup
```bash
python3 manage_knowledge_base.py backup /path/to/backup
```

#### Validate
```bash
python3 manage_knowledge_base.py validate
```

---

## Configuration Files

### documentation_config.yaml

Main configuration file with settings for:
- Output directories
- Download settings (concurrency, timeouts, retries)
- Crawl4AI configuration
- Content filters
- Labeling categories
- Context7 MCP settings
- Knowledge base management

**Key Sections**:
```yaml
output:
  base_dir: "documentation"
  ai_context: "documentation/ai_context"
  examples: "documentation/examples"
  scraped: "documentation/scraped"
  top_100: "documentation/top_100"

download:
  max_concurrent: 5
  timeout: 30
  retry_attempts: 3
  delay_between_requests: 1.0

crawl4ai:
  max_depth: 3
  follow_links: true
  extract_code_blocks: true
```

### sources.yaml

Defines documentation sources:
- Official documentation sites (Python, Docker, Kubernetes, etc.)
- Tutorial and learning sites
- API documentation
- Framework documentation
- Database documentation
- Repository sources for examples
- Context7 search queries

**Structure**:
```yaml
sources:
  - name: "Python Official Docs"
    url: "https://docs.python.org/3/"
    type: "official"
    priority: 1
    categories: ["language", "reference"]

repositories:
  - name: "awesome-python"
    url: "https://github.com/vinta/awesome-python"
    type: "curated-list"
    categories: ["python", "examples"]

context7_queries:
  - "Python best practices documentation"
  - "API design patterns"
```

### requirements.txt

Python dependencies:
- crawl4ai - Web crawling and documentation extraction
- beautifulsoup4 - HTML parsing
- requests - HTTP library
- aiohttp - Async HTTP
- pyyaml - YAML processing
- python-dotenv - Environment variables
- mcp - Model Context Protocol integration
- jsonschema - JSON validation
- gitpython - Git operations
- tqdm - Progress bars
- colorlog - Colored logging

---

## Installation

1. **Install Python dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```

2. **Verify installation**:
   ```bash
   python3 -c "import crawl4ai; import yaml; print('OK')"
   ```

---

## Complete Workflow

### Initial Setup

```bash
# 1. Install dependencies
pip3 install -r requirements.txt

# 2. Customize configuration (optional)
vim documentation_config.yaml
vim sources.yaml

# 3. Create directory structure
cd ../..
mkdir -p documentation/{ai_context,examples,scraped,top_100}
```

### Download and Process

```bash
# 1. Download documentation
python3 download_documentation.py

# 2. Ingest and index
python3 ingest_knowledge.py

# 3. Process examples
python3 ingest_examples.py

# 4. Label content
python3 label_content.py
```

### Search and Use

```bash
# Search for content
python3 manage_knowledge_base.py search "docker"

# View statistics
python3 manage_knowledge_base.py stats

# List categories
python3 manage_knowledge_base.py list categories
```

### Maintenance

```bash
# Update index
python3 manage_knowledge_base.py update

# Clean up old files
python3 manage_knowledge_base.py cleanup --days 30

# Create backup
python3 manage_knowledge_base.py backup ~/backups/kb_$(date +%Y%m%d)

# Validate integrity
python3 manage_knowledge_base.py validate
```

---

## Script Architecture

### Common Patterns

All scripts follow similar patterns:

1. **Configuration Loading**: Load YAML configuration
2. **Initialization**: Set up paths and logging
3. **Processing**: Core functionality
4. **Output**: Save results and metadata
5. **Logging**: Comprehensive logging throughout

### Error Handling

- Graceful degradation on individual file failures
- Comprehensive error logging
- Continue processing on non-fatal errors
- Summary of successes and failures

### Extensibility

Scripts are designed to be extended:
- Add new sources in `sources.yaml`
- Customize categories in `documentation_config.yaml`
- Modify tag extraction patterns
- Add new content filters

---

## Development

### Adding New Features

1. **New Source Type**:
   - Add source to `sources.yaml`
   - Update `download_documentation.py` if needed
   - Test with a single source first

2. **New Category**:
   - Add to `documentation_config.yaml` labels section
   - Update categorization logic in `label_content.py`
   - Run labeling on existing content

3. **New Tag Pattern**:
   - Update `_extract_tags()` method
   - Add keywords to pattern matching
   - Re-run labeling script

### Testing

```bash
# Test download with limited sources
python3 download_documentation.py  # Add --test flag if implemented

# Test ingestion
python3 ingest_knowledge.py

# Validate results
python3 manage_knowledge_base.py validate

# Check statistics
python3 manage_knowledge_base.py stats
```

### Debugging

Enable debug logging:
```python
logging.basicConfig(level=logging.DEBUG)
```

Or via environment variable:
```bash
export LOG_LEVEL=DEBUG
python3 download_documentation.py
```

---

## Troubleshooting

### Common Issues

**Issue**: Import errors
```bash
# Solution: Install dependencies
pip3 install -r requirements.txt
```

**Issue**: Permission denied
```bash
# Solution: Fix permissions
chmod +x *.py
chmod -R u+w ../../documentation/
```

**Issue**: Config file not found
```bash
# Solution: Run from scripts/documentation directory
cd scripts/documentation
python3 manage_knowledge_base.py stats
```

**Issue**: Empty results
```bash
# Solution: Check configuration and sources
vim sources.yaml  # Verify URLs are correct
python3 download_documentation.py  # Re-download
```

---

## Performance Optimization

### For Large Downloads

```yaml
# In documentation_config.yaml
download:
  max_concurrent: 10  # Increase concurrent downloads
  timeout: 60         # Increase timeout for large files
```

### For Large Repositories

```python
# Limit depth when crawling
crawl4ai:
  max_depth: 2  # Reduce from 3 to 2
```

### For Processing

- Process directories in parallel (future enhancement)
- Cache results to avoid reprocessing
- Use incremental updates instead of full re-indexing

---

## Best Practices

1. **Regular Updates**: Run weekly or bi-weekly
2. **Incremental Processing**: Process new content only when possible
3. **Validation**: Always validate after major changes
4. **Backup**: Regular backups before updates
5. **Monitoring**: Check logs for errors
6. **Configuration**: Keep configuration in version control
7. **Documentation**: Update README when adding features

---

## Future Enhancements

- [ ] Parallel processing for better performance
- [ ] Incremental updates (only new/changed content)
- [ ] Web interface for search and browse
- [ ] Integration with more MCP servers
- [ ] Real-time monitoring of documentation sources
- [ ] Automatic quality improvement suggestions
- [ ] Multi-language support
- [ ] Docker containerization
- [ ] API for programmatic access
- [ ] Scheduled automated updates

---

## Contributing

To contribute:

1. Test your changes thoroughly
2. Update documentation
3. Follow existing code style
4. Add logging for new features
5. Handle errors gracefully

---

## License

Same as the main repository license.

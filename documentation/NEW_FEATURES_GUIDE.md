# Knowledge Base - New Features Guide

This guide covers the new features added to enhance the Knowledge Base with web crawling, deep research, deployment automation, and ZSH integration.

## Table of Contents

1. [Web Crawling with Crawl4AI](#web-crawling)
2. [Deep Research Framework](#deep-research)
3. [ZSH Functions for Easy Management](#zsh-functions)
4. [Deployment Scripts](#deployment)
5. [Installation](#installation)
6. [Usage Examples](#usage-examples)

---

## Web Crawling

The `web_crawler.py` script integrates Crawl4AI to crawl websites and automatically add content to your knowledge base.

### Features

- Single URL or multiple URL crawling
- Sitemap-based bulk crawling
- Automatic content extraction and cleaning
- Markdown conversion
- Screenshot capture
- Automatic categorization
- Metadata tracking

### Usage

```bash
# Crawl a single URL
python3 scripts/documentation/web_crawler.py url "https://example.com" -c technology

# Crawl multiple URLs
python3 scripts/documentation/web_crawler.py multi "https://site1.com" "https://site2.com" -c research

# Crawl from a file of URLs
python3 scripts/documentation/web_crawler.py file urls.txt -c documentation

# Crawl entire sitemap
python3 scripts/documentation/web_crawler.py sitemap "https://example.com/sitemap.xml" -c docs

# Generate index of crawled content
python3 scripts/documentation/web_crawler.py index
```

### Output Structure

```
documentation/
  crawled/
    technology/
      example_com_article_20251030_120000.md
      example_com_article_20251030_120000.png  (if screenshots enabled)
    metadata/
      example_com_article_20251030_120000.md.json
    index.json
```

---

## Deep Research Framework

The `deep_research.py` script performs comprehensive AI-powered research on any topic and generates detailed reports.

### Features

- Multi-source research synthesis
- Automated key findings extraction
- Related topic discovery
- Citation tracking
- Configurable research depth
- Markdown report generation

### Usage

```bash
# Quick research
python3 scripts/documentation/deep_research.py "Docker containers" -d quick

# Medium depth research (default)
python3 scripts/documentation/deep_research.py "Kubernetes architecture"

# Deep research with more sources
python3 scripts/documentation/deep_research.py "AI agent frameworks" -d deep -s 20
```

### Research Depth Levels

- **quick**: Fast overview with 5 sources
- **medium**: Balanced research with 10 sources (default)
- **deep**: Comprehensive analysis with 15+ sources

### Output Structure

```
documentation/
  research/
    reports/
      ai_agent_frameworks_20251030_120000.md
      ai_agent_frameworks_20251030_120000.md.json
    sources/
```

---

## ZSH Functions

Enhanced ZSH functions for seamless knowledge base management from your terminal.

### Installation

```bash
# Copy the functions file
cp dotfiles/zsh/zsh_kb_functions ~/.zsh_kb_functions

# Add to your .zshrc
echo "source ~/.zsh_kb_functions" >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Available Functions

#### Basic Operations

```bash
# Add a file to knowledge base
kb_add ~/document.pdf research

# Add an entire folder
kb_add_folder ~/projects/docs devops

# Create a quick note
kb_note "Docker tips" infrastructure

# Search knowledge base
kb_search "kubernetes"

# List categories
kb_list

# List files in category
kb_list research

# Show status
kb_status
```

#### Git Operations

```bash
# Quick commit
kb_commit "Added new documentation"

# Push to remote
kb_push

# Pull from remote
kb_pull
```

#### Advanced Features

```bash
# Crawl a website
kb_crawl https://kubernetes.io/docs technology

# Perform deep research
kb_research "CI/CD pipelines" deep

# Generate documentation for a file
kb_doc ~/scripts/deploy.sh

# Sync to Dell server
kb_sync_dell

# Deploy to Cloudflare
kb_deploy_cloudflare
```

### Configuration

Set these environment variables in your `.zshrc`:

```bash
export KB_ROOT="$HOME/Knowledge-Base"          # Knowledge base location
export KB_DELL_SERVER="dell.cloudcurio.local"  # Dell server hostname
export KB_DELL_PATH="/opt/knowledge-base"      # Remote path on Dell server
```

---

## Deployment

### Deploy to Dell Server

Deploy your knowledge base to a Dell server in your Cloudcurio environment:

```bash
# Basic deployment
scripts/deployment/deploy_dell_server.sh -s dell.cloudcurio.local

# With custom user and path
scripts/deployment/deploy_dell_server.sh \
  --server 192.168.1.100 \
  --user admin \
  --path /opt/kb

# Dry run to see what would happen
scripts/deployment/deploy_dell_server.sh --dry-run

# Deploy without Docker
scripts/deployment/deploy_dell_server.sh --no-docker
```

#### Features

- Automatic file syncing via rsync
- Docker Compose deployment
- Systemd service setup
- Post-deployment hooks
- Configuration persistence

### Deploy to Cloudflare Pages

Deploy to Cloudflare Pages for global CDN hosting:

```bash
# Deploy main branch (automatic via Git)
scripts/deployment/deploy_cloudflare.sh

# Deploy specific branch
scripts/deployment/deploy_cloudflare.sh --branch develop

# Direct deployment with Wrangler
scripts/deployment/deploy_cloudflare.sh --direct

# Dry run
scripts/deployment/deploy_cloudflare.sh --dry-run
```

#### Features

- Automatic GitHub integration
- Direct deployment via Wrangler
- Custom domain support
- Environment variable management
- Build configuration

---

## Installation

### Prerequisites

```bash
# Python 3.9+
python3 --version

# Install Python dependencies
pip install -r requirements.txt

# Install crawl4ai (for web crawling)
pip install crawl4ai

# Install Playwright browsers (required by crawl4ai)
playwright install

# Install Wrangler (for Cloudflare direct deploy)
npm install -g wrangler
```

### Updated Requirements

Add to `scripts/documentation/requirements.txt`:

```
crawl4ai>=0.1.0
playwright>=1.40.0
openai>=1.3.0
aiohttp>=3.9.0
loguru>=0.7.0
tenacity>=8.2.0
```

### Environment Variables

Create a `.env` file in the repository root:

```bash
# OpenAI (for deep research)
OPENAI_API_KEY=sk-...

# Cloudflare (for direct deploy)
CLOUDFLARE_API_TOKEN=...

# Dell Server (optional, can be set in ZSH)
DELL_SERVER=dell.cloudcurio.local
DELL_USER=your_username
DELL_PATH=/opt/knowledge-base
```

---

## Usage Examples

### Complete Workflow Example

```bash
# 1. Research a topic
python3 scripts/documentation/deep_research.py "Docker Swarm vs Kubernetes"

# 2. Crawl documentation
python3 scripts/documentation/web_crawler.py url \
  "https://kubernetes.io/docs/concepts/" -c kubernetes

# 3. Add your own notes
kb_note "Comparison insights" architecture

# 4. Search for related content
kb_search "orchestration"

# 5. Commit changes
kb_commit "Added container orchestration research"

# 6. Deploy to Dell server
kb_sync_dell

# 7. Deploy to Cloudflare
kb_deploy_cloudflare
```

### Automated Research Pipeline

Create a research pipeline script:

```bash
#!/bin/bash
# research_pipeline.sh

TOPICS=(
    "microservices architecture"
    "service mesh"
    "API gateway patterns"
)

for topic in "${TOPICS[@]}"; do
    echo "Researching: $topic"
    python3 scripts/documentation/deep_research.py "$topic" -d medium
    sleep 5  # Rate limiting
done

# Generate index
python3 scripts/documentation/web_crawler.py index

# Commit results
kb_commit "Automated research pipeline: $(date)"
```

### Weekly Documentation Update

Create a cron job:

```bash
# Add to crontab: crontab -e
# Run every Sunday at 2 AM
0 2 * * 0 /path/to/knowledge-base/scripts/weekly_update.sh
```

Script content:

```bash
#!/bin/bash
# weekly_update.sh

cd /path/to/knowledge-base

# Crawl documentation sites
cat urls.txt | while read url; do
    python3 scripts/documentation/web_crawler.py url "$url" -c weekly
done

# Generate index
python3 scripts/documentation/web_crawler.py index

# Commit and push
kb_commit "Weekly documentation update: $(date)"
kb_push

# Deploy to servers
kb_sync_dell
kb_deploy_cloudflare
```

---

## Troubleshooting

### Web Crawler Issues

```bash
# If crawl4ai fails to install
pip install --upgrade pip
pip install 'crawl4ai[all]'
playwright install chromium

# If rate limited
# Add delays between requests in the script
# Or use a proxy
```

### Deep Research Issues

```bash
# If OpenAI API fails
# Check API key
echo $OPENAI_API_KEY

# Check API quota
# Visit https://platform.openai.com/account/usage

# Use alternative models
# Edit deep_research.py and change model to "gpt-3.5-turbo"
```

### Deployment Issues

```bash
# Dell server connection
# Test SSH
ssh user@dell.cloudcurio.local

# Check rsync
rsync --version

# Cloudflare deployment
# Check git remote
git remote -v

# Test Wrangler auth
wrangler whoami
```

---

## Advanced Configuration

### Custom Crawl Filters

Edit `web_crawler.py` to customize content extraction:

```python
# Add custom exclusions
crawler_config = CrawlerRunConfig(
    exclude_external_links=True,
    exclude_social_media_links=True,
    exclude_selectors=['.ads', '.sidebar', '.footer'],
    word_count_threshold=50
)
```

### Custom Research Prompts

Edit `deep_research.py` to customize research behavior:

```python
# Modify synthesis prompt
prompt = f"""
Analyze {topic} with focus on:
1. Practical applications
2. Security considerations  
3. Performance implications
4. Cost analysis
...
"""
```

### Custom ZSH Aliases

Add to your `.zshrc`:

```bash
alias kba='kb_add'
alias kbn='kb_note'
alias kbs='kb_search'
alias kbc='kb_commit'
alias kbp='kb_push'
alias kbstat='kb_status'
```

---

## Contributing

To add new features:

1. Follow existing code patterns
2. Add documentation to this guide
3. Include usage examples
4. Test thoroughly
5. Submit a pull request

---

## Support

For issues or questions:

1. Check troubleshooting section above
2. Review logs in `logs/` directory
3. Check GitHub issues
4. Create a new issue with details

---

## License

See main repository LICENSE file.

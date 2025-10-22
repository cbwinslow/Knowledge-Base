# Knowledge Base

This repository contains documentation, scripts, and configurations for server setup and management, including AI agent memories, rules, dotfiles, and various configuration files.

## Directories

- [scripts](scripts/) - Organized collection of utility scripts
- [master_documents](master_documents/) - Core documentation and setup files


## Master Documents

The [master_documents](master_documents/) directory contains:

- [install_scripts](master_documents/install_scripts/) - Installation scripts and documentation
- [configuration_files](master_documents/configuration_files/) - Configuration files used in the setup
- [reports](master_documents/reports/) - System reports and analysis tools
- [logs](master_documents/logs/) - Log management and centralization
- [ai_services](master_documents/ai_services/) - AI services setup and configuration

## AI Agents & Configuration Management

The repository includes automated workflows and tools for managing AI configurations:

### AI Agents
- **[memories](ai_agents/memories/)** - Store and retrieve AI agent memories
- **[rules](ai_agents/rules/)** - Define and manage AI agent rules
- **[crews](ai_agents/crews/)** - CrewAI crew configurations

### Dotfiles
- **[bash](dotfiles/bash/)** - Bash configurations, functions, and aliases
- **[zsh](dotfiles/zsh/)** - Zsh configurations, functions, and aliases

### Infrastructure
- **[mcp_servers](mcp_servers/)** - Model Context Protocol server configs
- **[docker_configs](docker_configs/)** - Docker Compose and container configs

### GitHub Workflows

Use these workflows to save configurations:
- `save-ai-memory.yml` - Save AI agent memories
- `save-ai-rule.yml` - Save AI agent rules
- `save-dotfile.yml` - Save shell dotfiles
- `save-docker-config.yml` - Save Docker configurations
- `save-mcp-server.yml` - Save MCP server configs
- `save-crew-config.yml` - Save CrewAI crew configs

### CLI Tool

Use the `kb_manager.sh` script for quick access:

```bash
# Save a memory
./scripts/utilities/kb_manager.sh memory "topic_name" "content here"

# Save a rule
./scripts/utilities/kb_manager.sh rule "rule_name" "rule content"

# Search content
./scripts/utilities/kb_manager.sh search "docker"

# List items
./scripts/utilities/kb_manager.sh list memories

# Recall content
./scripts/utilities/kb_manager.sh recall ai_agents/memories/file.md
```

## Scripts

The [scripts](scripts/) directory contains organized scripts by category:

- [AI Monitoring](scripts/ai_monitoring/) - Scripts for AI monitoring and related tools
- [Database](scripts/database/) - Scripts for database management and configuration
- [Deployment](scripts/deployment/) - Scripts for system deployment and setup
- [Documentation](scripts/documentation/) - Documentation management and knowledge base scripts
- [Networking](scripts/networking/) - Scripts for networking configuration
- [Storage](scripts/storage/) - Scripts for storage management
- [Utilities](scripts/utilities/) - Various utility scripts including kb_manager.sh

## Documentation Management System

The [documentation](documentation/) directory contains a comprehensive documentation management system:

- **Automated Download**: Uses context7 MCP server and crawl4ai to download documentation
- **Smart Organization**: Automatically categorizes and labels content
- **Code Examples**: Collects working examples from repositories
- **AI Context Ready**: Formats documentation for AI agent consumption
- **Searchable Index**: Creates searchable indices for quick access

### Key Features

- Downloads documentation from top 100 sources using context7 MCP server
- Scrapes documentation using crawl4ai from configured sources
- Collects working code examples from repositories
- Auto-labels and categorizes all content
- Creates searchable indices and metadata
- Provides comprehensive management tools

### Quick Start

```bash
# Install dependencies
cd scripts/documentation
pip3 install -r requirements.txt

# Download documentation
python3 download_documentation.py

# Process and index
python3 ingest_knowledge.py
python3 ingest_examples.py
python3 label_content.py

# Search and manage
python3 manage_knowledge_base.py search "docker"
python3 manage_knowledge_base.py stats
```

See [documentation/README.md](documentation/README.md) for detailed information.

## Getting Started

1. Review the documentation in [master_documents](master_documents/)
2. Use the report scripts in [master_documents/reports](master_documents/reports/) to gather system information
3. Set up log centralization using the scripts in [master_documents/logs](master_documents/logs/)
4. Install AI services using the configurations in [master_documents/ai_services](master_documents/ai_services/)

## Contributing

Feel free to contribute by adding new scripts, updating documentation, or improving existing tools.

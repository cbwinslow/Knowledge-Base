# Knowledge Base

This repository contains documentation, scripts, and configurations for the server setup and management.

## Directories

- [scripts](scripts/) - Organized collection of utility scripts
- [master_documents](master_documents/) - Core documentation and setup files
- [documentation](documentation/) - Comprehensive documentation management system

## Master Documents

The [master_documents](master_documents/) directory contains:

- [install_scripts](master_documents/install_scripts/) - Installation scripts and documentation
- [configuration_files](master_documents/configuration_files/) - Configuration files used in the setup
- [reports](master_documents/reports/) - System reports and analysis tools
- [logs](master_documents/logs/) - Log management and centralization
- [ai_services](master_documents/ai_services/) - AI services setup and configuration

## Scripts

The [scripts](scripts/) directory contains organized scripts by category:

- [AI Monitoring](scripts/ai_monitoring/) - Scripts for AI monitoring and related tools
- [Database](scripts/database/) - Scripts for database management and configuration
- [Deployment](scripts/deployment/) - Scripts for system deployment and setup
- [Documentation](scripts/documentation/) - Documentation management and knowledge base scripts
- [Networking](scripts/networking/) - Scripts for networking configuration
- [Storage](scripts/storage/) - Scripts for storage management
- [Utilities](scripts/utilities/) - Various utility scripts

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

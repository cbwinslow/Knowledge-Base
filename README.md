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

The [documentation](documentation/) directory contains a comprehensive documentation management system with extensive examples and guides:

### Structure

```
documentation/
├── examples/           # Production-ready code examples
│   ├── shell-scripts/ # Shell scripting best practices
│   └── python/        # Python examples (API, AI, automation)
├── how-to-guides/     # Step-by-step tutorials
├── troubleshooting-guide.md  # Comprehensive troubleshooting
└── README.md
```

### Code Examples

**Shell Scripts** ([examples/shell-scripts](documentation/examples/shell-scripts/))
- Production-ready database backup script
- Best practices and patterns
- Error handling and logging
- Complete with documentation

**Python Examples** ([examples/python](documentation/examples/python/))
- **AI Integration**: OpenAI, Anthropic, Ollama, LangChain
- **REST APIs**: Complete FastAPI application with auth
- **Automation**: System monitoring, file processing
- Production-ready patterns and best practices

### Docker Compose Examples

**Available Stacks** ([docker_configs/compose](docker_configs/compose/))
- **PostgreSQL**: Full setup with pgAdmin, backups, monitoring
- **Redis**: Cache setup with Redis Commander
- **Nginx**: Reverse proxy with SSL, load balancing
- **MongoDB**: Database with Mongo Express interface

Each includes:
- docker-compose.yml configuration
- Environment variable templates
- Comprehensive README with usage examples
- Production best practices
- Troubleshooting guides

### How-To Guides

**Available Guides** ([documentation/how-to-guides](documentation/how-to-guides/))
1. [Setting Up Production PostgreSQL](documentation/how-to-guides/setup-postgresql-production.md)
2. [Docker Compose Deployment](documentation/how-to-guides/docker-compose-deployment.md)
3. [Integrating LLMs in Your Application](documentation/how-to-guides/llm-integration.md)

Each guide includes:
- Step-by-step instructions
- Code examples and configurations
- Verification steps
- Troubleshooting section
- Production checklist

### Troubleshooting

See the [Troubleshooting Guide](documentation/troubleshooting-guide.md) for:
- Common Docker issues
- Database connection problems
- API and networking issues
- Performance optimization
- Debug commands and tools

### Key Features

- **Production-Ready Examples**: All code is tested and follows best practices
- **Comprehensive Documentation**: Each example includes full documentation
- **Real-World Patterns**: Error handling, logging, monitoring, security
- **Multiple Languages**: Shell, Python, YAML, SQL examples
- **Copy-Paste Ready**: Examples can be used directly in your projects

### Quick Start with Examples

```bash
# Use PostgreSQL stack
cd docker_configs/compose/postgresql
cp .env.example .env
docker-compose up -d

# Try Python LLM integration
cd documentation/examples/python/ai-integration
python llm-examples.py

# Run system monitoring
cd documentation/examples/python/automation
python system-monitoring.py
```

See [documentation/README.md](documentation/README.md) for detailed information about the documentation management system.

## Getting Started

1. Review the documentation in [master_documents](master_documents/)
2. Use the report scripts in [master_documents/reports](master_documents/reports/) to gather system information
3. Set up log centralization using the scripts in [master_documents/logs](master_documents/logs/)
4. Install AI services using the configurations in [master_documents/ai_services](master_documents/ai_services/)

## Contributing

Feel free to contribute by adding new scripts, updating documentation, or improving existing tools.

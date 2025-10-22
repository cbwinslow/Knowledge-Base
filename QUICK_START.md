# Quick Start Guide

Get started with the Knowledge Base AI agent workflows in minutes!

## Overview

This repository helps you store and manage:
- 🧠 AI agent memories and learnings
- 📋 AI agent rules and guidelines
- 🤖 CrewAI crew configurations
- 🔧 Dotfiles (bash/zsh configs)
- 🐳 Docker configurations
- 🔌 MCP server configurations

## Quick Examples

### 1. Save an AI Memory

Using GitHub CLI:
```bash
gh workflow run save-ai-memory.yml \
  -f memory_name="docker_tips" \
  -f content="Always use multi-stage builds for smaller images" \
  -f tags="docker,optimization"
```

Using the CLI tool:
```bash
./scripts/utilities/kb_manager.sh memory "docker_tips" "Always use multi-stage builds"
```

### 2. Save an AI Rule

```bash
gh workflow run save-ai-rule.yml \
  -f rule_name="security" \
  -f content="Never commit secrets or API keys" \
  -f priority="High"
```

### 3. Save Your Dotfiles

```bash
gh workflow run save-dotfile.yml \
  -f shell="bash" \
  -f file_type="aliases" \
  -f content="$(cat ~/.bash_aliases)"
```

### 4. Search Your Knowledge Base

```bash
./scripts/utilities/kb_manager.sh search "docker"
```

### 5. List All Memories

```bash
./scripts/utilities/kb_manager.sh list memories
```

### 6. Recall a Memory

```bash
./scripts/utilities/kb_manager.sh recall ai_agents/memories/docker_tips_20251022_140000.md
```

## Directory Structure

```
Knowledge-Base/
├── ai_agents/
│   ├── memories/          # AI memories with timestamps
│   ├── rules/             # AI rules and guidelines
│   └── crews/             # CrewAI configurations
├── dotfiles/
│   ├── bash/              # Bash configs, functions, aliases
│   └── zsh/               # Zsh configs, functions, aliases
├── mcp_servers/           # MCP server configurations
└── docker_configs/        # Docker and compose files
```

## Available Workflows

1. **save-ai-memory.yml** - Save AI agent memories
2. **save-ai-rule.yml** - Save AI agent rules
3. **save-dotfile.yml** - Save shell configurations
4. **save-docker-config.yml** - Save Docker configs
5. **save-mcp-server.yml** - Save MCP server configs
6. **save-crew-config.yml** - Save CrewAI crew configs

## CLI Tool Commands

```bash
# Save commands
./scripts/utilities/kb_manager.sh memory <name> <content>
./scripts/utilities/kb_manager.sh rule <name> <content>

# Search and retrieve
./scripts/utilities/kb_manager.sh search <query>
./scripts/utilities/kb_manager.sh list <category>
./scripts/utilities/kb_manager.sh recall <path>

# Categories: memories, rules, crews, dotfiles, docker, mcp
```

## Setup GitHub CLI (Optional)

If you don't have GitHub CLI:

```bash
# Install GitHub CLI
brew install gh  # macOS
# or
sudo apt install gh  # Ubuntu/Debian

# Authenticate
gh auth login
```

## Next Steps

1. Read the full documentation: [AI_AGENT_WORKFLOWS.md](AI_AGENT_WORKFLOWS.md)
2. Explore examples: Check the `example_*` files in each directory
3. Customize: Modify workflows and scripts for your needs
4. Integrate: Connect your AI agents to use these workflows

## Security Notes

⚠️ **Important:**
- Never commit actual secrets
- Use `.example` files as templates
- Real secret files are automatically ignored
- Review changes before pushing

## Getting Help

- Full documentation: [AI_AGENT_WORKFLOWS.md](AI_AGENT_WORKFLOWS.md)
- Main README: [README.md](README.md)
- Directory READMEs: Each directory has its own README

## Tips

💡 **Pro Tips:**
- Use tags when saving memories for easy searching
- Set priority on rules (High/Medium/Low)
- Test with examples before using with real data
- Keep descriptions clear and searchable
- Commit changes regularly

---

Happy organizing! 🚀

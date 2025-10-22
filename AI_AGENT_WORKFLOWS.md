# AI Agent Workflows Documentation

This document provides comprehensive information about using the AI agent workflows and configuration management system in this repository.

## Overview

This repository provides automated workflows and tools for AI agents to store and manage:
- Memories and learnings
- Rules and guidelines
- CrewAI crew configurations
- Dotfiles (bashrc, zshrc, functions, aliases)
- MCP (Model Context Protocol) server configurations
- Docker and container configurations

## Table of Contents

1. [Quick Start](#quick-start)
2. [GitHub Actions Workflows](#github-actions-workflows)
3. [CLI Management Tool](#cli-management-tool)
4. [Directory Structure](#directory-structure)
5. [Usage Examples](#usage-examples)
6. [Best Practices](#best-practices)
7. [Security Considerations](#security-considerations)

## Quick Start

### Using GitHub Actions Workflows

Trigger workflows using GitHub CLI:

```bash
# Save an AI memory
gh workflow run save-ai-memory.yml \
  -f memory_name="python_debugging" \
  -f content="Always check virtual environment is activated" \
  -f agent_name="CodeAssistant" \
  -f tags="python,debugging,tips"

# Save an AI rule
gh workflow run save-ai-rule.yml \
  -f rule_name="code_quality" \
  -f content="Write unit tests for all new functions" \
  -f priority="High" \
  -f applies_to="All coding agents"
```

### Using the CLI Tool

```bash
# Navigate to the repository
cd /path/to/Knowledge-Base

# Save a memory
./scripts/utilities/kb_manager.sh memory "topic" "content"

# Search for content
./scripts/utilities/kb_manager.sh search "docker"

# List all memories
./scripts/utilities/kb_manager.sh list memories
```

## GitHub Actions Workflows

### 1. Save AI Memory (`save-ai-memory.yml`)

Saves AI agent memories with timestamps.

**Inputs:**
- `memory_name` (required) - Name for the memory
- `content` (required) - Memory content
- `agent_name` (optional) - Name of the AI agent
- `tags` (optional) - Comma-separated tags

**Example:**
```bash
gh workflow run save-ai-memory.yml \
  -f memory_name="deployment_tips" \
  -f content="Always backup database before deployment" \
  -f agent_name="DeployBot" \
  -f tags="deployment,database,safety"
```

**Output:** Creates `ai_agents/memories/deployment_tips_YYYYMMDD_HHMMSS.md`

### 2. Save AI Rule (`save-ai-rule.yml`)

Creates or updates AI agent rules.

**Inputs:**
- `rule_name` (required) - Name for the rule file
- `content` (required) - Rule content
- `priority` (optional) - High/Medium/Low
- `applies_to` (optional) - What the rule applies to

**Example:**
```bash
gh workflow run save-ai-rule.yml \
  -f rule_name="security_rules" \
  -f content="Never commit secrets or API keys" \
  -f priority="High" \
  -f applies_to="All agents"
```

**Output:** Creates/updates `ai_agents/rules/security_rules.md`

### 3. Save Dotfile (`save-dotfile.yml`)

Saves shell configuration files.

**Inputs:**
- `shell` (required) - bash or zsh
- `file_type` (required) - rc, functions, aliases, or profile
- `content` (required) - File content
- `is_example` (optional) - Save as template

**Example:**
```bash
gh workflow run save-dotfile.yml \
  -f shell="bash" \
  -f file_type="aliases" \
  -f content="$(cat ~/.bash_aliases)" \
  -f is_example=false
```

**Output:** Creates/updates `dotfiles/bash/bash_aliases`

### 4. Save Docker Config (`save-docker-config.yml`)

Saves Docker and container configurations.

**Inputs:**
- `config_name` (required) - Configuration name
- `config_type` (required) - compose, dockerfile, volume, or network
- `content` (required) - Configuration content

**Example:**
```bash
gh workflow run save-docker-config.yml \
  -f config_name="myapp" \
  -f config_type="compose" \
  -f content="$(cat docker-compose.yml)"
```

**Output:** Creates `docker_configs/compose/myapp/docker-compose.yml`

### 5. Save MCP Server (`save-mcp-server.yml`)

Saves Model Context Protocol server configurations.

**Inputs:**
- `server_name` (required) - MCP server name
- `file_name` (required) - File to save (e.g., config.json)
- `content` (required) - File content

**Example:**
```bash
gh workflow run save-mcp-server.yml \
  -f server_name="filesystem_server" \
  -f file_name="config.json" \
  -f content="$(cat config.json)"
```

**Output:** Creates `mcp_servers/filesystem_server/config.json`

### 6. Save CrewAI Config (`save-crew-config.yml`)

Saves CrewAI crew configurations.

**Inputs:**
- `crew_name` (required) - Crew name
- `file_name` (required) - File to save (e.g., crew_config.yaml)
- `content` (required) - File content

**Example:**
```bash
gh workflow run save-crew-config.yml \
  -f crew_name="research_crew" \
  -f file_name="agents.yaml" \
  -f content="$(cat agents.yaml)"
```

**Output:** Creates `ai_agents/crews/research_crew/agents.yaml`

## CLI Management Tool

The `kb_manager.sh` script provides a convenient command-line interface.

### Commands

#### Save Memory
```bash
./scripts/utilities/kb_manager.sh memory "topic_name" "memory content"
```

#### Save Rule
```bash
./scripts/utilities/kb_manager.sh rule "rule_name" "rule content"
```

#### Save Dotfile
```bash
./scripts/utilities/kb_manager.sh dotfile bash aliases ~/.bash_aliases
```

#### Search Content
```bash
./scripts/utilities/kb_manager.sh search "docker"
./scripts/utilities/kb_manager.sh search "python debugging"
```

#### List Items
```bash
./scripts/utilities/kb_manager.sh list memories
./scripts/utilities/kb_manager.sh list rules
./scripts/utilities/kb_manager.sh list crews
./scripts/utilities/kb_manager.sh list dotfiles
./scripts/utilities/kb_manager.sh list docker
./scripts/utilities/kb_manager.sh list mcp
```

#### Recall Content
```bash
./scripts/utilities/kb_manager.sh recall ai_agents/memories/python_tips_20251022_140000.md
./scripts/utilities/kb_manager.sh recall ai_agents/rules/code_quality.md
```

## Directory Structure

```
Knowledge-Base/
├── ai_agents/
│   ├── memories/           # AI agent memories with timestamps
│   ├── rules/              # AI agent rules and guidelines
│   └── crews/              # CrewAI crew configurations
│       └── [crew_name]/
│           ├── crew_config.yaml
│           ├── agents.yaml
│           └── tasks.yaml
├── dotfiles/
│   ├── bash/
│   │   ├── bashrc
│   │   ├── bash_functions
│   │   ├── bash_aliases
│   │   └── bash_secrets.example
│   └── zsh/
│       ├── zshrc
│       ├── zsh_functions
│       ├── zsh_aliases
│       └── zsh_secrets.example
├── mcp_servers/
│   └── [server_name]/
│       ├── config.json
│       ├── server.py
│       └── requirements.txt
├── docker_configs/
│   ├── compose/
│   │   └── [app_name]/
│   │       └── docker-compose.yml
│   ├── dockerfiles/
│   │   └── Dockerfile.[app_name]
│   ├── volumes/
│   └── networks/
└── scripts/
    └── utilities/
        └── kb_manager.sh
```

## Usage Examples

### Example 1: AI Agent Learning System

An AI agent learns something new and saves it:

```bash
# Save the learning
gh workflow run save-ai-memory.yml \
  -f memory_name="kubernetes_deployment" \
  -f content="Use kubectl apply -f instead of create for idempotent deployments" \
  -f agent_name="DevOpsAgent" \
  -f tags="kubernetes,deployment,best-practices"

# Later, search for it
./scripts/utilities/kb_manager.sh search "kubernetes"
```

### Example 2: Establishing AI Agent Rules

Define rules for AI agent behavior:

```bash
# Create a security rule
gh workflow run save-ai-rule.yml \
  -f rule_name="api_security" \
  -f content="1. Always validate input\n2. Use HTTPS only\n3. Implement rate limiting" \
  -f priority="High"

# Create a code style rule
gh workflow run save-ai-rule.yml \
  -f rule_name="python_style" \
  -f content="Follow PEP 8 standards for all Python code" \
  -f priority="Medium"
```

### Example 3: Dotfile Management

Keep your dotfiles synchronized:

```bash
# Save your bash aliases
gh workflow run save-dotfile.yml \
  -f shell="bash" \
  -f file_type="aliases" \
  -f content="$(cat ~/.bash_aliases)"

# Save custom functions
gh workflow run save-dotfile.yml \
  -f shell="bash" \
  -f file_type="functions" \
  -f content="$(cat ~/.bash_functions)"

# Clone on a new machine and link
git clone https://github.com/yourusername/Knowledge-Base.git
cd Knowledge-Base
ln -s $(pwd)/dotfiles/bash/bash_aliases ~/.bash_aliases
ln -s $(pwd)/dotfiles/bash/bash_functions ~/.bash_functions
```

### Example 4: MCP Server Configuration

Store and version control your MCP servers:

```bash
# Save server configuration
gh workflow run save-mcp-server.yml \
  -f server_name="github_integration" \
  -f file_name="config.json" \
  -f content='{"name": "github-server", "capabilities": ["tools", "resources"]}'

# Save server implementation
gh workflow run save-mcp-server.yml \
  -f server_name="github_integration" \
  -f file_name="server.py" \
  -f content="$(cat server.py)"
```

### Example 5: Docker Configuration Management

Keep Docker configurations organized:

```bash
# Save a docker-compose file
gh workflow run save-docker-config.yml \
  -f config_name="webapp" \
  -f config_type="compose" \
  -f content="$(cat docker-compose.yml)"

# Save a Dockerfile
gh workflow run save-docker-config.yml \
  -f config_name="backend" \
  -f config_type="dockerfile" \
  -f content="$(cat Dockerfile)"
```

## Best Practices

### For Memories
1. **Be Specific**: Use descriptive names that indicate the content
2. **Use Tags**: Add relevant tags for easy searching
3. **Regular Updates**: Save learnings regularly while they're fresh
4. **Context Matters**: Include enough context for future reference

### For Rules
1. **Clear and Concise**: Rules should be easy to understand
2. **Prioritize**: Use priority levels appropriately
3. **Update Regularly**: Review and update rules as practices evolve
4. **Document Exceptions**: Note when rules don't apply

### For Dotfiles
1. **Never Commit Secrets**: Use `.example` files for templates
2. **Document Changes**: Comment your functions and aliases
3. **Test Before Committing**: Ensure configurations work
4. **Use Version Control**: Commit meaningful changes with good messages

### For Docker Configs
1. **Environment Variables**: Use env vars for configuration
2. **Resource Limits**: Always set memory and CPU limits
3. **Health Checks**: Include health check configurations
4. **Documentation**: Document each service's purpose

### For MCP Servers
1. **Clear Naming**: Use descriptive server names
2. **Version Control**: Include version in config
3. **Dependencies**: Always include requirements files
4. **Documentation**: Document capabilities and usage

## Security Considerations

### Secrets Management

**NEVER commit actual secrets!** Follow these guidelines:

1. **Use Templates**: Create `.example` files with placeholder values
2. **Gitignore**: Ensure secret files are in `.gitignore`
3. **Environment Variables**: Use env vars or secret management tools
4. **Review Before Push**: Always review changes before pushing

### Files to Never Commit

- `*_secrets` (without `.example`)
- `.env` files
- Private keys (`.key`, `.pem`)
- API tokens
- Database credentials
- SSH keys

### Safe Practices

1. **Use GitHub Secrets**: For workflow automation
2. **Rotate Credentials**: Regularly rotate API keys and tokens
3. **Audit Access**: Review who has access to the repository
4. **Encrypt Sensitive Data**: Use tools like `git-crypt` if needed

## Backup and Recovery

### Backing Up

The entire repository acts as a backup. Additional practices:

1. **Regular Commits**: Commit changes frequently
2. **Multiple Remotes**: Consider multiple git remotes
3. **Local Clones**: Keep local clones on multiple machines
4. **Export Important Data**: Periodically export critical configurations

### Recovery

To recover configurations:

```bash
# Clone the repository
git clone https://github.com/yourusername/Knowledge-Base.git

# Restore dotfiles
cd Knowledge-Base
ln -s $(pwd)/dotfiles/bash/bashrc ~/.bashrc
source ~/.bashrc

# Deploy Docker configs
cd docker_configs/compose/myapp
docker-compose up -d

# Use MCP servers
cd mcp_servers/my_server
pip install -r requirements.txt
```

## Integration with AI Systems

### Programmatic Access

AI agents can interact with this repository programmatically:

```python
import os
import subprocess
from datetime import datetime

def save_memory(name, content, tags=""):
    """Save an AI memory using the CLI tool."""
    cmd = [
        "./scripts/utilities/kb_manager.sh",
        "memory",
        name,
        content
    ]
    subprocess.run(cmd, cwd="/path/to/Knowledge-Base")

def search_knowledge(query):
    """Search the knowledge base."""
    cmd = ["./scripts/utilities/kb_manager.sh", "search", query]
    result = subprocess.run(
        cmd,
        cwd="/path/to/Knowledge-Base",
        capture_output=True,
        text=True
    )
    return result.stdout

# Usage
save_memory("api_pattern", "Use REST for public APIs, GraphQL for internal")
results = search_knowledge("docker")
```

### GitHub API Integration

Use the GitHub API to trigger workflows:

```python
import requests

def trigger_workflow(workflow_name, inputs):
    """Trigger a GitHub Actions workflow."""
    url = f"https://api.github.com/repos/owner/repo/actions/workflows/{workflow_name}/dispatches"
    headers = {
        "Authorization": f"token {os.getenv('GITHUB_TOKEN')}",
        "Accept": "application/vnd.github.v3+json"
    }
    data = {
        "ref": "main",
        "inputs": inputs
    }
    response = requests.post(url, headers=headers, json=data)
    return response.status_code == 204

# Usage
trigger_workflow("save-ai-memory.yml", {
    "memory_name": "new_learning",
    "content": "Content here",
    "agent_name": "MyAgent"
})
```

## Troubleshooting

### Common Issues

**Workflow not running:**
- Check you have the correct permissions
- Verify the workflow file syntax
- Ensure all required inputs are provided

**CLI tool not working:**
- Make sure the script is executable: `chmod +x scripts/utilities/kb_manager.sh`
- Check you're in the correct directory
- Verify file paths are correct

**Git push failures:**
- Check you have write access to the repository
- Ensure you're authenticated with GitHub
- Verify there are no merge conflicts

## Support and Contribution

To contribute or report issues:
1. Create an issue describing the problem or enhancement
2. Submit a pull request with your changes
3. Follow the existing code style and conventions
4. Update documentation as needed

---

For more information, see the main [README.md](README.md) and individual directory README files.

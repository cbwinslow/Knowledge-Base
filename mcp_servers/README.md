# MCP Servers Collection

Comprehensive collection of Model Context Protocol (MCP) servers for various services and integrations.

## Overview

This directory contains MCP server configurations for accessing and managing various services, tools, and platforms. These servers enable AI agents to interact with external systems through a standardized protocol.

## Available MCP Servers

### Cloud & Infrastructure
- **AWS** (`aws/`) - EC2, S3, Lambda, RDS, CloudWatch, ECS operations
- **Terraform** (`terraform/`) - Infrastructure as Code operations
- **Docker** (`docker/`) - Container management and operations
- **Kubernetes** (`kubernetes/`) - Cluster and resource management
- **Cloudflare** (`cloudflare/`) - DNS, CDN, and security management

### Databases
- **PostgreSQL** (`postgresql/`) - Database operations and management

### Version Control & CI/CD
- **GitHub** (`github/`) - Repository, PR, issue, and workflow management

### Knowledge & Memory
- **Knowledge Base** (`knowledge_base/`) - Document storage and retrieval
- **Memory** (`memory/`) - Short-term and long-term memory management
- **Rules** (`rules/`) - Business rules and policy management

### Security & Quality
- **CodeQL** (`codeql/`) - Security code analysis
- **SonarQube** (`sonarqube/`) - Code quality analysis

## Directory Structure

```
mcp_servers/
├── aws/
│   ├── config.json          # Server configuration
│   ├── server.py            # Server implementation (when available)
│   ├── requirements.txt     # Dependencies
│   └── README.md           # Documentation
├── terraform/
│   └── config.json
├── postgresql/
│   └── config.json
├── github/
│   └── config.json
├── docker/
│   └── config.json
├── kubernetes/
│   └── config.json
├── knowledge_base/
│   └── config.json
├── memory/
│   └── config.json
└── [other servers...]
```

## Configuration Format

Each MCP server follows a standard configuration format:

```json
{
  "name": "server-name",
  "version": "1.0.0",
  "description": "Server description",
  "protocol_version": "1.0",
  "capabilities": {
    "tools": true,
    "resources": true,
    "prompts": true
  },
  "transport": {
    "type": "stdio"
  },
  "tools": [...],
  "resources": [...],
  "authentication": {...}
}
```

## Usage

### With Claude Desktop

Add to your Claude Desktop configuration:

```json
{
  "mcpServers": {
    "aws": {
      "command": "python",
      "args": ["/path/to/mcp_servers/aws/server.py"],
      "env": {
        "AWS_PROFILE": "default"
      }
    },
    "github": {
      "command": "python",
      "args": ["/path/to/mcp_servers/github/server.py"],
      "env": {
        "GITHUB_TOKEN": "your-token"
      }
    }
  }
}
```

### With AI Agents

MCP servers can be integrated with AI agents to provide external service access:

```python
from crewai import Agent
from mcp_tools import MCPToolkit

# Create toolkit from MCP server
aws_toolkit = MCPToolkit(
    server_path="mcp_servers/aws/server.py",
    tools=["aws_ec2_list_instances", "aws_s3_list_buckets"]
)

# Create agent with MCP tools
agent = Agent(
    role="DevOps Engineer",
    tools=aws_toolkit.get_tools(),
    goal="Manage AWS infrastructure"
)
```

### Saving MCP Server Configurations

Use the GitHub Actions workflow:

```bash
gh workflow run save-mcp-server.yml -f server_name="my_server" -f config_content="$(cat config.json)"
```

Or manually add to the repository:

```bash
mkdir -p mcp_servers/my_server
cp config.json mcp_servers/my_server/
```

## Development

### Creating a New MCP Server

1. Create directory and configuration
2. Define tools and resources
3. Implement server logic
4. Add authentication
5. Document usage
6. Add tests

See individual server READMEs for detailed implementation examples.

## Security Best Practices

1. **Credentials:** Use environment variables, never hardcode
2. **Least Privilege:** Grant minimum required permissions
3. **Validation:** Validate all inputs thoroughly
4. **Encryption:** Use encrypted connections
5. **Audit Logging:** Log all operations
6. **Rate Limiting:** Implement API rate limits

## Related Resources

- [AI Agents](../agents/README.md) - Agent configurations
- [Crews](../ai_agents/crews/README.md) - Agent crews
- [Tools](../tools/README.md) - Tool configurations
- [MCP Specification](https://modelcontextprotocol.io/)

## Examples

Common MCP server types:
- Cloud service integrations (AWS, Azure, GCP)
- Database query servers (PostgreSQL, MySQL, MongoDB)
- API integration servers (GitHub, GitLab, Jira)
- Tool execution servers (Docker, Kubernetes, Terraform)
- Knowledge base servers (Documentation, Wiki)
- Memory management servers (Short-term, Long-term)
- Security scanning servers (CodeQL, SonarQube, Snyk)

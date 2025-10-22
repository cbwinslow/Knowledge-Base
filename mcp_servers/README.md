# MCP Servers

This directory stores Model Context Protocol (MCP) server configurations.

## Structure

Each MCP server should have its own subdirectory:

```
mcp_servers/
├── example_server/
│   ├── config.json
│   ├── server.py
│   ├── requirements.txt
│   └── README.md
```

## MCP Server Configuration

### config.json

```json
{
  "name": "example-server",
  "version": "1.0.0",
  "description": "Description of what this MCP server provides",
  "protocol_version": "1.0",
  "capabilities": {
    "tools": true,
    "resources": true,
    "prompts": true
  },
  "transport": {
    "type": "stdio"
  }
}
```

### Server Implementation

Each server directory should contain:
- **config.json** - Server configuration
- **server.py** or **server.js** - Server implementation
- **requirements.txt** or **package.json** - Dependencies
- **README.md** - Documentation

## Usage

### Saving MCP Server Configurations

Use the GitHub Actions workflow:

```bash
gh workflow run save-mcp-server.yml -f server_name="my_server" -f config_content="$(cat config.json)"
```

Or manually add to the repository:

```bash
mkdir -p mcp_servers/my_server
cp config.json mcp_servers/my_server/
cp server.py mcp_servers/my_server/
```

### Deploying MCP Servers

1. Clone this repository
2. Navigate to the server directory
3. Install dependencies
4. Configure the server in your MCP client

```bash
cd mcp_servers/my_server
pip install -r requirements.txt
# Configure in Claude Desktop or other MCP client
```

## Examples

Common MCP server types:
- File system access servers
- API integration servers
- Database query servers
- Tool execution servers
- Knowledge base servers

# Example MCP Server

This is an example Model Context Protocol (MCP) server that provides file system access tools.

## Overview

This server demonstrates how to create an MCP server that:
- Provides tools for AI assistants
- Implements the MCP protocol
- Handles stdio communication

## Files

- `config.json` - Server configuration
- `server.py` - Server implementation
- `requirements.txt` - Python dependencies

## Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Test the server
python server.py
```

## Configuration

The server can be configured in your MCP client (e.g., Claude Desktop):

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "python",
      "args": ["/path/to/server.py"],
      "env": {
        "ALLOWED_PATHS": "/home/user/documents"
      }
    }
  }
}
```

## Capabilities

This example server provides:
- File reading tools
- Directory listing tools
- File search tools

## Security

- Only allows access to specified paths
- Validates all file operations
- Sanitizes user inputs

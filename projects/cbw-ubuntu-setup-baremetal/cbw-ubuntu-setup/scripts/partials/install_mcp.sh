#!/usr/bin/env bash
set -euo pipefail

# Placeholder: clone and bring up MCP servers you choose
# Example: OpenAI MCP examples, local AI packaged, etc.

mkdir -p /opt/mcp
cd /opt/mcp

# Local AI packaged (user's repo)
if [[ ! -d "local-ai-packaged" ]]; then
  git clone https://github.com/cbwinslow/local-ai-packaged.git || true
fi

echo "[i] MCP stubs ready under /opt/mcp. Add compose files and services as needed."

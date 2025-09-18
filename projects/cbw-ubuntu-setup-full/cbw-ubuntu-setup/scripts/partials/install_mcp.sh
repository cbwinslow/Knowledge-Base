#!/usr/bin/env bash
set -euo pipefail
mkdir -p /opt/mcp
cd /opt/mcp
if [[ ! -d "local-ai-packaged" ]]; then
  git clone https://github.com/cbwinslow/local-ai-packaged.git || true
fi
echo "[i] MCP stubs in /opt/mcp. Add services as needed."

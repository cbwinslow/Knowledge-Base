#!/usr/bin/env python3
"""
Example MCP Server for File System Operations
This is a simplified example showing the structure of an MCP server.
"""

import json
import sys
import os
from pathlib import Path


class FileSystemMCPServer:
    """Example MCP server that provides file system tools."""
    
    def __init__(self):
        self.allowed_paths = self._get_allowed_paths()
    
    def _get_allowed_paths(self):
        """Get allowed paths from environment."""
        paths = os.getenv('ALLOWED_PATHS', '')
        return [Path(p.strip()) for p in paths.split(',') if p.strip()]
    
    def _is_path_allowed(self, path):
        """Check if path is in allowed directories."""
        path = Path(path).resolve()
        if not self.allowed_paths:
            return True  # No restrictions if not configured
        return any(path.is_relative_to(allowed) for allowed in self.allowed_paths)
    
    def read_file(self, path):
        """Read contents of a file."""
        try:
            path = Path(path)
            if not self._is_path_allowed(path):
                return {"error": "Path not allowed"}
            
            if not path.exists():
                return {"error": "File not found"}
            
            with open(path, 'r') as f:
                content = f.read()
            
            return {"content": content}
        except Exception as e:
            return {"error": str(e)}
    
    def list_directory(self, path):
        """List contents of a directory."""
        try:
            path = Path(path)
            if not self._is_path_allowed(path):
                return {"error": "Path not allowed"}
            
            if not path.exists():
                return {"error": "Directory not found"}
            
            if not path.is_dir():
                return {"error": "Path is not a directory"}
            
            entries = []
            for item in path.iterdir():
                entries.append({
                    "name": item.name,
                    "type": "directory" if item.is_dir() else "file",
                    "path": str(item)
                })
            
            return {"entries": entries}
        except Exception as e:
            return {"error": str(e)}
    
    def handle_request(self, request):
        """Handle an MCP request."""
        method = request.get('method')
        params = request.get('params', {})
        
        if method == 'read_file':
            return self.read_file(params.get('path'))
        elif method == 'list_directory':
            return self.list_directory(params.get('path'))
        else:
            return {"error": f"Unknown method: {method}"}
    
    def run(self):
        """Run the MCP server."""
        # In a real MCP server, this would implement the full protocol
        # This is a simplified example
        print("MCP Server started", file=sys.stderr)
        
        for line in sys.stdin:
            try:
                request = json.loads(line)
                response = self.handle_request(request)
                print(json.dumps(response))
                sys.stdout.flush()
            except json.JSONDecodeError:
                print(json.dumps({"error": "Invalid JSON"}))
                sys.stdout.flush()
            except Exception as e:
                print(json.dumps({"error": str(e)}))
                sys.stdout.flush()


if __name__ == '__main__':
    server = FileSystemMCPServer()
    server.run()

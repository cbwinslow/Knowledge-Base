#!/usr/bin/env python3
"""
Dynamic Table of Contents Generator
Creates and maintains a dynamic table of contents for the knowledge base
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Any
from dataclasses import dataclass, asdict
from datetime import datetime

@dataclass
class TOCItem:
    """Represents an item in the table of contents"""
    title: str
    path: str
    type: str  # 'file', 'directory'
    size: int = 0
    modified: str = ""
    description: str = ""
    tags: List[str] = None
    children: List['TOCItem'] = None
    
    def __post_init__(self):
        if self.children is None:
            self.children = []
        if self.tags is None:
            self.tags = []

class DynamicTOC:
    """Dynamic Table of Contents Generator"""
    
    def __init__(self, kb_path: str = "/home/cbwinslow/Knowledge-Base"):
        self.kb_path = Path(kb_path)
        self.toc_data = {}
        self.ignore_patterns = {
            '.git', '__pycache__', 'node_modules', '.venv', 'venv',
            '.DS_Store', '*.pyc', '*.log', '.pytest_cache'
        }
    
    def should_ignore(self, path: Path) -> bool:
        """Check if a path should be ignored"""
        for pattern in self.ignore_patterns:
            if pattern.startswith('*'):
                if path.name.endswith(pattern[1:]):
                    return True
            elif pattern in path.name:
                return True
        return False
    
    def extract_description(self, file_path: Path) -> str:
        """Extract description from file content"""
        if file_path.suffix.lower() not in ['.md', '.txt', '.rst']:
            return ""
        
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            lines = content.split('\n')
            
            # Look for first paragraph after title
            for i, line in enumerate(lines[1:], 1):
                line = line.strip()
                if line and not line.startswith('#') and not line.startswith('=') and not line.startswith('-'):
                    # Return first meaningful paragraph
                    desc_lines = [line]
                    j = i + 1
                    while j < len(lines) and j < i + 3:  # Max 3 lines for description
                        next_line = lines[j].strip()
                        if next_line and not next_line.startswith('#'):
                            desc_lines.append(next_line)
                        elif not next_line:
                            desc_lines.append("")
                        else:
                            break
                        j += 1
                    
                    desc = ' '.join(filter(None, desc_lines))
                    return desc[:200] + "..." if len(desc) > 200 else desc
            
            return ""
        except Exception:
            return ""
    
    def extract_tags(self, file_path: Path) -> List[str]:
        """Extract tags from file path and content"""
        tags = []
        
        # Tags from path
        path_parts = file_path.relative_to(self.kb_path).parts
        tags.extend([part.lower() for part in path_parts if part != file_path.name])
        
        # Tags from file extension
        ext = file_path.suffix.lower().lstrip('.')
        if ext:
            tags.append(ext)
        
        # Content-based tags for markdown files
        if file_path.suffix.lower() == '.md':
            try:
                content = file_path.read_text(encoding='utf-8', errors='ignore')
                content_lower = content.lower()
                
                # Common technology tags
                tech_keywords = {
                    'docker': ['docker', 'container', 'compose'],
                    'kubernetes': ['kubernetes', 'k8s', 'pod', 'deployment'],
                    'python': ['python', 'pip', 'import', 'def '],
                    'javascript': ['javascript', 'js', 'node', 'npm'],
                    'typescript': ['typescript', 'ts', 'interface', 'type '],
                    'react': ['react', 'jsx', 'component', 'usestate'],
                    'api': ['api', 'rest', 'endpoint', 'http'],
                    'database': ['database', 'sql', 'query', 'table'],
                    'ai': ['ai', 'llm', 'machine learning', 'model'],
                    'security': ['security', 'auth', 'token', 'encryption'],
                    'devops': ['devops', 'ci/cd', 'deployment', 'pipeline']
                }
                
                for tag, keywords in tech_keywords.items():
                    if any(keyword in content_lower for keyword in keywords):
                        tags.append(tag)
            
            except Exception:
                pass
        
        return list(set(tags))  # Remove duplicates
    
    def scan_directory(self, directory: Path, max_depth: int = 3) -> TOCItem:
        """Scan a directory and create TOC structure"""
        if self.should_ignore(directory):
            return None
        
        stat = directory.stat()
        
        toc_item = TOCItem(
            title=directory.name,
            path=str(directory.relative_to(self.kb_path)),
            type='directory',
            size=0,
            modified=datetime.fromtimestamp(stat.st_mtime).isoformat(),
            description="",
            tags=[],
            children=[]
        )
        
        try:
            items = []
            for item in directory.iterdir():
                if self.should_ignore(item):
                    continue
                
                if item.is_file():
                    file_item = self.scan_file(item)
                    if file_item:
                        items.append(file_item)
                elif item.is_dir() and max_depth > 0:
                    dir_item = self.scan_directory(item, max_depth - 1)
                    if dir_item and dir_item.children:
                        items.append(dir_item)
            
            # Sort items: directories first, then files, alphabetically
            toc_item.children = sorted(items, key=lambda x: (x.type != 'directory', x.title.lower()))
            
        except PermissionError:
            pass
        
        return toc_item
    
    def scan_file(self, file_path: Path) -> TOCItem:
        """Scan a file and create TOC item"""
        if self.should_ignore(file_path):
            return None
        
        stat = file_path.stat()
        
        # Determine title from filename
        title = file_path.stem
        if file_path.name.lower() in ['readme.md', 'index.md']:
            title = file_path.parent.name or 'Home'
        
        toc_item = TOCItem(
            title=title,
            path=str(file_path.relative_to(self.kb_path)),
            type='file',
            size=stat.st_size,
            modified=datetime.fromtimestamp(stat.st_mtime).isoformat(),
            description=self.extract_description(file_path),
            tags=self.extract_tags(file_path),
            children=[]
        )
        
        return toc_item
    
    def generate_toc(self) -> Dict[str, Any]:
        """Generate complete table of contents"""
        print("Scanning knowledge base...")
        
        root_item = self.scan_directory(self.kb_path)
        
        toc_data = {
            'generated_at': datetime.now().isoformat(),
            'kb_path': str(self.kb_path),
            'total_items': self._count_items(root_item),
            'root': asdict(root_item) if root_item else None
        }
        
        return toc_data
    
    def _count_items(self, item: TOCItem) -> int:
        """Count total items in TOC"""
        count = 1
        for child in item.children:
            count += self._count_items(child)
        return count
    
    def save_toc(self, output_path: str = None):
        """Save table of contents to file"""
        if output_path is None:
            output_path = self.kb_path / 'dynamic_toc.json'
        
        toc_data = self.generate_toc()
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(toc_data, f, indent=2, ensure_ascii=False)
        
        print(f"Table of contents saved to: {output_path}")
        return toc_data
    
    def generate_markdown_toc(self, toc_data: Dict[str, Any] = None) -> str:
        """Generate markdown table of contents"""
        if toc_data is None:
            toc_data = self.generate_toc()
        
        def item_to_markdown(item: Dict[str, Any], level: int = 0) -> str:
            if not item:
                return ""
            
            indent = '  ' * level
            prefix = '- ' if item['type'] == 'file' else '- '
            
            line = f"{indent}{prefix}**{item['title']}**"
            
            if item['type'] == 'file':
                line += f" ([{item['path']}]({item['path']}))"
                
                if item['description']:
                    line += f" - {item['description']}"
                
                if item['tags']:
                    tags_str = ', '.join([f"`{tag}`" for tag in item['tags'][:5]])
                    line += f" {tags_str}"
            
            markdown = line + "\n"
            
            for child in item.get('children', []):
                markdown += item_to_markdown(child, level + 1)
            
            return markdown
        
        root = toc_data.get('root', {})
        if not root:
            return "# Table of Contents\n\nNo items found."
        
        markdown = f"""# Dynamic Table of Contents

*Generated on: {toc_data['generated_at']}*  
*Total items: {toc_data['total_items']}*  

{item_to_markdown(root)}

---

## Statistics

- **Total Items**: {toc_data['total_items']}
- **Knowledge Base Path**: `{toc_data['kb_path']}`
- **Last Updated**: {toc_data['generated_at']}

## Usage

This table of contents is automatically generated and includes:
- All directories and files in the knowledge base
- File descriptions extracted from content
- Tags based on path and content analysis
- Modification timestamps

To regenerate this table of contents, run:
```bash
python3 scripts/documentation/dynamic_toc.py
```
"""
        
        return markdown
    
    def save_markdown_toc(self, output_path: str = None):
        """Save markdown table of contents"""
        if output_path is None:
            output_path = self.kb_path / 'TABLE_OF_CONTENTS.md'
        
        toc_data = self.generate_toc()
        markdown = self.generate_markdown_toc(toc_data)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(markdown)
        
        print(f"Markdown table of contents saved to: {output_path}")
        return markdown

def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Dynamic Table of Contents Generator')
    parser.add_argument('--kb-path', default='/home/cbwinslow/Knowledge-Base',
                       help='Knowledge base path')
    parser.add_argument('--output', '-o', help='Output file path')
    parser.add_argument('--format', choices=['json', 'markdown', 'both'], 
                       default='both', help='Output format')
    
    args = parser.parse_args()
    
    toc_generator = DynamicTOC(args.kb_path)
    
    if args.format in ['json', 'both']:
        json_path = args.output if args.format == 'json' else None
        toc_generator.save_toc(json_path)
    
    if args.format in ['markdown', 'both']:
        md_path = args.output if args.format == 'markdown' else None
        toc_generator.save_markdown_toc(md_path)

if __name__ == "__main__":
    main()
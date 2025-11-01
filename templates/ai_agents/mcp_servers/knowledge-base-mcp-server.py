"""
Knowledge Base MCP Server
Provides search and retrieval capabilities for the knowledge base via MCP protocol
"""

import asyncio
import json
from typing import Any, Dict, List, Optional
from pathlib import Path
from mcp import Server, Tool, types
from mcp.server import stdio_server
from dataclasses import dataclass

@dataclass
class SearchResult:
    """Search result from knowledge base"""
    title: str
    category: str
    path: str
    snippet: str
    score: float
    tags: List[str]

class KnowledgeBaseMCPServer:
    """MCP Server for Knowledge Base operations"""
    
    def __init__(self, kb_path: str):
        self.kb_path = Path(kb_path)
        self.server = Server("knowledge-base-server")
        self._register_tools()
    
    def _register_tools(self):
        """Register all available tools"""
        
        @self.server.tool()
        async def search_documentation(
            query: str,
            category: Optional[str] = None,
            limit: int = 10
        ) -> List[Dict[str, Any]]:
            """
            Search the knowledge base for documentation
            
            Args:
                query: Search query string
                category: Optional category filter (e.g., 'python', 'docker')
                limit: Maximum number of results to return
            
            Returns:
                List of search results with title, path, snippet, and score
            """
            results = await self._search(query, category, limit)
            return [
                {
                    "title": r.title,
                    "category": r.category,
                    "path": str(r.path),
                    "snippet": r.snippet,
                    "score": r.score,
                    "tags": r.tags
                }
                for r in results
            ]
        
        @self.server.tool()
        async def get_document(path: str) -> Dict[str, Any]:
            """
            Retrieve full content of a document
            
            Args:
                path: Path to the document relative to knowledge base root
            
            Returns:
                Document content and metadata
            """
            doc_path = self.kb_path / path
            
            if not doc_path.exists():
                raise FileNotFoundError(f"Document not found: {path}")
            
            content = doc_path.read_text()
            
            return {
                "path": path,
                "content": content,
                "size": doc_path.stat().st_size,
                "modified": doc_path.stat().st_mtime
            }
        
        @self.server.tool()
        async def list_categories() -> List[Dict[str, Any]]:
            """
            List all available categories in the knowledge base
            
            Returns:
                List of categories with counts
            """
            categories = await self._get_categories()
            return categories
        
        @self.server.tool()
        async def get_examples(
            language: str,
            topic: Optional[str] = None,
            difficulty: Optional[str] = None
        ) -> List[Dict[str, Any]]:
            """
            Get code examples for a specific language
            
            Args:
                language: Programming language (python, typescript, javascript, go, rust)
                topic: Optional topic filter
                difficulty: Optional difficulty level (beginner, intermediate, advanced)
            
            Returns:
                List of code examples with metadata
            """
            examples = await self._get_examples(language, topic, difficulty)
            return examples
        
        @self.server.tool()
        async def get_related_docs(path: str, limit: int = 5) -> List[Dict[str, Any]]:
            """
            Find related documentation based on a document path
            
            Args:
                path: Path to the reference document
                limit: Maximum number of related docs to return
            
            Returns:
                List of related documents
            """
            related = await self._find_related(path, limit)
            return related
    
    async def _search(
        self, 
        query: str, 
        category: Optional[str], 
        limit: int
    ) -> List[SearchResult]:
        """Internal search implementation"""
        # Implement actual search logic here
        # This could use:
        # - Full-text search (Elasticsearch, MeiliSearch)
        # - Vector search (embeddings)
        # - Simple file system search
        
        results = []
        
        # Example implementation: simple file system search
        for doc_path in self.kb_path.rglob("*.md"):
            if category and category not in str(doc_path):
                continue
            
            content = doc_path.read_text()
            if query.lower() in content.lower():
                # Calculate relevance score (simplified)
                score = content.lower().count(query.lower()) / len(content) * 100
                
                results.append(SearchResult(
                    title=doc_path.stem,
                    category=doc_path.parent.name,
                    path=doc_path.relative_to(self.kb_path),
                    snippet=self._extract_snippet(content, query),
                    score=score,
                    tags=self._extract_tags(content)
                ))
        
        # Sort by score and limit
        results.sort(key=lambda x: x.score, reverse=True)
        return results[:limit]
    
    async def _get_categories(self) -> List[Dict[str, Any]]:
        """Get all categories"""
        categories = {}
        
        for doc_path in self.kb_path.rglob("*.md"):
            category = doc_path.parent.name
            if category not in categories:
                categories[category] = {"name": category, "count": 0}
            categories[category]["count"] += 1
        
        return list(categories.values())
    
    async def _get_examples(
        self,
        language: str,
        topic: Optional[str],
        difficulty: Optional[str]
    ) -> List[Dict[str, Any]]:
        """Get code examples"""
        examples_dir = self.kb_path / "examples_scripts" / "programming" / language
        
        if not examples_dir.exists():
            return []
        
        examples = []
        for example_file in examples_dir.rglob(f"*.{self._get_extension(language)}"):
            if topic and topic not in str(example_file):
                continue
            if difficulty and difficulty not in str(example_file):
                continue
            
            examples.append({
                "name": example_file.stem,
                "path": str(example_file.relative_to(self.kb_path)),
                "language": language,
                "difficulty": self._extract_difficulty(example_file),
                "code": example_file.read_text()
            })
        
        return examples
    
    async def _find_related(self, path: str, limit: int) -> List[Dict[str, Any]]:
        """Find related documents"""
        # Implement similarity search
        # Could use:
        # - Tag-based similarity
        # - Content-based similarity (embeddings)
        # - Category-based similarity
        
        doc_path = self.kb_path / path
        if not doc_path.exists():
            return []
        
        # Simple implementation: same category
        related = []
        for sibling in doc_path.parent.glob("*.md"):
            if sibling != doc_path:
                related.append({
                    "title": sibling.stem,
                    "path": str(sibling.relative_to(self.kb_path)),
                    "category": sibling.parent.name
                })
        
        return related[:limit]
    
    def _extract_snippet(self, content: str, query: str, context: int = 100) -> str:
        """Extract relevant snippet around query"""
        query_pos = content.lower().find(query.lower())
        if query_pos == -1:
            return content[:200]
        
        start = max(0, query_pos - context)
        end = min(len(content), query_pos + len(query) + context)
        
        snippet = content[start:end]
        if start > 0:
            snippet = "..." + snippet
        if end < len(content):
            snippet = snippet + "..."
        
        return snippet
    
    def _extract_tags(self, content: str) -> List[str]:
        """Extract tags from document metadata"""
        # Look for tags in frontmatter or metadata
        tags = []
        lines = content.split("\n")
        for line in lines:
            if line.startswith("tags:") or line.startswith("Tags:"):
                tags_str = line.split(":", 1)[1]
                tags = [t.strip() for t in tags_str.split(",")]
                break
        return tags
    
    def _get_extension(self, language: str) -> str:
        """Get file extension for language"""
        extensions = {
            "python": "py",
            "typescript": "ts",
            "javascript": "js",
            "go": "go",
            "rust": "rs"
        }
        return extensions.get(language, "txt")
    
    def _extract_difficulty(self, path: Path) -> str:
        """Extract difficulty from path"""
        path_str = str(path).lower()
        if "beginner" in path_str or "basics" in path_str:
            return "beginner"
        elif "advanced" in path_str:
            return "advanced"
        else:
            return "intermediate"
    
    async def run(self):
        """Run the MCP server"""
        async with stdio_server() as (read_stream, write_stream):
            await self.server.run(
                read_stream,
                write_stream,
                self.server.create_initialization_options()
            )

async def main():
    """Main entry point"""
    import os
    
    # Get knowledge base path from environment or use default
    kb_path = os.getenv("KB_PATH", "./documentation")
    
    # Create and run server
    server = KnowledgeBaseMCPServer(kb_path)
    await server.run()

if __name__ == "__main__":
    asyncio.run(main())

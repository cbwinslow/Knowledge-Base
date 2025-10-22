#!/usr/bin/env python3
"""
Knowledge Base Management Script
Manages the knowledge base: update, search, cleanup, and maintenance
"""

import argparse
import json
import logging
import os
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import yaml

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class KnowledgeBaseManager:
    """Main class for managing the knowledge base"""
    
    def __init__(self, config_path: str = "documentation_config.yaml"):
        """Initialize the manager with configuration"""
        self.config = self._load_config(config_path)
        self.base_dir = Path(self.config['output']['base_dir'])
        self.index_file = Path(self.config['knowledge_base']['index_file'])
        
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            return {}
    
    def _load_index(self) -> Dict:
        """Load the knowledge base index"""
        if not self.index_file.exists():
            logger.warning("Index file does not exist")
            return {}
        
        with open(self.index_file, 'r') as f:
            return json.load(f)
    
    def _save_index(self, index: Dict):
        """Save the knowledge base index"""
        self.index_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.index_file, 'w') as f:
            json.dump(index, f, indent=2)
        logger.info(f"Index saved to: {self.index_file}")
    
    def search(self, query: str, category: Optional[str] = None, 
               tags: Optional[List[str]] = None) -> List[Dict]:
        """
        Search the knowledge base
        
        Args:
            query: Search query string
            category: Optional category filter
            tags: Optional list of tags to filter by
            
        Returns:
            List of matching items
        """
        logger.info(f"Searching for: {query}")
        
        index = self._load_index()
        items = index.get('items', [])
        results = []
        
        query_lower = query.lower()
        
        for item in items:
            # Check if query matches file name or path
            if (query_lower in item.get('file_name', '').lower() or 
                query_lower in item.get('file_path', '').lower()):
                
                # Apply category filter
                if category and item.get('category') != category:
                    continue
                
                # Apply tag filter
                if tags:
                    item_tags = item.get('tags', [])
                    if not any(tag in item_tags for tag in tags):
                        continue
                
                results.append(item)
        
        logger.info(f"Found {len(results)} results")
        return results
    
    def list_categories(self) -> Dict[str, int]:
        """
        List all categories and their counts
        
        Returns:
            Dictionary mapping category names to counts
        """
        index = self._load_index()
        categories = index.get('categories', {})
        
        category_counts = {cat: len(items) for cat, items in categories.items()}
        return category_counts
    
    def list_tags(self) -> Dict[str, int]:
        """
        List all tags and their counts
        
        Returns:
            Dictionary mapping tag names to counts
        """
        index = self._load_index()
        tags = index.get('tags', {})
        
        tag_counts = {tag: len(items) for tag, items in tags.items()}
        return tag_counts
    
    def get_statistics(self) -> Dict:
        """
        Get knowledge base statistics
        
        Returns:
            Dictionary containing statistics
        """
        index = self._load_index()
        
        stats = {
            'total_items': index.get('total_items', 0),
            'categories': len(index.get('categories', {})),
            'tags': len(index.get('tags', {})),
            'generated_at': index.get('generated_at', 'unknown'),
            'category_breakdown': self.list_categories(),
            'tag_breakdown': self.list_tags()
        }
        
        # Calculate total size
        total_size = 0
        for item in index.get('items', []):
            total_size += item.get('file_size', 0)
        
        stats['total_size_mb'] = round(total_size / (1024 * 1024), 2)
        
        return stats
    
    def cleanup_old_files(self, days: int = 30):
        """
        Clean up old or temporary files
        
        Args:
            days: Remove files older than this many days
        """
        logger.info(f"Cleaning up files older than {days} days...")
        
        # Implementation would scan for old files and remove them
        # For now, just log the action
        logger.info("Cleanup completed")
    
    def update_index(self):
        """Update the knowledge base index by re-ingesting all content"""
        logger.info("Updating knowledge base index...")
        
        # This would call the ingestion scripts
        from ingest_knowledge import KnowledgeIngester
        
        ingester = KnowledgeIngester()
        ingester.run()
        
        logger.info("Index update completed")
    
    def export_metadata(self, output_path: Path):
        """
        Export knowledge base metadata to a file
        
        Args:
            output_path: Path to save the metadata
        """
        index = self._load_index()
        stats = self.get_statistics()
        
        export_data = {
            'statistics': stats,
            'index': index
        }
        
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        if output_path.suffix == '.json':
            with open(output_path, 'w') as f:
                json.dump(export_data, f, indent=2)
        elif output_path.suffix in ['.yml', '.yaml']:
            with open(output_path, 'w') as f:
                yaml.dump(export_data, f, default_flow_style=False)
        
        logger.info(f"Metadata exported to: {output_path}")
    
    def backup(self, backup_dir: Path):
        """
        Create a backup of the knowledge base
        
        Args:
            backup_dir: Directory to store the backup
        """
        logger.info(f"Creating backup in: {backup_dir}")
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = backup_dir / f"kb_backup_{timestamp}"
        backup_path.mkdir(parents=True, exist_ok=True)
        
        # Copy documentation directory
        if self.base_dir.exists():
            shutil.copytree(self.base_dir, backup_path / 'documentation', 
                          dirs_exist_ok=True)
        
        # Copy index
        if self.index_file.exists():
            shutil.copy2(self.index_file, backup_path / 'index.json')
        
        logger.info(f"Backup created at: {backup_path}")
    
    def validate(self) -> bool:
        """
        Validate the knowledge base integrity
        
        Returns:
            True if validation passes
        """
        logger.info("Validating knowledge base...")
        
        issues = []
        
        # Check if base directory exists
        if not self.base_dir.exists():
            issues.append(f"Base directory does not exist: {self.base_dir}")
        
        # Check if index exists
        if not self.index_file.exists():
            issues.append(f"Index file does not exist: {self.index_file}")
        else:
            # Validate index structure
            index = self._load_index()
            if 'items' not in index:
                issues.append("Index missing 'items' field")
        
        # Report issues
        if issues:
            logger.error("Validation failed:")
            for issue in issues:
                logger.error(f"  - {issue}")
            return False
        
        logger.info("Validation passed")
        return True


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Manage the knowledge base")
    
    subparsers = parser.add_subparsers(dest='command', help='Commands')
    
    # Search command
    search_parser = subparsers.add_parser('search', help='Search the knowledge base')
    search_parser.add_argument('query', help='Search query')
    search_parser.add_argument('--category', help='Filter by category')
    search_parser.add_argument('--tags', nargs='+', help='Filter by tags')
    
    # Stats command
    subparsers.add_parser('stats', help='Show knowledge base statistics')
    
    # List command
    list_parser = subparsers.add_parser('list', help='List categories or tags')
    list_parser.add_argument('type', choices=['categories', 'tags'], 
                           help='What to list')
    
    # Update command
    subparsers.add_parser('update', help='Update the knowledge base index')
    
    # Cleanup command
    cleanup_parser = subparsers.add_parser('cleanup', help='Clean up old files')
    cleanup_parser.add_argument('--days', type=int, default=30,
                              help='Remove files older than this many days')
    
    # Export command
    export_parser = subparsers.add_parser('export', help='Export metadata')
    export_parser.add_argument('output', help='Output file path')
    
    # Backup command
    backup_parser = subparsers.add_parser('backup', help='Create a backup')
    backup_parser.add_argument('directory', help='Backup directory')
    
    # Validate command
    subparsers.add_parser('validate', help='Validate knowledge base integrity')
    
    args = parser.parse_args()
    
    # Get script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create manager
    manager = KnowledgeBaseManager()
    
    # Execute command
    try:
        if args.command == 'search':
            results = manager.search(args.query, args.category, args.tags)
            print(f"\nFound {len(results)} results:\n")
            for result in results[:10]:  # Show first 10
                print(f"  - {result['file_name']} ({result['category']})")
        
        elif args.command == 'stats':
            stats = manager.get_statistics()
            print("\nKnowledge Base Statistics:")
            print(f"  Total items: {stats['total_items']}")
            print(f"  Categories: {stats['categories']}")
            print(f"  Tags: {stats['tags']}")
            print(f"  Total size: {stats['total_size_mb']} MB")
            print(f"  Last updated: {stats['generated_at']}")
        
        elif args.command == 'list':
            if args.type == 'categories':
                categories = manager.list_categories()
                print("\nCategories:")
                for cat, count in sorted(categories.items()):
                    print(f"  - {cat}: {count}")
            else:
                tags = manager.list_tags()
                print("\nTags:")
                for tag, count in sorted(tags.items()):
                    print(f"  - {tag}: {count}")
        
        elif args.command == 'update':
            manager.update_index()
        
        elif args.command == 'cleanup':
            manager.cleanup_old_files(args.days)
        
        elif args.command == 'export':
            manager.export_metadata(Path(args.output))
        
        elif args.command == 'backup':
            manager.backup(Path(args.directory))
        
        elif args.command == 'validate':
            valid = manager.validate()
            exit(0 if valid else 1)
        
        else:
            parser.print_help()
    
    except Exception as e:
        logger.error(f"Error: {e}")
        exit(1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Knowledge Ingestion Script
Processes and indexes downloaded documentation into the knowledge base
"""

import json
import logging
import os
import re
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


class KnowledgeIngester:
    """Main class for ingesting knowledge into the knowledge base"""
    
    def __init__(self, config_path: str = "documentation_config.yaml"):
        """Initialize the ingester with configuration"""
        self.config = self._load_config(config_path)
        self.base_dir = Path(self.config['output']['base_dir'])
        self.knowledge_items = []
        
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            return {}
    
    def extract_metadata(self, file_path: Path) -> Dict:
        """
        Extract metadata from a documentation file
        
        Args:
            file_path: Path to the documentation file
            
        Returns:
            Dictionary containing extracted metadata
        """
        metadata = {
            'file_path': str(file_path),
            'file_name': file_path.name,
            'file_size': file_path.stat().st_size if file_path.exists() else 0,
            'created_at': datetime.now().isoformat(),
            'tags': [],
            'category': 'unknown'
        }
        
        # Try to extract metadata from content
        if file_path.suffix in ['.md', '.txt', '.rst']:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read(5000)  # Read first 5000 chars
                    
                    # Extract title
                    title_match = re.search(r'^#\s+(.+)$', content, re.MULTILINE)
                    if title_match:
                        metadata['title'] = title_match.group(1)
                    
                    # Auto-categorize based on content
                    metadata['category'] = self._categorize_content(content)
                    metadata['tags'] = self._extract_tags(content)
                    
            except Exception as e:
                logger.warning(f"Error reading file {file_path}: {e}")
        
        return metadata
    
    def _categorize_content(self, content: str) -> str:
        """
        Automatically categorize content based on keywords
        
        Args:
            content: Text content to categorize
            
        Returns:
            Category name
        """
        content_lower = content.lower()
        
        categories = {
            'tutorial': ['tutorial', 'how to', 'guide', 'step by step'],
            'reference': ['reference', 'api', 'documentation', 'specification'],
            'examples': ['example', 'sample', 'demo', 'showcase'],
            'best-practices': ['best practice', 'pattern', 'guideline', 'standard'],
            'api-docs': ['endpoint', 'request', 'response', 'authentication']
        }
        
        for category, keywords in categories.items():
            if any(keyword in content_lower for keyword in keywords):
                return category
        
        return 'general'
    
    def _extract_tags(self, content: str) -> List[str]:
        """
        Extract relevant tags from content
        
        Args:
            content: Text content to extract tags from
            
        Returns:
            List of tags
        """
        tags = set()
        content_lower = content.lower()
        
        # Common technology tags
        tech_keywords = [
            'python', 'javascript', 'docker', 'kubernetes', 'api', 'rest',
            'graphql', 'database', 'sql', 'nosql', 'mongodb', 'postgresql',
            'redis', 'nginx', 'apache', 'linux', 'aws', 'azure', 'gcp',
            'react', 'vue', 'angular', 'django', 'flask', 'fastapi',
            'machine learning', 'ai', 'devops', 'ci/cd', 'testing'
        ]
        
        for keyword in tech_keywords:
            if keyword in content_lower:
                tags.add(keyword)
        
        return list(tags)
    
    def process_directory(self, directory: Path) -> List[Dict]:
        """
        Process all documentation files in a directory
        
        Args:
            directory: Directory to process
            
        Returns:
            List of processed knowledge items
        """
        items = []
        
        if not directory.exists():
            logger.warning(f"Directory does not exist: {directory}")
            return items
        
        # Process all supported file types
        file_patterns = self.config['filters']['include_patterns']
        
        for pattern in file_patterns:
            for file_path in directory.rglob(pattern):
                if file_path.is_file():
                    # Check file size
                    if file_path.stat().st_size < self.config['filters']['min_content_length']:
                        continue
                    
                    metadata = self.extract_metadata(file_path)
                    items.append(metadata)
                    logger.debug(f"Processed: {file_path}")
        
        return items
    
    def ingest_all(self):
        """Ingest all documentation from configured directories"""
        logger.info("Starting knowledge ingestion...")
        
        # Process each documentation directory
        for dir_key, dir_path in self.config['output'].items():
            if dir_key == 'base_dir':
                continue
                
            directory = Path(dir_path)
            logger.info(f"Processing directory: {directory}")
            
            items = self.process_directory(directory)
            self.knowledge_items.extend(items)
            
            logger.info(f"Found {len(items)} items in {directory}")
        
        logger.info(f"Total knowledge items ingested: {len(self.knowledge_items)}")
    
    def create_index(self):
        """Create searchable index of ingested knowledge"""
        index = {
            'generated_at': datetime.now().isoformat(),
            'total_items': len(self.knowledge_items),
            'categories': {},
            'tags': {},
            'items': self.knowledge_items
        }
        
        # Build category index
        for item in self.knowledge_items:
            category = item.get('category', 'unknown')
            if category not in index['categories']:
                index['categories'][category] = []
            index['categories'][category].append(item['file_path'])
        
        # Build tag index
        for item in self.knowledge_items:
            for tag in item.get('tags', []):
                if tag not in index['tags']:
                    index['tags'][tag] = []
                index['tags'][tag].append(item['file_path'])
        
        return index
    
    def save_index(self):
        """Save the knowledge index to file"""
        index = self.create_index()
        
        index_file = Path(self.config['knowledge_base']['index_file'])
        index_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(index_file, 'w') as f:
            json.dump(index, f, indent=2)
        
        logger.info(f"Knowledge index saved to: {index_file}")
        
        # Also save a summary
        summary_file = index_file.parent / 'knowledge_summary.yaml'
        summary = {
            'total_items': index['total_items'],
            'categories': {k: len(v) for k, v in index['categories'].items()},
            'tags': {k: len(v) for k, v in index['tags'].items()},
            'generated_at': index['generated_at']
        }
        
        with open(summary_file, 'w') as f:
            yaml.dump(summary, f, default_flow_style=False)
        
        logger.info(f"Knowledge summary saved to: {summary_file}")
    
    def run(self):
        """Main execution method"""
        logger.info("Starting knowledge ingestion process...")
        
        # Ingest all documentation
        self.ingest_all()
        
        # Create and save index
        self.save_index()
        
        logger.info("Knowledge ingestion completed!")


def main():
    """Main entry point"""
    # Get script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create and run ingester
    ingester = KnowledgeIngester()
    
    try:
        ingester.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise


if __name__ == "__main__":
    main()

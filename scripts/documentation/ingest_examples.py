#!/usr/bin/env python3
"""
Examples Ingestion Script
Processes and organizes working code examples from repositories and documentation
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


class ExamplesIngester:
    """Main class for ingesting code examples"""
    
    def __init__(self, config_path: str = "documentation_config.yaml"):
        """Initialize the ingester with configuration"""
        self.config = self._load_config(config_path)
        self.examples_dir = Path(self.config['output']['examples'])
        self.examples = []
        
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            return {}
    
    def detect_language(self, file_path: Path) -> str:
        """
        Detect programming language from file extension
        
        Args:
            file_path: Path to the code file
            
        Returns:
            Language name
        """
        extension_map = {
            '.py': 'python',
            '.js': 'javascript',
            '.ts': 'typescript',
            '.java': 'java',
            '.cpp': 'cpp',
            '.c': 'c',
            '.go': 'go',
            '.rs': 'rust',
            '.rb': 'ruby',
            '.php': 'php',
            '.sh': 'shell',
            '.bash': 'bash',
            '.yml': 'yaml',
            '.yaml': 'yaml',
            '.json': 'json',
            '.xml': 'xml',
            '.html': 'html',
            '.css': 'css',
            '.sql': 'sql',
            '.md': 'markdown'
        }
        
        return extension_map.get(file_path.suffix.lower(), 'unknown')
    
    def extract_example_metadata(self, file_path: Path) -> Dict:
        """
        Extract metadata from an example file
        
        Args:
            file_path: Path to the example file
            
        Returns:
            Dictionary containing example metadata
        """
        metadata = {
            'file_path': str(file_path),
            'file_name': file_path.name,
            'language': self.detect_language(file_path),
            'file_size': file_path.stat().st_size if file_path.exists() else 0,
            'created_at': datetime.now().isoformat(),
            'type': 'code-example',
            'description': '',
            'tags': []
        }
        
        # Try to extract description from comments
        if file_path.suffix in ['.py', '.js', '.ts', '.java', '.cpp', '.go']:
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read(2000)  # Read first 2000 chars
                    
                    # Extract docstring or comments
                    if file_path.suffix == '.py':
                        docstring = re.search(r'"""(.+?)"""', content, re.DOTALL)
                        if docstring:
                            metadata['description'] = docstring.group(1).strip()
                    
                    # Extract tags from content
                    metadata['tags'] = self._extract_example_tags(content, file_path)
                    
            except Exception as e:
                logger.warning(f"Error reading example file {file_path}: {e}")
        
        return metadata
    
    def _extract_example_tags(self, content: str, file_path: Path) -> List[str]:
        """
        Extract relevant tags from example content
        
        Args:
            content: Code content
            file_path: Path to the file
            
        Returns:
            List of tags
        """
        tags = []
        content_lower = content.lower()
        
        # Check for common patterns
        patterns = {
            'api': ['api', 'endpoint', 'request', 'response'],
            'async': ['async', 'await', 'promise', 'asyncio'],
            'database': ['database', 'sql', 'query', 'orm'],
            'authentication': ['auth', 'login', 'token', 'jwt'],
            'testing': ['test', 'unittest', 'pytest', 'jest'],
            'cli': ['argparse', 'click', 'commander', 'main'],
            'web': ['http', 'server', 'client', 'flask', 'fastapi', 'express'],
            'data-processing': ['pandas', 'numpy', 'data', 'process'],
            'machine-learning': ['model', 'train', 'predict', 'sklearn', 'tensorflow']
        }
        
        for tag, keywords in patterns.items():
            if any(keyword in content_lower for keyword in keywords):
                tags.append(tag)
        
        # Add language tag
        tags.append(self.detect_language(file_path))
        
        return list(set(tags))
    
    def is_example_file(self, file_path: Path) -> bool:
        """
        Determine if a file is likely an example file
        
        Args:
            file_path: Path to check
            
        Returns:
            True if file appears to be an example
        """
        # Check filename patterns
        name_lower = file_path.name.lower()
        example_patterns = [
            'example', 'sample', 'demo', 'test', 'tutorial',
            'quickstart', 'getting_started', 'hello'
        ]
        
        if any(pattern in name_lower for pattern in example_patterns):
            return True
        
        # Check directory patterns
        path_str = str(file_path).lower()
        dir_patterns = ['examples', 'samples', 'demos', 'tutorials']
        
        if any(pattern in path_str for pattern in dir_patterns):
            return True
        
        return False
    
    def process_examples_directory(self, directory: Path) -> List[Dict]:
        """
        Process all example files in a directory
        
        Args:
            directory: Directory to process
            
        Returns:
            List of processed examples
        """
        examples = []
        
        if not directory.exists():
            logger.warning(f"Directory does not exist: {directory}")
            return examples
        
        # Process code files
        code_extensions = ['.py', '.js', '.ts', '.java', '.cpp', '.go', '.rs']
        
        for ext in code_extensions:
            for file_path in directory.rglob(f'*{ext}'):
                if file_path.is_file() and self.is_example_file(file_path):
                    metadata = self.extract_example_metadata(file_path)
                    examples.append(metadata)
                    logger.debug(f"Processed example: {file_path}")
        
        return examples
    
    def organize_by_category(self):
        """Organize examples by category (language, type, tags)"""
        organized = {
            'by_language': {},
            'by_tag': {},
            'by_type': {}
        }
        
        for example in self.examples:
            # Organize by language
            language = example.get('language', 'unknown')
            if language not in organized['by_language']:
                organized['by_language'][language] = []
            organized['by_language'][language].append(example)
            
            # Organize by tags
            for tag in example.get('tags', []):
                if tag not in organized['by_tag']:
                    organized['by_tag'][tag] = []
                organized['by_tag'][tag].append(example)
            
            # Organize by type
            example_type = example.get('type', 'unknown')
            if example_type not in organized['by_type']:
                organized['by_type'][example_type] = []
            organized['by_type'][example_type].append(example)
        
        return organized
    
    def ingest_all(self):
        """Ingest all examples from the examples directory"""
        logger.info("Starting examples ingestion...")
        
        if not self.examples_dir.exists():
            logger.warning(f"Examples directory does not exist: {self.examples_dir}")
            return
        
        # Process each subdirectory
        for subdir in self.examples_dir.iterdir():
            if subdir.is_dir():
                logger.info(f"Processing examples directory: {subdir}")
                examples = self.process_examples_directory(subdir)
                self.examples.extend(examples)
                logger.info(f"Found {len(examples)} examples in {subdir.name}")
        
        logger.info(f"Total examples ingested: {len(self.examples)}")
    
    def create_examples_index(self):
        """Create searchable index of examples"""
        organized = self.organize_by_category()
        
        index = {
            'generated_at': datetime.now().isoformat(),
            'total_examples': len(self.examples),
            'by_language': {k: len(v) for k, v in organized['by_language'].items()},
            'by_tag': {k: len(v) for k, v in organized['by_tag'].items()},
            'organized': organized,
            'examples': self.examples
        }
        
        return index
    
    def save_index(self):
        """Save the examples index to file"""
        index = self.create_examples_index()
        
        # Save main index
        index_file = self.examples_dir / 'examples_index.json'
        with open(index_file, 'w') as f:
            json.dump(index, f, indent=2)
        
        logger.info(f"Examples index saved to: {index_file}")
        
        # Save summary
        summary_file = self.examples_dir / 'examples_summary.yaml'
        summary = {
            'total_examples': index['total_examples'],
            'by_language': index['by_language'],
            'by_tag': index['by_tag'],
            'generated_at': index['generated_at']
        }
        
        with open(summary_file, 'w') as f:
            yaml.dump(summary, f, default_flow_style=False)
        
        logger.info(f"Examples summary saved to: {summary_file}")
    
    def run(self):
        """Main execution method"""
        logger.info("Starting examples ingestion process...")
        
        # Ingest all examples
        self.ingest_all()
        
        # Create and save index
        if self.examples:
            self.save_index()
        else:
            logger.warning("No examples found to index")
        
        logger.info("Examples ingestion completed!")


def main():
    """Main entry point"""
    # Get script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create and run ingester
    ingester = ExamplesIngester()
    
    try:
        ingester.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise


if __name__ == "__main__":
    main()

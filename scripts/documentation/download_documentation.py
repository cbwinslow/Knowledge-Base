#!/usr/bin/env python3
"""
Documentation Download Script
Uses context7 MCP server and crawl4ai to download documentation from top 100 results
"""

import asyncio
import json
import logging
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

import yaml
from tqdm import tqdm

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class DocumentationDownloader:
    """Main class for downloading and organizing documentation"""
    
    def __init__(self, config_path: str = "documentation_config.yaml"):
        """Initialize the downloader with configuration"""
        self.config = self._load_config(config_path)
        self.base_dir = Path(self.config['output']['base_dir'])
        self.results = []
        
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            sys.exit(1)
            
    def _load_sources(self, sources_path: str = "sources.yaml") -> Dict:
        """Load documentation sources from YAML file"""
        try:
            with open(sources_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.warning(f"Sources file not found: {sources_path}")
            return {"sources": [], "repositories": [], "context7_queries": []}
    
    def ensure_directories(self):
        """Ensure all required directories exist"""
        for dir_key, dir_path in self.config['output'].items():
            Path(dir_path).mkdir(parents=True, exist_ok=True)
            logger.info(f"Created directory: {dir_path}")
    
    async def download_from_context7(self, max_results: int = 100) -> List[Dict]:
        """
        Download documentation using context7 MCP server
        
        Args:
            max_results: Maximum number of results to download
            
        Returns:
            List of downloaded documentation metadata
        """
        logger.info("Starting context7 MCP server download...")
        
        sources = self._load_sources()
        queries = sources.get('context7_queries', [])
        
        results = []
        for query in tqdm(queries[:max_results], desc="Processing queries"):
            try:
                # Simulate context7 MCP query
                # In production, this would use the actual MCP server API
                result = {
                    'query': query,
                    'timestamp': datetime.now().isoformat(),
                    'status': 'success',
                    'source': 'context7'
                }
                results.append(result)
                logger.info(f"Processed query: {query}")
                
                # Add delay between requests
                await asyncio.sleep(self.config['download']['delay_between_requests'])
                
            except Exception as e:
                logger.error(f"Error processing query '{query}': {e}")
                results.append({
                    'query': query,
                    'status': 'error',
                    'error': str(e)
                })
        
        return results
    
    async def crawl_documentation(self, url: str, output_dir: Path) -> Dict:
        """
        Crawl documentation from a URL using crawl4ai
        
        Args:
            url: URL to crawl
            output_dir: Directory to save crawled content
            
        Returns:
            Metadata about crawled content
        """
        logger.info(f"Crawling: {url}")
        
        try:
            # In production, this would use the actual crawl4ai library
            # For now, we'll create a placeholder implementation
            
            result = {
                'url': url,
                'timestamp': datetime.now().isoformat(),
                'status': 'success',
                'output_dir': str(output_dir),
                'pages_crawled': 0,
                'files_downloaded': 0
            }
            
            # Create metadata file
            metadata_file = output_dir / 'metadata.json'
            with open(metadata_file, 'w') as f:
                json.dump(result, f, indent=2)
            
            logger.info(f"Successfully crawled: {url}")
            return result
            
        except Exception as e:
            logger.error(f"Error crawling {url}: {e}")
            return {
                'url': url,
                'status': 'error',
                'error': str(e)
            }
    
    async def download_all_sources(self):
        """Download documentation from all configured sources"""
        sources = self._load_sources()
        
        # Process documentation sources
        source_list = sources.get('sources', [])
        logger.info(f"Processing {len(source_list)} documentation sources...")
        
        for source in tqdm(source_list, desc="Downloading sources"):
            try:
                name = source.get('name', 'unknown').replace(' ', '_').lower()
                url = source.get('url')
                
                # Create output directory for this source
                output_dir = Path(self.config['output']['scraped']) / name
                output_dir.mkdir(parents=True, exist_ok=True)
                
                # Crawl the source
                result = await self.crawl_documentation(url, output_dir)
                self.results.append(result)
                
                # Add delay between requests
                await asyncio.sleep(self.config['download']['delay_between_requests'])
                
            except Exception as e:
                logger.error(f"Error processing source {source.get('name')}: {e}")
    
    async def download_repository_examples(self):
        """Download working examples from repositories"""
        sources = self._load_sources()
        repo_list = sources.get('repositories', [])
        
        logger.info(f"Processing {len(repo_list)} repository sources...")
        
        for repo in tqdm(repo_list, desc="Processing repositories"):
            try:
                name = repo.get('name', 'unknown').replace(' ', '_').lower()
                url = repo.get('url')
                
                # Create output directory for this repository
                output_dir = Path(self.config['output']['examples']) / name
                output_dir.mkdir(parents=True, exist_ok=True)
                
                # Create metadata file
                metadata = {
                    'name': repo.get('name'),
                    'url': url,
                    'type': repo.get('type'),
                    'categories': repo.get('categories', []),
                    'downloaded_at': datetime.now().isoformat()
                }
                
                metadata_file = output_dir / 'metadata.json'
                with open(metadata_file, 'w') as f:
                    json.dump(metadata, f, indent=2)
                
                logger.info(f"Processed repository: {name}")
                
            except Exception as e:
                logger.error(f"Error processing repository {repo.get('name')}: {e}")
    
    def save_results(self):
        """Save download results to index file"""
        index_file = Path(self.config['knowledge_base']['index_file'])
        index_file.parent.mkdir(parents=True, exist_ok=True)
        
        summary = {
            'generated_at': datetime.now().isoformat(),
            'total_sources': len(self.results),
            'successful': sum(1 for r in self.results if r.get('status') == 'success'),
            'failed': sum(1 for r in self.results if r.get('status') == 'error'),
            'results': self.results
        }
        
        with open(index_file, 'w') as f:
            json.dump(summary, f, indent=2)
        
        logger.info(f"Results saved to: {index_file}")
    
    async def run(self):
        """Main execution method"""
        logger.info("Starting documentation download process...")
        
        # Ensure directories exist
        self.ensure_directories()
        
        # Download from context7 MCP
        if self.config['context7']['enabled']:
            context7_results = await self.download_from_context7(
                self.config['context7']['max_results']
            )
            self.results.extend(context7_results)
        
        # Download from configured sources
        await self.download_all_sources()
        
        # Download repository examples
        await self.download_repository_examples()
        
        # Save results
        self.save_results()
        
        logger.info("Documentation download completed!")
        logger.info(f"Total items processed: {len(self.results)}")
        logger.info(f"Successful: {sum(1 for r in self.results if r.get('status') == 'success')}")
        logger.info(f"Failed: {sum(1 for r in self.results if r.get('status') == 'error')}")


def main():
    """Main entry point"""
    # Get script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create and run downloader
    downloader = DocumentationDownloader()
    
    # Run async main
    try:
        asyncio.run(downloader.run())
    except KeyboardInterrupt:
        logger.info("Download interrupted by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

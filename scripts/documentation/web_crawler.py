#!/usr/bin/env python3
"""
Web Crawler for Knowledge Base using Crawl4AI

This script uses crawl4ai to crawl websites and ingest content
into the knowledge base. It supports:
- Single URL crawling
- Sitemap-based crawling
- Depth-limited recursive crawling
- Content filtering and cleaning
- Automatic categorization
- Markdown conversion
"""

import os
import sys
import json
import asyncio
import argparse
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional
from urllib.parse import urlparse

try:
    from crawl4ai import AsyncWebCrawler, BrowserConfig, CrawlerRunConfig
    from crawl4ai.extraction_strategy import LLMExtractionStrategy
    from crawl4ai.chunking_strategy import RegexChunking
except ImportError:
    print("Error: crawl4ai not installed. Run: pip install crawl4ai")
    sys.exit(1)

from loguru import logger

# Configuration
REPO_ROOT = Path(__file__).parent.parent.parent
KNOWLEDGE_BASE_DIR = REPO_ROOT / "documentation" / "crawled"
METADATA_DIR = KNOWLEDGE_BASE_DIR / "metadata"


class KnowledgeBaseCrawler:
    """Crawler for ingesting web content into knowledge base"""
    
    def __init__(self, output_dir: Optional[Path] = None):
        self.output_dir = output_dir or KNOWLEDGE_BASE_DIR
        self.metadata_dir = METADATA_DIR
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.metadata_dir.mkdir(parents=True, exist_ok=True)
        
        # Configure logger
        logger.add(
            REPO_ROOT / "logs" / "crawler_{time}.log",
            rotation="1 day",
            retention="7 days",
            level="INFO"
        )
    
    async def crawl_url(
        self,
        url: str,
        category: str = "general",
        extract_content: bool = True,
        save_screenshots: bool = False
    ) -> Dict:
        """
        Crawl a single URL and save to knowledge base
        
        Args:
            url: URL to crawl
            category: Category for organization
            extract_content: Whether to extract main content
            save_screenshots: Whether to save page screenshots
            
        Returns:
            Metadata about the crawled content
        """
        logger.info(f"Crawling URL: {url}")
        
        # Configure browser
        browser_config = BrowserConfig(
            headless=True,
            verbose=False
        )
        
        # Configure crawler
        crawler_config = CrawlerRunConfig(
            word_count_threshold=10,
            exclude_external_links=True,
            remove_overlay_elements=True,
            screenshot=save_screenshots
        )
        
        async with AsyncWebCrawler(config=browser_config) as crawler:
            result = await crawler.arun(
                url=url,
                config=crawler_config
            )
            
            if not result.success:
                logger.error(f"Failed to crawl {url}: {result.error_message}")
                return {"success": False, "error": result.error_message}
            
            # Extract content
            content = result.markdown if extract_content else result.html
            
            # Generate filename
            parsed_url = urlparse(url)
            domain = parsed_url.netloc.replace("www.", "")
            path = parsed_url.path.strip("/").replace("/", "_")
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            
            filename = f"{domain}_{path}_{timestamp}.md" if path else f"{domain}_{timestamp}.md"
            
            # Create category directory
            category_dir = self.output_dir / category
            category_dir.mkdir(parents=True, exist_ok=True)
            
            # Save content
            output_path = category_dir / filename
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write(f"# {result.title or 'Untitled'}\n\n")
                f.write(f"**Source:** {url}\n")
                f.write(f"**Crawled:** {datetime.now().isoformat()}\n")
                f.write(f"**Category:** {category}\n\n")
                f.write("---\n\n")
                f.write(content)
            
            # Save metadata
            metadata = {
                "url": url,
                "title": result.title,
                "category": category,
                "filename": str(output_path.relative_to(REPO_ROOT)),
                "crawled_at": datetime.now().isoformat(),
                "word_count": len(content.split()),
                "links_count": len(result.links.get("internal", [])),
                "success": True
            }
            
            metadata_file = self.metadata_dir / f"{filename}.json"
            with open(metadata_file, 'w') as f:
                json.dump(metadata, f, indent=2)
            
            logger.info(f"Saved to: {output_path}")
            
            # Save screenshot if requested
            if save_screenshots and result.screenshot:
                screenshot_path = category_dir / f"{filename.replace('.md', '.png')}"
                with open(screenshot_path, 'wb') as f:
                    f.write(result.screenshot)
                logger.info(f"Screenshot saved to: {screenshot_path}")
            
            return metadata
    
    async def crawl_multiple(
        self,
        urls: List[str],
        category: str = "general",
        max_concurrent: int = 5
    ) -> List[Dict]:
        """
        Crawl multiple URLs concurrently
        
        Args:
            urls: List of URLs to crawl
            category: Category for organization
            max_concurrent: Maximum concurrent crawls
            
        Returns:
            List of metadata for each crawled URL
        """
        logger.info(f"Crawling {len(urls)} URLs...")
        
        semaphore = asyncio.Semaphore(max_concurrent)
        
        async def crawl_with_limit(url):
            async with semaphore:
                return await self.crawl_url(url, category)
        
        tasks = [crawl_with_limit(url) for url in urls]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Filter out exceptions
        successful = [r for r in results if isinstance(r, dict) and r.get("success")]
        logger.info(f"Successfully crawled {len(successful)}/{len(urls)} URLs")
        
        return successful
    
    async def crawl_sitemap(
        self,
        sitemap_url: str,
        category: str = "general",
        limit: Optional[int] = None
    ) -> List[Dict]:
        """
        Crawl all URLs from a sitemap
        
        Args:
            sitemap_url: URL of the sitemap
            category: Category for organization
            limit: Maximum number of URLs to crawl
            
        Returns:
            List of metadata for each crawled URL
        """
        import xml.etree.ElementTree as ET
        import aiohttp
        
        logger.info(f"Fetching sitemap: {sitemap_url}")
        
        async with aiohttp.ClientSession() as session:
            async with session.get(sitemap_url) as response:
                if response.status != 200:
                    logger.error(f"Failed to fetch sitemap: {response.status}")
                    return []
                
                sitemap_xml = await response.text()
        
        # Parse sitemap
        root = ET.fromstring(sitemap_xml)
        namespace = {'ns': 'http://www.sitemaps.org/schemas/sitemap/0.9'}
        
        urls = []
        for url in root.findall('.//ns:url/ns:loc', namespace):
            urls.append(url.text)
            if limit and len(urls) >= limit:
                break
        
        logger.info(f"Found {len(urls)} URLs in sitemap")
        
        # Crawl all URLs
        return await self.crawl_multiple(urls, category)
    
    def generate_index(self) -> Dict:
        """
        Generate an index of all crawled content
        
        Returns:
            Index metadata
        """
        logger.info("Generating index...")
        
        index = {
            "generated_at": datetime.now().isoformat(),
            "categories": {},
            "total_documents": 0
        }
        
        # Scan all metadata files
        for metadata_file in self.metadata_dir.glob("*.json"):
            try:
                with open(metadata_file) as f:
                    metadata = json.load(f)
                
                category = metadata.get("category", "general")
                if category not in index["categories"]:
                    index["categories"][category] = []
                
                index["categories"][category].append({
                    "title": metadata.get("title"),
                    "url": metadata.get("url"),
                    "filename": metadata.get("filename"),
                    "crawled_at": metadata.get("crawled_at"),
                    "word_count": metadata.get("word_count")
                })
                
                index["total_documents"] += 1
            except Exception as e:
                logger.error(f"Error reading metadata {metadata_file}: {e}")
        
        # Save index
        index_file = self.output_dir / "index.json"
        with open(index_file, 'w') as f:
            json.dump(index, f, indent=2)
        
        logger.info(f"Index generated with {index['total_documents']} documents")
        
        return index


async def main():
    """Main CLI interface"""
    parser = argparse.ArgumentParser(
        description="Crawl websites and add to knowledge base"
    )
    
    subparsers = parser.add_subparsers(dest="command", help="Command to run")
    
    # Crawl single URL
    url_parser = subparsers.add_parser("url", help="Crawl a single URL")
    url_parser.add_argument("url", help="URL to crawl")
    url_parser.add_argument("-c", "--category", default="general", help="Category")
    url_parser.add_argument("-s", "--screenshot", action="store_true", help="Save screenshot")
    
    # Crawl multiple URLs
    multi_parser = subparsers.add_parser("multi", help="Crawl multiple URLs")
    multi_parser.add_argument("urls", nargs="+", help="URLs to crawl")
    multi_parser.add_argument("-c", "--category", default="general", help="Category")
    
    # Crawl from file
    file_parser = subparsers.add_parser("file", help="Crawl URLs from file")
    file_parser.add_argument("file", help="File with URLs (one per line)")
    file_parser.add_argument("-c", "--category", default="general", help="Category")
    
    # Crawl sitemap
    sitemap_parser = subparsers.add_parser("sitemap", help="Crawl from sitemap")
    sitemap_parser.add_argument("sitemap_url", help="Sitemap URL")
    sitemap_parser.add_argument("-c", "--category", default="general", help="Category")
    sitemap_parser.add_argument("-l", "--limit", type=int, help="Max URLs to crawl")
    
    # Generate index
    subparsers.add_parser("index", help="Generate index of crawled content")
    
    args = parser.parse_args()
    
    if not args.command:
        parser.print_help()
        return
    
    crawler = KnowledgeBaseCrawler()
    
    if args.command == "url":
        result = await crawler.crawl_url(
            args.url,
            category=args.category,
            save_screenshots=args.screenshot
        )
        print(json.dumps(result, indent=2))
    
    elif args.command == "multi":
        results = await crawler.crawl_multiple(
            args.urls,
            category=args.category
        )
        print(f"Crawled {len(results)} URLs successfully")
    
    elif args.command == "file":
        with open(args.file) as f:
            urls = [line.strip() for line in f if line.strip()]
        results = await crawler.crawl_multiple(
            urls,
            category=args.category
        )
        print(f"Crawled {len(results)}/{len(urls)} URLs successfully")
    
    elif args.command == "sitemap":
        results = await crawler.crawl_sitemap(
            args.sitemap_url,
            category=args.category,
            limit=args.limit
        )
        print(f"Crawled {len(results)} URLs from sitemap")
    
    elif args.command == "index":
        index = crawler.generate_index()
        print(f"Generated index with {index['total_documents']} documents")
        print(f"Categories: {', '.join(index['categories'].keys())}")


if __name__ == "__main__":
    asyncio.run(main())

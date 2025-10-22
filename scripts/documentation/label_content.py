#!/usr/bin/env python3
"""
Content Labeling Script
Automatically labels and categorizes documentation and examples
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


class ContentLabeler:
    """Main class for labeling and categorizing content"""
    
    def __init__(self, config_path: str = "documentation_config.yaml"):
        """Initialize the labeler with configuration"""
        self.config = self._load_config(config_path)
        self.base_dir = Path(self.config['output']['base_dir'])
        self.labeled_items = []
        
    def _load_config(self, config_path: str) -> Dict:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            logger.error(f"Config file not found: {config_path}")
            return {}
    
    def analyze_content(self, file_path: Path) -> Dict:
        """
        Analyze content and generate labels
        
        Args:
            file_path: Path to the file to analyze
            
        Returns:
            Dictionary containing labels and metadata
        """
        labels = {
            'file_path': str(file_path),
            'file_name': file_path.name,
            'categories': [],
            'tags': [],
            'quality_score': 0,
            'difficulty_level': 'unknown',
            'estimated_read_time': 0
        }
        
        if not file_path.exists():
            return labels
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Analyze content
            labels['categories'] = self._categorize(content, file_path)
            labels['tags'] = self._extract_tags(content)
            labels['quality_score'] = self._calculate_quality_score(content)
            labels['difficulty_level'] = self._determine_difficulty(content)
            labels['estimated_read_time'] = self._estimate_read_time(content)
            
        except Exception as e:
            logger.warning(f"Error analyzing {file_path}: {e}")
        
        return labels
    
    def _categorize(self, content: str, file_path: Path) -> List[str]:
        """
        Categorize content based on various signals
        
        Args:
            content: File content
            file_path: Path to the file
            
        Returns:
            List of categories
        """
        categories = []
        content_lower = content.lower()
        
        # Category detection patterns
        category_patterns = {
            'tutorial': [
                r'step\s+\d+', r'how\s+to', r'guide', r'walkthrough',
                r'getting\s+started', r'introduction'
            ],
            'reference': [
                r'api\s+reference', r'documentation', r'specification',
                r'parameters?:', r'returns?:'
            ],
            'guide': [
                r'best\s+practice', r'guideline', r'recommendation',
                r'should', r'must', r'avoid'
            ],
            'api-docs': [
                r'endpoint', r'request', r'response', r'authentication',
                r'authorization', r'http'
            ],
            'examples': [
                r'example', r'sample', r'demo', r'usage',
                r'```', r'code\s+snippet'
            ],
            'best-practices': [
                r'best\s+practice', r'pattern', r'anti-pattern',
                r'convention', r'standard'
            ]
        }
        
        # Check patterns
        for category, patterns in category_patterns.items():
            for pattern in patterns:
                if re.search(pattern, content_lower):
                    categories.append(category)
                    break
        
        # Check file path
        path_str = str(file_path).lower()
        if 'tutorial' in path_str:
            categories.append('tutorial')
        if 'example' in path_str:
            categories.append('examples')
        if 'reference' in path_str or 'api' in path_str:
            categories.append('reference')
        
        return list(set(categories)) if categories else ['general']
    
    def _extract_tags(self, content: str) -> List[str]:
        """
        Extract relevant tags from content
        
        Args:
            content: File content
            
        Returns:
            List of tags
        """
        tags = set()
        content_lower = content.lower()
        
        # Technology tags
        tech_tags = {
            'python': ['python', 'pip', 'virtualenv', 'pypi'],
            'javascript': ['javascript', 'npm', 'node', 'yarn'],
            'typescript': ['typescript', 'tsc'],
            'docker': ['docker', 'dockerfile', 'container'],
            'kubernetes': ['kubernetes', 'k8s', 'kubectl'],
            'api': ['api', 'rest', 'restful', 'graphql'],
            'database': ['database', 'sql', 'nosql', 'db'],
            'web': ['web', 'http', 'https', 'html', 'css'],
            'backend': ['backend', 'server', 'api'],
            'frontend': ['frontend', 'client', 'ui', 'ux'],
            'devops': ['devops', 'ci/cd', 'deployment', 'pipeline'],
            'testing': ['test', 'testing', 'unittest', 'pytest', 'jest'],
            'security': ['security', 'auth', 'encryption', 'ssl', 'tls'],
            'performance': ['performance', 'optimization', 'cache', 'speed'],
            'architecture': ['architecture', 'design', 'pattern', 'microservice'],
            'cloud': ['aws', 'azure', 'gcp', 'cloud'],
            'data': ['data', 'analytics', 'etl', 'processing'],
            'ai': ['ai', 'ml', 'machine learning', 'neural', 'model'],
            'monitoring': ['monitoring', 'logging', 'metrics', 'observability']
        }
        
        for tag, keywords in tech_tags.items():
            if any(keyword in content_lower for keyword in keywords):
                tags.add(tag)
        
        # Framework tags
        frameworks = [
            'django', 'flask', 'fastapi', 'react', 'vue', 'angular',
            'express', 'nextjs', 'gatsby', 'spring', 'rails'
        ]
        
        for framework in frameworks:
            if framework in content_lower:
                tags.add(framework)
        
        return list(tags)
    
    def _calculate_quality_score(self, content: str) -> int:
        """
        Calculate a quality score for the content
        
        Args:
            content: File content
            
        Returns:
            Quality score (0-100)
        """
        score = 50  # Base score
        
        # Check for code blocks
        code_blocks = len(re.findall(r'```', content))
        score += min(code_blocks * 5, 20)
        
        # Check for headings
        headings = len(re.findall(r'^#+\s+', content, re.MULTILINE))
        score += min(headings * 3, 15)
        
        # Check for links
        links = len(re.findall(r'\[.+?\]\(.+?\)', content))
        score += min(links * 2, 10)
        
        # Check length (prefer medium-length docs)
        word_count = len(content.split())
        if 200 <= word_count <= 2000:
            score += 10
        elif word_count > 100:
            score += 5
        
        return min(score, 100)
    
    def _determine_difficulty(self, content: str) -> str:
        """
        Determine the difficulty level of the content
        
        Args:
            content: File content
            
        Returns:
            Difficulty level string
        """
        content_lower = content.lower()
        
        # Beginner indicators
        beginner_keywords = [
            'introduction', 'getting started', 'basic', 'beginner',
            'simple', 'hello world', 'tutorial', 'quick start'
        ]
        
        # Advanced indicators
        advanced_keywords = [
            'advanced', 'expert', 'optimization', 'performance',
            'architecture', 'internal', 'deep dive', 'production'
        ]
        
        beginner_score = sum(1 for k in beginner_keywords if k in content_lower)
        advanced_score = sum(1 for k in advanced_keywords if k in content_lower)
        
        if beginner_score > advanced_score:
            return 'beginner'
        elif advanced_score > beginner_score * 2:
            return 'advanced'
        else:
            return 'intermediate'
    
    def _estimate_read_time(self, content: str) -> int:
        """
        Estimate reading time in minutes
        
        Args:
            content: File content
            
        Returns:
            Estimated minutes to read
        """
        # Average reading speed: 200 words per minute
        word_count = len(content.split())
        return max(1, round(word_count / 200))
    
    def label_directory(self, directory: Path) -> List[Dict]:
        """
        Label all files in a directory
        
        Args:
            directory: Directory to process
            
        Returns:
            List of labeled items
        """
        labeled_items = []
        
        if not directory.exists():
            logger.warning(f"Directory does not exist: {directory}")
            return labeled_items
        
        # Process files
        file_patterns = ['*.md', '*.rst', '*.txt', '*.py', '*.js', '*.ts']
        
        for pattern in file_patterns:
            for file_path in directory.rglob(pattern):
                if file_path.is_file():
                    labels = self.analyze_content(file_path)
                    labeled_items.append(labels)
                    logger.debug(f"Labeled: {file_path}")
        
        return labeled_items
    
    def label_all(self):
        """Label all content in the documentation directory"""
        logger.info("Starting content labeling...")
        
        # Process each documentation directory
        for dir_key, dir_path in self.config['output'].items():
            if dir_key == 'base_dir':
                continue
            
            directory = Path(dir_path)
            if directory.exists():
                logger.info(f"Labeling directory: {directory}")
                items = self.label_directory(directory)
                self.labeled_items.extend(items)
                logger.info(f"Labeled {len(items)} items in {directory}")
        
        logger.info(f"Total items labeled: {len(self.labeled_items)}")
    
    def save_labels(self):
        """Save labels to file"""
        output_file = self.base_dir / 'labels.json'
        
        labels_data = {
            'generated_at': datetime.now().isoformat(),
            'total_items': len(self.labeled_items),
            'labels': self.labeled_items
        }
        
        with open(output_file, 'w') as f:
            json.dump(labels_data, f, indent=2)
        
        logger.info(f"Labels saved to: {output_file}")
        
        # Save summary
        summary_file = self.base_dir / 'labels_summary.yaml'
        
        # Collect statistics
        all_categories = []
        all_tags = []
        difficulty_counts = {}
        
        for item in self.labeled_items:
            all_categories.extend(item.get('categories', []))
            all_tags.extend(item.get('tags', []))
            
            difficulty = item.get('difficulty_level', 'unknown')
            difficulty_counts[difficulty] = difficulty_counts.get(difficulty, 0) + 1
        
        summary = {
            'total_items': len(self.labeled_items),
            'categories': {cat: all_categories.count(cat) 
                          for cat in set(all_categories)},
            'tags': {tag: all_tags.count(tag) for tag in set(all_tags)},
            'difficulty_levels': difficulty_counts,
            'generated_at': labels_data['generated_at']
        }
        
        with open(summary_file, 'w') as f:
            yaml.dump(summary, f, default_flow_style=False)
        
        logger.info(f"Summary saved to: {summary_file}")
    
    def run(self):
        """Main execution method"""
        logger.info("Starting content labeling process...")
        
        # Label all content
        self.label_all()
        
        # Save labels
        if self.labeled_items:
            self.save_labels()
        else:
            logger.warning("No items to label")
        
        logger.info("Content labeling completed!")


def main():
    """Main entry point"""
    # Get script directory
    script_dir = Path(__file__).parent
    os.chdir(script_dir)
    
    # Create and run labeler
    labeler = ContentLabeler()
    
    try:
        labeler.run()
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        raise


if __name__ == "__main__":
    main()

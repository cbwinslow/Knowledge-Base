#!/usr/bin/env python3
"""
Simple RAG Knowledge Base Manager (using only built-in libraries)
Creates a basic RAG system without external dependencies
"""

import os
import sys
import json
import argparse
import hashlib
import math
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass
from datetime import datetime
import re
from collections import Counter

@dataclass
class Document:
    """Represents a document in the knowledge base"""
    file_path: str
    content: str
    metadata: Dict[str, Any]
    doc_id: str

class SimpleRAGKnowledgeBase:
    """Simple RAG-enabled knowledge base manager using TF-IDF"""
    
    def __init__(self, kb_path: str = "/home/cbwinslow/Knowledge-Base", 
                 persist_directory: str = "./simple_rag_db"):
        self.kb_path = Path(kb_path)
        self.persist_directory = Path(persist_directory)
        self.persist_directory.mkdir(exist_ok=True)
        
        # Storage files
        self.docs_file = self.persist_directory / "documents.json"
        self.index_file = self.persist_directory / "tfidf_index.json"
        self.vocab_file = self.persist_directory / "vocabulary.json"
        
        # Load existing data
        self.documents = self._load_documents()
        self.vocabulary = self._load_vocabulary()
        self.tfidf_index = self._load_tfidf_index()
    
    def _load_documents(self) -> Dict[str, Document]:
        """Load documents from storage"""
        if self.docs_file.exists():
            with open(self.docs_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return {
                    doc_id: Document(
                        file_path=doc_data['file_path'],
                        content=doc_data['content'],
                        metadata=doc_data['metadata'],
                        doc_id=doc_data['doc_id']
                    )
                    for doc_id, doc_data in data.items()
                }
        return {}
    
    def _load_vocabulary(self) -> Dict[str, int]:
        """Load vocabulary from storage"""
        if self.vocab_file.exists():
            with open(self.vocab_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def _load_tfidf_index(self) -> Dict[str, Dict[str, float]]:
        """Load TF-IDF index from storage"""
        if self.index_file.exists():
            with open(self.index_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        return {}
    
    def _save_documents(self):
        """Save documents to storage"""
        data = {
            doc_id: {
                'file_path': doc.file_path,
                'content': doc.content,
                'metadata': doc.metadata,
                'doc_id': doc.doc_id
            }
            for doc_id, doc in self.documents.items()
        }
        with open(self.docs_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def _save_vocabulary(self):
        """Save vocabulary to storage"""
        with open(self.vocab_file, 'w', encoding='utf-8') as f:
            json.dump(self.vocabulary, f, indent=2, ensure_ascii=False)
    
    def _save_tfidf_index(self):
        """Save TF-IDF index to storage"""
        with open(self.index_file, 'w', encoding='utf-8') as f:
            json.dump(self.tfidf_index, f, indent=2, ensure_ascii=False)
    
    def _tokenize(self, text: str) -> List[str]:
        """Simple tokenization"""
        # Convert to lowercase and split on non-alphanumeric
        tokens = re.findall(r'\b\w+\b', text.lower())
        # Remove very short tokens and common stop words
        stop_words = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she', 'it', 'we', 'they', 'what', 'which', 'who', 'when', 'where', 'why', 'how'}
        return [token for token in tokens if len(token) > 2 and token not in stop_words]
    
    def _build_vocabulary(self, documents: List[Document]):
        """Build vocabulary from documents"""
        word_counts = Counter()
        for doc in documents:
            tokens = self._tokenize(doc.content)
            word_counts.update(tokens)
        
        # Keep only words that appear in at least 2 documents but not too frequently
        min_docs = max(2, len(documents) // 100)
        max_docs = len(documents) * 0.8
        
        # Count document frequency
        doc_freq = Counter()
        for doc in documents:
            tokens = set(self._tokenize(doc.content))
            doc_freq.update(tokens)
        
        self.vocabulary = {
            word: idx for idx, (word, count) in enumerate(word_counts.items())
            if min_docs <= doc_freq[word] <= max_docs
        }
    
    def _compute_tfidf(self, documents: List[Document]):
        """Compute TF-IDF vectors for documents"""
        n_docs = len(documents)
        
        # Compute document frequency
        doc_freq = Counter()
        for doc in documents:
            tokens = set(self._tokenize(doc.content))
            for token in tokens:
                if token in self.vocabulary:
                    doc_freq[token] += 1
        
        # Compute TF-IDF for each document
        self.tfidf_index = {}
        for doc in documents:
            tokens = self._tokenize(doc.content)
            token_counts = Counter(tokens)
            
            tfidf_vector = {}
            for token, count in token_counts.items():
                if token in self.vocabulary:
                    tf = count / len(tokens)  # Term frequency
                    idf = math.log(n_docs / doc_freq[token])  # Inverse document frequency
                    tfidf_vector[token] = tf * idf
            
            self.tfidf_index[doc.doc_id] = tfidf_vector
    
    def _cosine_similarity(self, query_vector: Dict[str, float], 
                          doc_vector: Dict[str, float]) -> float:
        """Compute cosine similarity between two vectors"""
        # Get common terms
        common_terms = set(query_vector.keys()) & set(doc_vector.keys())
        
        if not common_terms:
            return 0.0
        
        # Compute dot product
        dot_product = sum(query_vector[term] * doc_vector[term] for term in common_terms)
        
        # Compute magnitudes
        query_magnitude = math.sqrt(sum(v**2 for v in query_vector.values()))
        doc_magnitude = math.sqrt(sum(v**2 for v in doc_vector.values()))
        
        if query_magnitude == 0 or doc_magnitude == 0:
            return 0.0
        
        return dot_product / (query_magnitude * doc_magnitude)
    
    def extract_text_from_file(self, file_path: Path) -> str:
        """Extract text content from various file types"""
        try:
            if file_path.suffix.lower() in ['.md', '.txt', '.py', '.sh', '.yaml', '.yml', '.json']:
                return file_path.read_text(encoding='utf-8', errors='ignore')
            else:
                return ""
        except Exception as e:
            print(f"Error reading {file_path}: {e}")
            return ""
    
    def get_file_metadata(self, file_path: Path) -> Dict[str, Any]:
        """Extract metadata from file path and content"""
        stat = file_path.stat()
        
        # Determine category based on path
        path_parts = file_path.relative_to(self.kb_path).parts
        category = path_parts[0] if len(path_parts) > 0 else "root"
        subcategory = path_parts[1] if len(path_parts) > 1 else ""
        
        # Determine file type
        file_type = file_path.suffix.lower().lstrip('.') or 'unknown'
        
        return {
            'file_path': str(file_path.relative_to(self.kb_path)),
            'absolute_path': str(file_path),
            'category': category,
            'subcategory': subcategory,
            'file_type': file_type,
            'file_size': stat.st_size,
            'created_at': datetime.fromtimestamp(stat.st_ctime).isoformat(),
            'modified_at': datetime.fromtimestamp(stat.st_mtime).isoformat(),
            'indexed_at': datetime.now().isoformat()
        }
    
    def index_directory(self, directory: Optional[str] = None, 
                       file_patterns: List[str] = None) -> int:
        """Index documents from the knowledge base"""
        if file_patterns is None:
            file_patterns = ['*.md', '*.txt', '*.py', '*.sh', '*.yaml', '*.yml', '*.json']
        
        if directory:
            search_path = self.kb_path / directory
        else:
            search_path = self.kb_path
        
        documents = []
        indexed_count = 0
        
        print(f"Indexing files in: {search_path}")
        
        for pattern in file_patterns:
            for file_path in search_path.rglob(pattern):
                if file_path.is_file():
                    # Skip certain directories
                    if any(skip in str(file_path) for skip in ['.git', '__pycache__', 'node_modules', '.venv']):
                        continue
                    
                    content = self.extract_text_from_file(file_path)
                    if content and len(content.strip()) > 50:  # Skip very short files
                        metadata = self.get_file_metadata(file_path)
                        doc_id = hashlib.md5(str(file_path).encode()).hexdigest()
                        
                        documents.append(Document(
                            file_path=str(file_path),
                            content=content,
                            metadata=metadata,
                            doc_id=doc_id
                        ))
        
        if documents:
            print(f"Processing {len(documents)} documents...")
            
            # Add to documents storage
            for doc in documents:
                self.documents[doc.doc_id] = doc
            
            # Build vocabulary and TF-IDF index
            self._build_vocabulary(list(self.documents.values()))
            self._compute_tfidf(list(self.documents.values()))
            
            # Save everything
            self._save_documents()
            self._save_vocabulary()
            self._save_tfidf_index()
            
            indexed_count = len(documents)
        
        print(f"Indexed {indexed_count} new documents")
        print(f"Total documents in index: {len(self.documents)}")
        print(f"Vocabulary size: {len(self.vocabulary)}")
        
        return indexed_count
    
    def search(self, query: str, n_results: int = 5, 
               category_filter: Optional[str] = None) -> List[Dict[str, Any]]:
        """Search the knowledge base"""
        # Process query
        query_tokens = self._tokenize(query)
        query_vector = {}
        
        # Compute query TF-IDF
        token_counts = Counter(query_tokens)
        for token, count in token_counts.items():
            if token in self.vocabulary:
                query_vector[token] = count / len(query_tokens)
        
        if not query_vector:
            return []
        
        # Compute similarities
        results = []
        for doc_id, doc in self.documents.items():
            if category_filter and doc.metadata.get('category') != category_filter:
                continue
            
            doc_vector = self.tfidf_index.get(doc_id, {})
            similarity = self._cosine_similarity(query_vector, doc_vector)
            
            if similarity > 0:
                results.append({
                    'doc_id': doc_id,
                    'content': doc.content,
                    'metadata': doc.metadata,
                    'similarity_score': similarity
                })
        
        # Sort by similarity and return top results
        results.sort(key=lambda x: x['similarity_score'], reverse=True)
        return results[:n_results]
    
    def get_stats(self) -> Dict[str, Any]:
        """Get knowledge base statistics"""
        categories = {}
        file_types = {}
        
        for doc in self.documents.values():
            category = doc.metadata.get('category', 'unknown')
            file_type = doc.metadata.get('file_type', 'unknown')
            
            categories[category] = categories.get(category, 0) + 1
            file_types[file_type] = file_types.get(file_type, 0) + 1
        
        return {
            'total_documents': len(self.documents),
            'vocabulary_size': len(self.vocabulary),
            'categories': categories,
            'file_types': file_types,
            'persist_directory': str(self.persist_directory)
        }
    
    def rebuild_index(self) -> int:
        """Rebuild the entire index"""
        # Clear existing data
        self.documents.clear()
        self.vocabulary.clear()
        self.tfidf_index.clear()
        
        # Re-index everything
        return self.index_directory()

def main():
    parser = argparse.ArgumentParser(description='Simple RAG Knowledge Base Manager')
    parser.add_argument('action', choices=['index', 'search', 'stats', 'rebuild'],
                       help='Action to perform')
    parser.add_argument('--query', '-q', help='Search query')
    parser.add_argument('--directory', '-d', help='Directory to index (default: all)')
    parser.add_argument('--results', '-n', type=int, default=5, help='Number of search results')
    parser.add_argument('--category', '-c', help='Filter by category')
    parser.add_argument('--kb-path', default='/home/cbwinslow/Knowledge-Base', 
                       help='Knowledge base path')
    parser.add_argument('--persist-dir', default='./simple_rag_db', 
                       help='RAG database persist directory')
    
    args = parser.parse_args()
    
    rag_kb = SimpleRAGKnowledgeBase(args.kb_path, args.persist_dir)
    
    if args.action == 'index':
        count = rag_kb.index_directory(args.directory)
        print(f"Successfully indexed {count} documents")
    
    elif args.action == 'search':
        if not args.query:
            print("Error: --query is required for search")
            sys.exit(1)
        
        results = rag_kb.search(args.query, args.results, args.category)
        
        if not results:
            print("No results found")
        else:
            print(f"\nFound {len(results)} results for '{args.query}':\n")
            for i, result in enumerate(results, 1):
                print(f"{i}. {result['metadata']['file_path']}")
                print(f"   Category: {result['metadata']['category']}")
                print(f"   Similarity: {result['similarity_score']:.3f}")
                print(f"   Content: {result['content'][:200]}...")
                print()
    
    elif args.action == 'stats':
        stats = rag_kb.get_stats()
        print(f"\nKnowledge Base Statistics:")
        print(f"Total Documents: {stats['total_documents']}")
        print(f"Vocabulary Size: {stats['vocabulary_size']}")
        print(f"\nCategories:")
        for category, count in sorted(stats['categories'].items()):
            print(f"  {category}: {count}")
        print(f"\nFile Types:")
        for file_type, count in sorted(stats['file_types'].items()):
            print(f"  {file_type}: {count}")
        print(f"\nPersist Directory: {stats['persist_directory']}")
    
    elif args.action == 'rebuild':
        count = rag_kb.rebuild_index()
        print(f"Rebuilt index with {count} documents")

if __name__ == "__main__":
    main()
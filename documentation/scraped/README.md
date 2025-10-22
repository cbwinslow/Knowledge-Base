# Scraped Documentation

This directory contains documentation scraped from various official and community sources using crawl4ai.

## Purpose

Provides:
- Official documentation from authoritative sources
- Tutorial content from learning platforms
- API documentation
- Framework and library documentation

## Sources

Documentation is scraped from:
- Official documentation sites (Python, Docker, Kubernetes, etc.)
- Tutorial platforms (Real Python, MDN, etc.)
- API documentation (OpenAI, Anthropic, etc.)
- Framework documentation (Django, React, FastAPI, etc.)

See `scripts/documentation/sources.yaml` for the complete list.

## Organization

Content is organized by source:
```
scraped/
├── python_official_docs/
├── docker_docs/
├── kubernetes_docs/
└── ...
```

Each source directory contains:
- Scraped documentation files
- `metadata.json` with source information
- Preserved directory structure when applicable

## Metadata

Each source includes metadata:
- Source URL
- Download timestamp
- Content type
- Categories and tags

## Updates

To update scraped documentation:

```bash
cd scripts/documentation
python3 download_documentation.py
python3 ingest_knowledge.py
```

## Search

Search scraped documentation:

```bash
cd scripts/documentation
python3 manage_knowledge_base.py search "docker containers"
```

## Quality

Content quality is maintained by:
- Filtering based on configuration rules
- Automatic quality scoring
- Source reputation and priority
- Content validation

## Maintenance

Scraped content is managed by:
- `download_documentation.py` - Scrapes using crawl4ai
- `ingest_knowledge.py` - Indexes content
- `label_content.py` - Categorizes and tags
- `manage_knowledge_base.py` - Maintenance and cleanup

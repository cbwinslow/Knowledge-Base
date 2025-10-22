# Working Examples

This directory contains working code examples collected from various repositories and documentation sources.

## Purpose

Provides:
- Production-ready code examples
- Best practice implementations
- Common use case solutions
- Learning resources

## Organization

Examples are organized by:
- **Programming Language** (Python, JavaScript, etc.)
- **Framework** (Django, React, etc.)
- **Category** (API, Database, Testing, etc.)
- **Source Repository**

## Index Files

- `examples_index.json` - Complete index of all examples
- `examples_summary.yaml` - Summary statistics

## Content Structure

Each example includes:
- Source code files
- Metadata (language, tags, description)
- Source attribution
- Usage notes

## Finding Examples

Use the management script to search:

```bash
cd scripts/documentation
python3 manage_knowledge_base.py search "api example"
```

Or browse the index files directly.

## Maintenance

Examples are collected by:
- `download_documentation.py` - Downloads from repositories
- `ingest_examples.py` - Processes and indexes examples
- `label_content.py` - Labels and categorizes

Run these scripts to update the collection.

# Top 100 Documentation Results

This directory contains the top 100 most relevant documentation results retrieved using the context7 MCP server.

## Purpose

Provides:
- Highest quality documentation
- Most relevant content based on configured queries
- Curated documentation for specific topics
- Priority content for AI agents

## Selection Process

Content is selected by:
1. Running context7 MCP server queries
2. Retrieving top results for each query
3. Ranking by relevance and quality
4. Selecting top 100 overall

## Query Topics

Queries are configured in `scripts/documentation/sources.yaml`:
- Python best practices
- API design patterns
- Docker deployment
- Kubernetes configuration
- CI/CD pipelines
- Microservices architecture
- Database design
- Testing frameworks
- And more...

## Organization

Content is organized by:
- Query topic
- Relevance score
- Content type
- Source quality

## Quality

Top 100 content is selected based on:
- Relevance to queries
- Source authority
- Content completeness
- Code example quality
- Community validation

## Index

The collection includes:
- Individual documentation files
- Metadata for each item
- Overall quality scores
- Source attribution

## Updates

To update the top 100:

```bash
cd scripts/documentation
python3 download_documentation.py
```

The script will:
1. Query context7 MCP server
2. Retrieve and rank results
3. Select top 100
4. Download and organize

## Configuration

Configure queries in `scripts/documentation/sources.yaml`:

```yaml
context7_queries:
  - "Your query here"
  - "Another query"
```

Adjust the number of results in `scripts/documentation/documentation_config.yaml`:

```yaml
context7:
  enabled: true
  max_results: 100
```

## Usage

This collection is ideal for:
- Quick reference for common tasks
- Learning best practices
- Finding high-quality examples
- AI agent context documents

## Search

Search the top 100:

```bash
cd scripts/documentation
python3 manage_knowledge_base.py search "query" --tags top100
```

## Maintenance

Content is maintained by:
- Regular re-queries to context7 MCP
- Quality validation
- Outdated content removal
- Source verification

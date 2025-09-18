# CloudCurio KB Stack

Multi-graph, versioned knowledge base using TerminusDB (authoritative), Neo4j, JanusGraph/NebulaGraph, OpenSearch, Qdrant, and a FastAPI BFF.

## Quickstart
1) Copy `.env.example` to `.env` and set secrets
2) `docker compose up -d`
3) `make bootstrap` to create DB/branches and apply schema
4) `make init` to initialize indexes

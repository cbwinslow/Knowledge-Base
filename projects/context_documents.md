## Context Documents for OpenDiscourse Project

This file collects concise context summaries—in Markdown—for each major area covered in the project.

---

### 1. AI Agent Heuristics
Based on `ai_agent_heuristics.md`:
- Bootstrapped with Create React App (CRA).
- Standard scripts: `npm start`, `npm test`, `npm run build`, `npm run eject`.
- Development guidance: use CRA docs and React docs for learning.
- **Tech Stack Research:** React, JavaScript, Jest for testing, Webpack for bundling, ESLint and Prettier for code quality.

---

### 2. Intelligent Project Breakdown Workflow
From `project_breakdown_workflow.txt`:
- **Frontend:** React + HTML/CSS.
- **Backend:** Node.js + Express.
- **Database:** MongoDB.
- **Agents:** TensorFlow.js microservices:
  - Project Agent (NLP breakdown)
  - Task Agents (microgoals execution)
  - Batch Manager (jobs scheduling)
- **Tech Stack Research:** TensorFlow.js, Express, MongoDB, Docker for microservices, Kubernetes for orchestration.

---

### 3. OpenDiscourse RAG Integration
From `opendiscourse_rag_integration.md`:
- **Vector DB:** Weaviate.
- **RAG Engine:** Verba.
- **Advanced Retrieval:** HyDE, Fusion, Self-RAG.
- **Local Dev:** simple-local-rag.
- **Embeddings:** text-embedding-3-small / bge-large.
- **Monorepo:** moon.
- **Roadmap Phases:** Boot → Ingest → MVP → Advanced → GraphRAG → UX.
- **Tech Stack Research:** Weaviate, Verba, LangChain, PyTorch or TensorFlow for embeddings, Kubernetes for scalable deployment.

---

### 4. Composite AI Agent Strategy
From `ai_agent_composite_model(2).md`:
- **Execution Flow:** Goal ingestion → DAG construction → microgoal decomposition → agent allocation → execution → ensemble arbitration → feedback loop.
- **Agent roles:** Planner, Builder, Refiner, Verifier, Meta-Agent.
- **Tech stack:** Dockerized FastAPI + Celery + Redis + PostgreSQL.
- **Tech Stack Research:** FastAPI, Celery, Redis, PostgreSQL, Docker Compose, Kubernetes for container orchestration.

---

### 5. Government Document Crawling Guide
From `GovDoc_Crawling_and_Discovery_Guide.pdf`:
- **Discovery:** Crawling (Scrapy), search APIs, RSS, sitemaps, Wayback.
- **Advanced:** IP scanning, ASN mapping, CT logs, DNS brute.
- **Tools:** Scrapy, Playwright, BeautifulSoup; pdfminer, pytesseract; PostgreSQL, Qdrant, Elasticsearch.
- **Next Steps:** Build crawler, integrate IP scanning, AI classify & index.
- **Tech Stack Research:** Scrapy, Playwright for browser automation, Elasticsearch and Qdrant for indexing and retrieval, Python OCR libraries.

---

### 6. AI News Website Framework
From `AI News Website Framework_.pdf`:
- **Vision:** Autonomous news pipeline via OpenRouter + multi-agent MAS.
- **Key agents:** Research, Content Draft, SEO, Fact-Check, Ethics, Publishing, Overseer.
- **Core features:** PDF ingestion, web search, model routing, citations, pseudonyms.
- **Architecture:** Django/Express backend, React frontend, Ghost/WordPress CMS, vector + relational DB.
- **Tech Stack Research:** Django, React, Express, WordPress/Ghost for CMS, Elasticsearch for search indexing, Docker and Kubernetes.

---

### 7. Software Requirements Specification (SRS)
From `SRS.md`:
- **Functional:** Multi-agent orchestration, microgoal tracking, automation scripts, documentation.
- **Microgoals:** Ollama integration, Agent-Zero, Codex setup, DB scripts, docs creation.
- **Non-Functional:** Security, auditability, cross-platform.
- **Tech Stack Research:** Ollama, Agent-Zero, OpenAI Codex API, PostgreSQL, CI/CD pipelines (GitHub Actions).

---

### 8. Project Task Board
From `project_tasks.md`:
- Tracks status of each microgoal.
- Categories: Ollama, Agent-Zero, Codex, docs, scripts, UI integration.
- **Tech Stack Research:** Trello or Jira for task tracking, GitHub Project boards for integration.

---

### 9. Deployment Guide
From `README-DEPLOYMENT.md`:
- **Infra:** Kubernetes + Ceph.
- **Components:** React/Express, NVIDIA NIM RAG, PostgreSQL + pgvector, Ceph storage.
- **Steps:** Clone, configure env, update k8s manifests, deploy script.
- **Scaling:** HPA for web & workers.
- **Monitoring & Troubleshooting:** logs, health checks, autoscaling.
- **Tech Stack Research:** Kubernetes, Ceph for storage, NVIDIA NIM, pgvector, Prometheus and Grafana for monitoring.

---

### 10. Project Structure
From `PROJECT_STRUCTURE.md`:
- **Root:** .env, Docker, package.json, config files.
- **Client:** React pages & components.
- **Server:** Express API, controllers, services, workers, scripts.
- **Shared:** TypeScript schemas.
- **Docs & CI/CD:** GitHub Actions, k8s manifests, deploy scripts.
- **Tech Stack Research:** Docker, GitHub Actions, React, Express, TypeScript, Kubernetes.

---

> _Use these context summaries as a reference and derive more detailed markdown files where needed._


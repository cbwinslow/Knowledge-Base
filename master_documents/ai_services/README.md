# AI Services

This directory contains setup and configuration files for AI services.

## Services Installed

- [LocalAI](localai/) - API to run LLMs locally
- [AnythingLLM](anythingllm/) - Private ChatGPT-like application

## Services to Install

- GPT4All
- LM Studio
- Archon
- LocalRecall
- Graphite
- Flowise
- n8n
- SearXNG
- Supabase

## Setup

Each service has its own directory with:
- A `docker-compose.yml` file for container configuration
- A setup script to pull images and start services
- A README with usage instructions

## Prerequisites

- Docker
- Docker Compose

## Usage

Navigate to each service directory and run the setup script:
```bash
cd localai
./setup_localai.sh
```

#!/bin/bash

# AnythingLLM Setup Script

echo "Setting up AnythingLLM..."

# Create necessary directories
mkdir -p storage

# Pull the AnythingLLM Docker image
echo "Pulling AnythingLLM Docker image..."
docker pull mintplexlabs/anythingllm:latest

# Start AnythingLLM using docker-compose
echo "Starting AnythingLLM..."
docker-compose up -d

echo "AnythingLLM setup complete!"
echo "You can access AnythingLLM at http://localhost:3001"
echo "Check logs with: docker-compose logs -f"

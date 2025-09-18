#!/bin/bash

# LocalAI Setup Script

echo "Setting up LocalAI..."

# Create necessary directories
mkdir -p models config

# Pull the LocalAI Docker image
echo "Pulling LocalAI Docker image..."
docker pull localai/localai:latest

# Create a basic configuration
echo "Creating basic configuration..."
echo "debug: true" > config/application.yaml

# Start LocalAI using docker-compose
echo "Starting LocalAI..."
docker-compose up -d

echo "LocalAI setup complete!"
echo "You can access LocalAI at http://localhost:8080"
echo "Check logs with: docker-compose logs -f"

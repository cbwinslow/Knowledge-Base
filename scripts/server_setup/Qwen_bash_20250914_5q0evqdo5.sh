#!/bin/bash

# Setup vector databases (Pinecone alternatives, ChromaDB, etc.)
echo "Setting up vector databases..."

mkdir -p /opt/vector-dbs/{chroma,weaviate,qdrant,milvus}

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    apt update
    apt install -y docker-compose
fi

# Setup ChromaDB
cat > /opt/vector-dbs/chroma/docker-compose.yml << EOF
version: "3.9"

services:
  chromadb:
    image: chromadb/chroma:0.4.15
    container_name: chromadb
    environment:
      - IS_PERSISTENT=TRUE
      - CHROMA_SERVER_AUTHN_PROVIDER=chromadb.auth.token_authn.TokenAuthnProvider
      - CHROMA_SERVER_AUTHN_CREDENTIALS=chroma-token
      - CHROMA_SERVER_AUTHN_CREDENTIALS_FILE=/chroma/chroma-token.txt
    volumes:
      - chroma_data:/chroma/chroma-data
    ports:
      - "8000:8000"
    restart: unless-stopped
    networks:
      - vector-net

volumes:
  chroma_data:

networks:
  vector-net:
    driver: bridge
EOF

# Setup Qdrant
cat > /opt/vector-dbs/qdrant/docker-compose.yml << EOF
version: "3.8"

services:
  qdrant:
    image: qdrant/qdrant:v1.3.0
    container_name: qdrant
    volumes:
      - qdrant_storage:/qdrant/storage
    ports:
      - "6333:6333"
      - "6334:6334"
    restart: unless-stopped
    networks:
      - vector-net

volumes:
  qdrant_storage:

networks:
  vector-net:
    driver: bridge
EOF

# Setup Weaviate
cat > /opt/vector-dbs/weaviate/docker-compose.yml << EOF
version: '3.4'
services:
  weaviate:
    image: semitechnologies/weaviate:1.21.4
    container_name: weaviate
    ports:
     - 8080:8080
     - 50051:50051
    restart: on-failure:0
    environment:
      QUERY_DEFAULTS_LIMIT: 25
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: 'true'
      PERSISTENCE_DATA_PATH: '/var/lib/weaviate'
      DEFAULT_VECTORIZER_MODULE: 'none'
      CLUSTER_HOSTNAME: 'node1'
      ENABLE_MODULES: 'text2vec-transformers'
    volumes:
      - weaviate_data:/var/lib/weaviate
    networks:
      - vector-net

volumes:
  weaviate_data:

networks:
  vector-net:
    driver: bridge
EOF

# Start vector databases
cd /opt/vector-dbs/chroma
docker-compose up -d

cd /opt/vector-dbs/qdrant
docker-compose up -d

cd /opt/vector-dbs/weaviate
docker-compose up -d

echo "Vector databases setup completed."
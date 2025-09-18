#!/usr/bin/env bash
#===============================================================================
# ██╗   ██╗███████╗████████╗ █████╗ ██████╗  ██████╗ ███████╗    ██████╗  █████╗ ████████╗ █████╗ 
# ██║   ██║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔════╝ ██╔════╝    ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
# ██║   ██║███████╗   ██║   ███████║██████╔╝██║  ███╗█████╗      ██║  ██║███████║   ██║   ███████║
# ╚██╗ ██╔╝╚════██║   ██║   ██╔══██║██╔══██╗██║   ██║██╔══╝      ██║  ██║██╔══██║   ██║   ██╔══██║
#  ╚████╔╝ ███████║   ██║   ██║  ██║██║  ██║╚██████╔╝███████╗    ██████╔╝██║  ██║   ██║   ██║  ██║
#   ╚═══╝  ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
#===============================================================================
# File: vector_db_tool.sh
# Description: Vector database management and search tool
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -Eeuo pipefail

# Global variables
LOG_FILE="/tmp/vector_db_tool.log"
TEMP_DIR="/tmp/vector_db_tool"
VECTORDB_CONFIG="/etc/vector_db/config.conf"
VECTORDB_DATA_DIR="/var/lib/vector_db"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() { echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "$LOG_FILE"; }
info() { echo -e "${GREEN}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
error() { echo -e "${RED}[ERROR]${NC} $*" | tee -a "$LOG_FILE"; }
debug() { [[ "${DEBUG:-0}" == "1" ]] && echo -e "${PURPLE}[DEBUG]${NC} $*" | tee -a "$LOG_FILE" || true; }

# Utility functions
print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}Vector Database Tool - Management and Search${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

print_section_header() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

print_divider() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Running without root privileges - some operations may be limited"
    fi
}

create_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

cleanup() {
    rm -rf "$TEMP_DIR"
    debug "Cleaned up temporary files"
}

trap cleanup EXIT

# Vector database functions
check_vector_db_status() {
    print_section_header "Vector Database Status"
    
    # Check if PostgreSQL with pgvector is installed
    if command -v psql >/dev/null 2>&1; then
        echo -e "${GREEN}PostgreSQL: ${NC}INSTALLED ($(psql --version | head -1))"
        
        # Check if pgvector extension is available
        if psql -t -c "SELECT 1 FROM pg_extension WHERE extname = 'vector';" 2>/dev/null | grep -q 1; then
            echo -e "${GREEN}pgvector Extension: ${NC}INSTALLED"
        else
            echo -e "${YELLOW}pgvector Extension: ${NC}NOT INSTALLED"
        fi
    else
        echo -e "${RED}PostgreSQL: ${NC}NOT INSTALLED"
    fi
    
    # Check if Qdrant is installed
    if command -v qdrant >/dev/null 2>&1; then
        echo -e "${GREEN}Qdrant: ${NC}INSTALLED ($(qdrant --version 2>&1 | head -1))"
    elif [[ -f "/usr/local/bin/qdrant" ]]; then
        echo -e "${GREEN}Qdrant: ${NC}INSTALLED (/usr/local/bin/qdrant)"
    else
        echo -e "${YELLOW}Qdrant: ${NC}NOT INSTALLED"
    fi
    
    # Check if Weaviate is installed
    if command -v weaviate >/dev/null 2>&1; then
        echo -e "${GREEN}Weaviate: ${NC}INSTALLED ($(weaviate version 2>&1 | head -1))"
    elif docker ps | grep -q weaviate; then
        echo -e "${GREEN}Weaviate: ${NC}RUNNING IN DOCKER"
    else
        echo -e "${YELLOW}Weaviate: ${NC}NOT INSTALLED/RUNNING"
    fi
    
    # Check if Milvus is installed
    if docker ps | grep -q milvus; then
        echo -e "${GREEN}Milvus: ${NC}RUNNING IN DOCKER"
    else
        echo -e "${YELLOW}Milvus: ${NC}NOT RUNNING"
    fi
    
    echo
    info "Vector database status check completed"
}

initialize_pgvector() {
    local database=${1:-"postgres"}
    local user=${2:-"postgres"}
    
    print_section_header "Initializing pgvector Extension"
    
    # Check if PostgreSQL is installed
    if ! command -v psql >/dev/null 2>&1; then
        error "PostgreSQL is not installed"
        return 1
    fi
    
    # Enable pgvector extension
    echo -e "${GREEN}Enabling pgvector extension in database: $database${NC}"
    
    if psql -U "$user" -d "$database" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1; then
        echo -e "${GREEN}SUCCESS: pgvector extension enabled${NC}"
    else
        error "Failed to enable pgvector extension"
        return 1
    fi
    
    # Verify extension is enabled
    if psql -U "$user" -d "$database" -t -c "SELECT extname FROM pg_extension WHERE extname = 'vector';" | grep -q vector; then
        echo -e "${GREEN}VERIFIED: pgvector extension is active${NC}"
    else
        error "Verification failed - extension not active"
        return 1
    fi
    
    # Create a sample vector table
    echo -e "${GREEN}Creating sample vector table${NC}"
    psql -U "$user" -d "$database" <<EOF
CREATE TABLE IF NOT EXISTS documents (
    id bigserial PRIMARY KEY,
    content text,
    embedding vector(1536),
    metadata jsonb
);
CREATE INDEX ON documents USING ivfflat (embedding vector_cosine_ops);
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Sample vector table created${NC}"
    else
        error "Failed to create sample vector table"
        return 1
    fi
    
    info "pgvector initialization completed"
}

create_vector_table() {
    local database=$1
    local table_name=$2
    local dimensions=${3:-1536}
    local user=${4:-"postgres"}
    
    if [[ -z "$database" ]] || [[ -z "$table_name" ]]; then
        error "Database name and table name are required"
        return 1
    fi
    
    print_section_header "Creating Vector Table: $table_name"
    
    # Check if PostgreSQL is installed
    if ! command -v psql >/dev/null 2>&1; then
        error "PostgreSQL is not installed"
        return 1
    fi
    
    # Check if pgvector extension is enabled
    if ! psql -U "$user" -d "$database" -t -c "SELECT extname FROM pg_extension WHERE extname = 'vector';" | grep -q vector; then
        error "pgvector extension is not enabled in database $database"
        return 1
    fi
    
    # Create the vector table
    echo -e "${GREEN}Creating vector table with $dimensions dimensions${NC}"
    psql -U "$user" -d "$database" <<EOF
CREATE TABLE IF NOT EXISTS $table_name (
    id bigserial PRIMARY KEY,
    content text,
    embedding vector($dimensions),
    metadata jsonb,
    created_at timestamp DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for efficient similarity search
CREATE INDEX ON $table_name USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX ON $table_name USING hnsw (embedding vector_l2_ops);
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Vector table $table_name created${NC}"
        
        # Show table structure
        echo
        echo -e "${GREEN}Table Structure:${NC}"
        psql -U "$user" -d "$database" -c "\d $table_name" | sed "s/^/  /"
    else
        error "Failed to create vector table $table_name"
        return 1
    fi
    
    info "Vector table creation completed"
}

insert_vector_data() {
    local database=$1
    local table_name=$2
    local content_file=$3
    local user=${4:-"postgres"}
    
    if [[ -z "$database" ]] || [[ -z "$table_name" ]] || [[ -z "$content_file" ]]; then
        error "Database name, table name, and content file are required"
        return 1
    fi
    
    if [[ ! -f "$content_file" ]]; then
        error "Content file $content_file does not exist"
        return 1
    fi
    
    print_section_header "Inserting Vector Data into $table_name"
    
    # Check if PostgreSQL is installed
    if ! command -v psql >/dev/null 2>&1; then
        error "PostgreSQL is not installed"
        return 1
    fi
    
    # For demonstration, we'll insert sample data
    # In a real implementation, you would use an embedding model to generate vectors
    echo -e "${GREEN}Inserting sample vector data${NC}"
    
    # Insert sample data
    psql -U "$user" -d "$database" <<EOF
INSERT INTO $table_name (content, embedding, metadata) VALUES
('This is a sample document about artificial intelligence', 
 '[0.1,0.2,0.3,0.4,0.5]', 
 '{"category": "technology", "author": "system"}'),
('Machine learning is a subset of artificial intelligence', 
 '[0.2,0.3,0.4,0.5,0.6]', 
 '{"category": "technology", "author": "system"}'),
('Natural language processing enables computers to understand human language', 
 '[0.3,0.4,0.5,0.6,0.7]', 
 '{"category": "linguistics", "author": "system"}');
EOF
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}SUCCESS: Sample vector data inserted${NC}"
        
        # Show inserted data
        echo
        echo -e "${GREEN}Inserted Records:${NC}"
        psql -U "$user" -d "$database" -c "SELECT id, content, metadata FROM $table_name ORDER BY id;" | sed "s/^/  /"
    else
        error "Failed to insert vector data"
        return 1
    fi
    
    info "Vector data insertion completed"
}

search_similar_vectors() {
    local database=$1
    local table_name=$2
    local query_vector=$3
    local limit=${4:-5}
    local user=${5:-"postgres"}
    
    if [[ -z "$database" ]] || [[ -z "$table_name" ]] || [[ -z "$query_vector" ]]; then
        error "Database name, table name, and query vector are required"
        return 1
    fi
    
    print_section_header "Searching Similar Vectors"
    
    # Check if PostgreSQL is installed
    if ! command -v psql >/dev/null 2>&1; then
        error "PostgreSQL is not installed"
        return 1
    fi
    
    # Perform similarity search
    echo -e "${GREEN}Performing cosine similarity search${NC}"
    echo -e "${GREEN}Query vector: $query_vector${NC}"
    echo -e "${GREEN}Top $limit similar results:${NC}"
    
    psql -U "$user" -d "$database" <<EOF
SELECT 
    id,
    content,
    metadata,
    1 - (embedding <=> '$query_vector') AS cosine_similarity
FROM $table_name 
ORDER BY embedding <=> '$query_vector'
LIMIT $limit;
EOF
    
    if [[ $? -ne 0 ]]; then
        error "Failed to perform similarity search"
        return 1
    fi
    
    info "Similarity search completed"
}

vectorize_text() {
    local text="$1"
    
    if [[ -z "$text" ]]; then
        error "Text to vectorize is required"
        return 1
    fi
    
    print_section_header "Vectorizing Text"
    
    echo -e "${GREEN}Text to vectorize:${NC}"
    echo "  $text"
    echo
    
    # In a real implementation, you would use an embedding model
    # For demonstration, we'll generate a mock vector
    echo -e "${YELLOW}Note: This is a mock implementation. In production, use an actual embedding model.${NC}"
    
    # Mock vector generation (in reality, you'd use OpenAI, Sentence Transformers, etc.)
    MOCK_VECTOR="[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]"
    echo -e "${GREEN}Generated vector:${NC}"
    echo "  $MOCK_VECTOR"
    
    # In a real implementation, you might do something like:
    # curl -X POST "http://localhost:11434/api/embeddings" \
    #   -H "Content-Type: application/json" \
    #   -d '{"model": "nomic-embed-text", "prompt": "'"$text"'"}'
    
    info "Text vectorization completed (mock implementation)"
}

show_pgvector_info() {
    local database=${1:-"postgres"}
    local user=${2:-"postgres"}
    
    print_section_header "pgvector Information"
    
    # Check if PostgreSQL is installed
    if ! command -v psql >/dev/null 2>&1; then
        error "PostgreSQL is not installed"
        return 1
    fi
    
    # Show pgvector version
    echo -e "${GREEN}pgvector Version:${NC}"
    psql -U "$user" -d "$database" -c "SELECT extversion FROM pg_extension WHERE extname = 'vector';" 2>/dev/null || echo "  Not installed"
    
    echo
    echo -e "${GREEN}Available Vector Operations:${NC}"
    echo "  - vector_l2_ops: L2 distance"
    echo "  - vector_ip_ops: Inner product"
    echo "  - vector_cosine_ops: Cosine distance"
    
    echo
    echo -e "${GREEN}Available Index Types:${NC}"
    echo "  - ivfflat: Inverted file flat"
    echo "  - hnsw: Hierarchical navigable small world"
    
    echo
    echo -e "${GREEN}Sample Usage:${NC}"
    echo "  CREATE TABLE items (id bigserial, embedding vector(3));"
    echo "  CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops);"
    echo "  SELECT * FROM items ORDER BY embedding <-> '[1,2,3]' LIMIT 5;"
}

install_qdrant() {
    print_section_header "Installing Qdrant Vector Database"
    
    # Check if Docker is available (preferred installation method)
    if command -v docker >/dev/null 2>&1; then
        echo -e "${GREEN}Installing Qdrant via Docker${NC}"
        
        # Pull and run Qdrant
        docker pull qdrant/qdrant:latest
        
        # Create Qdrant data directory
        mkdir -p /var/lib/qdrant
        
        # Run Qdrant container
        docker run -d \
            --name qdrant \
            -p 6333:6333 \
            -p 6334:6334 \
            -v /var/lib/qdrant:/qdrant/storage \
            qdrant/qdrant:latest
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}SUCCESS: Qdrant installed and running${NC}"
            echo -e "${GREEN}Access Qdrant at: http://localhost:6333${NC}"
        else
            error "Failed to install/run Qdrant"
            return 1
        fi
    else
        echo -e "${YELLOW}Docker not available, checking for binary installation${NC}"
        
        # Try to download binary
        if command -v wget >/dev/null 2>&1; then
            echo -e "${GREEN}Downloading Qdrant binary${NC}"
            mkdir -p /tmp/qdrant
            cd /tmp/qdrant
            wget -O qdrant.tar.gz https://github.com/qdrant/qdrant/releases/latest/download/qdrant-x86_64-unknown-linux-gnu.tar.gz
            
            if [[ -f "qdrant.tar.gz" ]]; then
                tar -xzf qdrant.tar.gz
                chmod +x qdrant
                sudo cp qdrant /usr/local/bin/
                echo -e "${GREEN}SUCCESS: Qdrant binary installed to /usr/local/bin/qdrant${NC}"
            else
                error "Failed to download Qdrant binary"
                return 1
            fi
        else
            error "Neither Docker nor wget available for Qdrant installation"
            return 1
        fi
    fi
    
    info "Qdrant installation completed"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  status                          Check vector database status"
    echo "  init-pgvector [db] [user]       Initialize pgvector extension"
    echo "  create-table <db> <table> [dim] [user]  Create vector table"
    echo "  insert-data <db> <table> <file> [user]  Insert vector data"
    echo "  search <db> <table> <vector> [limit] [user]  Search similar vectors"
    echo "  vectorize <text>                Vectorize text (mock implementation)"
    echo "  pgvector-info [db] [user]       Show pgvector information"
    echo "  install-qdrant                  Install Qdrant vector database"
    echo "  help                           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 status"
    echo "  $0 init-pgvector mydb postgres"
    echo "  $0 create-table mydb documents 1536 postgres"
    echo "  $0 insert-data mydb documents /path/to/content.txt postgres"
    echo "  $0 search mydb documents '[0.1,0.2,0.3]' 10 postgres"
    echo "  $0 vectorize \"This is sample text to vectorize\""
    echo "  $0 pgvector-info mydb postgres"
    echo "  $0 install-qdrant"
}

# Main execution
main() {
    # Allow help commands without root
    local command=${1:-"help"}
    
    if [[ "$command" == "help" ]] || [[ "$command" == "--help" ]] || [[ "$command" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    check_root
    create_temp_dir
    
    local command=${1:-"help"}
    
    case "$command" in
        status)
            check_vector_db_status
            ;;
        init-pgvector)
            local db="${2:-postgres}"
            local user="${3:-postgres}"
            initialize_pgvector "$db" "$user"
            ;;
        create-table)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]]; then
                error "Database name and table name required for create-table command"
                show_usage
                exit 1
            fi
            local db="$2"
            local table="$3"
            local dim="${4:-1536}"
            local user="${5:-postgres}"
            create_vector_table "$db" "$table" "$dim" "$user"
            ;;
        insert-data)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]] || [[ -z "${4:-}" ]]; then
                error "Database name, table name, and content file required for insert-data command"
                show_usage
                exit 1
            fi
            local db="$2"
            local table="$3"
            local file="$4"
            local user="${5:-postgres}"
            insert_vector_data "$db" "$table" "$file" "$user"
            ;;
        search)
            if [[ -z "${2:-}" ]] || [[ -z "${3:-}" ]] || [[ -z "${4:-}" ]]; then
                error "Database name, table name, and query vector required for search command"
                show_usage
                exit 1
            fi
            local db="$2"
            local table="$3"
            local vector="$4"
            local limit="${5:-5}"
            local user="${6:-postgres}"
            search_similar_vectors "$db" "$table" "$vector" "$limit" "$user"
            ;;
        vectorize)
            if [[ -z "${2:-}" ]]; then
                error "Text required for vectorize command"
                show_usage
                exit 1
            fi
            local text="$2"
            vectorize_text "$text"
            ;;
        pgvector-info)
            local db="${2:-postgres}"
            local user="${3:-postgres}"
            show_pgvector_info "$db" "$user"
            ;;
        install-qdrant)
            install_qdrant
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: $command"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
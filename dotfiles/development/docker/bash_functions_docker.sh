#!/bin/bash
# Docker Functions - Template
# Category: Container Management
# Description: Functions for managing Docker containers, images, and resources
# Usage: Source this file in your .bashrc or .zshrc
# Author: Knowledge Base Team
# Last Updated: 2025-11-01

# =============================================================================
# Container Management
# =============================================================================

# Function: docker_list_running
# Description: List all running Docker containers
# Usage: docker_list_running
# Returns: Formatted list of running containers
docker_list_running() {
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function: docker_list_all
# Description: List all Docker containers (including stopped)
# Usage: docker_list_all
# Returns: Formatted list of all containers
docker_list_all() {
    docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Function: docker_start_container
# Description: Start a Docker container by name or ID
# Usage: docker_start_container <container_name_or_id>
# Arguments:
#   $1 - Container name or ID
# Returns: 0 on success, 1 on failure
# Example: docker_start_container myapp
docker_start_container() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_start_container <container_name_or_id>"
        return 1
    fi
    
    local container="$1"
    
    echo "Starting container: $container"
    docker start "$container"
}

# Function: docker_stop_container
# Description: Stop a Docker container by name or ID
# Usage: docker_stop_container <container_name_or_id>
# Arguments:
#   $1 - Container name or ID
# Returns: 0 on success, 1 on failure
# Example: docker_stop_container myapp
docker_stop_container() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_stop_container <container_name_or_id>"
        return 1
    fi
    
    local container="$1"
    
    echo "Stopping container: $container"
    docker stop "$container"
}

# Function: docker_restart_container
# Description: Restart a Docker container by name or ID
# Usage: docker_restart_container <container_name_or_id>
# Arguments:
#   $1 - Container name or ID
# Returns: 0 on success, 1 on failure
# Example: docker_restart_container myapp
docker_restart_container() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_restart_container <container_name_or_id>"
        return 1
    fi
    
    local container="$1"
    
    echo "Restarting container: $container"
    docker restart "$container"
}

# Function: docker_logs
# Description: View logs from a Docker container
# Usage: docker_logs <container_name_or_id> [lines]
# Arguments:
#   $1 - Container name or ID
#   $2 - Number of lines to show (default: 100)
# Returns: Container logs
# Example: docker_logs myapp 50
docker_logs() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_logs <container_name_or_id> [lines]"
        return 1
    fi
    
    local container="$1"
    local lines="${2:-100}"
    
    docker logs --tail "$lines" -f "$container"
}

# Function: docker_exec_bash
# Description: Execute bash shell in a running container
# Usage: docker_exec_bash <container_name_or_id>
# Arguments:
#   $1 - Container name or ID
# Returns: Interactive bash session
# Example: docker_exec_bash myapp
docker_exec_bash() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_exec_bash <container_name_or_id>"
        return 1
    fi
    
    local container="$1"
    
    docker exec -it "$container" /bin/bash
}

# Function: docker_exec_sh
# Description: Execute sh shell in a running container (for minimal containers)
# Usage: docker_exec_sh <container_name_or_id>
# Arguments:
#   $1 - Container name or ID
# Returns: Interactive sh session
# Example: docker_exec_sh myapp
docker_exec_sh() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Container name or ID required"
        echo "Usage: docker_exec_sh <container_name_or_id>"
        return 1
    fi
    
    local container="$1"
    
    docker exec -it "$container" /bin/sh
}

# =============================================================================
# Image Management
# =============================================================================

# Function: docker_list_images
# Description: List all Docker images
# Usage: docker_list_images
# Returns: Formatted list of images
docker_list_images() {
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"
}

# Function: docker_pull_image
# Description: Pull a Docker image from registry
# Usage: docker_pull_image <image_name>
# Arguments:
#   $1 - Image name (e.g., nginx:latest)
# Returns: 0 on success, 1 on failure
# Example: docker_pull_image nginx:latest
docker_pull_image() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Image name required"
        echo "Usage: docker_pull_image <image_name>"
        return 1
    fi
    
    local image="$1"
    
    echo "Pulling image: $image"
    docker pull "$image"
}

# Function: docker_remove_image
# Description: Remove a Docker image
# Usage: docker_remove_image <image_id_or_name>
# Arguments:
#   $1 - Image ID or name
# Returns: 0 on success, 1 on failure
# Example: docker_remove_image nginx:latest
docker_remove_image() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Image ID or name required"
        echo "Usage: docker_remove_image <image_id_or_name>"
        return 1
    fi
    
    local image="$1"
    
    echo "Removing image: $image"
    docker rmi "$image"
}

# =============================================================================
# Cleanup Functions
# =============================================================================

# Function: docker_cleanup_containers
# Description: Remove all stopped containers
# Usage: docker_cleanup_containers
# Returns: 0 on success
docker_cleanup_containers() {
    echo "Removing all stopped containers..."
    docker container prune -f
}

# Function: docker_cleanup_images
# Description: Remove all dangling images
# Usage: docker_cleanup_images
# Returns: 0 on success
docker_cleanup_images() {
    echo "Removing dangling images..."
    docker image prune -f
}

# Function: docker_cleanup_volumes
# Description: Remove all unused volumes
# Usage: docker_cleanup_volumes
# Returns: 0 on success
docker_cleanup_volumes() {
    echo "Removing unused volumes..."
    docker volume prune -f
}

# Function: docker_cleanup_all
# Description: Complete Docker cleanup (containers, images, volumes, networks)
# Usage: docker_cleanup_all
# Returns: 0 on success
docker_cleanup_all() {
    echo "Performing complete Docker cleanup..."
    echo "This will remove:"
    echo "  - All stopped containers"
    echo "  - All unused networks"
    echo "  - All dangling images"
    echo "  - All build cache"
    
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker system prune -a -f --volumes
        echo "Cleanup complete!"
    else
        echo "Cleanup cancelled"
    fi
}

# =============================================================================
# System Information
# =============================================================================

# Function: docker_info
# Description: Display Docker system information
# Usage: docker_info
# Returns: Docker system info
docker_info() {
    docker system df
    echo ""
    docker info
}

# Function: docker_stats
# Description: Display live container resource usage statistics
# Usage: docker_stats
# Returns: Live stats for all running containers
docker_stats() {
    docker stats
}

# =============================================================================
# Network Management
# =============================================================================

# Function: docker_list_networks
# Description: List all Docker networks
# Usage: docker_list_networks
# Returns: List of Docker networks
docker_list_networks() {
    docker network ls
}

# Function: docker_inspect_network
# Description: Inspect a Docker network
# Usage: docker_inspect_network <network_name>
# Arguments:
#   $1 - Network name
# Returns: Network details
# Example: docker_inspect_network bridge
docker_inspect_network() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Network name required"
        echo "Usage: docker_inspect_network <network_name>"
        return 1
    fi
    
    local network="$1"
    
    docker network inspect "$network"
}

# =============================================================================
# Volume Management
# =============================================================================

# Function: docker_list_volumes
# Description: List all Docker volumes
# Usage: docker_list_volumes
# Returns: List of Docker volumes
docker_list_volumes() {
    docker volume ls
}

# Function: docker_inspect_volume
# Description: Inspect a Docker volume
# Usage: docker_inspect_volume <volume_name>
# Arguments:
#   $1 - Volume name
# Returns: Volume details
# Example: docker_inspect_volume mydata
docker_inspect_volume() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Volume name required"
        echo "Usage: docker_inspect_volume <volume_name>"
        return 1
    fi
    
    local volume="$1"
    
    docker volume inspect "$volume"
}

#!/bin/zsh

# =============================================================================
# DOCKER MANAGEMENT FUNCTIONS (HOMELAB)
# =============================================================================
# Docker container and image management utilities
# =============================================================================

# Clean up Docker system
docker_cleanup() {
    echo "🧹 Cleaning up Docker system..."
    docker system prune -af --volumes
    echo "✅ Docker cleanup completed"
}

# Show Docker resource usage
docker_stats() {
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Stop all containers
docker_stop_all() {
    echo "🛑 Stopping all containers..."
    docker stop $(docker ps -q)
    echo "✅ All containers stopped"
}

# Remove all stopped containers
docker_remove_stopped() {
    echo "🗑️  Removing stopped containers..."
    docker rm $(docker ps -a -q -f status=exited)
    echo "✅ Stopped containers removed"
}

# Backup Docker volumes
docker_backup_volumes() {
    local backup_dir="${1:-/backup/docker}"
    mkdir -p "$backup_dir"
    
    for volume in $(docker volume ls -q); do
        echo "💾 Backing up volume: $volume"
        docker run --rm -v "$volume":/volume -v "$backup_dir":/backup alpine tar czf "/backup/${volume}.tar.gz" -C /volume .
    done
    
    echo "✅ Docker volumes backed up to $backup_dir"
}
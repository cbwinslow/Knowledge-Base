# Docker Configuration

Configuration files, functions, and aliases for Docker container management.

## Files

### Functions
- `bash_functions_docker.sh` - Comprehensive Docker functions for container, image, and system management

### Aliases
- `bash_aliases_docker.sh` - Quick shortcuts for common Docker commands

## Installation

### Load Functions

```bash
# Add to ~/.bashrc or ~/.zshrc
source ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh
source ~/Knowledge-Base/dotfiles/development/docker/bash_aliases_docker.sh
```

### Symlink Approach

```bash
ln -sf ~/Knowledge-Base/dotfiles/development/docker/bash_functions_docker.sh ~/.bash_functions_docker
ln -sf ~/Knowledge-Base/dotfiles/development/docker/bash_aliases_docker.sh ~/.bash_aliases_docker

# Add to ~/.bashrc
echo 'source ~/.bash_functions_docker' >> ~/.bashrc
echo 'source ~/.bash_aliases_docker' >> ~/.bashrc
source ~/.bashrc
```

## Function Reference

### Container Management

- `docker_list_running` - List running containers
- `docker_list_all` - List all containers
- `docker_start_container <name>` - Start a container
- `docker_stop_container <name>` - Stop a container
- `docker_restart_container <name>` - Restart a container
- `docker_logs <name> [lines]` - View container logs
- `docker_exec_bash <name>` - Execute bash in container
- `docker_exec_sh <name>` - Execute sh in container

### Image Management

- `docker_list_images` - List all images
- `docker_pull_image <name>` - Pull an image
- `docker_remove_image <name>` - Remove an image

### Cleanup

- `docker_cleanup_containers` - Remove stopped containers
- `docker_cleanup_images` - Remove dangling images
- `docker_cleanup_volumes` - Remove unused volumes
- `docker_cleanup_all` - Complete system cleanup

### System Information

- `docker_info` - Display system information
- `docker_stats` - Live resource usage statistics

### Network Management

- `docker_list_networks` - List networks
- `docker_inspect_network <name>` - Inspect a network

### Volume Management

- `docker_list_volumes` - List volumes
- `docker_inspect_volume <name>` - Inspect a volume

## Alias Reference

### Basic Commands

- `dps` - docker ps
- `dpsa` - docker ps -a
- `dimg` - docker images
- `dstart` - docker start
- `dstop` - docker stop

### Docker Compose

- `dc` - docker-compose
- `dcup` - docker-compose up -d
- `dcdown` - docker-compose down
- `dclogs` - docker-compose logs -f

### Cleanup

- `dprune` - docker system prune -f
- `dprunea` - docker system prune -a -f
- `dcprune` - docker container prune -f

## Prerequisites

- Docker installed and running
- Docker Compose (optional, for compose aliases)

## Usage Examples

```bash
# Start a container
docker_start_container myapp

# View logs
docker_logs myapp 50

# Execute commands in container
docker_exec_bash myapp

# Cleanup system
docker_cleanup_all

# Using aliases
dps                  # List running containers
dcup                 # Start compose services
dclogs myservice     # View compose logs
```

## Tips

1. **Regular Cleanup**: Run `docker_cleanup_all` periodically to free disk space
2. **Monitor Resources**: Use `docker_stats` to monitor container resource usage
3. **Quick Logs**: Use `docker_logs` with line count to view recent logs only
4. **Shell Access**: Try `docker_exec_bash` first, fall back to `docker_exec_sh` for minimal containers

## Troubleshooting

### Permission Denied

```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

### Container Won't Start

```bash
# Check logs
docker_logs <container_name>

# Check status
docker ps -a | grep <container_name>

# Inspect container
docker inspect <container_name>
```

### Out of Disk Space

```bash
# Check disk usage
docker_info

# Clean up everything
docker_cleanup_all
```

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

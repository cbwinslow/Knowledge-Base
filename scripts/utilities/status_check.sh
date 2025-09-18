#!/usr/bin/env bash
# status_check.sh - Check status of all services
set -Eeuo pipefail

RED='\033[31m'; GREEN='\033[32m'; YEL='\033[33m'; NC='\033[0m'
info(){ echo -e "${GREEN}[INFO]${NC} $*"; }
warn(){ echo -e "${YEL}[WARN]${NC} $*"; }
err(){ echo -e "${RED}[ERR ]${NC} $*"; }

SERVICES=(
  "docker"
  "redis-server"
  "nginx"
  "cloudflared"
  "ollama"
  "localai"
  "localrecall"
  "keycloak"
  "minio"
  "graphite-web"
  "carbon-cache"
)

check_service_status() {
  local service=$1
  if systemctl is-active --quiet "$service"; then
    info "$service: RUNNING"
  else
    warn "$service: NOT RUNNING"
  fi
}

check_docker_containers() {
  if command -v docker >/dev/null 2>&1; then
    local count=$(docker ps -q | wc -l)
    if [ "$count" -gt 0 ]; then
      info "Docker containers running: $count"
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | sed "s/^/  /"
    else
      info "No Docker containers running"
    fi
  else
    warn "Docker not installed"
  fi
}

check_ports_in_use() {
  info "Checking registered ports:"
  if [ -f "./tools/PORTS.registry" ]; then
    while IFS=$'\t' read -r port service; do
      [[ $port =~ ^#.*$ ]] && continue
      [[ -z $port ]] && continue
      
      if ss -tulpn | grep -q ":$port "; then
        echo "  Port $port ($service): IN USE"
      else
        echo "  Port $port ($service): FREE"
      fi
    done < "./tools/PORTS.registry"
  else
    warn "Port registry not found"
  fi
}

echo "=== CloudCurio AI Stack Status ==="
echo

info "Service Status:"
for service in "${SERVICES[@]}"; do
  check_service_status "$service"
done

echo
check_docker_containers

echo
check_ports_in_use

echo
info "System Resources:"
echo "  CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
echo "  Memory Usage: $(free | grep Mem | awk '{printf("%.2f%%", $3/$2 * 100.0)}')"
echo "  Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
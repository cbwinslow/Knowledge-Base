#!/usr/bin/env bash
#===============================================================================
# ███╗   ██╗███████╗████████╗    ███████╗██████╗  █████╗ ███╗   ███╗███████╗██╗
# ████╗  ██║██╔════╝╚══██╔══╝    ██╔════╝██╔══██╗██╔══██╗████╗ ████║██╔════╝██║
# ██╔██╗ ██║█████╗     ██║       █████╗  ██║  ██║███████║██╔████╔██║█████╗  ██║
# ██║╚██╗██║██╔══╝     ██║       ██╔══╝  ██║  ██║██╔══██║██║╚██╔╝██║██╔══╝  ╚═╝
# ██║ ╚████║███████╗   ██║       ███████╗██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██╗
# ╚═╝  ╚═══╝╚══════╝   ╚═╝       ╚══════╝╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═╝
#===============================================================================
# File: setup_completion_checklist.sh
# Description: Checklist for completing the CBW Ubuntu setup
# Author: System Administrator
# Date: 2025-09-15
#===============================================================================

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
info() { echo -e "${GREEN}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

print_header() {
    echo -e "${BLUE}===============================================================================${NC}"
    echo -e "${BLUE}CBW Ubuntu Setup Completion Checklist${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

show_checklist() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Pre-Installation Checklist${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "□ Run conflict resolver (requires sudo):"
    echo "    sudo /home/cbwinslow/resolve_setup_conflicts.sh --all"
    echo
    echo "□ Stop conflicting services:"
    echo "    sudo systemctl stop grafana-server"
    echo "    sudo systemctl stop prometheus"
    echo "    sudo systemctl stop postgresql"
    echo
    echo "□ Verify fstab is fixed:"
    echo "    grep -v \"^#\" /etc/fstab | grep -v \"^$\" | wc -l"
    echo "    grep -v \"^#\" /etc/fstab | grep -v \"^$\" | sort | uniq | wc -l"
    echo "    (Both numbers should be equal)"
    echo
    echo "□ Verify docker-compose files are updated:"
    echo "    grep -n \"3001:3000\" /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose/monitoring.yml"
    echo "    grep -n \"9091:9090\" /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose/monitoring.yml"
    echo "    grep -n \"5433:5432\" /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose/databases.yml"
    echo
    
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Installation${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "□ Run the setup:"
    echo "    /home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo "□ Monitor installation progress:"
    echo "    tail -f /tmp/CBW-install.log"
    echo
    
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Post-Installation Verification${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "□ Check Docker containers:"
    echo "    docker ps"
    echo
    echo "□ Verify services are accessible:"
    echo "    curl -s http://localhost:3001 | grep -i grafana"
    echo "    curl -s http://localhost:9091 | grep -i prometheus"
    echo "    curl -s http://localhost:8081 | grep -i cadvisor"
    echo
    echo "□ Check databases:"
    echo "    docker exec -it pg psql -U postgres -c \"SELECT version();\""
    echo
    echo "□ Start additional services if needed:"
    echo "    cd /home/cbwinslow/server_setup/cbw-ubuntu-setup-baremetal/cbw-ubuntu-setup/docker/compose"
    echo "    docker compose -f kong.yml up -d"
    echo "    docker compose -f mcp.yml up -d"
    echo "    docker compose -f netdata.yml up -d"
    echo
    
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Documentation${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "□ Review setup guides:"
    echo "    cat /home/cbwinslow/SYSTEM_TOOLS_SUITE.md"
    echo "    cat /home/cbwinslow/SETUP_GUIDE.md"
    echo "    cat /home/cbwinslow/NEXT_STEPS.md"
    echo "    cat /home/cbwinslow/PORT_CONFLICTS.md"
}

show_quick_start() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Quick Start Commands${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    echo "# 1. Fix conflicts (requires sudo)"
    echo "sudo /home/cbwinslow/resolve_setup_conflicts.sh --all"
    echo
    echo "# 2. Stop conflicting services"
    echo "sudo systemctl stop grafana-server prometheus postgresql"
    echo
    echo "# 3. Run setup"
    echo "/home/cbwinslow/run_bare_metal_setup.sh --full-install"
    echo
    echo "# 4. Monitor progress"
    echo "tail -f /tmp/CBW-install.log"
    echo
    echo "# 5. Verify installation"
    echo "docker ps"
}

main() {
    print_header
    show_checklist
    echo
    show_quick_start
    echo
    info "Print this checklist anytime with: /home/cbwinslow/setup_completion_checklist.sh"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
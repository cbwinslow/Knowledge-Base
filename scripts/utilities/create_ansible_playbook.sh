#!/usr/bin/env bash
#===============================================================================
# █████╗ ███╗   ██╗██████╗     ██╗ █████╗ ███╗   ██╗██████╗  ██████╗ 
# ██╔══██╗████╗  ██║██╔══██╗    ██║██╔══██╗████╗  ██║██╔══██╗██╔═══██╗
# ███████║██╔██╗ ██║██║  ██║    ██║███████║██╔██╗ ██║██║  ██║██║   ██║
# ██╔══██║██║╚██╗██║██║  ██║    ██║██╔══██║██║╚██╗██║██║  ██║██║   ██║
# ██║  ██║██║ ╚████║██████╔╝    ██║██║  ██║██║ ╚████║██████╔╝╚██████╔╝
# ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝ 
#===============================================================================
# File: create_ansible_playbook.sh
# Description: Create Ansible playbook for CBW setup using IaC principles
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
    echo -e "${BLUE}Creating Ansible Playbook for CBW Setup${NC}"
    echo -e "${BLUE}===============================================================================${NC}"
    echo
}

create_ansible_structure() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Ansible structure${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    # Create directories
    mkdir -p /home/cbwinslow/cbw_ansible/{playbooks,roles,inventory,group_vars,host_vars,files,templates}
    
    # Create inventory
    cat > /home/cbwinslow/cbw_ansible/inventory/hosts <<'EOF'
[local]
localhost ansible_connection=local

[servers]
cbwserver ansible_host=192.168.4.117 ansible_user=cbwinslow

[webservers]
cbwserver

[databases]
cbwserver

[monitoring]
cbwserver
EOF
    
    info "Created Ansible inventory"
    
    # Create ansible.cfg
    cat > /home/cbwinslow/cbw_ansible/ansible.cfg <<'EOF'
[defaults]
inventory = ./inventory/hosts
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml
bin_ansible_callbacks = True

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
    
    info "Created Ansible configuration"
}

create_main_playbook() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating main playbook${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_ansible/playbooks/cbw_setup.yml <<'EOF'
---
- name: CBW Ubuntu Server Setup
  hosts: servers
  become: yes
  vars:
    server_ip: "192.168.4.117"
    hostname_new: "cbwserver"
    dotfiles_repo: "https://github.com/cbwinslow/dotfiles"
    scripts_repo: "https://github.com/cbwinslow/binfiles"
    github_user: "cbwinslow"
    pg_ver: "16"
    app_db: "app"
    app_user: "appuser"
    app_pass: "apppass"
    
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes
        
    - name: Install base packages
      apt:
        name:
          - curl
          - ca-certificates
          - gnupg
          - lsb-release
          - software-properties-common
          - git
          - unzip
          - jq
          - ufw
        state: present
        
    - name: Set hostname
      hostname:
        name: "{{ hostname_new }}"
      ignore_errors: yes
      
    - name: Add hostname to /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "{{ server_ip }} {{ hostname_new }}"
        create: yes
        
    # Include role-based tasks
    - name: Include networking and security setup
      include_tasks: "../roles/network_security/tasks/main.yml"
      
    - name: Include Docker setup
      include_tasks: "../roles/docker/tasks/main.yml"
      
    - name: Include Python setup
      include_tasks: "../roles/python/tasks/main.yml"
      
    - name: Include database setup
      include_tasks: "../roles/databases/tasks/main.yml"
      
    - name: Include monitoring setup
      include_tasks: "../roles/monitoring/tasks/main.yml"
EOF
    
    info "Created main playbook"
}

create_network_security_role() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating network security role${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_ansible/roles/network_security/{tasks,files,templates}
    
    cat > /home/cbwinslow/cbw_ansible/roles/network_security/tasks/main.yml <<'EOF'
---
- name: Install network security tools
  apt:
    name:
      - openssh-server
      - net-tools
      - iproute2
      - iptables-persistent
      - nload
      - iftop
      - iptraf-ng
      - htop
      - glances
      - fail2ban
      - suricata
      - goaccess
    state: present

- name: Configure UFW - default deny incoming
  ufw:
    direction: incoming
    policy: deny
  notify: Reload UFW

- name: Configure UFW - default allow outgoing
  ufw:
    direction: outgoing
    policy: allow
  notify: Reload UFW

- name: Configure UFW - allow SSH
  ufw:
    rule: allow
    port: '22'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow HTTP
  ufw:
    rule: allow
    port: '80'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow HTTPS
  ufw:
    rule: allow
    port: '443'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow Grafana
  ufw:
    rule: allow
    port: '3000'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow Prometheus
  ufw:
    rule: allow
    port: '9090'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow Loki
  ufw:
    rule: allow
    port: '3100'
    proto: tcp
  notify: Reload UFW

- name: Configure UFW - allow Kong
  ufw:
    rule: allow
    port: '8000:8001'
    proto: tcp
  notify: Reload UFW

- name: Enable UFW
  ufw:
    state: enabled
  notify: Reload UFW

- name: Configure Fail2ban
  copy:
    content: |
      [DEFAULT]
      bantime = 1h
      findtime = 10m
      maxretry = 5
      backend = systemd
      destemail = root@localhost
      action = %(action_mw)s

      [sshd]
      enabled = true
      port    = ssh
      logpath = %(sshd_log)s
    dest: /etc/fail2ban/jail.local

- name: Start and enable Fail2ban
  systemd:
    name: fail2ban
    state: started
    enabled: yes

- name: Configure Suricata
  copy:
    content: |
      # Minimal Suricata config (AF-PACKET)
      vars:
        address-groups:
          HOME_NET: "[192.168.4.0/24]"
      af-packet:
        - interface: any
          cluster-id: 99
          cluster-type: cluster_flow
          defrag: yes
      outputs:
        - eve-log:
            enabled: yes
            filetype: regular
            filename: /var/log/suricata/eve.json
            types: [alert, http, dns, tls, ssh, stats]
    dest: /etc/suricata/suricata.yaml

- name: Start and enable Suricata
  systemd:
    name: suricata
    state: started
    enabled: yes

- name: Configure GoAccess
  file:
    path: /etc/goaccess
    state: directory
    mode: '0755'
    
- name: Configure GoAccess settings
  copy:
    content: |
      time-format %T
      date-format %d/%b/%Y
      log-format COMBINED
      real-time-html true
      ws-url 127.0.0.1
      port 7890
    dest: /etc/goaccess/goaccess.conf

  handlers:
    - name: Reload UFW
      ufw:
        state: reloaded
EOF
    
    info "Created network security role"
}

create_docker_role() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Docker role${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_ansible/roles/docker/{tasks,files,templates}
    
    cat > /home/cbwinslow/cbw_ansible/roles/docker/tasks/main.yml <<'EOF'
---
- name: Install Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present
    update_cache: yes

- name: Install Docker packages
  apt:
    name:
      - docker-ce
      - docker-ce-cli
      - containerd.io
      - docker-buildx-plugin
      - docker-compose-plugin
    state: present

- name: Create Docker daemon directory
  file:
    path: /etc/docker
    state: directory
    mode: '0755'

- name: Configure Docker daemon
  copy:
    content: |
      {
        "log-driver": "json-file",
        "log-opts": { "max-size": "10m", "max-file": "3" },
        "exec-opts": ["native.cgroupdriver=systemd"]
      }
    dest: /etc/docker/daemon.json

- name: Start and enable Docker
  systemd:
    name: docker
    state: started
    enabled: yes
    daemon_reload: yes

- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes
EOF
    
    info "Created Docker role"
}

create_python_role() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating Python role${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_ansible/roles/python/{tasks,files,templates}
    
    cat > /home/cbwinslow/cbw_ansible/roles/python/tasks/main.yml <<'EOF'
---
- name: Install Python build dependencies
  apt:
    name:
      - make
      - build-essential
      - libssl-dev
      - zlib1g-dev
      - libbz2-dev
      - libreadline-dev
      - libsqlite3-dev
      - wget
      - curl
      - llvm
      - libncursesw5-dev
      - xz-utils
      - tk-dev
      - libxml2-dev
      - libxmlsec1-dev
      - libffi-dev
      - liblzma-dev
    state: present

- name: Install pyenv
  shell: curl https://pyenv.run | bash
  args:
    creates: "{{ ansible_env.HOME }}/.pyenv"
  environment:
    HOME: "{{ ansible_env.HOME }}"

- name: Add pyenv to shell profile
  lineinfile:
    path: "{{ ansible_env.HOME }}/.bashrc"
    line: 'export PYENV_ROOT="$HOME/.pyenv"'
    create: yes

- name: Add pyenv to PATH
  lineinfile:
    path: "{{ ansible_env.HOME }}/.bashrc"
    line: 'export PATH="$PYENV_ROOT/bin:$PATH"'

- name: Add pyenv init to shell
    lineinfile:
      path: "{{ ansible_env.HOME }}/.bashrc"
      line: 'eval "$(pyenv init -)"'
EOF
    
    info "Created Python role"
}

create_database_role() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating database role${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_ansible/roles/databases/{tasks,files,templates}
    
    cat > /home/cbwinslow/cbw_ansible/roles/databases/tasks/main.yml <<'EOF'
---
- name: Install PostgreSQL GPG key
  apt_key:
    url: https://www.postgresql.org/media/keys/ACCC4CF8.asc
    state: present

- name: Add PostgreSQL repository
  apt_repository:
    repo: "deb http://apt.postgresql.org/pub/repos/apt {{ ansible_distribution_release }}-pgdg main"
    state: present
    update_cache: yes

- name: Install PostgreSQL and pgvector
  apt:
    name:
      - "postgresql-{{ pg_ver }}"
      - "postgresql-{{ pg_ver }}-pgvector"
      - postgresql-client-common
    state: present

- name: Start and enable PostgreSQL
  systemd:
    name: "postgresql@{{ pg_ver }}-main"
    state: started
    enabled: yes

- name: Create application database
  postgresql_db:
    name: "{{ app_db }}"
    state: present
  become_user: postgres

- name: Create application user
  postgresql_user:
    name: "{{ app_user }}"
    password: "{{ app_pass }}"
    state: present
  become_user: postgres

- name: Enable pgvector extension
  postgresql_ext:
    name: vector
    db: "{{ app_db }}"
  become_user: postgres

- name: Tune PostgreSQL configuration
  lineinfile:
    path: "/etc/postgresql/{{ pg_ver }}/main/postgresql.conf"
    line: "{{ item }}"
    create: yes
  loop:
    - "shared_buffers = 1GB"
    - "work_mem = 64MB"
    - "maintenance_work_mem = 256MB"
    - "listen_addresses = '*'"
  notify: Restart PostgreSQL

- name: Configure PostgreSQL authentication
  lineinfile:
    path: "/etc/postgresql/{{ pg_ver }}/main/pg_hba.conf"
    line: "host    all             all             0.0.0.0/0               md5"
    insertafter: EOF
  notify: Restart PostgreSQL

- name: Install Qdrant GPG key
  apt_key:
    url: https://qdrant.github.io/qdrant-ppa/pubkey.gpg
    state: present

- name: Add Qdrant repository
  apt_repository:
    repo: "deb https://qdrant.github.io/qdrant-ppa/ {{ ansible_distribution_release }} main"
    state: present
    update_cache: yes

- name: Install Qdrant
  apt:
    name: qdrant
    state: present

- name: Start and enable Qdrant
  systemd:
    name: qdrant
    state: started
    enabled: yes

  handlers:
    - name: Restart PostgreSQL
      systemd:
        name: "postgresql@{{ pg_ver }}-main"
        state: restarted
EOF
    
    info "Created database role"
}

create_monitoring_role() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating monitoring role${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    mkdir -p /home/cbwinslow/cbw_ansible/roles/monitoring/{tasks,files,templates}
    
    cat > /home/cbwinslow/cbw_ansible/roles/monitoring/tasks/main.yml <<'EOF'
---
- name: Create monitoring directories
  file:
    path: "{{ item }}"
    state: directory
    mode: '0755'
  loop:
    - /opt/monitoring
    - /opt/monitoring/prometheus
    - /opt/monitoring/grafana
    - /opt/monitoring/loki
    - /opt/monitoring/promtail

- name: Install monitoring tools
  apt:
    name:
      - prometheus
      - grafana
    state: present

- name: Start and enable Prometheus
  systemd:
    name: prometheus
    state: started
    enabled: yes

- name: Start and enable Grafana
  systemd:
    name: grafana-server
    state: started
    enabled: yes

- name: Configure Prometheus
  copy:
    content: |
      global:
        scrape_interval: 15s
        
      scrape_configs:
        - job_name: 'prometheus'
          static_configs:
            - targets: ['localhost:9090']
            
        - job_name: 'node'
          static_configs:
            - targets: ['localhost:9100']
    dest: /etc/prometheus/prometheus.yml
  notify: Restart Prometheus

- name: Create Loki configuration
  copy:
    content: |
      auth_enabled: false
      
      server:
        http_listen_port: 3100
        
      ingester:
        lifecycler:
          address: 127.0.0.1
          ring:
            kvstore:
              store: inmemory
            replication_factor: 1
    dest: /opt/monitoring/loki/local-config.yaml

  handlers:
    - name: Restart Prometheus
      systemd:
        name: prometheus
        state: restarted
EOF
    
    info "Created monitoring role"
}

create_master_config() {
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    echo -e "${BLUE}Creating master configuration file${NC}"
    echo -e "${BLUE}-------------------------------------------------------------------------------${NC}"
    
    cat > /home/cbwinslow/cbw_ansible/cbw_config.yml <<'EOF'
# CBW Infrastructure Configuration
# This file serves as the single source of truth for all infrastructure settings

# Server Configuration
server:
  hostname: cbwserver
  ip: 192.168.4.117
  timezone: America/New_York
  locale: en_US.UTF-8

# User Configuration
users:
  - name: cbwinslow
    groups: [docker, sudo]
    ssh_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD...your_key_here..."

# Network Configuration
network:
  firewall:
    default_policy:
      incoming: deny
      outgoing: allow
    allowed_ports:
      - port: 22
        protocol: tcp
        service: ssh
      - port: 80
        protocol: tcp
        service: http
      - port: 443
        protocol: tcp
        service: https
      - port: 3000
        protocol: tcp
        service: grafana
      - port: 9090
        protocol: tcp
        service: prometheus
      - port: 3100
        protocol: tcp
        service: loki
      - port: 8000:8001
        protocol: tcp
        service: kong

# Docker Configuration
docker:
  version: latest
  daemon_options:
    log_driver: json-file
    log_opts:
      max_size: 10m
      max_file: 3
    exec_opts:
      - native.cgroupdriver=systemd

# Database Configuration
databases:
  postgresql:
    version: 16
    databases:
      - name: app
        extensions:
          - vector
    users:
      - name: appuser
        password: apppass
  qdrant:
    version: latest
  mongodb:
    version: 7
  opensearch:
    version: 2.17.1
  rabbitmq:
    version: 3-management

# Monitoring Configuration
monitoring:
  prometheus:
    port: 9090
    retention: 15d
  grafana:
    port: 3001  # Changed from 3000 to avoid conflicts
    admin_user: admin
    admin_password: admin
  loki:
    port: 3100
  promtail:
    port: 9080

# Security Configuration
security:
  fail2ban:
    enabled: true
    bantime: 1h
    findtime: 10m
    maxretry: 5
  ufw:
    enabled: true
  suricata:
    enabled: true

# Development Tools
development:
  nodejs:
    enabled: true
  python:
    enabled: true
    version_manager: pyenv
  git:
    enabled: true

# Service Ports Mapping
# This section defines all service ports to avoid conflicts
ports:
  grafana: 3001      # Changed from 3000
  prometheus: 9091   # Changed from 9090
  postgresql: 5433   # Changed from 5432
  cadvisor: 8081     # Changed from 8080
  qdrant_http: 6333
  qdrant_grpc: 6334
  mongodb: 27017
  opensearch: 9200
  opensearch_monitoring: 9600
  rabbitmq: 5672
  rabbitmq_management: 15672
  kong_proxy: 8000
  kong_proxy_ssl: 8443
  kong_admin: 8001
  kong_admin_ssl: 8444
  loki: 3100
  dcgm_exporter: 9400
EOF
    
    info "Created master configuration file"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --create-all     Create all Ansible structure and playbooks (default)"
    echo "  --create-structure  Create basic Ansible directory structure"
    echo "  --create-roles   Create all roles"
    echo "  --create-config  Create master configuration file"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --create-all"
    echo "  $0 --create-structure"
    echo "  $0 --create-roles"
}

main() {
    print_header
    
    # Parse arguments
    local create_structure=false
    local create_roles=false
    local create_config=false
    
    if [[ $# -eq 0 ]]; then
        create_structure=true
        create_roles=true
        create_config=true
    else
        while [[ $# -gt 0 ]]; do
            case $1 in
                --create-all)
                    create_structure=true
                    create_roles=true
                    create_config=true
                    shift
                    ;;
                --create-structure)
                    create_structure=true
                    shift
                    ;;
                --create-roles)
                    create_roles=true
                    shift
                    ;;
                --create-config)
                    create_config=true
                    shift
                    ;;
                --help|-h)
                    show_usage
                    exit 0
                    ;;
                *)
                    error "Unknown option: $1"
                    show_usage
                    exit 1
                    ;;
            esac
        done
    fi
    
    # Execute requested actions
    if [[ "$create_structure" == true ]]; then
        create_ansible_structure
    fi
    
    if [[ "$create_roles" == true ]]; then
        create_main_playbook
        create_network_security_role
        create_docker_role
        create_python_role
        create_database_role
        create_monitoring_role
    fi
    
    if [[ "$create_config" == true ]]; then
        create_master_config
    fi
    
    echo
    info "Ansible structure created successfully!"
    info "You can now run the playbook with:"
    echo "  cd /home/cbwinslow/cbw_ansible"
    echo "  ansible-playbook playbooks/cbw_setup.yml"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
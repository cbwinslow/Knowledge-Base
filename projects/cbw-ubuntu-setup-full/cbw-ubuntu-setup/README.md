# CBW Ubuntu Server Full Installer (192.168.4.117)

Turnkey scripts and stacks to bootstrap an AI-ready, monitored, and secured Ubuntu Server.
Tested on Ubuntu 22.04/24.04 **bare metal**.

Includes:
- **Bare metal DBs**: PostgreSQL 16 + pgvector, Qdrant, MongoDB 7, OpenSearch 2.x, RabbitMQ, Neo4j (APOC + GDS)
- **Supabase** (Docker) with offset ports
- **Monitoring**: Prometheus, Grafana, Loki, Promtail, node_exporter, cAdvisor, DCGM exporter; Netdata
- **Gateways & Security**: Kong, Fail2ban, UFW, Suricata, GoAccess
- **NVIDIA**: container toolkit, CUDA 12.x, cuDNN, DCGM
- **Python**: 3.10 via pyenv + `uv` package manager
- **Admin UIs**: pgAdmin (:5050), Mongo Express (:8081), Neo4j Bloom (:7475, optional license)
- **PortGuard**: detect/resolve port conflicts and patch compose files
- **Repo Cloner**: local-ai-packaged, Qdrant, pgvector, pigsty, etc.
- **MCP stubs**

## Quick start
```bash
unzip cbw-ubuntu-setup-full.zip -d ~/
cd ~/cbw-ubuntu-setup/scripts
sudo bash install.sh
```

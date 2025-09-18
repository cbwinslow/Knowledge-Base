# CBW Ubuntu Server Setup (192.168.4.117)

Turnkey scripts and Docker stacks to bootstrap an AI‑ready, monitored, and secured Ubuntu Server.
Tested on Ubuntu 22.04/24.04 bare metal.

## Contents
- **scripts/install.sh** — One‑shot orchestrator.
- **scripts/partials/** — Installers by domain (Docker, NVIDIA, security, databases, monitoring, Kong, Python, MCP, repos).
- **docker/compose/** — Compose stacks: monitoring, databases, kong, mcp, netdata.
- **configs/** — Prebaked configs for Prometheus, Loki, Promtail, Fail2ban, Suricata, GoAccess.

## Quick start
```bash
git clone <this-bundle> ~/cbw-ubuntu-setup
cd ~/cbw-ubuntu-setup/scripts
sudo bash install.sh
```
> You can run components individually, e.g. `sudo bash partials/install_docker.sh`.

## Notes
- CUDA/cuDNN packages come from NVIDIA apt repos. cuDNN may require acceptance of license; script handles repo add + package names.
- Kong runs with Postgres; pgvector enabled.
- Monitoring includes: node_exporter, cAdvisor, DCGM (NVIDIA GPU) exporter, Prometheus, Grafana, Loki, Promtail. Netdata optional.
- Web traffic analysis: **GoAccess** (real‑time log visualizer) and **ntopng** (optional, commented).
- Python toolchain installs **pyenv** for Python 3.10 and **uv** for package management.
- Dotfiles repo is configurable via `DOTFILES_REPO` env (defaults to `https://github.com/cbwinslow/dotfiles` if exists).

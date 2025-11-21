# Scripts Organization Guide

This guide defines the categories for all scripts in the repository and explains how to organize them consistently.

## Category taxonomy

| Category | Directory | Purpose | Example script types |
| --- | --- | --- | --- |
| Deployment automation | `scripts/deployment/` | End-to-end provisioning, cloudflare setup, and phased rollout orchestration for the platform. | Full setup orchestrators, installer bundles, readiness or verification checks, and troubleshooting helpers tied to deployments. |
| Server setup | `scripts/server_setup/` | Host-level configuration, service hardening, and one-off administrative tasks for servers. | System service installs, access control helpers, networking services, and ad hoc maintenance utilities. |
| Database | `scripts/database/` | Database provisioning, backups, port mapping, and helper utilities. | PostgreSQL installers, backup routines, vector database helpers, and port mapping scripts. |
| Storage | `scripts/storage/` | Storage planning, reconfiguration, optimization, and recovery workflows. | Disk prefetching, ZFS recovery, storage decision helpers, and tuning scripts. |
| Networking | `scripts/networking/` | Network configuration and tunneling utilities. | WireGuard/ZeroTier setup, static network configuration, Apache suite helpers, and proxy configuration. |
| AI monitoring | `scripts/ai_monitoring/` | AI stack provisioning and observability helpers. | LocalAI setup, monitoring tool installation, credential configuration, and demo/playbook scripts. |
| Documentation & knowledge workflows | `scripts/documentation/` | Knowledge base ingestion, labeling, and documentation tooling. | Ingestion pipelines, RAG utilities, documentation builders, and supporting configs. |
| Utilities | `scripts/utilities/` | Cross-cutting helpers that support multiple categories without being tied to a single domain. | Status reporters, orchestration wrappers, quick-start helpers, or small fix-up scripts reused across workflows. |

## Placement rules

1. **Choose the closest matching category** using the table above; prefer existing directories over creating new ones.
2. **Deployment vs. server setup**: place scripts that orchestrate many steps across services in `deployment/`; host-level, single-system tasks belong in `server_setup/`.
3. **Shared helpers** that are reused by several categories (for example, generic status checks) go in `utilities/`.
4. **Documentation-oriented scripts** (ingestion, labeling, RAG, and content management) live in `documentation/`, even if they interact with external services.
5. **Networking-specific automation** that focuses on connectivity, tunneling, or proxies goes in `networking/`; otherwise keep it in deployment/server setup as appropriate.

## Naming and metadata

- Use descriptive, action-oriented names (e.g., `install_`, `configure_`, `verify_`, `setup_`).
- Add a short header comment at the top of each script with purpose, prerequisites, and owner/contact if available.
- If a script is an orchestrator, note which sub-scripts it calls to keep traceability clear.

## Maintaining the catalog

- When adding a new script, update the relevant directory README (or add one if missing) with a one-line summary of the script.
- Keep this guide in sync if a new category is introduced or an existing one is split/merged.
- Prefer moving scripts into these directories over duplicating similar utilities elsewhere; if duplication is unavoidable, document the reasons in the README for that directory.

# Scripts

This directory hosts the automation and helper scripts that support the Knowledge Base platform. Scripts are grouped by domain to make it easy to find, reuse, and maintain related tasks.

## Category overview

- **Deployment automation** (`deployment/`): end-to-end provisioning, phased rollouts, Cloudflare setup, and verification checks.
- **Server setup** (`server_setup/`): host-level configuration, service hardening, and administrative utilities.
- **Database** (`database/`): PostgreSQL install, backup, port-mapping, and vector database helpers.
- **Storage** (`storage/`): storage planning, optimization, and recovery workflows.
- **Networking** (`networking/`): connectivity, tunneling, and proxy configuration.
- **AI monitoring** (`ai_monitoring/`): AI stack provisioning, observability tools, and demos.
- **Documentation & knowledge workflows** (`documentation/`): ingestion, labeling, RAG utilities, and documentation tooling.
- **Utilities** (`utilities/`): shared helpers and small wrappers that support multiple categories.

See [ORGANIZATION.md](./ORGANIZATION.md) for the full taxonomy, placement rules, and maintenance guidance.

## Usage

Most scripts are designed to be run with bash:

```bash
./script_name.sh
```

Some scripts may require root privileges:

```bash
sudo ./script_name.sh
```

## Adding or moving scripts

- Place new scripts in the category directory that best matches their purpose (see the overview above).
- Use descriptive, action-oriented names (e.g., `install_`, `configure_`, `verify_`, `setup_`).
- Update the README within the target directory with a brief description of new scripts when you add them.
- Prefer reusing or refactoring existing utilities in `utilities/` before adding new ones that duplicate behavior.

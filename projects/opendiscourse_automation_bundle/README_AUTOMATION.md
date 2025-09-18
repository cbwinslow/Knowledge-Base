
# OpenDiscourse – Automation Bundle

This bundle adds:
1) **Issue conversion** from `project_tasks.md` and `SRS.md` → GitHub Issues.
2) **Agent assignment** via labels/assignees.
3) **Auto-tracker** (GitHub Projects v2) sync hooks.
4) **Architecture diagram generation** from PlantUML/Mermaid sources.

> Minimal configuration required: create a bot token secret named **GH_PAT** with `repo` and `project` scopes.

## Quick Start
1. Copy this bundle into the root of your repository.
2. Ensure `project_tasks.md` and `SRS.md` exist in the repo root.
3. In repo **Settings → Secrets → Actions**, add `GH_PAT`.
4. Push to `main` (or run the workflow from the Actions tab).

## Contents
- `.github/workflows/issue-sync.yml` — Parses markdown → creates/updates issues.
- `.github/workflows/project-sync.yml` — Keeps Project v2 board in sync.
- `.github/workflows/diagram-gen.yml` — Renders PlantUML/Mermaid to `docs/diagrams/rendered/`.
- `scripts/parse_tasks.py`, `scripts/parse_srs.py` — Markdown parsers.
- `scripts/manage_issues.py` — Reconciles issues with markdown.
- `scripts/agent_router.py` — Assigns `agent/*` labels & assignees.
- `scripts/common.py` — Shared helpers (GitHub API, md utils).
- `requirements.txt` — Python deps for Actions runner.
- `docs/diagrams/*.puml|*.mmd` — Example sources.
- `.vscode/settings.json` — Quality-of-life dev settings.

## Project Board (GitHub Projects v2)
- Create a project named **OpenDiscourse Roadmap**.
- Add fields: `Status` (Backlog, Triaged, In Progress, Review, Done), `Priority`, `Owner`.
- The workflows will add items and move them between columns based on labels and PR events.

## Notes
- The scripts prefer **idempotency** via a stable `microgoal:<uuid>` label (derived from content if missing).
- Router logic is conservative — humans can override by commenting: `@router reassign agent/ollama`.

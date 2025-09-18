# GitHub Issue Automation & Agent‑Ops Integration Plan

**Doc ID:** ODS‑AUTOMATION‑20250721‑01\
**Revision Date:** 2025‑07‑21\
**Status:** Draft for internal review

---

## 1   Objective

This document formalises how we will **convert internal task artefacts** (`project_tasks.md`, SRS microgoals) into **living GitHub Issues**, map each issue to an **AI‑or human‑agent owner**, wire the repository to an **auto‑tracker board**, and generate **architecture diagrams** on‑commit.  The goal is to guarantee single‑source traceability from requirement → task → issue → PR → deployment.

---

## 2   High‑Level Workflow

```
┌─────────────┐   push/sched   ┌──────────────────┐   REST    ┌──────────────────┐
│ project_*.md│──────────────▶│   Issue‑Sync GH‑CI│──────────▶│  GitHub Issues   │
└─────────────┘ (parser)       │  (create/update) │           └─────────┬────────┘
                               └─────────┬────────┘                     │ labels
                                         │                              ▼
                               ┌─────────▼────────┐        web‑hooks ┌───────────────┐
                               │  Agent Router    │<─────────────────│ PR / Commits │
                               │  (LangChain)     │ assign           └───────────────┘
                               └─────────┬────────┘                             │
                                         │ GraphQL status                        │
                                         ▼                                       ▼
                               ┌──────────────────┐        WS/SSE     ┌─────────────────┐
                               │  Tracker Board   │<────────────────▶│  VS‑Code UI     │
                               │  (GH Projects v2)│  auto‑move cards  └─────────────────┘
```

---

## 3   GitHub Issue Conversion

### 3.1   Source Artefacts

| Source File            | Parser Module            | Trigger                     | Notes                                        |
| ---------------------- | ------------------------ | --------------------------- | -------------------------------------------- |
| `project_tasks.md`     | `scripts/parse_tasks.py` | CI on `main` + nightly cron | Markdown table → JSON list                   |
| `SRS.md` §“Microgoals” | `scripts/parse_srs.py`   | same                        | Detect "## Microgoals" section, extract rows |

### 3.2   CI Workflow (`.github/workflows/issue-sync.yml`)

```yaml
name: Sync MD → Issues
on:
  push:
    paths:
      - 'project_tasks.md'
      - 'SRS.md'
  schedule:
    - cron: '0 3 * * *'  # nightly 03:00 UTC
jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Parse & diff ↔ GitHub Issues
        uses: ./.github/actions/md-to-issues
        with:
          gh-token: ${{ secrets.GH_PAT }}
```

**Custom composite‑action** `md-to-issues` implements:

1. **Parse** markdown tables → `tasks.json`.
2. **Compare** against existing open issues (GraphQL search by `microgoal-id` label).
3. **Create / update / close** issues accordingly using GraphQL API.
4. Apply labels: `area/<domain>`, `agent/<owner>`, `priority/P1‑P3`.
5. Add a checklist with acceptance criteria.

> **Key Tag Conventions**\
> • `microgoal:<uuid>` – stable handle to guarantee idempotency.\
> • `requires-diagram` – signals PlantUML job (see §6) to attach PNG.

---

## 4   Agent Assignment Mapping

### 4.1   Role Dictionary (source of truth `AGENT.md`)

| Agent Label (`agent/<label>`) | Capability Domain                | Backing Technology | Allowed Issue Types      |
| ----------------------------- | -------------------------------- | ------------------ | ------------------------ |
| `agent/ollama`                | Local LLM 70B (coding, drafting) | Ollama REST        | `enhancement`,`research` |
| `agent/codex`                 | Code synthesis/unit tests        | OpenAI Codex       | `bug`,`enhancement`      |
| `agent/agent-zero`            | Review & PR audit                | Agent‑Zero SaaS    | `review`,`refactor`      |
| `agent/copilot`               | Glue tasks, docs                 | ChatGPT‑o3         | `documentation`,`chore`  |

### 4.2   Routing Logic (inside `scripts/agent_router.py`)

```python
RULES = [
  (lambda t: 'db' in t.tags,        'agent/ollama'),
  (lambda t: t.type == 'review',    'agent/agent-zero'),
  (lambda t: 'script' in t.title,   'agent/codex'),
  # default
  (lambda t: True,                 'agent/copilot')
]
```

The **Agent Router** runs post‑issue‑creation, assigns `assignees` and `agent/*` label. Human maintainers can override via conventional Re‑assign comment `@router reassign agent/ollama`.

---

## 5   Task Auto‑Tracker Integration

### 5.1   GitHub Projects v2

- Board name: **“OpenDiscourse Roadmap”**.
- Views: *Backlog*, *Triaged*, *In Progress*, *Review*, *Done*.
- Built‑in **field mapping**:
  - `Status` ← Issue `state` & project automation.
  - `Owner` ← first assignee.
  - `Priority` ← label regexp `priority/(P\d)`.

### 5.2   Automation Rules

| Event                        | Condition | Action                                             |
| ---------------------------- | --------- | -------------------------------------------------- |
| **Issue created**            | any       | Add to board column **Backlog**                    |
| **Label ****\`\`**** added** |           | Move to **Triaged**                                |
| **Linked PR opened**         |           | Set **Status → In Progress**                       |
| **PR merged**                |           | Status → **Review** then **Done** after CI success |
| **Issue closed w/o PR**      |           | Column → **Done**                                  |

### 5.3   Status‑Sync GitHub Action (`project-sync.yml`)

Runs every 10 minutes; reconciles discrepancies between issue labels, board fields, and `project_tasks.md` statuses (`TODO/DOING/DONE`).

---

## 6   Architecture Diagram Generation Pipeline

### 6.1   PlantUML as Code

- Canonical diagram sources live under `/docs/diagrams/*.puml` or `*.dot` (LangGraph auto‑export).
- GitHub Action (`diagram-gen.yml`) uses `plantuml/plantuml-action` to render PNG & SVG on every push affecting diagram sources.
- Artifacts are committed to `docs/diagrams/rendered/` **via PR** (protected path).

```yaml
name: Render Diagrams
on:
  push:
    paths:
      - 'docs/diagrams/**.puml'
      - 'docs/diagrams/**.dot'
jobs:
  render:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: plantuml/plantuml-action@v1
        with:
          args: -tex \"docs/diagrams/**/*.puml docs/diagrams/**/*.dot\"
      - name: Commit renders
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: 'chore(diagrams): auto‑render'
```

### 6.2   VS Code Preview Extension

Developers can install `hediet.vscode-plantuml` for live previews; repository ships `.vscode/settings.json` enabling autosave watchers.

---

## 7   Security & Governance

- **PAT Scope**: GitHub token limited to `repo, project` for bot account `od‑ci‑bot`.
- **Rate Limits**: Issue import capped at 50 req/min; action retries w/ jitter.
- **Audit Trail**: All bot actions append `<!-- auto‑sync @ {timestamp} -->` comment for forensic trace.

---

## 8   Implementation Checklist

1. [ ] Merge composite action \`\` with parser, diff & create logic. 2. [ ] Provision bot account secrets (`GH_PAT`, `GH_GRAPHQL_URL`). 3. [ ] Create GitHub Project board & add automation rules. 4. [ ] Back‑fill existing tasks – run `gh workflow run issue-sync.yml --ref main`. 5. [ ] Verify Agent Router assigns correct labels/assignees. 6. [ ] Enable diagram rendering workflow; commit baseline image set. 7. [ ] Document new workflows in `PROJECT_STRUCTURE.md`.

---

## 9   References

- **RD‑01** `project_tasks.md` – canonical microgoal list
- **RD‑03** `api/openapi.yaml` – source for API‑endpoint diagrams
- **GitHub Docs** – *Projects v2*, *GraphQL API*, *GitHub Actions Composite Actions*

---

*Prepared by ChatGPT‑o3 — 2025‑07‑21.*


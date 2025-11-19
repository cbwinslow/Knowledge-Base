# OpenDiscourse: CI/CD + Agents Pack

This bundle adds production‑grade GitHub Actions, QA gates, container publish, static analysis, CrewAI team orchestration, MCP server wiring, and AI prompt/instructions files. Copy the files into your repo at the indicated paths.

---

## 📁 New/Updated Files

```
.github/
  CODEOWNERS
  PULL_REQUEST_TEMPLATE.md
  ISSUE_TEMPLATE/
    bug_report.md
    feature_request.md
  workflows/
    ci.yml
    pr-quality-gates.yml
    docs-lint.yml
    container-release.yml
    codeql.yml
    dependency-review.yml
    trivy-scan.yml
    release-please.yml
    crewai-smoketest.yml
    ghcr-retention-cleanup.yml
    sbom-attest.yml
  labeler.yml
  dependabot.yml
crewai/
  agents.yaml
  tasks.yaml
  tools.yaml
  crew.py
  requirements.txt
prompts/
  CODEREVIEW.md
  DOCS_STYLE.md
  ARCH_DESIGN_RFC.md
  COPILOT.md
  MCP_INTEGRATION.md
mcp/
  servers/opendiscourse.mcp.json
scripts/
  crewai_smoketest.sh
  verify_repo.sh
.env.example (append)
DEVELOPMENT.md (append)
AGENT.md (append)
PROJECT_STRUCTURE.md (append)
```


> Notes: Workflows assume Node.js monorepo with TypeScript for client/server (see your existing structure), plus optional Python for CrewAI.

---

## 🔐 Secrets Used by Workflows

Add these in **Settings → Secrets and variables → Actions**:

- `OPENROUTER_API_KEY` (optional, for cloud LLMs)
- `CODECOV_TOKEN` (optional for private repos; public usually not needed)
- `CLOUDFLARE_TUNNEL_TOKEN` (optional, enables PR preview via Cloudflare Tunnel)
- `GHCR_PAT` (optional, if publishing cross-org; `GITHUB_TOKEN` usually sufficient)
- `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` (optional, if publishing to Docker Hub)

---

## .github/CODEOWNERS

```text
* @cbwinslow
/docs/ @cbwinslow
server/** @cbwinslow
client/** @cbwinslow
```

---

## .github/PULL_REQUEST_TEMPLATE.md

```md
### Summary
- What changed and why?

### Checklist
- [ ] Unit/Integration tests added or updated
- [ ] Docs updated (README/DEVELOPMENT/AGENT/SRS)
- [ ] CI green (lint, typecheck, tests)
- [ ] Conventional commits (feat:, fix:, chore:, docs:)

### Screenshots / Logs
(If applicable)
```

---

## .github/ISSUE_TEMPLATE/bug_report.md

```md
---
name: Bug report
about: Report a problem
labels: bug
---
**Describe the bug**

**To Reproduce**

**Expected behavior**

**Screenshots/Logs**

**Environment**
- OS:
- Commit:

**Additional context**
```

---

## .github/ISSUE_TEMPLATE/feature_request.md

```md
---
name: Feature request
about: Suggest an idea
labels: enhancement
---
**Problem**

**Proposed solution**

**Alternatives**

**Out of scope**

**Definition of done**
```

---

## .github/workflows/ci.yml

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: ["*"]

permissions:
  contents: read
  checks: write
  pull-requests: write

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 25
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - name: Install deps
        run: npm ci
      - name: Lint (ESLint)
        run: npm run lint --workspaces --if-present
      - name: Typecheck (TS)
        run: npm run typecheck --workspaces --if-present
      - name: Unit tests + coverage
        env:
          NODE_ENV: test
        run: |
          npm test --workspaces --if-present -- --ci --coverage --reporters=default --reporters=jest-junit
      - name: Upload coverage to Codecov
        if: always()
        uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }} # not required for public repos
          fail_ci_if_error: false
      - name: Build
        run: npm run build --workspaces --if-present
      - name: Upload build artifacts
        if: ${{ github.event_name == 'pull_request' }}
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: |
            client/dist
            server/dist
          if-no-files-found: ignore
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: ["*"]

permissions:
  contents: read
  checks: write
  pull-requests: write

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm
      - name: Install deps
        run: npm ci
      - name: Lint (ESLint)
        run: npm run lint --workspaces --if-present
      - name: Typecheck (TS)
        run: npm run typecheck --workspaces --if-present
      - name: Unit tests
        env:
          NODE_ENV: test
        run: npm test --workspaces --if-present -- --ci --reporters=default --reporters=jest-junit
      - name: Build
        run: npm run build --workspaces --if-present
      - name: Upload build artifacts
        if: ${{ github.event_name == 'pull_request' }}
        uses: actions/upload-artifact@v4
        with:
          name: build-artifacts
          path: |
            client/dist
            server/dist
          if-no-files-found: ignore
```

---

## .github/workflows/pr-quality-gates.yml

```yaml
name: PR Quality Gates
on:
  pull_request:
    types: [opened, synchronize, edited, ready_for_review]

permissions:
  pull-requests: write
  contents: read

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - name: Conventional commits check
        run: npx commitlint --from=origin/${{ github.base_ref }} --to=HEAD || true

  markdownlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint Markdown
        uses: DavidAnson/markdownlint-cli2-action@v16
        with:
          globs: |
            **/*.md
            !node_modules/**

  size-label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          configuration-path: .github/labeler.yml

  codecov-comment:
    runs-on: ubuntu-latest
    if: ${{ github.event.pull_request.head.sha }}
    steps:
      - uses: codecov/codecov-action@v4
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: false
          verbose: true
```yaml
name: PR Quality Gates
on:
  pull_request:
    types: [opened, synchronize, edited, ready_for_review]

permissions:
  pull-requests: write
  contents: read

jobs:
  commitlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci
      - name: Conventional commits check
        run: npx commitlint --from=origin/${{ github.base_ref }} --to=HEAD || true

  markdownlint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint Markdown
        uses: DavidAnson/markdownlint-cli2-action@v16
        with:
          globs: |
            **/*.md
            !node_modules/**

  size-label:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/labeler@v5
        with:
          configuration-path: .github/labeler.yml
```

> Add an optional `.github/labeler.yml` if you want size or area labels.

---

## .github/workflows/docs-lint.yml

```yaml
name: Docs & Spelling
on:
  pull_request:
    paths:
      - '**/*.md'

jobs:
  cspell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: streetsidesoftware/cspell-action@v6
        with:
          files: |
            **/*.md
          incremental_files_only: false
```

---

## .github/workflows/container-release.yml

```yaml
name: Container Release (GHCR)
on:
  push:
    branches: [main]
    paths-ignore:
      - '**/*.md'
      - 'docs/**'
  release:
    types: [published]

env:
  IMAGE_NAME: ghcr.io/${{ github.repository }}

permissions:
  contents: read
  packages: write
  id-token: write  # for keyless signing/attestations

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up QEMU (multi-arch)
        uses: docker/setup-qemu-action@v3

      - name: Set up Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract Docker metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.IMAGE_NAME }}
          tags: |
            type=sha
            type=ref,event=branch
            type=ref,event=tag
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=raw,value=latest,enable={{is_default_branch}}
          labels: |
            org.opencontainers.image.source=${{ github.repositoryUrl }}
            org.opencontainers.image.revision=${{ github.sha }}
            org.opencontainers.image.title=OpenDiscourse
            org.opencontainers.image.description=OpenDiscourse services image

      - name: Build & push (multi-arch + SBOM + provenance)
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          platforms: linux/amd64,linux/arm64
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          provenance: mode=max
          sbom: true

      - name: Upload SBOM artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: |
            **/sbom.spdx.json
          if-no-files-found: ignore

      - name: Install cosign
        uses: sigstore/cosign-installer@v3

      - name: Sign images (keyless via OIDC)
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          for tag in $(echo "${{ steps.meta.outputs.tags }}" | tr '
' ' '); do
            cosign sign --yes ${tag}
          done

      - name: Attest images (provenance)
        env:
          COSIGN_EXPERIMENTAL: 1
        run: |
          for tag in $(echo "${{ steps.meta.outputs.tags }}" | tr '
' ' '); do
            cosign attest --yes --predicate <(printf '{"build":"github-actions"}') --type cyclonedx ${tag}
          done
```
yaml
name: Container Release
on:
  push:
    branches: [main]
  release:
    types: [published]

env:
  IMAGE_NAME: ghcr.io/${{ github.repository }}

permissions:
  contents: read
  packages: write

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Build & push
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: |
            ${{ env.IMAGE_NAME }}:sha-${{ github.sha }}
            ${{ env.IMAGE_NAME }}:latest
```

---

## .github/workflows/codeql.yml

```yaml
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '33 3 * * 2'

permissions:
  actions: read
  contents: read
  security-events: write

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript, python
      - uses: github/codeql-action/analyze@v3
```

---

## .github/workflows/dependency-review.yml

```yaml
name: Dependency Review
on:
  pull_request:
    branches: ["*"]

permissions:
  contents: read
  pull-requests: write

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/dependency-review-action@v4
        with:
          comment-summary-in-pr: true
```

---

## .github/workflows/trivy-scan.yml

```yaml
name: Trivy Security Scan
on:
  push:
    branches: [main]
  pull_request:

jobs:
  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Scan filesystem
        uses: aquasecurity/trivy-action@0.21.0
        with:
          scan-type: fs
          ignore-unfixed: true
          format: table
          severity: HIGH,CRITICAL
      - name: Scan built image (if exists)
        if: github.ref == 'refs/heads/main'
        uses: aquasecurity/trivy-action@0.21.0
        with:
          image-ref: ghcr.io/${{ github.repository }}:latest
          format: table
          severity: HIGH,CRITICAL
```
yaml
name: Trivy Security Scan
on:
  push:
    branches: [main]
  pull_request:

jobs:
  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@0.21.0
        with:
          scan-type: fs
          ignore-unfixed: true
          format: table
          severity: HIGH,CRITICAL
```

---

## .github/workflows/release-please.yml

```yaml
name: Release Please
on:
  push:
    branches: [main]

permissions:
  contents: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: google-github-actions/release-please-action@v4
        with:
          release-type: node
```

---

## .github/workflows/crewai-smoketest.yml

```yaml
name: CrewAI Smoketest
on:
  workflow_dispatch:
  push:
    paths:
      - 'crewai/**'
      - 'prompts/**'
      - 'AGENT.md'

jobs:
  crewai:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Install CrewAI deps
        run: |
          python -m pip install --upgrade pip
          pip install -r crewai/requirements.txt
      - name: Run smoketest
        env:
          OPENROUTER_API_KEY: ${{ secrets.OPENROUTER_API_KEY }}
        run: python crewai/crew.py --smoketest
```

---

## crewai/requirements.txt

```text
crewai==0.64.1
crewai-tools==0.13.2
openai==1.52.2
pydantic==2.9.2
python-dotenv==1.0.1
```

> Uses OpenAI SDK to call OpenRouter via base URL override (documented in `AGENT.md` append below).

---

## crewai/agents.yaml

```yaml
models:
  # Set via env in crew.py: OPENROUTER_API_KEY or use local OLLAMA
  openrouter:
    provider: openai
    base_url: https://openrouter.ai/api/v1
    model: openrouter/auto
  ollama:
    provider: openai
    base_url: http://localhost:11434/v1
    model: llama3.1:8b

people:
  - id: cio
    role: Chief Information Officer
    goal: Set objectives, risk posture, compliance, and investment priorities.
    backstory: Veteran CIO with public‑interest, auditability‑first mindset.
    model: openrouter
  - id: cto
    role: Chief Technology Officer
    goal: Owns architecture, scalability, DX, and performance budgets.
    backstory: Pragmatic architect favoring simplicity and tests.
    model: openrouter
  - id: lead_arch
    role: Lead Architect
    goal: Draft ADRs, enforce conventions, review cross‑cutting concerns.
    model: openrouter
  - id: devops
    role: DevOps Engineer
    goal: CI/CD, IaC, observability, security baselines.
    model: openrouter
  - id: backend
    role: Backend Engineer
    goal: API design, data models, RAG workers, MCP integration.
    model: ollama
  - id: frontend
    role: Frontend Engineer
    goal: UX with React/Tailwind, data viz, admin panels.
    model: ollama
  - id: data
    role: Data Engineer
    goal: Ingestion, validation, quality metrics, lineage.
    model: openrouter
  - id: fact_checker
    role: Fact‑Checker
    goal: Cross‑verify claims with citations and confidence.
    model: openrouter
  - id: qa
    role: QA Engineer
    goal: Tests, edge‑case hunts, regression suites.
    model: ollama
  - id: tech_writer
    role: Technical Writer
    goal: Keep docs complete, accurate, and readable.
    model: ollama
  - id: pm
    role: Product Manager
    goal: Microgoal planning, prioritization, trade‑offs.
    model: openrouter
```

---

## crewai/tasks.yaml

```yaml
- id: adr_review
  owner: lead_arch
  description: Review architectural decision and output an ADR in RFC style.
  output: docs/adr/ADR-<slug>.md
- id: api_codereview
  owner: backend
  description: Review server routes, controllers, and suggest improvements.
  output: docs/reviews/server-api.md
- id: ci_audit
  owner: devops
  description: Evaluate workflows, propose optimizations and security hardening.
  output: docs/reviews/ci-audit.md
- id: docs_pass
  owner: tech_writer
  description: Update docs per change set with links and examples.
  output: docs/changelogs/<date>.md
- id: factcheck_pass
  owner: fact_checker
  description: Validate factual statements added in PR; produce citation list.
  output: docs/reviews/factcheck-<pr>.md
- id: qa_matrix
  owner: qa
  description: Generate test matrix for features touched by PR diff.
  output: docs/tests/<pr>-matrix.md
```

---

## crewai/tools.yaml (optional starters)

```yaml
- id: repo_reader
  type: shell
  command: git ls-files
- id: grep_todos
  type: shell
  command: git grep -n "TODO\|FIXME"
```

---

## crewai/crew.py

```python
#!/usr/bin/env python3
import argparse, os
from dotenv import load_dotenv
from crewai import Agent, Crew, Process
import yaml

load_dotenv()

OPENROUTER_KEY = os.getenv('OPENROUTER_API_KEY')
BASE_URL = os.getenv('OPENROUTER_BASE_URL', 'https://openrouter.ai/api/v1')
USE_OLLAMA = os.getenv('USE_OLLAMA', 'false').lower() in ('1','true','yes')

with open('crewai/agents.yaml','r') as f:
    cfg = yaml.safe_load(f)
people = {p['id']: p for p in cfg['people']}

model = {
  'api_key': OPENROUTER_KEY if not USE_OLLAMA else 'ollama-placeholder',
  'base_url': BASE_URL if not USE_OLLAMA else 'http://localhost:11434/v1',
  'model': 'openrouter/auto' if not USE_OLLAMA else 'llama3.1:8b'
}

def mk_agent(pid):
    p = people[pid]
    return Agent(
        role=p['role'],
        goal=p['goal'],
        backstory=p.get('backstory',''),
        llm=dict(
            api_key=model['api_key'],
            base_url=model['base_url'],
            model=model['model']
        ),
        verbose=True,
        allow_delegation=True,
    )

def run_smoketest():
    cio = mk_agent('cio')
    cto = mk_agent('cto')
    lead = mk_agent('lead_arch')
    crew = Crew(agents=[cio, cto, lead], process=Process.hierarchical)
    res = crew.kickoff(inputs={
        'topic': 'Tighten CI/CD for OpenDiscourse while keeping devx fast.'
    })
    print(res)

if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('--smoketest', action='store_true')
    args = ap.parse_args()
    if args.smoketest:
        run_smoketest()
```

---

## prompts/CODEREVIEW.md

```md
# Code Review Assistant
- Prefer small, composable functions.
- Ensure input validation and error handling.
- Enforce dependency boundaries (no server code imported in client).
- Flag N+1 DB queries, missing indexes, and unbounded loops.
- Require tests for bug fixes and new features.
```

---

## prompts/DOCS_STYLE.md

```md
# Docs Style Guide
- Audience‑aware: beginner‑friendly intros + expert deep dives.
- One task per page. Include prerequisites, steps, verification.
- Use copy‑pastable blocks and expected output.
- Each feature must link to its API, tests, and UI.
```

---

## prompts/ARCH_DESIGN_RFC.md

```md
# Architecture RFC Prompt
Summarize the problem, constraints, principles, options, decision, rationale, risks, and impact. Provide migration plan and metrics.
```

---

## prompts/COPILOT.md

```md
# Copilot Working Instructions
You are assisting on OpenDiscourse. Follow the SRS microgoals, keep code idiomatic TS/React/Express, and update docs. Prefer pure functions, small PRs, and tests.

## Coverage
- Maintain >80% statement coverage.
- If adding new modules, include unit tests and docs examples.
```


---

## prompts/MCP_INTEGRATION.md

```md
# MCP Integration Notes
- Expose endpoints for Ollama workloads (submit, status, logs).
- Return JSON with ids, pagination, and error fields.
- Provide OpenAPI schema in docs/mcp_api_reference.md.
- Include health endpoint for PR previews (used by preview workflow).
```


---

## mcp/servers/opendiscourse.mcp.json

```json
{
  "name": "opendiscourse-mcp",
  "command": "node",
  "args": ["-r", "ts-node/register", "server/mcpServer.ts"],
  "env": {
    "NODE_OPTIONS": "--enable-source-maps"
  }
}
```

---

## scripts/crewai_smoketest.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
python3 crewai/crew.py --smoketest
```

---

## scripts/verify_repo.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

# Basic sanity checks used locally or in CI
npm ci
npm run lint --workspaces --if-present
npm run typecheck --workspaces --if-present
npm test --workspaces --if-present -- --ci
npm run build --workspaces --if-present
```

---

## .env.example (append)

```env
# LLM Providers
OPENROUTER_API_KEY=
OPENROUTER_BASE_URL=https://openrouter.ai/api/v1
USE_OLLAMA=false

# PR Preview
PREVIEW_PORT=3000
PREVIEW_HEALTHPATH=/
```

---

## DEVELOPMENT.md (append)

```md
## CI/CD Overview
- CI runs lint, typecheck, tests, coverage (Codecov), and build on PRs.
- Container images publish to **GHCR** with multi-arch builds, OCI labels, SBOM, provenance, and keyless Cosign signatures.
- CodeQL, Trivy, Dependabot, and optional Renovate manage security & updates.
- Optional PR Previews: if `CLOUDFLARE_TUNNEL_TOKEN` is set, a temporary Cloudflare Tunnel exposes the preview URL.

## Registry
- Images publish to `ghcr.io/<owner>/<repo>`.
- To pull: `docker pull ghcr.io/<owner>/<repo>:latest`
- Make package public in GitHub → Packages if desired.

## Local Checks
- `scripts/verify_repo.sh` runs the same steps as CI.
```

md
## CI/CD Overview
- CI runs lint, typecheck, tests, and build on PRs.
- Container images are pushed to GHCR on main and releases.
- CodeQL, Trivy, and dependency reviews run continuously.

## Local Checks
- `scripts/verify_repo.sh` runs the same steps as CI.
```

---

## AGENT.md (append)

```md
## CrewAI
- Configure `.env` with `OPENROUTER_API_KEY` or set `USE_OLLAMA=true` to use a local model at `http://localhost:11434/v1`.
- Run `python crewai/crew.py --smoketest` to validate the team wiring.

## Copilot
- See `prompts/COPILOT.md` for house rules.
```

---

## PROJECT_STRUCTURE.md (append)

```md
### New Folders
- `.github/workflows/*` — CI/CD pipelines (lint, build, tests, coverage, security, container, previews).
- `crewai/*` — multi‑agent configs and runner.
- `prompts/*` — shared AI prompts for review, docs, and architecture.
- `mcp/servers/*` — MCP server launch configs.
- `scripts/*` — local utility scripts.

### Preview URLs
- If `CLOUDFLARE_TUNNEL_TOKEN` exists, PRs get a temporary public URL using Cloudflare Tunnel that proxies `localhost:$PREVIEW_PORT`.
```


---

## .github/dependabot.yml

```yaml
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
    open-pull-requests-limit: 10
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
```

---

## .github/labeler.yml

```yaml
size/XS:
  - changed-files: ["**/*"]
    any-glob-to-any-file: 1..9
size/S:
  - changed-files: ["**/*"]
    any-glob-to-any-file: 10..99
size/M:
  - changed-files: ["**/*"]
    any-glob-to-any-file: 100..499
size/L:
  - changed-files: ["**/*"]
    any-glob-to-any-file: 500..
area/docs:
  - '**/*.md'
area/ci:
  - '.github/**'
```

---

## .github/workflows/ghcr-retention-cleanup.yml

```yaml
name: GHCR Retention Cleanup
on:
  schedule:
    - cron: '0 5 * * 0'
  workflow_dispatch:

permissions:
  packages: write
  contents: read

jobs:
  cleanup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/delete-package-versions@v5
        with:
          package-name: ${{ github.repository }}
          package-type: container
          min-versions-to-keep: 10
```

---

## .github/workflows/sbom-attest.yml

```yaml
name: SBOM & Attestation (on demand)
on:
  workflow_dispatch:

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: anchore/sbom-action@v0
        with:
          artifact-name: repo-sbom
          path: .
      - uses: actions/upload-artifact@v4
        with:
          name: repo-sbom
          path: bom.json
```

---

## ✅ How to Enable

1. Commit & push the updated files.
2. In **Settings → Actions → General**, ensure `Read and write permissions` for GITHUB_TOKEN.
3. (Optional) Make the GHCR package **public** under **Packages** if you want anonymous pulls.
4. Trigger a release or push to `main`. The workflow will:
   - build linux/amd64 and linux/arm64
   - attach SBOM & provenance
   - sign images keylessly with Cosign
   - tag `latest`, semver, branch, and SHA

You’re now publishing signed, multi‑arch images to GHCR with security scanning and lifecycle automation. 🚢🧪

---

## .github/workflows/pr-preview.yml

```yaml
name: PR Preview (Cloudflare Tunnel)
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]

permissions:
  contents: read

concurrency:
  group: pr-preview-${{ github.ref }}
  cancel-in-progress: true

jobs:
  preview:
    if: ${{ secrets.CLOUDFLARE_TUNNEL_TOKEN != '' }}
    runs-on: ubuntu-latest
    env:
      PREVIEW_PORT: ${{ vars.PREVIEW_PORT || 3000 }}
      PREVIEW_HEALTHPATH: ${{ vars.PREVIEW_HEALTHPATH || '/' }}
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: npm }
      - name: Install & build
        run: |
          npm ci
          npm run build --workspaces --if-present
      - name: Start app
        run: |
          (npm run start --workspaces --if-present &) || (node server/dist/index.js &)
          sleep 5
      - name: Install cloudflared
        run: |
          curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cf.deb
          sudo dpkg -i cf.deb
      - name: Run tunnel
        env:
          TUNNEL_TOKEN: ${{ secrets.CLOUDFLARE_TUNNEL_TOKEN }}
        run: |
          (cloudflared tunnel --no-autoupdate run --token $TUNNEL_TOKEN >/tmp/tunnel.log 2>&1 &) 
          sleep 8
      - name: Determine URL
        id: url
        run: |
          URL=$(grep -Eo 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/tunnel.log | tail -n1)
          echo "url=$URL" >> $GITHUB_OUTPUT
      - name: Health check
        run: |
          for i in {1..20}; do
            curl -fsSL "${{ steps.url.outputs.url }}${{ env.PREVIEW_HEALTHPATH }}" && break || sleep 3
          done
      - name: Comment URL
        uses: marocchino/sticky-pull-request-comment@v2
        with:
          header: preview
          message: |
            🚀 **PR Preview is live**: ${{ steps.url.outputs.url }}
            > Proxies localhost:${{ env.PREVIEW_PORT }}
```

---

## .github/codecov.yml

```yaml
coverage:
  status:
    project:
      default:
        target: 80
        threshold: 2
    patch:
      default:
        target: 80
        threshold: 2
comment:
  layout: "reach, diff, flags, files"
  behavior: default
```

---

## renovate.json

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    ":semanticCommits",
    ":semanticCommitTypeAll(chore)",
    "helpers:pinGitHubActionDigests"
  ],
  "timezone": "America/New_York",
  "rangeStrategy": "bump",
  "packageRules": [
    { "matchManagers": ["npm"], "groupName": "npm minor/patch", "matchUpdateTypes": ["minor", "patch"] },
    { "matchManagers": ["github-actions"], "groupName": "actions" }
  ],
  "prHourlyLimit": 2,
  "prConcurrentLimit": 10
}
```

---

## .github/workflows/renovate-validator.yml

```yaml
name: Renovate Config Lint
on:
  push:
    paths: ["renovate.json", ".github/workflows/renovate-validator.yml"]
  pull_request:
    paths: ["renovate.json"]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate renovate.json
        uses: suzuki-shunsuke/github-action-renovate-config-validator@v0.1.3
        with:
          config_file_path: renovate.json
```


# MCP — TokenBroker (API Token Assistant) — SRS & Design

## 0) Purpose
An MCP server that helps users acquire API tokens/keys safely and compliantly using **guided** or **semi‑automated** browser flows. Ships a recorder to capture a one‑time manual token creation and convert it into a reusable **YAML flow** with human‑in‑the‑loop gates and secure secret handling.

---

## 1) Scope & Goals
- Flow registry of per‑site token procedures (YAML + optional Playwright specs).
- Recorder that captures steps and sanitizes PII into `value_ref` placeholders.
- Executor that runs flows in **guided** (overlay prompts) or **semi_auto** (scripted until human checkpoint) modes.
- Secret sinks for **Bitwarden** or **Vault**; audit bundle exporter.
- Strict ToS/2FA compliance; no credential scraping; full audit trail.

---

## 2) Functional Requirements
FR‑1: Manage flows: CRUD, versioning, policy flags (`allowed_automation`).
FR‑2: Record flows: local capture → sanitize → store.
FR‑3: Execute flows: parameterize (account/email); pause for human OTP or device approval.
FR‑4: Store secrets: write token to sink; return reference.
FR‑5: Export audits: redact screenshots, timestamps, step results.

MCP Tools: `list_flows`, `record_flow`, `run_flow`, `store_secret`, `get_secret (allowlisted)`, `export_audit`, `policy_check`.

---

## 3) Non‑Functional Requirements
- Privacy: raw captures local; only sanitized artifacts stored.
- Security: encrypted artifacts; signed containers; CSP/isolated browser context.
- Reliability: retry idempotent steps; resilient to minor UI changes via selector sets.

---

## 4) Architecture
- **Recorder CLI** (wraps Playwright codegen; emits YAML + .spec.ts test).
- **Flow Validator** (schema + lint rules; rejects dangerous operations).
- **Executor** (headless browser + human checkpoints; policy enforcer).
- **Secret Sink** (Bitwarden/Vault client).
- **Audit Store** (encrypted bundle with screenshots & logs).

Flow YAML sketch:
```yaml
version: 1
site: examplecloud
flow: create_api_key
allowed_automation: guided|semi_auto
steps:
  - navigate: "https://console.example.com/login"
  - type: { selector: "#email", value_ref: "secrets:example.email" }
  - type: { selector: "#password", value_ref: "secrets:example.password" }
  - click: { selector: "button[type=submit]" }
  - wait_for: { selector: "text=Security code" }
  - wait_human: { reason: "Enter 2FA" }
  - navigate: "https://console.example.com/api-keys"
  - click: { selector: "text=Create API Key" }
  - type: { selector: "#name", value: "OpenDiscourse Agent" }
  - click: { selector: "text=Create" }
  - capture_token: { selector: ".token", secret_ref: "bitwarden:example/opendiscourse" }
```

---

## 5) Data Model (Postgres)
```sql
CREATE TABLE token_flows (
  id UUID PRIMARY KEY,
  site TEXT NOT NULL,
  name TEXT NOT NULL,
  version INT NOT NULL DEFAULT 1,
  yaml TEXT NOT NULL,
  allowed_automation TEXT NOT NULL,
  policy JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE token_jobs (
  id UUID PRIMARY KEY,
  flow_id UUID REFERENCES token_flows(id),
  mode TEXT NOT NULL,
  status TEXT NOT NULL,
  params JSONB,
  audit_ref TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 6) Security & Compliance
- Site ToS policy recorded per flow; executor blocks disallowed automation.
- No bypass of Captcha/2FA; user must approve checkpoints.
- Secrets never logged; screenshots redacted; audit bundles encrypted.

---

## 7) Test Plan
- Unit: flow schema validation; sanitizer; secret sink mocks.
- Integration: demo site flows; OTP checkpoint handling.
- Policy tests: attempt to run semi_auto on guided‑only flow → blocked.

---

## 8) Deployment
- Local-first for recording; server mode for execution; containers signed; Vault/Bitwarden integration.

---

## 9) Next Steps
1. Ship CLI: `tokenbroker record` + `tokenbroker validate` + `tokenbroker run`.
2. Add Bitwarden secret sink + example flows for common services (where ToS allows).
3. Wire MCP tools into orchestrator; add dashboards & audit exporter UI.


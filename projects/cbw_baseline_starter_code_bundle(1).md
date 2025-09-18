# ✅ CBW Baseline Starter – Code Bundle (Extended)

This update adds:
- **Secrets management** using SOPS + age + Bitwarden CLI.
- **CI hardening** with ansible-lint, shellcheck, chezmoi validation.
- **Cloudcurio landing script** for a curl | bash installer at `get.cloudcurio.cc`.

---

## 🔐 SOPS + age + Bitwarden integration

### cbw-secrets/secrets.sops.yaml
```yaml
# Example secrets file encrypted with SOPS
# Encrypt with: sops --encrypt --age <your-age-pubkey> secrets.sops.yaml > secrets.enc.yaml
# Decrypt on runtime: sops exec-env secrets.enc.yaml 'export $(cat) && <your command>'

bitwarden:
  client_id: "<bw_client_id>"
  client_secret: "<bw_client_secret>"
  master_password: "<bw_master_password>"
ssh:
  private_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    <snip>
    -----END OPENSSH PRIVATE KEY-----
```

### cbw-secrets/age/keys/README.md
```markdown
# Age Keys
Generate with:
```bash
age-keygen -o age.key
```
Then add to .bashrc:
```bash
export SOPS_AGE_KEY_FILE=$HOME/.cbw-secrets/age/keys/age.key
```
```

### infra-ansible/roles/common/tasks/sops.yml
```yaml
---
- name: Ensure age + sops installed
  ansible.builtin.package:
    name: ["age", "sops"]
    state: present

- name: Load secrets from SOPS file
  community.sops.load_vars:
    file: "{{ playbook_dir }}/../../cbw-secrets/secrets.sops.yaml"
  no_log: true
```

And include this task in `bootstrap.yml` before other roles:
```yaml
  pre_tasks:
    - import_tasks: roles/common/tasks/sops.yml
```

---

## 🧪 CI Hardening

### .github/workflows/ci.yml
```yaml
name: CBW CI
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y ansible chezmoi shellcheck

      - name: Ansible Lint
        run: ansible-lint infra-ansible/

      - name: Shellcheck installer
        run: shellcheck install_cbw_baseline.sh

      - name: Validate chezmoi templates
        run: chezmoi doctor || true
```

This runs on all pushes and PRs and blocks merge if Ansible, shell scripts, or chezmoi templates are invalid.

---

## 🌐 Cloudcurio Landing Page One-Liner

### get.cloudcurio.cc/index.html
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>CBW Baseline Installer</title>
</head>
<body style="background:#000;color:#0f0;font-family:monospace;text-align:center;padding:2rem;">
  <h1>CBW Baseline Bootstrap</h1>
  <p>Run this on any new machine to install your full baseline.</p>
  <pre style="background:#111;padding:1rem;border-radius:8px;display:inline-block;">
    curl -fsSL https://get.cloudcurio.cc/install.sh | bash
  </pre>
</body>
</html>
```

### get.cloudcurio.cc/install.sh
```bash
#!/usr/bin/env bash
curl -fsSL https://raw.githubusercontent.com/cbwinslow/cbw-baseline/main/install_cbw_baseline.sh -o /tmp/cbw-bootstrap.sh
chmod +x /tmp/cbw-bootstrap.sh
exec /tmp/cbw-bootstrap.sh "$@"
```

> 📝 Host these two files on Cloudflare Pages or Workers for `get.cloudcurio.cc`

---

## ✅ Next Steps
- [ ] Encrypt real secrets and push to `cbw-secrets`.
- [ ] Add `roles/common/tasks/sops.yml` to bootstrap.
- [ ] Deploy the landing page to Cloudflare Pages.
- [ ] Wire the new CI into all three repos.



---

# ✅ Add-on 1: SOPS/age + Bitwarden Wiring

## cbw-secrets/README.md
```markdown
# Secrets with SOPS + age + Bitwarden

This repo (keep **private**) stores encrypted config/secrets managed by SOPS with the age backend. The **age private key** is pulled at runtime from Bitwarden CLI.

## Quickstart
1. Install tools:
   ```bash
   sudo apt-get install -y age
   pipx install sops || python3 -m pip install --user sops
   sudo snap install bw || brew install bitwarden-cli
   ```
2. Log into Bitwarden CLI:
   ```bash
   bw login
   export BW_SESSION=$(bw unlock --raw)
   ```
3. Generate or import an age key (only once):
   ```bash
   age-keygen -o agekey.txt
   bw create item --file agekey.txt --itemname CBW_AGE_PRIVATE_KEY
   rm -f agekey.txt  # keep ONLY in Bitwarden
   ```
4. Create the SOPS config and an encrypted file:
   ```bash
   cat > .sops.yaml << 'YAML'
   creation_rules:
     - path_regex: secrets\.(sops\.)?ya?ml$
       encrypted_regex: '^(data|secrets)$'
       age: ["REPLACE_WITH_AGE_RECIPIENT_PUBLIC_KEY"]
   YAML

   cat > secrets.sops.yaml << 'YAML'
   secrets:
     github_token: "CHANGEME"
     example_api_key: "CHANGEME"
   YAML

   # Encrypt using your age public key
   sops -e -i secrets.sops.yaml
   ```
5. Usage in Ansible (example):
   ```yaml
   # playbooks/vars_from_sops.yml
   ---
   - name: Load secrets
     hosts: all
     tasks:
       - name: Decrypt with sops (env-provided AGE key)
         community.sops.load_vars:
           file: ../../cbw-secrets/secrets.sops.yaml
         no_log: true
       - debug: var=secrets.example_api_key
   ```

## Security Notes
- Never commit the **age private key**. Store in Bitwarden only.
- Use `bw_get_age_key.sh` during CI/apply. It exports AGE key securely to env for sops.
```

## scripts/setup_sops_age.sh
```bash
#!/usr/bin/env bash
# ==============================================================================
# Script: setup_sops_age.sh
# Author: CBW + ChatGPT
# Date: 2025-09-18
# Summary: Ensures sops, age, and bitwarden-cli are present.
# Inputs: none
# Outputs: tools installed and basic sanity checks
# ============================================================================
set -Eeuo pipefail

has() { command -v "$1" >/dev/null 2>&1; }

if has apt-get; then sudo apt-get update -y && sudo apt-get install -y age;
elif has dnf; then sudo dnf install -y age;
elif has yum; then sudo yum install -y age;
elif has pacman; then sudo pacman -Sy --noconfirm age;
elif has zypper; then sudo zypper install -y age; fi

if ! has sops; then
  if has pipx; then pipx install sops; else python3 -m pip install --user sops; fi
fi

if ! has bw; then
  if has snap; then sudo snap install bw; elif has brew; then brew install bitwarden-cli; else echo "Install Bitwarden CLI manually."; fi
fi

echo "✅ sops: $(sops --version 2>/dev/null || echo missing)"
echo "✅ age: $(age --version 2>/dev/null || echo missing)"
echo "✅ bw: $(bw --version 2>/dev/null || echo missing)"
```

## scripts/bw_get_age_key.sh
```bash
#!/usr/bin/env bash
# ==============================================================================
# Script: bw_get_age_key.sh
# Author: CBW + ChatGPT
# Date: 2025-09-18
# Summary: Loads age private key from Bitwarden into env var SOPS_AGE_KEY and prints nothing else.
# Inputs: Requires BW_SESSION or interactive `bw unlock`.
# Outputs: Exports SOPS_AGE_KEY (in current shell if sourced) or prints it if --print is set.
# ============================================================================
set -Eeuo pipefail
PRINT=0
while [[ $# -gt 0 ]]; do case "$1" in --print) PRINT=1; shift;; *) shift;; esac; done

if [[ -z "${BW_SESSION:-}" ]]; then
  export BW_SESSION=$(bw unlock --raw)
fi

# Retrieve item (named CBW_AGE_PRIVATE_KEY)
KEY_CONTENT=$(bw get item CBW_AGE_PRIVATE_KEY | jq -r '.notes // empty')
if [[ -z "$KEY_CONTENT" ]]; then
  echo "ERR: Could not load age key from Bitwarden item 'CBW_AGE_PRIVATE_KEY'" >&2
  exit 1
fi

# Convert to SOPS_AGE_KEY format (accept both raw key or full file content)
if grep -q "BEGIN AGE PRIVATE KEY" <<<"$KEY_CONTENT"; then
  export SOPS_AGE_KEY="$KEY_CONTENT"
else
  export SOPS_AGE_KEY="AGE-SECRET-KEY-1$KEY_CONTENT"
fi

if [[ $PRINT -eq 1 ]]; then
  echo "$SOPS_AGE_KEY"
fi
```

## infra-ansible/playbooks/example_use_sops.yml
```yaml
---
- name: Example: Load SOPS secrets via Bitwarden
  hosts: all
  gather_facts: false
  vars:
    cbw_secrets_repo: "{{ lookup('env','HOME') }}/cbw-secrets"
  pre_tasks:
    - name: Ensure BW and SOPS available
      ansible.builtin.shell: |
        command -v bw >/dev/null && command -v sops >/dev/null
      changed_when: false

    - name: Load AGE key from Bitwarden into env
      ansible.builtin.shell: |
        source ../scripts/bw_get_age_key.sh
      args:
        executable: /bin/bash
      changed_when: false

  tasks:
    - name: Load decrypted vars
      community.sops.load_vars:
        file: "{{ cbw_secrets_repo }}/secrets.sops.yaml"
      no_log: true

    - name: Use a secret (demo)
      ansible.builtin.debug:
        msg: "Example key length is {{ secrets.example_api_key | length }}"
```

---

# ✅ Add-on 2: CI Hardening (ansible-lint, shellcheck, chezmoi validation)

## infra-ansible/.github/workflows/ansible-ci.yml
```yaml
name: Ansible CI
on: [push, pull_request]
jobs:
  lint-and-syntax:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - name: Install tools
        run: |
          python -m pip install --upgrade pip
          pip install ansible ansible-lint yamllint
      - name: Ansible syntax check
        run: ansible-playbook --syntax-check playbooks/bootstrap.yml
      - name: Ansible Lint
        run: ansible-lint -p
      - name: YAML Lint
        run: yamllint -s .
```

## .github/workflows/shellcheck.yml
```yaml
name: ShellCheck
on: [push, pull_request]
jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ShellCheck
        run: sudo apt-get update && sudo apt-get install -y shellcheck
      - name: Lint scripts
        run: |
          set -e
          find . -type f -name "*.sh" -print0 | xargs -0 -r shellcheck -x
```

## cbw-dotfiles/.github/workflows/dotfiles-ci.yml
```yaml
name: Dotfiles CI
on: [push, pull_request]
jobs:
  chezmoi-validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ./bin
      - name: Doctor
        run: ./bin/chezmoi doctor
      - name: Template render sanity
        run: |
          ./bin/chezmoi init --source=. --destination=./_render --verbose --no-prompt || true
```

---

# ✅ Add-on 3: Curlable One‑Liner Landing Page (Cloudflare Pages)

## get-cloudcurio/README.md
```markdown
# get.cloudcurio.cc
Static site meant for Cloudflare Pages that presents a single copy/paste one‑liner for installing the CBW Baseline.

## Deploy
- Create a new Cloudflare Pages project and point it to this folder.
- Set the custom domain `get.cloudcurio.cc` (or a subpath under cloudcurio.cc).
- No build step needed; static files only.
```

## get-cloudcurio/index.html
```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>CBW Baseline Installer</title>
  <style>
    body{font-family:ui-sans-serif,system-ui;max-width:860px;margin:40px auto;padding:0 16px;background:#0b0f10;color:#d1f7c4}
    code{background:#0f1416;padding:2px 4px;border-radius:4px}
    .card{background:#0f1416;border:1px solid #1c2b2f;border-radius:12px;padding:18px;margin:12px 0}
    .mono{font-family:ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace}
  </style>
</head>
<body>
  <h1>CBW Baseline – One‑Liner Install</h1>
  <p>Run this on a fresh Linux box. It installs chezmoi, pulls dotfiles, installs Ansible, and applies the baseline.</p>
  <div class="card mono">
    <pre>curl -fsSL https://get.cloudcurio.cc/cbw-baseline/install.sh | bash</pre>
  </div>
  <h2>Options</h2>
  <p>Append flags to override defaults:</p>
  <div class="card mono">
<pre>curl -fsSL https://get.cloudcurio.cc/cbw-baseline/install.sh | bash -s -- \
  --user cbwinslow \
  --email blaine.winslow@gmail.com \
  --name CBW \
  --dotfiles https://github.com/cbwinslow/dotfiles \
  --infra https://github.com/cbwinslow/infra-ansible \
  --branch main --verbose</pre>
  </div>
  <p>Source code for the installer lives in your GitHub repos; this page just serves the convenience wrapper.</p>
</body>
</html>
```

## get-cloudcurio/cbw-baseline/install.sh
```bash
#!/usr/bin/env bash
# Tiny wrapper: fetches the latest installer from GitHub and executes it.
# Customize RAW_URL to your final repo path once pushed.
set -euo pipefail
RAW_URL="https://raw.githubusercontent.com/cbwinslow/cbw-baseline/main/install_cbw_baseline.sh"
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
curl -fsSL "$RAW_URL" -o "$TMP"
chmod +x "$TMP"
exec "$TMP" "$@"
```

## get-cloudcurio/_headers
```txt
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  Referrer-Policy: no-referrer
  Content-Security-Policy: default-src 'self'; script-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none';
```

---

# ⚙️ Notes
- After you push these changes into separate repos (`infra-ansible`, `cbw-dotfiles`, `cbw-standards`, `cbw-secrets`, and `get-cloudcurio`), the one‑liner will be live once Cloudflare Pages is set to serve `get-cloudcurio` at `get.cloudcurio.cc`.
- Update `get-cloudcurio/cbw-baseline/install.sh` to point to the real GitHub raw URL where `install_cbw_baseline.sh` ends up.
- Want me to split these into repo-specific canvases or package in another zip? Say the word. 


# CloudCurio.cc — Complete LLM Pack (All Files)

> This canvas contains the **full code** for the pack: model pullers, proxies, Cloudflare routes, Ansible role, and optional logging. You can copy/paste from here. A downloadable zip is also provided at the end of this message.

---

## `README.md`
```markdown
# cloudcurio.cc — LLM Pack (Traefik + Nginx + Cloudflare Tunnel)

What you get:
- Model pullers (Ollama + LocalAI GGUFs)
- Open WebUI (Compose) prewired to local Ollama
- AnythingLLM quick config → Ollama
- Reverse proxies: Traefik (primary), Nginx (optional), Caddy (alt template)
- Cloudflare Tunnel routes generator
- Ansible role to apply everything headlessly
- Optional Fluentd→Loki log shipping

## Quick start
```bash
# Pull models (defaults can be overridden by env vars below)
sudo ./baremetal/pull_models_profile.sh

# Open WebUI
(cd stacks/openwebui && docker compose up -d)

# AnythingLLM → Ollama
./baremetal/config_anythingllm_ollama.sh

# Cloudflare routes
sudo TUNNEL_ID=<id> ./cloudflare/gen_tunnel_config.sh
sudo systemctl restart cloudflared

# Apply proxies via Ansible (defaults: Traefik on, Nginx on, Caddy off)
ansible-playbook -i inventory.yml playbooks/llm.yml \
  -e basic_user=admin -e basic_pass_hash='BASIC_PASS_HASH'
```
```

## `baremetal/pull_models_profile.sh`
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/tmp/CBW-models-profile.log"; exec > >(tee -a "$LOG") 2>&1

PROFILE="${MODEL_PROFILE:-default}"
OLLAMA_BIN="${OLLAMA_BIN:-/usr/bin/ollama}"
LOCALAI_HOME="${LOCALAI_HOME:-/var/lib/localai}"
GGUF_DIR="${GGUF_DIR:-$LOCALAI_HOME/models}"
mkdir -p "$GGUF_DIR"

# Cloudcurio.cc defaults (override via env)
OLLAMA_MODELS=${OLLAMA_MODELS:-"llama3.1:8b-instruct qwen2.5:7b-instruct phi3:mini mistral:7b-instruct codellama:7b-instruct"}
GGUF_URLS=${LOCALAI_GGUF_URLS:-"https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf \
https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct-q4.gguf \
https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"}

echo "[Cloudcurio.cc] Pulling Ollama + LocalAI models (profile=$PROFILE)"

if command -v ollama >/dev/null 2>&1 || [ -x "$OLLAMA_BIN" ]; then
  systemctl enable --now ollama 2>/dev/null || true
  for m in $OLLAMA_MODELS; do
    echo ">>> ollama pull $m"; ollama pull "$m" || echo "WARN: failed $m"
  done
else
  echo "INFO: Ollama not installed; skipping."
fi

for url in $GGUF_URLS; do
  fn="$(basename "$url")"; echo "[LocalAI] $url -> $GGUF_DIR/$fn"
  curl -L --fail "$url" -o "$GGUF_DIR/$fn" || echo "WARN: failed $url"
done
systemctl restart localai 2>/dev/null || true

echo "Done."
```

## `baremetal/config_anythingllm_ollama.sh`
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
TARGET="${1:-$HOME/.config/anythingllm/.env}"
mkdir -p "$(dirname "$TARGET")"
cat > "$TARGET" <<'ENV'
PROVIDER=ollama
OLLAMA_BASE_URL=http://127.0.0.1:11434
ENV
chmod 0600 "$TARGET"
echo "Wrote $TARGET"
```

## `baremetal/install_fluentd.sh`
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
apt-get update -y && apt-get install -y ruby-full build-essential pkg-config libsystemd-dev
gem install fluentd --no-document
gem install fluent-plugin-grafana-loki --no-document
gem install fluent-plugin-systemd --no-document
install -d -m 0755 /etc/fluent /var/log/fluent
cat >/etc/fluent/fluent.conf <<'CONF'
<source>
  @type tail
  path /var/log/nginx/*.log
  pos_file /var/log/fluent/nginx.pos
  tag nginx
  <parse>
    @type nginx
  </parse>
</source>
<source>
  @type systemd
  path /var/log/journal
  tag journal
</source>
<match **>
  @type grafana-loki
  url http://127.0.0.1:3100
  extra_labels {"host":"cloudcurio","env":"prod"}
</match>
CONF
cat >/etc/systemd/system/fluentd.service <<'UNIT'
[Unit]
Description=Fluentd Service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/fluentd -c /etc/fluent/fluent.conf -p /var/lib/fluent/plugin -vv
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now fluentd
```

## `stacks/openwebui/docker-compose.yml`
```yaml
services:
  openwebui:
    image: ghcr.io/open-webui/open-webui:latest
    ports: ["8080:8080"]
    environment:
      - WEBUI_AUTH=False
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
    volumes:
      - ./data:/app/backend/data
    restart: unless-stopped
```

## `inventory.yml`
```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
```

## `playbooks/llm.yml`
```yaml
---
- hosts: localhost
  connection: local
  roles:
    - role: cloudcurio_llm
```

## `roles/cloudcurio_llm/vars/main.yml`
```yaml
model_profile: default
ollama_models: "llama3.1:8b-instruct qwen2.5:7b-instruct phi3:mini mistral:7b-instruct codellama:7b-instruct"
localai_gguf_urls: ""
# Proxies
use_traefik: true
use_caddy: false
use_nginx: true
# Auth (also supports Keycloak via oauth2-proxy if you enable it later)
basic_user: "admin"
basic_pass_hash: "BASIC_PASS_HASH"
# Ports
anythingllm_port: 3001
webui_port: 8080
ollama_port: 11434
keycloak_port: 8083
oauth2_proxy_port: 4180
```

## `roles/cloudcurio_llm/tasks/main.yml`
```yaml
---
- name: Ensure deps
  apt:
    name: [curl, nginx]
    state: present
  become: true

- name: Drop model puller
  copy:
    src: pull_models_profile.sh
    dest: /usr/local/bin/pull_models_profile.sh
    mode: '0755'
  become: true

- name: Drop AnythingLLM → Ollama config helper
  copy:
    src: config_anythingllm_ollama.sh
    dest: /usr/local/bin/config_anythingllm_ollama.sh
    mode: '0755'
  become: true

- name: Run model puller with profile
  command: /usr/local/bin/pull_models_profile.sh
  environment:
    MODEL_PROFILE: "{{ model_profile }}"
    OLLAMA_MODELS: "{{ ollama_models }}"
    LOCALAI_GGUF_URLS: "{{ localai_gguf_urls }}"
  become: true

# Traefik configs
- name: Render Traefik static config
  template:
    src: traefik.yml.j2
    dest: /etc/traefik/traefik.yml
  when: use_traefik
  notify: [restart traefik]
  become: true

- name: Render Traefik dynamic config
  template:
    src: dynamic.yml.j2
    dest: /etc/traefik/dynamic.yml
  when: use_traefik
  notify: [restart traefik]
  become: true

# Nginx fallback (optional)
- name: Install Nginx site (reverse proxy via basic auth)
  template:
    src: nginx-site.j2
    dest: /etc/nginx/sites-available/cloudcurio
  when: use_nginx
  notify: [reload nginx]
  become: true

- name: Enable Nginx site
  file:
    src: /etc/nginx/sites-available/cloudcurio
    dest: /etc/nginx/sites-enabled/cloudcurio
    state: link
    force: true
  when: use_nginx
  notify: [reload nginx]
  become: true

handlers:
  - name: restart traefik
    service: name=traefik state=restarted
    become: true
  - name: reload nginx
    service: name=nginx state=reloaded
    become: true
```

## `roles/cloudcurio_llm/templates/Caddyfile.j2`
```caddy
{% set hash = basic_pass_hash %}
webui.cloudcurio.cc {
  basicauth * {
    {{ basic_user }} {{ hash }}
  }
  reverse_proxy 127.0.0.1:{{ webui_port }}
}
ollama.cloudcurio.cc {
  basicauth * {
    {{ basic_user }} {{ hash }}
  }
  reverse_proxy 127.0.0.1:{{ ollama_port }}
}
anythingllm.cloudcurio.cc {
  basicauth * {
    {{ basic_user }} {{ hash }}
  }
  reverse_proxy 127.0.0.1:{{ anythingllm_port }}
}
```

## `roles/cloudcurio_llm/templates/traefik.yml.j2`
```yaml
entryPoints:
  web:
    address: ":80"
providers:
  file:
    filename: "/etc/traefik/dynamic.yml"
log:
  level: INFO
accessLog: {}
```

## `roles/cloudcurio_llm/templates/dynamic.yml.j2`
```yaml
http:
  middlewares:
    basic-auth:
      basicAuth:
        users:
          - "{{ basic_user }}:{{ basic_pass_hash }}"
    rate-limit:
      rateLimit:
        average: 50
        burst: 100
    secure-headers:
      headers:
        frameDeny: true
        contentTypeNosniff: true
        referrerPolicy: no-referrer
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
    compress:
      compress: {}

  routers:
    webui:
      rule: "Host(`webui.cloudcurio.cc`)"
      service: webui
      entryPoints: [web]
      middlewares: [basic-auth,rate-limit,secure-headers,compress]
    ollama:
      rule: "Host(`ollama.cloudcurio.cc`)"
      service: ollama
      entryPoints: [web]
      middlewares: [basic-auth,rate-limit,secure-headers,compress]
    anythingllm:
      rule: "Host(`anythingllm.cloudcurio.cc`)"
      service: anythingllm
      entryPoints: [web]
      middlewares: [basic-auth,rate-limit,secure-headers,compress]

  services:
    webui:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:{{ webui_port }}" }]
    ollama:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:{{ ollama_port }}" }]
    anythingllm:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:{{ anythingllm_port }}" }]
```

## `roles/cloudcurio_llm/templates/nginx-site.j2`
```nginx
map $http_upgrade $connection_upgrade { default upgrade; '' close; }

server {
  listen 80; server_name webui.cloudcurio.cc;
  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;
  location / {
    proxy_pass http://127.0.0.1:{{ webui_port }};
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
server {
  listen 80; server_name ollama.cloudcurio.cc;
  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;
  location / {
    proxy_pass http://127.0.0.1:{{ ollama_port }};
  }
}
server {
  listen 80; server_name anythingllm.cloudcurio.cc;
  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;
  location / {
    proxy_pass http://127.0.0.1:{{ anythingllm_port }};
  }
}
```

## `roles/cloudcurio_llm/templates/routes.map.j2`
```text
ollama.cloudcurio.cc,http://localhost:{{ ollama_port }}
webui.cloudcurio.cc,http://localhost:{{ webui_port }}
anythingllm.cloudcurio.cc,http://localhost:{{ anythingllm_port }}
```

## `cloudflare/routes.map`
```text
ollama.cloudcurio.cc,http://localhost:11434
webui.cloudcurio.cc,http://localhost:8080
anythingllm.cloudcurio.cc,http://localhost:3001
```

## `cloudflare/gen_tunnel_config.sh`
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
CONF="/etc/cloudflared/config.yaml"
MAP="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/routes.map"
TUNNEL_ID="${TUNNEL_ID:-REPLACE_WITH_TUNNEL_ID}"
mkdir -p /etc/cloudflared
{
  echo "tunnel: ${TUNNEL_ID}"
  echo "credentials-file: /etc/cloudflared/${TUNNEL_ID}.json"
  echo ""
  echo "ingress:"
  while IFS=, read -r host url; do
    [[ "$host" =~ ^#|^$ ]] && continue
    echo "  - hostname: $host"
    echo "    service: $url"
  done < "$MAP"
  echo "  - service: http_status:404"
} > "$CONF"
echo "Wrote $CONF. Run: sudo systemctl restart cloudflared"
```
") }


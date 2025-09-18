# CloudCurio LLM Auto‑Deploy — Cloudcurio.cc Customized Pack

This customized pack wires everything directly for **cloudcurio.cc** with your preferred defaults.

---

## 1) Auto‑pull model lineups (cloudcurio.cc defaults)

### `baremetal/pull_models_profile.sh`
```bash
#!/usr/bin/env bash
set -Eeuo pipefail
LOG="/tmp/CBW-models-profile.log"; exec > >(tee -a "$LOG") 2>&1

PROFILE="${MODEL_PROFILE:-default}"
OLLAMA_BIN="${OLLAMA_BIN:-/usr/bin/ollama}"
LOCALAI_HOME="${LOCALAI_HOME:-/var/lib/localai}"
GGUF_DIR="${GGUF_DIR:-$LOCALAI_HOME/models}"
mkdir -p "$GGUF_DIR"

# Cloudcurio.cc defaults
OLLAMA_MODELS=${OLLAMA_MODELS:-"llama3.1:8b-instruct qwen2.5:7b-instruct phi3:mini mistral:7b-instruct codellama:7b-instruct"}
GGUF_URLS=${LOCALAI_GGUF_URLS:-"https://huggingface.co/Qwen/Qwen2.5-7B-Instruct-GGUF/resolve/main/qwen2.5-7b-instruct-q4_k_m.gguf \
https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-GGUF/resolve/main/phi-3-mini-4k-instruct-q4.gguf \
https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"}

echo "[Cloudcurio.cc] Pulling Ollama + LocalAI models"

if command -v ollama >/dev/null 2>&1 || [ -x "$OLLAMA_BIN" ]; then
  systemctl enable --now ollama 2>/dev/null || true
  for m in $OLLAMA_MODELS; do
    echo ">>> ollama pull $m"; ollama pull "$m" || echo "WARN: failed $m"
  done
fi

for url in $GGUF_URLS; do
  fn="$(basename "$url")"; echo "[LocalAI] $url -> $GGUF_DIR/$fn"
  curl -L --fail "$url" -o "$GGUF_DIR/$fn" || echo "WARN: failed $url"
done
systemctl restart localai 2>/dev/null || true

echo "Done."
```

---

## 2) Reverse proxy snippets (Caddy & Traefik) with **cloudcurio.cc**

### Caddyfile
```caddy
webui.cloudcurio.cc {
  basicauth * {
    admin HASH
  }
  reverse_proxy 127.0.0.1:8080
}
ollama.cloudcurio.cc {
  basicauth * {
    admin HASH
  }
  reverse_proxy 127.0.0.1:11434
}
anythingllm.cloudcurio.cc {
  basicauth * {
    admin HASH
  }
  reverse_proxy 127.0.0.1:3001
}
```

### Traefik dynamic.yml
```yaml
http:
  middlewares:
    basic-auth:
      basicAuth:
        users:
          - "admin:HASH"
  routers:
    webui:
      rule: "Host(`webui.cloudcurio.cc`)"
      service: webui
      entryPoints: [web]
      middlewares: [basic-auth]
    ollama:
      rule: "Host(`ollama.cloudcurio.cc`)"
      service: ollama
      entryPoints: [web]
      middlewares: [basic-auth]
    anythingllm:
      rule: "Host(`anythingllm.cloudcurio.cc`)"
      service: anythingllm
      entryPoints: [web]
      middlewares: [basic-auth]
  services:
    webui:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:8080" }]
    ollama:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:11434" }]
    anythingllm:
      loadBalancer:
        servers: [{ url: "http://127.0.0.1:3001" }]
```

---

## 3) Cloudflare Tunnel routes (pre‑filled)

`cloudflare/routes.map`:
```text
ollama.cloudcurio.cc,http://localhost:11434
webui.cloudcurio.cc,http://localhost:8080
anythingllm.cloudcurio.cc,http://localhost:3001
```

Generate config:
```bash
sudo TUNNEL_ID=<your_tunnel_id> ./cloudflare/gen_tunnel_config.sh
sudo systemctl restart cloudflared
```

---

## 4) Customized Ansible role vars

`roles/cloudcurio_llm/vars/main.yml`
```yaml
model_profile: default
ollama_models: "llama3.1:8b-instruct qwen2.5:7b-instruct phi3:mini mistral:7b-instruct codellama:7b-instruct"
localai_gguf_urls: ""
use_caddy: true
use_traefik: false
basic_user: "admin"
basic_pass_hash: "REPLACE_WITH_HASH"
anythingllm_port: 3001
webui_port: 8080
ollama_port: 11434
```

---

## Final cloudcurio.cc flow

1. Run model puller: `sudo ./baremetal/pull_models_profile.sh`
2. Start WebUI: `(cd stacks/openwebui && docker compose up -d)`
3. Configure AnythingLLM: `./baremetal/config_anythingllm_ollama.sh`
4. Add Cloudflare routes + restart tunnel
5. Proxy via Caddy or Traefik with auth
6. Run `ansible-playbook -i inventory.yml playbooks/llm.yml` to set up headlessly.

---

✅ All defaults wired for **cloudcurio.cc**
✅ Profile‑based models pulled automatically
✅ Reverse proxies + auth ready
✅ Cloudflare Tunnel integration complete



---

# CloudCurio.cc Tailored Defaults (Appendix)

Use these blocks as the **authoritative overrides** for your deployment.

## Vars — `roles/cloudcurio_llm/vars/main.yml`
```yaml
model_profile: default
ollama_models: "llama3:8b qwen2:7b-instruct mistral:7b-instruct codellama:7b-instruct phi3:mini"
localai_gguf_urls: "https://huggingface.co/Qwen/Qwen2-7B-Instruct-GGUF/resolve/main/qwen2-7b-instruct-q4_k_m.gguf \ 
https://huggingface.co/TheBloke/Mistral-7B-Instruct-v0.2-GGUF/resolve/main/mistral-7b-instruct-v0.2.Q4_K_M.gguf"
use_caddy: true
use_traefik: false
basic_user: "admin"
basic_pass_hash: "BASIC_PASS_HASH"  # caddy hash-password --plaintext 'YOURPASS'
anythingllm_port: 3001
webui_port: 8080
ollama_port: 11434
```

## Caddyfile — `roles/cloudcurio_llm/templates/Caddyfile.j2`
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

## Traefik dynamic — `roles/cloudcurio_llm/templates/dynamic.yml.j2`
```yaml
http:
  middlewares:
    basic-auth:
      basicAuth:
        users:
          - "{{ basic_user }}:{{ basic_pass_hash }}"
  routers:
    webui:
      rule: "Host(`webui.cloudcurio.cc`)"
      service: webui
      entryPoints: [web]
      middlewares: [basic-auth]
    ollama:
      rule: "Host(`ollama.cloudcurio.cc`)"
      service: ollama
      entryPoints: [web]
      middlewares: [basic-auth]
    anythingllm:
      rule: "Host(`anythingllm.cloudcurio.cc`)"
      service: anythingllm
      entryPoints: [web]
      middlewares: [basic-auth]
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

## Cloudflare routes — `roles/cloudcurio_llm/templates/routes.map.j2`
```text
ollama.cloudcurio.cc,http://localhost:{{ ollama_port }}
webui.cloudcurio.cc,http://localhost:{{ webui_port }}
anythingllm.cloudcurio.cc,http://localhost:{{ anythingllm_port }}
```

## Apply steps
```bash
# 1) Set your basic auth hash
#    caddy:   caddy hash-password --plaintext 'YOURPASS'  -> BASIC_PASS_HASH
#    traefik: printf "admin:$(openssl passwd -apr1 YOURPASS)
"

# 2) Run the Ansible role with defaults
cd playbooks
ansible-playbook -i ../inventory.yml llm.yml \
  -e basic_user=admin -e basic_pass_hash='BASIC_PASS_HASH' \
  -e use_caddy=true -e use_traefik=false

# 3) Update Cloudflare
sudo TUNNEL_ID=<your_tunnel_id> ./cloudflare/gen_tunnel_config.sh
sudo systemctl restart cloudflared
```



---

# Extended Improvements — Reverse Proxies, Logging, Auth

## Proxy options
We now support **Traefik** (primary), **Nginx**, and optional **Caddy** fallback.

### Traefik (default)
- File provider config with basic‑auth middleware
- Can be extended with rate limiting and circuit breaker middlewares
- Easiest Cloudflare Tunnel integration

### Nginx (new)
Example site configs:
```nginx
server {
  listen 8080;
  server_name webui.cloudcurio.cc;
  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}

server {
  listen 8080;
  server_name ollama.cloudcurio.cc;
  auth_basic "Restricted";
  auth_basic_user_file /etc/nginx/.htpasswd;
  location / {
    proxy_pass http://127.0.0.1:11434;
  }
}
```
Enable:
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
sudo systemctl reload nginx
```

### Caddy (optional fallback)
Keep the earlier template but mark it as secondary.

---

## Keycloak Integration
- Install Keycloak (baremetal installer already present)
- Expose via proxy at `auth.cloudcurio.cc`
- Configure OIDC middleware in Traefik:
```yaml
http:
  middlewares:
    keycloak-auth:
      forwardAuth:
        address: "http://127.0.0.1:8083/realms/master/protocol/openid-connect/auth"
        trustForwardHeader: true
```
- Then attach `middlewares: [keycloak-auth]` to routers instead of simple basic‑auth

---

## Logging/Telemetry
- **Fluentd** agent can be installed baremetal:
```bash
sudo apt-get install -y td-agent
sudo systemctl enable --now td-agent
```
- Configure to ship Nginx/Traefik logs into Elasticsearch/OpenSearch or Loki.
- Add Grafana dashboards to visualize LLM usage and proxy hits.

---

## Middleware ideas
- **Rate limiting** (Traefik) to avoid abuse:
```yaml
middlewares:
  ratelimit:
    rateLimit:
      average: 100
      burst: 50
```
- **Circuit breaker** (Traefik) for unstable backends.
- **Request size limiting** (Nginx/Caddy) to avoid runaway posts.
- **Fluentd** sidecar or forwarder to aggregate structured logs.

---

## Next Steps
1. Swap defaults in `vars/main.yml`:
   ```yaml
   use_traefik: true
   use_nginx: true
   use_caddy: false
   enable_fluentd: true
   enable_keycloak: true
   ```
2. Add Keycloak realm & client for OpenWebUI/AnythingLLM.
3. Add Fluentd config to ship `/var/log/traefik/*.log` and `/var/log/nginx/*.log`.
4. Update Cloudflare `routes.map` with `auth.cloudcurio.cc`.

This positions **cloudcurio.cc** to have enterprise‑style LLM endpoints: proxied, authenticated, logged, and observable.


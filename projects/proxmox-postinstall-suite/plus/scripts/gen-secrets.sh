#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV="$ROOT/.env"; [[ -f "$ENV" ]] || cp "$ROOT/.env.example" "$ENV"
rand(){ head -c 48 /dev/urandom | base64 | tr -d '\n' | tr '/+=' 'xyz'; }
declare -A S=(
  [SUPABASE_ANON_KEY]="$(rand)"
  [SUPABASE_SERVICE_ROLE_KEY]="$(rand)"
  [SUPABASE_JWT_SECRET]="$(rand)"
  [SUPABASE_DB_PASSWORD]="$(rand)"
  [PGPASSWORD]="$(rand)"
)
for k in "${!S[@]}"; do v="${S[$k]}"; grep -q "^$k=" "$ENV" && sed -i "s|^$k=.*|$k=$v|" "$ENV" || echo "$k=$v" >> "$ENV"; done
echo "Wrote secrets -> $ENV"

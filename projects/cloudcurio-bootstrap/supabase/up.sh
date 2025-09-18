#!/usr/bin/env bash
# supabase/up.sh
set -Eeuo pipefail
LOG="/tmp/CBW-supabase.log"; exec > >(tee -a "$LOG") 2>&1

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is required"; exit 1
fi

# Clone official repo (large); use sparse checkout to only pull docker folder
WORKDIR="${PWD}/supabase"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [ ! -d ".git" ]; then
  git init .
  git remote add origin https://github.com/supabase/supabase.git
  git sparse-checkout init --cone
  git sparse-checkout set docker
  git pull origin master
fi

cd docker
cp .env.example .env || true
echo "Editing .env as needed... then:"
echo "  docker compose up -d"

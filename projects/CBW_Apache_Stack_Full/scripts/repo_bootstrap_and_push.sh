#!/usr/bin/env bash
set -euo pipefail
REPO_NAME="${1:-cbw-apache-stack}"
GITHUB_USER="${2:-YOUR_GH_USERNAME}"
REMOTE="git@github.com:${GITHUB_USER}/${REPO_NAME}.git"
if command -v gh >/dev/null 2>&1; then
  gh repo view "${GITHUB_USER}/${REPO_NAME}" >/dev/null 2>&1 || gh repo create "${GITHUB_USER}/${REPO_NAME}" --private --confirm --source . --push --remote origin --disable-wiki
fi
git init
git add .
if ! git config user.name >/dev/null; then git config user.name "CBW"; fi
if ! git config user.email >/dev/null; then git config user.email "cbw@example.com"; fi
git commit -m "Initial commit: CBW Apache Stack" || true
git branch -M main
if ! git remote | grep -q '^origin$'; then git remote add origin "${REMOTE}"; else git remote set-url origin "${REMOTE}"; fi
git push -u origin main
echo "[+] Repo pushed to ${REMOTE}"

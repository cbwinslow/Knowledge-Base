#!/usr/bin/env bash
set -euo pipefail
LIST="${1:-$(dirname "$0")/../repos.txt}"
DEST="/opt/github"
sudo mkdir -p "$DEST"; sudo chown -R "$USER":"$USER" "$DEST"
while IFS= read -r URL || [[ -n "$URL" ]]; do
  [[ -z "$URL" || "$URL" =~ ^# ]] && continue
  NAME="$(basename "$URL" .git)"; TARGET="$DEST/$NAME"
  if [[ -d "$TARGET/.git" ]]; then git -C "$TARGET" pull --ff-only; else git clone "$URL" "$TARGET"; fi
done < "$LIST"
echo "Repos in $DEST"

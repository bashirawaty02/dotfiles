#!/usr/bin/env bash
set -euo pipefail

LATEST_BACKUP=$(ls -td "$HOME"/dotfile_bk_* 2>/dev/null | head -n 1)

if [[ -z "${LATEST_BACKUP:-}" ]]; then
    echo "No backup directory found."
    exit 1
fi

echo ">>> Restoring from $LATEST_BACKUP"

for item in "$LATEST_BACKUP"/*; do
    name=$(basename "$item")
    echo ">>> Restoring $name"
    mv "$item" "$HOME/$name"
done

echo ">>> Restore complete!"

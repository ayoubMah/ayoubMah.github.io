#!/usr/bin/env bash
# Publish the blog from Linux. Same steps as forWind.ps1; the sync logic lives in sync.py.
set -euo pipefail

# === CONFIG === (override any of these with an env var)
VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/obsidianDir/ayoubObsidian}"
OBSIDIAN_POSTS="${OBSIDIAN_POSTS:-$VAULT/BLOG}"
OBSIDIAN_ILT="${OBSIDIAN_ILT:-$VAULT/ILT}"
ATTACHMENTS="${ATTACHMENTS:-$VAULT/Attachments}"
HUGO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

trap 'echo "❌ Failed at line $LINENO - nothing was pushed." >&2' ERR

cd "$HUGO_DIR"

echo "=== 1. Pulling latest from GitHub (other machine's posts/edits/deletes) ==="
git pull --rebase --autostash origin master
git submodule update --init --recursive

echo "=== 2. Syncing vault <-> content ==="
python3 "$HUGO_DIR/sync.py" --repo "$HUGO_DIR" --blog "$OBSIDIAN_POSTS" --ilt "$OBSIDIAN_ILT" --attachments "$ATTACHMENTS"

echo "=== 3. Test build with Hugo (GitHub Actions does the real build) ==="
hugo --minify

echo "=== 4. Committing and pushing ==="
git add -A
if git diff --cached --quiet; then
    echo "Nothing to publish - no changes."
else
    git commit -m "Auto-publish (linux): $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin master
fi

echo "✅ Done!"

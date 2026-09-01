#!/usr/bin/env bash
# Install this kit's agents and skills into ~/.claude.
#
# Anything replaced is first copied into
# ~/.claude/backups/claude-code-kit-<timestamp>/ under the same relative path.
# Nothing else in ~/.claude is touched — settings.json included.
set -euo pipefail

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DEST="$HOME/.claude"
BACKUP="$DEST/backups/claude-code-kit-$(date +%Y%m%dT%H%M%S)"

installed=0
backed_up=0

for top in agents skills; do
  [ -d "$REPO_DIR/$top" ] || continue
  while IFS= read -r -d '' src; do
    rel="$top/${src#"$REPO_DIR/$top/"}"
    dst="$DEST/$rel"
    if [ -e "$dst" ]; then
      cmp -s "$src" "$dst" && continue
      mkdir -p "$(dirname "$BACKUP/$rel")"
      cp -p "$dst" "$BACKUP/$rel"
      backed_up=$((backed_up + 1))
    fi
    mkdir -p "$(dirname "$dst")"
    cp -p "$src" "$dst"
    installed=$((installed + 1))
  done < <(find "$REPO_DIR/$top" -type f -print0)
done

echo "installed $installed file(s); backed up $backed_up replaced file(s)"
[ "$backed_up" -gt 0 ] && echo "backups in $BACKUP"
echo "done. restart Claude Code to pick up the new agents and skills."

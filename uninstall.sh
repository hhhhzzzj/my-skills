#!/usr/bin/env bash
# Uninstall my-claude-skills (macOS / Linux): remove symlinks and the install dir.

set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/my-claude-skills"
SKILLS_DIR="${HOME}/.claude/skills"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Not installed at $INSTALL_DIR. Nothing to do."
  exit 0
fi

shopt -s nullglob
for s in "$INSTALL_DIR"/skills/*/; do
  name=$(basename "$s")
  link="$SKILLS_DIR/$name"
  if [ -L "$link" ]; then
    rm "$link"
    echo "  - $name"
  fi
done

rm -rf "$INSTALL_DIR"
echo
echo "Uninstalled my-claude-skills."

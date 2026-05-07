#!/usr/bin/env bash
# Uninstall my-claude-skills (macOS / Linux): remove managed Claude Code symlinks, managed Windsurf copies, and the install dir.

set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/my-claude-skills"
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
WINDSURF_SKILLS_DIR="${HOME}/.codeium/windsurf/skills"

if [ ! -d "$INSTALL_DIR" ]; then
  echo "Not installed at $INSTALL_DIR. Nothing to do."
  exit 0
fi

is_our_link() {
  local path="$1"
  local expected_root="$2"
  [ -L "$path" ] || return 1
  local target
  target=$(readlink "$path")
  case "$target" in
    /*) ;;
    *) target="$(cd "$(dirname "$path")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")" || return 1 ;;
  esac
  case "$target" in
    "$expected_root"/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_our_copy() {
  [ -f "$1/.my-claude-skills-managed" ]
}

SRC_ROOT="$INSTALL_DIR/skills"
shopt -s nullglob
for s in "$SRC_ROOT"/*/; do
  name=$(basename "$s")
  link="$CLAUDE_SKILLS_DIR/$name"
  if is_our_link "$link" "$SRC_ROOT"; then
    rm "$link"
    echo "  - Claude Code: $name"
  fi

  copy="$WINDSURF_SKILLS_DIR/$name"
  if [ -d "$copy" ] && is_our_copy "$copy"; then
    rm -rf "$copy"
    echo "  - Windsurf:    $name"
  fi
done

rm -rf "$INSTALL_DIR"
echo
echo "Uninstalled my-claude-skills."

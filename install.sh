#!/usr/bin/env bash
# Install my-claude-skills on macOS / Linux.
#
# Remote one-liner:
#   curl -fsSL https://raw.githubusercontent.com/hhhhzzzj/my-skills/main/install.sh | sh
#
# Local:
#   ./install.sh

set -euo pipefail

REPO="hhhhzzzj/my-skills"
INSTALL_DIR="${HOME}/.local/share/my-claude-skills"
SKILLS_DIR="${HOME}/.claude/skills"

echo "==> my-claude-skills installer"

# 1. Check git
if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not installed." >&2
  exit 1
fi

# 2. Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[1/3] Updating existing install at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "[1/3] Cloning $REPO to $INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth=1 "https://github.com/${REPO}.git" "$INSTALL_DIR"
fi

# 3. Ensure ~/.claude/skills exists
echo "[2/3] Ensuring $SKILLS_DIR exists"
mkdir -p "$SKILLS_DIR"

# Helper: is this entry a symlink whose target lives under our INSTALL_DIR?
is_our_link() {
  local path="$1"
  local expected_root="$2"
  [ -L "$path" ] || return 1
  local target
  target=$(readlink "$path")
  # Resolve relative targets to absolute
  case "$target" in
    /*) ;;
    *) target="$(cd "$(dirname "$path")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")" || return 1 ;;
  esac
  case "$target" in
    "$expected_root"/*) return 0 ;;
    *) return 1 ;;
  esac
}

# 4. Sync skills (idempotent + safe)
echo "[3/3] Syncing skills"
SRC_ROOT="$INSTALL_DIR/skills"

shopt -s nullglob
repo_skills=("$SRC_ROOT"/*/)
if [ "${#repo_skills[@]}" -eq 0 ]; then
  echo "Error: no skills found under $SRC_ROOT" >&2
  exit 1
fi

# Build set of names currently in the repo
declare -A in_repo=()
for s in "${repo_skills[@]}"; do
  in_repo[$(basename "$s")]=1
done

# 4a. Clean up stale links: ours but the skill is no longer in the repo
for e in "$SKILLS_DIR"/*; do
  [ -e "$e" ] || continue
  name=$(basename "$e")
  if is_our_link "$e" "$SRC_ROOT" && [ -z "${in_repo[$name]:-}" ]; then
    rm "$e"
    echo "  - $name (removed: no longer in repo)"
  fi
done

# 4b. Link / skip / warn each repo skill
added=0
kept=0
skipped=0
for s in "${repo_skills[@]}"; do
  name=$(basename "$s")
  link="$SKILLS_DIR/$name"

  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    ln -s "${s%/}" "$link"
    echo "  + $name"
    added=$((added + 1))
  elif is_our_link "$link" "$SRC_ROOT"; then
    echo "  = $name (already linked, content updated via git pull)"
    kept=$((kept + 1))
  else
    echo "  ! $name (skipped: $link exists and is NOT managed by my-claude-skills)" >&2
    skipped=$((skipped + 1))
  fi
done

echo
printf 'Done. %d new, %d already linked, %d skipped.\n' "$added" "$kept" "$skipped"
if [ "$skipped" -gt 0 ]; then
  echo "  -> To replace a skipped one with my-claude-skills' version: remove that path manually, then re-run."
fi
echo "Installed location: $INSTALL_DIR"
echo "Linked to:          $SKILLS_DIR"
echo "Restart Claude Code (or reload skills) to pick them up."

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
CLAUDE_SKILLS_DIR="${HOME}/.claude/skills"
WINDSURF_SKILLS_DIR="${HOME}/.codeium/windsurf/skills"

echo "==> my-claude-skills installer"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required but not installed." >&2
  exit 1
fi

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "[1/4] Updating existing install at $INSTALL_DIR"
  git -C "$INSTALL_DIR" pull --ff-only
else
  echo "[1/4] Cloning $REPO to $INSTALL_DIR"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone --depth=1 "https://github.com/${REPO}.git" "$INSTALL_DIR"
fi

echo "[2/4] Ensuring target directories exist"
mkdir -p "$CLAUDE_SKILLS_DIR" "$WINDSURF_SKILLS_DIR"

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
repo_skills=("$SRC_ROOT"/*/)
if [ "${#repo_skills[@]}" -eq 0 ]; then
  echo "Error: no skills found under $SRC_ROOT" >&2
  exit 1
fi

declare -A in_repo=()
for s in "${repo_skills[@]}"; do
  in_repo[$(basename "$s")]=1
done

echo "[3/4] Syncing Claude Code skills"
for e in "$CLAUDE_SKILLS_DIR"/*; do
  [ -e "$e" ] || continue
  name=$(basename "$e")
  if is_our_link "$e" "$SRC_ROOT" && [ -z "${in_repo[$name]:-}" ]; then
    rm "$e"
    echo "  - $name (removed: no longer in repo)"
  fi
done

claude_added=0
claude_kept=0
claude_skipped=0
for s in "${repo_skills[@]}"; do
  name=$(basename "$s")
  link="$CLAUDE_SKILLS_DIR/$name"
  if [ ! -e "$link" ] && [ ! -L "$link" ]; then
    ln -s "${s%/}" "$link"
    echo "  + $name"
    claude_added=$((claude_added + 1))
  elif is_our_link "$link" "$SRC_ROOT"; then
    echo "  = $name (already linked, content updated via git pull)"
    claude_kept=$((claude_kept + 1))
  else
    echo "  ! $name (skipped: $link exists and is NOT managed by my-claude-skills)" >&2
    claude_skipped=$((claude_skipped + 1))
  fi
done

echo "[4/4] Syncing Windsurf skills"
for e in "$WINDSURF_SKILLS_DIR"/*; do
  [ -e "$e" ] || continue
  name=$(basename "$e")
  if [ -d "$e" ] && is_our_copy "$e" && [ -z "${in_repo[$name]:-}" ]; then
    rm -rf "$e"
    echo "  - $name (removed: no longer in repo)"
  fi
done

windsurf_added=0
windsurf_updated=0
windsurf_skipped=0
for s in "${repo_skills[@]}"; do
  name=$(basename "$s")
  copy="$WINDSURF_SKILLS_DIR/$name"
  if [ ! -e "$copy" ] && [ ! -L "$copy" ]; then
    cp -R "${s%/}" "$copy"
    : > "$copy/.my-claude-skills-managed"
    echo "  + $name"
    windsurf_added=$((windsurf_added + 1))
  elif [ -d "$copy" ] && is_our_copy "$copy"; then
    rm -rf "$copy"
    cp -R "${s%/}" "$copy"
    : > "$copy/.my-claude-skills-managed"
    echo "  = $name (copied latest content)"
    windsurf_updated=$((windsurf_updated + 1))
  else
    echo "  ! $name (skipped: $copy exists and is NOT managed by my-claude-skills)" >&2
    windsurf_skipped=$((windsurf_skipped + 1))
  fi
done

echo
printf 'Claude Code: %d new, %d already linked, %d skipped.\n' "$claude_added" "$claude_kept" "$claude_skipped"
printf 'Windsurf:    %d new, %d updated, %d skipped.\n' "$windsurf_added" "$windsurf_updated" "$windsurf_skipped"
if [ "$((claude_skipped + windsurf_skipped))" -gt 0 ]; then
  echo "  -> To replace a skipped one with my-claude-skills' version: remove that path manually, then re-run."
fi
echo "Installed location: $INSTALL_DIR"
echo "Claude linked to:   $CLAUDE_SKILLS_DIR"
echo "Windsurf copied to: $WINDSURF_SKILLS_DIR"
echo "Restart Claude Code / Windsurf (or reload skills) to pick them up."


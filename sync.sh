#!/usr/bin/env bash
# =============================================================================
# sync.sh — Sync skills from this repo to Hermes / Codex / Claude Code
#
# Usage:
#   bash sync.sh                   # interactive mode (asks which tools)
#   bash sync.sh --all             # sync to all detected tools
#   bash sync.sh --hermes          # Hermes only
#   bash sync.sh --codex           # Codex only
#   bash sync.sh --claude          # Claude Code only
#   bash sync.sh --link            # use symlinks instead of copy (default)
#   bash sync.sh --copy            # force copy instead of symlinks
#   bash sync.sh --dry-run         # show what would be done
#
# First time setup on a new server:
#   git clone <your-repo-url> ~/skills-repo
#   cd ~/skills-repo && bash sync.sh --all
# =============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_SRC="$REPO_DIR/skills"

MODE="link"   # link or copy
DRY_RUN=false
TARGETS=()

# ---- Parse args ----
for arg in "$@"; do
  case "$arg" in
    --all)    TARGETS=(hermes codex claude) ;;
    --hermes) TARGETS+=(hermes) ;;
    --codex)  TARGETS+=(codex) ;;
    --claude) TARGETS+=(claude) ;;
    --link)   MODE="link" ;;
    --copy)   MODE="copy" ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h)
      sed -n '2,17p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
  esac
done

# If no target specified, detect interactively
if [ ${#TARGETS[@]} -eq 0 ]; then
  echo "Detected tools on this machine:"
  [ -d "$HOME/.hermes/skills" ] && echo "  [1] Hermes  (~/.hermes/skills/)"
  [ -d "$HOME/.codex/skills" ]  && echo "  [2] Codex   (~/.codex/skills/)"
  [ -d "$HOME/.claude" ]        && echo "  [3] Claude  (~/.claude/skills/)"
  echo ""
  echo "Sync to which? (e.g. 1, 1 2, or 'all')"
  read -r selection
  [[ "$selection" == "all" ]] && TARGETS=(hermes codex claude) || true
  for s in $selection; do
    case "$s" in
      1) TARGETS+=(hermes) ;;
      2) TARGETS+=(codex) ;;
      3) TARGETS+=(claude) ;;
    esac
  done
fi

# ---- Helpers ----
do_link() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    echo "  [ln -s] $src -> $dst"
    return
  fi
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return  # already linked correctly
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    rm -rf "$dst"
  fi
  ln -s "$src" "$dst"
}

do_copy() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    echo "  [cp]    $src -> $dst"
    return
  fi
  if [ -e "$dst" ]; then
    rm -rf "$dst"
  fi
  cp -r "$src" "$dst"
}

sync_skill() {
  local skill_dir="$1" dest_root="$2" tool_name="$3"
  local skill_name
  skill_name="$(basename "$skill_dir")"
  local dst="$dest_root/$skill_name"

  if [ "$MODE" = "link" ]; then
    do_link "$skill_dir" "$dst"
  else
    do_copy "$skill_dir" "$dst"
  fi
}

# ---- Sync ----
for tool in "${TARGETS[@]}"; do
  case "$tool" in
    hermes)
      DEST="$HOME/.hermes/skills"
      echo "━━━ Hermes → $DEST ━━━"
      mkdir -p "$DEST"
      for skill_dir in "$SKILLS_SRC"/*/; do
        sync_skill "$skill_dir" "$DEST" "Hermes"
      done
      echo "  → Synced $(ls -d "$SKILLS_SRC"/*/ 2>/dev/null | wc -l) skills"
      echo ""
      ;;

    codex)
      DEST="$HOME/.codex/skills"
      echo "━━━ Codex → $DEST ━━━"
      mkdir -p "$DEST"
      for skill_dir in "$SKILLS_SRC"/*/; do
        sync_skill "$skill_dir" "$DEST" "Codex"
      done
      echo "  → Synced $(ls -d "$SKILLS_SRC"/*/ 2>/dev/null | wc -l) skills"
      echo ""
      ;;

    claude)
      DEST="$HOME/.claude/skills"
      echo "━━━ Claude Code → $DEST ━━━"
      mkdir -p "$DEST"
      # Claude Code uses flat .md files, copy each SKILL.md
      for skill_dir in "$SKILLS_SRC"/*/; do
        skill_name="$(basename "$skill_dir")"
        src_md="$skill_dir/SKILL.md"
        dst_md="$DEST/$skill_name.md"
        if [ ! -f "$src_md" ]; then
          continue
        fi
        if $DRY_RUN; then
          echo "  [cp]    $src_md -> $dst_md"
        else
          cp "$src_md" "$dst_md"
        fi
      done
      echo "  → Synced $(ls "$DEST"/*.md 2>/dev/null | wc -l) skills"
      echo ""
      ;;
  esac
done

if $DRY_RUN; then
  echo "── Dry run complete. Remove --dry-run to apply. ──"
else
  echo "✅ Done. Skills synced."
fi

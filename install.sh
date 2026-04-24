#!/usr/bin/env bash
set -euo pipefail

TAC_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

echo "TAC Installer -- Think. Architect. Code."
echo "========================================="
echo ""

# Ensure skills directory exists
mkdir -p "$SKILLS_DIR"

# Symlink each skill
count=0
for skill_dir in "$TAC_DIR/skills"/tac-*; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"
  if [ -L "$target" ]; then
    rm "$target"
  elif [ -d "$target" ]; then
    echo "  ! Skipping $skill_name (directory exists, not a symlink)"
    continue
  fi
  ln -s "$skill_dir" "$target"
  echo "  + Linked $skill_name"
  count=$((count + 1))
done

echo ""
echo "  $count skills installed."
echo ""

# Check if hooks are registered
SETTINGS="$HOME/.claude/settings.json"
if [ -f "$SETTINGS" ]; then
  if grep -q "tac-session-start" "$SETTINGS" 2>/dev/null; then
    echo "  Hooks: already registered."
  else
    echo "  Hooks: NOT registered. Add to $SETTINGS manually."
    echo "  See $TAC_DIR/hooks/README.md for instructions."
  fi
else
  echo "  Hooks: settings.json not found. See hooks/README.md."
fi

echo ""
echo "TAC installed. 6 commands available:"
echo ""
echo "  /tac-init   — Initialize TAC in a project"
echo "  /tac-new    — Full pipeline: think -> build -> safe -> auto"
echo "  /tac-think  — Explore an idea (ASK + DESIGN, no coding)"
echo "  /tac-build  — Build a feature (smart gate + auto)"
echo "  /tac-go     — Resume from where you stopped"
echo "  /tac-safe   — Verify before deploy"
echo ""
echo "Run /tac-init in your project to get started."

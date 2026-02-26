#!/usr/bin/env bash
set -euo pipefail

# sync-skills.sh — Copy agentfiles skills and agents to ~/.claude/ for Claude Code

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENTFILES_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_SRC="$AGENTFILES_DIR/skills"
SKILLS_DST="$HOME/.claude/skills"

echo "Syncing skills from $SKILLS_SRC to $SKILLS_DST..."

# Create destination if it doesn't exist
mkdir -p "$SKILLS_DST"

# Sync each skill directory
for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_dir")"
  dest="$SKILLS_DST/$skill_name"

  # Create destination directory
  mkdir -p "$dest/references"

  # Copy SKILL.md
  if [ -f "$skill_dir/SKILL.md" ]; then
    cp "$skill_dir/SKILL.md" "$dest/SKILL.md"
    echo "  + $skill_name/SKILL.md"
  fi

  # Copy all reference files
  if [ -d "$skill_dir/references" ]; then
    for ref_file in "$skill_dir/references"/*.md; do
      if [ -f "$ref_file" ]; then
        cp "$ref_file" "$dest/references/"
        echo "  + $skill_name/references/$(basename "$ref_file")"
      fi
    done
  fi
done

# Sync agents (flat structure)
AGENTS_SRC="$AGENTFILES_DIR/agents"
AGENTS_DST="$HOME/.claude/agents"

if [ -d "$AGENTS_SRC" ]; then
  echo ""
  echo "Syncing agents from $AGENTS_SRC to $AGENTS_DST..."
  mkdir -p "$AGENTS_DST"

  for agent_file in "$AGENTS_SRC"/*.md; do
    if [ -f "$agent_file" ]; then
      cp "$agent_file" "$AGENTS_DST/"
      echo "  + agents/$(basename "$agent_file")"
    fi
  done
fi

echo ""
echo "Done! Skills synced to $SKILLS_DST"
echo "       Agents synced to $AGENTS_DST"

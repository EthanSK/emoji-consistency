#!/bin/bash
set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/emoji-consistency"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$SKILL_DIR/scripts"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
cp "$SCRIPT_DIR/README.md" "$SKILL_DIR/README.md"
cp "$SCRIPT_DIR/LICENSE" "$SKILL_DIR/LICENSE"
cp "$SCRIPT_DIR/install.sh" "$SKILL_DIR/install.sh"
cp "$SCRIPT_DIR"/scripts/*.sh "$SKILL_DIR/scripts/"
chmod +x "$SKILL_DIR/install.sh" "$SKILL_DIR"/scripts/*.sh

echo "Installed emoji-consistency skill to $SKILL_DIR"
echo ""
echo "Prerequisites:"
echo "  - jq"
echo "  - bash"
echo "  - optional: flock for stronger concurrent write protection"
echo ""
echo "The skill will activate automatically when Claude Code chooses emoji for named entities."

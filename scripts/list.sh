#!/bin/bash
set -euo pipefail

STORE="$HOME/.claude/emoji-assignments.json"

need_jq() { command -v jq >/dev/null 2>&1 || { echo "emoji-consistency: jq is required" >&2; exit 2; }; }
normalize() { printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g' | tr '[:upper:]' '[:lower:]'; }

need_jq
KIND=""
PARENT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)
      [[ $# -ge 2 ]] || { echo "usage: list.sh [--kind <kind>] [--parent <name>]" >&2; exit 2; }
      KIND="$2"; shift 2 ;;
    --parent)
      [[ $# -ge 2 ]] || { echo "usage: list.sh [--kind <kind>] [--parent <name>]" >&2; exit 2; }
      PARENT="$(normalize "$2")"; shift 2 ;;
    *)
      echo "usage: list.sh [--kind <kind>] [--parent <name>]" >&2; exit 2 ;;
  esac
done
[[ -z "$KIND" || "$KIND" =~ ^(project|task|subtask|category)$ ]] || { echo "emoji-consistency: invalid kind '$KIND'" >&2; exit 2; }

printf '%-32s %-8s %-10s %-32s %s\n' "name" "emoji" "kind" "parent" "dateLastUsed"
[[ -e "$STORE" ]] || exit 0
jq -r --arg k "$KIND" --arg p "$PARENT" '
  .entries[]?
  | select(($k == "" or .kind == $k) and ($p == "" or .parent == $p))
  | [.name, .emoji, .kind, (.parent // "-"), .dateLastUsed]
  | @tsv
' "$STORE" | while IFS=$'\t' read -r name emoji kind parent last; do
  printf '%-32s %-8s %-10s %-32s %s\n' "$name" "$emoji" "$kind" "$parent" "$last"
done

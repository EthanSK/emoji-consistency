#!/bin/bash
set -euo pipefail

STORE="$HOME/.claude/emoji-assignments.json"

need_jq() { command -v jq >/dev/null 2>&1 || { echo "emoji-consistency: jq is required" >&2; exit 2; }; }
warn_flock() {
  command -v flock >/dev/null 2>&1 && return 0
  local warn="$HOME/.claude/emoji-assignments.no-flock-warned"
  if [[ ! -e "$warn" ]]; then
    mkdir -p "$HOME/.claude"
    echo "emoji-consistency: flock not found; using atomic rename only" >&2
    : >"$warn"
  fi
}
write_pruned() {
  local tmp before after
  before="$(jq '.entries | length' "$STORE")"
  tmp="$(mktemp "${STORE}.tmp.XXXXXX")"
  jq --argjson now "$(date -u +%s)" '
    def age: (($now - (.dateLastUsed | fromdateiso8601)) / 86400);
    .entries |= map(select(
      .kind == "project" or
      (.kind == "subtask" and age <= 30) or
      (.kind == "task" and age <= 90) or
      (.kind == "category" and age <= 180)
    ))
  ' "$STORE" >"$tmp"
  after="$(jq '.entries | length' "$tmp")"
  SUBTASKS="$(jq '[.entries[] | select(.kind == "subtask" and (($now - (.dateLastUsed | fromdateiso8601)) / 86400) > 30)] | length' --argjson now "$(date -u +%s)" "$STORE")"
  TASKS="$(jq '[.entries[] | select(.kind == "task" and (($now - (.dateLastUsed | fromdateiso8601)) / 86400) > 90)] | length' --argjson now "$(date -u +%s)" "$STORE")"
  CATEGORIES="$(jq '[.entries[] | select(.kind == "category" and (($now - (.dateLastUsed | fromdateiso8601)) / 86400) > 180)] | length' --argjson now "$(date -u +%s)" "$STORE")"
  PRUNED=$((before - after))
  mv "$tmp" "$STORE"
}

need_jq
[[ $# -le 1 ]] || { echo "usage: prune.sh [--force]" >&2; exit 2; }
[[ $# -eq 0 || "$1" == "--force" ]] || { echo "usage: prune.sh [--force]" >&2; exit 2; }
if [[ ! -e "$STORE" ]]; then
  echo "pruned 0 entries (0 subtasks, 0 tasks, 0 categories)"
  exit 0
fi

warn_flock
if command -v flock >/dev/null 2>&1; then
  exec 9>"$STORE.lock"
  flock 9
  write_pruned
else
  write_pruned
fi
echo "pruned $PRUNED entries ($SUBTASKS subtasks, $TASKS tasks, $CATEGORIES categories)"

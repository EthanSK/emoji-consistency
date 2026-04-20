#!/bin/bash
set -euo pipefail

STORE="$HOME/.claude/emoji-assignments.json"
STAMP="$HOME/.claude/emoji-assignments.prune-stamp"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

need_jq() { command -v jq >/dev/null 2>&1 || { echo "emoji-consistency: jq is required" >&2; exit 2; }; }
normalize() { printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g' | tr '[:upper:]' '[:lower:]'; }
warn_flock() {
  command -v flock >/dev/null 2>&1 && return 0
  local warn="$HOME/.claude/emoji-assignments.no-flock-warned"
  if [[ ! -e "$warn" ]]; then
    mkdir -p "$HOME/.claude"
    echo "emoji-consistency: flock not found; using atomic rename only" >&2
    : >"$warn"
  fi
}
maybe_prune() {
  [[ -e "$STORE" ]] || return 0
  local count size now last=0
  count="$(jq '.entries | length' "$STORE")"
  size="$(wc -c <"$STORE" | tr -d ' ')"
  [[ "$count" -gt 200 || "$size" -gt 51200 ]] || return 0
  now="$(date -u +%s)"
  [[ -e "$STAMP" ]] && last="$(cat "$STAMP" 2>/dev/null || echo 0)"
  [[ $((now - last)) -gt 86400 ]] || return 0
  "$SKILL_DIR/scripts/prune.sh" --force >/dev/null
  printf '%s\n' "$now" >"$STAMP"
}
write_json() {
  local tmp
  tmp="$(mktemp "${STORE}.tmp.XXXXXX")"
  jq --arg n "$NAME" --arg now "$NOW" '(.entries[] | select(.name == $n) | .dateLastUsed) = $now' "$STORE" >"$tmp"
  mv "$tmp" "$STORE"
}

need_jq
[[ $# -eq 1 ]] || { echo "usage: lookup.sh <name>" >&2; exit 2; }
NAME="$(normalize "$1")"
maybe_prune
[[ -e "$STORE" ]] || exit 0

EMOJI="$(jq -r --arg n "$NAME" '.entries[]? | select(.name == $n) | .emoji' "$STORE" | head -n 1)"
[[ -n "$EMOJI" ]] || exit 1

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
warn_flock
if command -v flock >/dev/null 2>&1; then
  exec 9>"$STORE.lock"
  flock 9
  write_json
else
  write_json
fi
printf '%s\n' "$EMOJI"

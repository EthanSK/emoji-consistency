#!/bin/bash
set -euo pipefail

STORE="$HOME/.claude/emoji-assignments.json"
STAMP="$HOME/.claude/emoji-assignments.prune-stamp"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

need_jq() { command -v jq >/dev/null 2>&1 || { echo "emoji-consistency: jq is required" >&2; exit 2; }; }
normalize() { printf '%s' "$1" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/[[:space:]]+/-/g' | tr '[:upper:]' '[:lower:]'; }
init_store() { mkdir -p "$(dirname "$STORE")"; [[ -e "$STORE" ]] || printf '{"version":1,"entries":[]}\n' >"$STORE"; }
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
  jq --arg n "$NAME" --arg e "$EMOJI" --arg k "$KIND" --arg now "$NOW" --argjson p "$PARENT_JSON" '
    if any(.entries[]?; .name == $n) then
      (.entries[] | select(.name == $n)) |= (.emoji = $e | .kind = $k | .parent = $p | .dateLastUsed = $now)
    else
      .entries += [{name:$n, emoji:$e, kind:$k, dateCreated:$now, dateLastUsed:$now, parent:$p}]
    end
  ' "$STORE" >"$tmp"
  mv "$tmp" "$STORE"
}

need_jq
[[ $# -ge 3 && $# -le 4 ]] || { echo "usage: record.sh <name> <emoji> <kind> [parent]" >&2; exit 2; }
NAME="$(normalize "$1")"
EMOJI="$2"
KIND="$3"
[[ "$KIND" =~ ^(project|task|subtask|category)$ ]] || { echo "emoji-consistency: invalid kind '$KIND'" >&2; exit 2; }
[[ -n "$EMOJI" ]] || { echo "emoji-consistency: emoji must be non-empty" >&2; exit 2; }
if [[ $# -eq 4 && -n "${4:-}" ]]; then
  PARENT_JSON="$(jq -Rn --arg p "$(normalize "$4")" '$p')"
else
  PARENT_JSON="null"
fi

maybe_prune
init_store
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

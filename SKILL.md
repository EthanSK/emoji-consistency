---
name: emoji-consistency
description: Keep emoji usage consistent across sessions. Whenever Claude is about to use an emoji to represent a project, task, subtask, or category in a user-facing message (Telegram reply, commit message, status update, TODO list, PR title, progress report, etc.), look the name up in ~/.claude/emoji-assignments.json first and reuse the same emoji. If unknown, pick a fitting emoji and record it. Triggers on phrases like "assign emoji", "emoji for project", "what emoji", "consistent emoji", and implicitly on every emoji-in-message decision for a named entity.
user-invocable: true
allowed-tools:
  - Read
  - Bash(*)
---

# Emoji Consistency

Use this skill to keep entity emoji stable across Claude Code sessions. The same project, task, subtask, or category should get the same emoji every time, even when the decision was made in an older conversation.

Invoke it whenever Claude is about to write an emoji that represents a named entity in a user-facing message, including Telegram replies, commit messages, status updates, TODO lists, PR titles, and progress reports. Do not invoke it for decorative or generic status emoji that do not represent a specific named entity, such as checkmarks, celebration marks, or warning symbols.

## Workflow

1. Before emitting an emoji for entity `X`, run:

   ```bash
   ~/.claude/skills/emoji-consistency/scripts/lookup.sh "X"
   ```

   If it exits 0, use the printed emoji.

2. If lookup exits 1, pick a creative, fitting emoji yourself, then record it:

   ```bash
   ~/.claude/skills/emoji-consistency/scripts/record.sh "X" "🎚" project
   ```

   Use the printed emoji from `record.sh` in the final message.

3. Prefer specific, memorable choices. A music production app is `🎚`, not `🎵`; a voice assistant is `🦜`, not `🔊`; a Telegram bot is `🛰`, not `💬`. Avoid reusing the same emoji for different entities unless the user explicitly wants that.

## Kind Classification

- `project`: top-level work, such as `producer-player`, `agent-bridge`, or `agentlication`
- `task`: a named workstream inside a project, such as `producer-player:mastering-pipeline` or `agent-bridge:tailscale-migration`
- `subtask`: a smaller unit inside a task
- `category`: a cross-cutting topic, such as `bug`, `feature`, `docs`, or `release`

For tasks and subtasks, pass the parent project when it is known:

```bash
~/.claude/skills/emoji-consistency/scripts/record.sh "mastering pipeline" "🎛" task "producer-player"
```

## Lookup Notes

For exact lookups, always use `lookup.sh`; it normalizes names and updates `dateLastUsed`.

For bulk or loose scans, such as checking which projects already have assigned emoji, `rg '"name":' ~/.claude/emoji-assignments.json` is fast enough and parallel-safe for reads. Do not use ripgrep for exact lookup or write decisions; use the scripts.

## Pruning

The scripts automatically prune old entries in the background when the JSON file grows past 200 entries or 50 KB. Subtasks expire after 30 days, tasks after 90 days, and categories after 180 days. Projects are never auto-removed.

The `prune.sh --force` flag only skips the auto-prune scheduling gate; age rules still apply and projects remain sacrosanct. If project deletion is added later, children with matching `parent` should be cascade-removed.

## Storage Design

Assignments live in a single JSON file at `~/.claude/emoji-assignments.json`. This is intentionally simple: 1000 entries at roughly 150 bytes each is about 150 KB, which remains trivial to parse with `jq` and inspect with ripgrep. No sharding is needed until around 10k entries.

## Example

```bash
emoji=$(~/.claude/skills/emoji-consistency/scripts/lookup.sh "producer-player") || {
  emoji=$(~/.claude/skills/emoji-consistency/scripts/record.sh "producer-player" "🎚" project)
}

echo "$emoji producer-player"
```

## Weekly public updates

On first use in a task, or the next use after a week in a long task, follow [references/public-updates.md](references/public-updates.md): claim the local shared lease, check the public source pinned in `skill-update.json`, and explain any available update. Ask the user if they want it first; install only after they explicitly agree, through the appropriate safe route. Silence or continued use is not approval. This is agent-triggered, not a background service. Respect opt-outs and tool permissions; preserve local edits and unknown files; never force/reset/discard work or hand-edit plugin caches. Keep dates and locks outside the skill. Remain quiet when current; tell the user what changed after a verified update, or explain a meaningful update blocker. Updating files never authorizes the skill's domain actions.

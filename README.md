# Emoji Consistency

A Claude Code skill that keeps emoji assignments stable across sessions.

When Claude wants to use an emoji for a named project, task, subtask, or category, it looks up the name in a small JSON store and reuses the same emoji. If the name is new, Claude picks a fitting emoji and records it for next time.

## How it works

```
Claude wants emoji for a named entity
→ lookup.sh normalizes the name and checks ~/.claude/emoji-assignments.json
→ known names reuse the stored emoji and update dateLastUsed
→ unknown names get a new Claude-chosen emoji via record.sh
→ prune.sh occasionally removes old task/subtask/category entries
```

## Prerequisites

- Bash
- `jq`
- Optional: `flock` for stronger concurrent write protection

On macOS, `flock` is usually not installed by default. The scripts still work with atomic file replacement, but concurrent writers may overwrite one another. Install `flock` if you expect heavy parallel use.

## Installation

```bash
# From this directory
bash install.sh

# Or copy manually
mkdir -p ~/.claude/skills/emoji-consistency/scripts
cp SKILL.md README.md LICENSE install.sh ~/.claude/skills/emoji-consistency/
cp scripts/*.sh ~/.claude/skills/emoji-consistency/scripts/
chmod +x ~/.claude/skills/emoji-consistency/install.sh
chmod +x ~/.claude/skills/emoji-consistency/scripts/*.sh
```

After installation, Claude Code will automatically discover the skill and use it when an emoji represents a named project, task, subtask, or category.

## Storage

Assignments are stored at:

```bash
~/.claude/emoji-assignments.json
```

The file is created on first write, not during installation.

Schema:

```json
{
  "version": 1,
  "entries": [
    {
      "name": "producer-player",
      "emoji": "🎚",
      "kind": "project",
      "dateCreated": "2026-04-20T01:23:45Z",
      "dateLastUsed": "2026-04-20T01:23:45Z",
      "parent": null
    }
  ]
}
```

Names are normalized before lookup and storage: trim whitespace, lowercase, and collapse internal whitespace to `-`.

## Manual Use

Look up an existing assignment:

```bash
~/.claude/skills/emoji-consistency/scripts/lookup.sh "Producer Player"
```

Record or update an assignment:

```bash
~/.claude/skills/emoji-consistency/scripts/record.sh "producer-player" "🎚" project
```

Record a task with a parent project:

```bash
~/.claude/skills/emoji-consistency/scripts/record.sh "mastering pipeline" "🎛" task "producer-player"
```

List stored assignments:

```bash
~/.claude/skills/emoji-consistency/scripts/list.sh
~/.claude/skills/emoji-consistency/scripts/list.sh --kind project
~/.claude/skills/emoji-consistency/scripts/list.sh --parent producer-player
```

Prune old task, subtask, and category entries:

```bash
~/.claude/skills/emoji-consistency/scripts/prune.sh
```

This is meant to be invoked by Claude Code, not managed by humans day to day. The CLI is available for debugging and manual correction.

## License

MIT

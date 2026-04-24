# TAC Hooks

Hooks integrate TAC with Claude Code's lifecycle events.

## Registration

Add the following to your `~/.claude/settings.json` to register the TAC session-start hook:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [{
          "type": "command",
          "command": "node \"$HOME/.claude/tac/hooks/tac-session-start.js\""
        }]
      }
    ]
  }
}
```

This runs automatically when a new Claude Code session starts. If a `.tac/` project exists in the working directory, it displays the current TAC status (feature, stage, stack) as additional context. If no TAC project exists, it stays silent.

## What It Does

- **tac-session-start.js** — Reads `.tac/state.json` from the current working directory and outputs a one-line status summary. Also checks `.tac/context/pending.json` for any interrupted work that can be resumed with `/tac-go`.

## Behavior

- If `.tac/state.json` does not exist: no output (silent exit)
- If `.tac/state.json` is malformed: no output (silent exit)
- If fields are missing: uses defaults ("no feature", "IDLE", "unknown")
- Output is plain text to stdout, picked up by Claude Code as `additionalContext`

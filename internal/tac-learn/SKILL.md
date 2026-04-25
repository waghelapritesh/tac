---
name: tac-learn
description: Captures and applies project-specific learnings — patterns, preferences, and gotchas that improve over time
argument-hint: "[add \"lesson\" | remove <id>]"
---

# TAC Learn — Project Learnings System

Captures lessons from real pipeline events and applies them to future work. The system gets smarter with every feature.

## Storage

All learnings are stored in `.tac/learnings.json`:

```json
{
  "learnings": [
    {
      "id": 1,
      "type": "pattern",
      "lesson": "Service name is 'inventree-server' not 'inventree'",
      "source": "SAFE caught wrong service name in f-20260425-payments",
      "added": "2026-04-25T10:30:00Z",
      "applied_count": 0
    },
    {
      "id": 2,
      "type": "preference",
      "lesson": "User prefers data tables over card layouts for list pages",
      "source": "User rejected card layout in sketch for f-20260425-analytics",
      "added": "2026-04-25T11:00:00Z",
      "applied_count": 3
    },
    {
      "id": 3,
      "type": "gotcha",
      "lesson": "Always run 'manage.py prerender' before 'collectstatic' when editing translated JS",
      "source": "Deploy failed in f-20260420-alerts because prerender was skipped",
      "added": "2026-04-20T14:00:00Z",
      "applied_count": 5
    }
  ]
}
```

## Learning Types

| Type | When Captured | Example |
|------|--------------|---------|
| `pattern` | Debug finds a root cause | "Django signals fire twice when using `post_save` with `update_fields`" |
| `preference` | User rejects a sketch variant or expresses a preference | "User prefers data tables over card layouts" |
| `gotcha` | SAFE catches an issue, or forensics identifies a lesson | "Always run prerender before collectstatic" |

## Auto-Capture (via tac-autowire)

Learnings are captured automatically at these trigger points:

- **SAFE catches an issue** → save as `gotcha` learning
  - Source: "SAFE caught {issue} in {feature-id}"
- **User rejects a sketch variant** → save as `preference` learning
  - Source: "User rejected {variant} in sketch for {feature-id}"
- **Debug finds a root cause** → save as `pattern` learning
  - Source: "Debug found {root-cause} in {feature-id}"
- **Forensics identifies a lesson** → save as `gotcha` learning
  - Source: "Forensics lesson from {feature-id}: {summary}"

### Auto-Capture Process

1. Detect the trigger event (SAFE failure, sketch rejection, debug resolution, forensics report)
2. Extract the lesson as a concise, actionable statement
3. Check for duplicates — if a similar lesson already exists, skip (don't add near-duplicates)
4. Assign next available `id` (max existing id + 1)
5. Write to `.tac/learnings.json`
6. Display: "Learning captured: {lesson}"

## Auto-Apply (via tac-spawn)

When spawning agents, inject relevant learnings into each agent's system prompt:

1. Load `.tac/learnings.json`
2. Filter learnings by keyword relevance to the current task:
   - Match learning `lesson` text against task description, file names, and feature name
   - Include all `gotcha` type learnings (they're always relevant)
   - Include `preference` learnings when building UI
   - Include `pattern` learnings when the keywords match
3. Inject matched learnings into the agent prompt:
   ```
   PROJECT LEARNINGS (from past experience):
   - Service name is 'inventree-server' not 'inventree'
   - User prefers data tables over card layouts
   - Always run prerender before collectstatic
   ```
4. Increment `applied_count` for each injected learning
5. Write updated counts back to `.tac/learnings.json`

## Manual Commands (via /tac-do learn)

### `learn` (no sub-command) — List all learnings

Display all learnings grouped by type:

```
Project Learnings (3 total)

  Patterns:
    #1  Service name is 'inventree-server' not 'inventree'
        Source: SAFE caught wrong service name in f-20260425-payments
        Applied: 0 times

  Preferences:
    #2  User prefers data tables over card layouts for list pages
        Source: User rejected card layout in sketch for f-20260425-analytics
        Applied: 3 times

  Gotchas:
    #3  Always run 'manage.py prerender' before 'collectstatic' when editing translated JS
        Source: Deploy failed in f-20260420-alerts because prerender was skipped
        Applied: 5 times
```

If no learnings exist: "No learnings captured yet. They'll accumulate as you use TAC."

### `learn add "lesson"` — Manually add a learning

1. Parse the lesson text from the argument (quoted string after `add`)
2. Ask the user for the type: pattern, preference, or gotcha
3. Create the learning entry with:
   - `id`: max existing id + 1 (or 1 if empty)
   - `type`: user's choice
   - `lesson`: the provided text
   - `source`: "Manually added"
   - `added`: current ISO timestamp
   - `applied_count`: 0
4. Append to `.tac/learnings.json`
5. Display: "Learning #{id} added: {lesson}"

### `learn remove <id>` — Remove a learning

1. Parse the id from the argument
2. Find the learning with matching `id` in `.tac/learnings.json`
3. If not found: "Learning #{id} not found."
4. Show the learning and ask for confirmation: "Remove this learning? {lesson} (yes/no)"
5. If confirmed: remove from array, write file
6. Display: "Learning #{id} removed."

## Error Handling

- If `.tac/learnings.json` doesn't exist, create it with `{"learnings": []}`
- If JSON is corrupted, warn and start fresh with empty array
- Never block the pipeline for learning failures — learnings are advisory

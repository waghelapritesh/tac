---
name: tac-status
description: Use when checking TAC project progress — shows all features, their current stage, and what's next
---

# TAC Status

Show the current state of the TAC project.

## Steps

1. **Check for .tac/ directory** in the current working directory.
   - If `.tac/` does not exist, display: "No TAC project found. Run /tac-init first."
   - Stop here if missing.

2. **Read `.tac/state.json`** and extract:
   - `project_name` — the project name
   - `stack` — the tech stack
   - `current_feature` — the feature currently in progress (may be null)
   - `current_stage` — the active stage (ASK / DESIGN / SAFE / AUTO / DONE)

3. **Read all files in `.tac/history/*.json`**. Each file represents one feature. For each, extract:
   - `id` — feature identifier
   - `name` — short description
   - `stage` — current stage (ASK / DESIGN / SAFE / AUTO / DONE)
   - `created_at` — when it was started
   - `updated_at` — last activity

4. **Display the status report** in this format:

```
TAC Project: {project_name}
Stack: {stack}
─────────────────────────────────

Features:
  {stage_emoji} {name}  [{stage}]  (last: {updated_at})
  ...

Current: {current_feature or "None"}
Stage:   {current_stage or "Idle"}

Next action: {recommended_action}
```

Stage emojis: ASK = ?, DESIGN = D, SAFE = S, AUTO = A, DONE = checkmark

5. **Determine recommended action**:
   - If no current feature: "Start a new feature with /tac-new <idea>"
   - If stage is ASK: "Continue requirements gathering with /tac-ask"
   - If stage is DESIGN: "Continue design with /tac-design"
   - If stage is SAFE or AUTO: "SAFE and AUTO stages coming in TAC v2"
   - If stage is DONE: "Feature complete. Start next with /tac-new <idea>"

6. **If `.tac/context/pending.json` exists**, also show:
   - "Pending checkpoint found — resume with /tac-go"

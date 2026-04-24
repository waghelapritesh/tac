---
name: tac-go
description: Use when resuming work after a break — reads .tac/context/pending.json and continues from exact checkpoint
---

# TAC Go (Resume)

Resume work from where you left off.

## Steps

1. **Check for `.tac/context/pending.json`**.
   - If missing, display: "No pending work found. Start a new feature with /tac-new <idea> or check status with /tac-status."
   - Stop here if missing.

2. **Read `.tac/context/pending.json`** and extract:
   - `feature_id` — which feature
   - `feature_name` — short description
   - `stage` — the stage we paused at (ASK / DESIGN / SAFE / AUTO)
   - `last_action` — what was completed before pausing
   - `next_action` — what needs to happen next
   - `context` — any saved context (partial answers, design notes, etc.)
   - `paused_at` — timestamp of the pause

3. **Display the resume summary**:

```
Resuming: {feature_name}
Stage:    {stage}
Paused:   {paused_at}

Last completed: {last_action}
Next step:      {next_action}
```

4. **Ask the user to confirm**: "Continue from this checkpoint? (yes / no / restart)"
   - If "restart" — clear pending.json and route to /tac-new
   - If "no" — stop

5. **Route to the appropriate skill based on stage**:
   - **ASK** — Follow the tac-ask workflow. Pass saved context so questions aren't repeated.
   - **DESIGN** — Follow the tac-design workflow. Pass saved context (partial spec, decisions made).
   - **SAFE** — Display: "SAFE stage coming in TAC v2. Your design is saved in .tac/history/{feature_id}/DESIGN.md"
   - **AUTO** — Display: "AUTO stage coming in TAC v2. Your design is saved in .tac/history/{feature_id}/DESIGN.md"

6. **Reference the resume workflow** at `$HOME/.claude/tac/workflows/resume.md` for detailed resume procedures.

---
name: tac-new
description: Use when starting a new feature from an idea — runs the full TAC pipeline ASK then DESIGN then SAFE then AUTO
argument-hint: "<idea-description>"
---

# TAC New Feature Pipeline

Orchestrate a new feature through the full TAC pipeline: ASK -> DESIGN -> SAFE -> AUTO.

## Prerequisites

1. **Check for `.tac/` directory**.
   - If missing, initialize it:
     - Create `.tac/`, `.tac/history/`, `.tac/context/`
     - Create `.tac/state.json` with `{ "project_name": null, "stack": null, "current_feature": null, "current_stage": null }`
     - Ask the user for project name and stack, then update state.json
   - If `.tac/state.json` exists but `project_name` is null, ask for it now.

2. **Check for in-progress feature** in `.tac/state.json`.
   - If `current_feature` is not null, warn: "Feature '{name}' is in progress at stage {stage}. Complete it first or use /tac-go to resume."
   - Let user choose: continue existing, abandon it, or cancel.

## Pipeline

### Step 1: Create Feature Entry

Generate a feature ID: `f-{YYYYMMDD}-{short-slug}` (e.g., `f-20260424-price-grid`).

Create `.tac/history/{feature_id}.json`:
```json
{
  "id": "{feature_id}",
  "name": "{idea from argument}",
  "stage": "ASK",
  "created_at": "{ISO timestamp}",
  "updated_at": "{ISO timestamp}",
  "ask_complete": false,
  "design_complete": false,
  "safe_complete": false,
  "auto_complete": false
}
```

Update `.tac/state.json`:
```json
{
  "current_feature": "{feature_id}",
  "current_stage": "ASK"
}
```

Write initial `.tac/context/pending.json`:
```json
{
  "feature_id": "{feature_id}",
  "feature_name": "{idea}",
  "stage": "ASK",
  "last_action": "Feature created",
  "next_action": "Begin requirements gathering",
  "context": {},
  "paused_at": null
}
```

### Step 2: ASK Stage (Inline)

Run the ASK stage directly — do NOT spawn a subagent. This stage requires user interaction.

Follow the tac-ask skill workflow:
- Ask adaptive requirements questions based on the idea
- Gather constraints, users, edge cases, existing patterns
- Produce a requirements summary

On completion:
- Save requirements to `.tac/history/{feature_id}/ASK.md`
- Update history JSON: `"ask_complete": true, "stage": "DESIGN"`
- Update state.json: `"current_stage": "DESIGN"`
- Update pending.json: `"stage": "DESIGN", "last_action": "ASK complete", "next_action": "Begin design"`

### Step 3: DESIGN Stage (Inline)

Run the DESIGN stage directly after ASK completes.

Follow the tac-design skill workflow:
- Read the ASK.md requirements
- Produce architecture decisions, data model, API design, UI wireframes as appropriate
- Write the design spec

On completion:
- Save design to `.tac/history/{feature_id}/DESIGN.md`
- Update history JSON: `"design_complete": true, "stage": "SAFE"`
- Update state.json: `"current_stage": "SAFE"`
- Update pending.json: `"stage": "SAFE", "last_action": "DESIGN complete", "next_action": "Safety review"`

### Step 4: SAFE + AUTO (Deferred)

Display:
```
ASK and DESIGN stages complete for: {feature_name}

Artifacts:
  .tac/history/{feature_id}/ASK.md    — Requirements
  .tac/history/{feature_id}/DESIGN.md — Design spec

SAFE and AUTO stages coming in TAC v2.
To resume later: /tac-go
```

Update state.json and pending.json to reflect the paused state.

## Error Handling

- If the user interrupts at any point, save current progress to pending.json immediately
- If a stage fails, keep the feature at that stage so /tac-go can resume
- Never lose user answers — always persist to pending.json context

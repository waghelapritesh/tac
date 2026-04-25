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

### Step 4: Auto-Documentation

After DESIGN completes, automatically generate project docs in `.tac/docs/`:

1. **PRD.md** — Product Requirements Document derived from ASK answers:
   - Problem statement, target users, requirements, success criteria
   - Auto-generated from `.tac/history/{feature_id}/ASK.md`

2. **SOP.md** — Standard Operating Procedure:
   - How to deploy, test, rollback this feature
   - Stack-specific steps from `.tac/stacks/{stack}.json`
   - Auto-generated from the DESIGN plan

3. Save to `.tac/docs/{feature_id}/PRD.md` and `.tac/docs/{feature_id}/SOP.md`

### Step 5: SAFE Stage (Auto-Run)

Run the tac-safe verification automatically — no user permission needed.

Follow the tac-safe skill:
- Verify file paths, patterns, core page impact, DB schema
- Run stack-specific safety checks
- Run tests if they exist

On PASS:
- Update history JSON: `"safe_complete": true, "stage": "AUTO"`
- **Proceed immediately to AUTO** — no confirmation needed
- Display: "SAFE passed. Building autonomously..."

On BLOCK:
- Show the blocking issues
- STOP and ask user to resolve
- Save state for `/tac-go` resume

### Step 6: AUTO Stage (Fully Autonomous)

**Runs without permission after SAFE passes.** This is the whole point — you said what to build, TAC verified it's safe, now it builds.

1. Read the plan from `.tac/history/{feature_id}-plan.json`
2. Classify tasks into waves (see internal/tac-spawn)
3. Execute wave by wave:
   - Each agent follows TDD (test first → fail → code → pass)
   - Each template agent includes mobile responsive CSS
   - Each wave commits atomically
4. After all waves:
   - Run full tac-safe verification on completed code
   - Update `.tac/history/{feature_id}.json`: `"auto_complete": true`
   - Generate/update SOP.md with actual deploy commands
5. Display summary:
   ```
   TAC Complete: {feature_name}
   
   Built: {n} files across {w} waves
   Tests: {t} passing
   Docs:  .tac/docs/{feature_id}/PRD.md
          .tac/docs/{feature_id}/SOP.md
   
   Ready to deploy? Run your deploy script.
   ```

Update state.json and pending.json.

## Auto-Spawn (Parallel Execution)

When the DESIGN stage produces a plan with 3+ independent tasks, TAC **automatically** uses parallel multi-agent execution. No need to invoke `/tac-spawn` separately.

**Detection rule:** After DESIGN completes, if the plan has tasks that can be wave-classified (see tac-spawn skill), auto-spawn kicks in:
- 1-2 tasks → sequential execution (no spawn overhead)
- 3+ tasks with independent groups → auto-spawn parallel agents per wave

The tac-spawn skill contains the full wave classification and agent prompt template. This orchestrator invokes it automatically when the plan qualifies.

## Auto-Wiring

At each stage transition, invoke the `tac-autowire` internal skill to determine and run any auto-triggered skills. See `internal/tac-autowire/SKILL.md` for the full decision table.

Progress is shown as a persistent progress bar updated at each transition:
- `[░░░░░░░░░░░░░░░░] ASK — asking question 1/5`
- `[████░░░░░░░░░░░░] DESIGN — generating approaches`
- `[████████░░░░░░░░] SAFE — verifying (test-ui: background)`
- `[████████████░░░░] AUTO — Wave 3/4 building`
- `[████████████████] DONE — PR created, roadmap advanced`

## Error Handling

- If the user interrupts at any point, save current progress to pending.json immediately
- If a stage fails, keep the feature at that stage so /tac-go can resume
- Never lose user answers — always persist to pending.json context

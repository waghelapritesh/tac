# TAC Resume Workflow

How TAC restores context and continues work after a break.

## Resume Flow

### 1. Load Checkpoint

Read `.tac/context/pending.json` which contains:
- Feature ID and name
- Current stage (ASK / DESIGN / SAFE / AUTO)
- Last completed action
- Next required action
- Saved context (partial work, decisions, answers)
- Pause timestamp

### 2. Validate State

- Confirm `.tac/state.json` matches the pending feature
- Confirm feature history file exists at `.tac/history/{feature_id}.json`
- If state is inconsistent, warn the user and offer to reset

### 3. Restore Context by Stage

#### ASK Stage Resume
- Reload any answered requirements questions from context
- Skip already-answered questions
- Continue from the next unanswered question
- Preserve all prior decisions

#### DESIGN Stage Resume
- Reload the requirements doc (ASK output)
- Reload any partial design decisions from context
- Continue design from the last saved checkpoint
- Do not re-ask resolved design questions

#### SAFE Stage Resume (v2)
- Reload the design spec
- Continue safety/review checks from where paused

#### AUTO Stage Resume (v2)
- Reload the design spec + safety clearance
- Continue implementation from last committed checkpoint

### 4. Update State on Resume

After successfully resuming:
- Update `paused_at` to null in pending.json
- Update `updated_at` in the feature history file
- Update `state.json` to reflect active work

### 5. Save New Checkpoint on Pause

When work is interrupted or a stage completes:
- Write fresh `.tac/context/pending.json` with current progress
- Update `.tac/history/{feature_id}.json` with new stage/status
- Update `.tac/state.json`

## File Locations

| File | Purpose |
|------|---------|
| `.tac/state.json` | Global project state — current feature + stage |
| `.tac/context/pending.json` | Resume checkpoint — exactly where to pick up |
| `.tac/history/{id}.json` | Per-feature history — full lifecycle record |
| `.tac/history/{id}/ASK.md` | Requirements output from ASK stage |
| `.tac/history/{id}/DESIGN.md` | Design spec output from DESIGN stage |

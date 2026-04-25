---
name: tac-build
description: Use when building a feature — smart gate decides whether to ASK first or skip to DESIGN based on request clarity
argument-hint: "<feature-description>"
---

# TAC Build (Smart Gate)

Analyze the feature request and decide the fastest safe path through the pipeline.

## Smart Gate Decision

Evaluate the feature description against three criteria:

### Criterion 1: Names a specific page or URL
- PASS: "Add export button to /price/ page", "New /tickets/ page", "Filter on SO list"
- FAIL: "Improve the reporting", "Make search better", "Add analytics"

### Criterion 2: References existing patterns
- PASS: "Like the SKU page but for licenses", "Same card layout as stock list", "Follow the GRN deploy pattern"
- FAIL: "Build a new kind of interface", "Something innovative for dashboards"

### Criterion 3: No ambiguous requirements
- PASS: "Add a column showing last purchase date to the parts table"
- FAIL: "Make the parts page more useful", "Add some kind of tracking", "Improve workflow"

## Routing Logic

### All 3 criteria PASS -> Skip ASK, go to DESIGN

The request is clear enough to design directly.

1. Check `.tac/` exists (init if needed, same as tac-new)
2. Create feature entry in `.tac/history/` with stage set to "DESIGN"
3. Update state.json and pending.json
4. Display: "Smart Gate: Request is clear — skipping ASK, starting DESIGN directly."
5. Run DESIGN stage inline (follow tac-design workflow)
6. On DESIGN complete, check for SAFE/AUTO eligibility (see below)

### Any criterion FAILS -> Route to ASK first

The request needs clarification.

1. Display which criteria failed:
   ```
   Smart Gate: Routing to ASK stage.
   - Specific page/URL: {PASS/FAIL}
   - References patterns:  {PASS/FAIL}
   - Clear requirements:   {PASS/FAIL}
   ```
2. Follow the full tac-new pipeline (ASK -> DESIGN -> ...)

### Existing plan + SAFE verified + fresh (<24h) -> Ready for AUTO

If the feature already has a completed DESIGN and the design file is less than 24 hours old:

1. Check `.tac/history/{feature_id}/DESIGN.md` exists
2. Check `design_complete: true` in history JSON
3. Check `updated_at` is within 24 hours
4. Display: "Design is fresh and verified. AUTO stage coming in TAC v2."

## Auto-Wiring

At each stage transition, invoke the `tac-autowire` internal skill to determine and run any auto-triggered skills. See `internal/tac-autowire/SKILL.md` for the full decision table.

Progress is shown as a persistent progress bar updated at each transition:
- `[░░░░░░░░░░░░░░░░] ASK — asking question 1/5`
- `[████░░░░░░░░░░░░] DESIGN — generating approaches`
- `[████████░░░░░░░░] SAFE — verifying (test-ui: background)`
- `[████████████░░░░] AUTO — Wave 3/4 building`
- `[████████████████] DONE — PR created, roadmap advanced`

## State Management

All state updates follow the same pattern as tac-new:
- Create/update `.tac/history/{feature_id}.json`
- Update `.tac/state.json` with current feature and stage
- Write `.tac/context/pending.json` at every stage transition
- Never lose progress — persist before any potentially interruptible step

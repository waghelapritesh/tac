---
name: tac-autowire
description: Auto-invoked at pipeline transitions — determines which skills to trigger based on context, runs them, and reports progress
---

# TAC Auto-Wire — Pipeline Transition Engine

Auto-invoked at every pipeline stage transition. Determines which skills to trigger based on context, runs them, and reports progress via a persistent progress bar.

## Decision Table

### On Pipeline START (tac-new or tac-build invoked)

1. Run `health` (quick check, non-blocking) — verify `.tac/` integrity
2. Check `seeds` from `.tac/seeds.json` — surface any matching seeds for this feature
3. Display initial progress bar:
   ```
   TAC: {feature-slug}
   [░░░░░░░░░░░░░░░░] STARTING — health: ok | seeds: {N} matched
   ```

### On DESIGN Complete

1. Count unanswered technical questions in the spec (DESIGN.md)
   - If >2 unanswered questions: auto-trigger `spike` for each unknown
   - Display: "DESIGN has {N} unknowns — running spike..."
2. Check if feature involves a new UI page or component
   - Scan DESIGN.md for keywords: "new page", "new component", "new template", "new view", UI file paths
   - If yes: auto-trigger `sketch` to generate 2-3 layout variants
   - Display: "New UI detected — generating sketch variants..."
3. Update progress bar:
   ```
   TAC: {feature-slug}
   [████░░░░░░░░░░░░] DESIGN complete | spike: {skipped|running} | sketch: {skipped|running}
   ```

### On AUTO Start

1. Auto-trigger `worktree create` — isolate feature on its own branch
   - Branch name: `feat/{feature-slug}`
   - If worktree creation fails (e.g., dirty working tree): warn but continue
2. Display progress bar:
   ```
   TAC: {feature-slug}
   [████████░░░░░░░░] AUTO starting — Wave 0/{N} | worktree: created
   ```

### After Each Wave Commits

1. Update progress bar with wave count:
   ```
   TAC: {feature-slug}
   [████████████░░░░] AUTO — Wave {K}/{N} complete | {files_changed} files changed
   ```
2. Check if wave included frontend files (*.html, *.css, *.jsx, *.tsx, *.vue, *.svelte, templates/*)
   - If yes: auto-trigger `test-ui` in background
   - Display: `test-ui: running`
3. If `test-ui` finds errors:
   - Auto-trigger `debug` with the test-ui error output
   - If debug produces a fix: apply fix, re-run test-ui
   - If debug fails after 3 cycles: flag the issue and continue (do not block the pipeline)
   - Display: `test-ui: {N} errors → debug: cycle {1-3}`

### On ALL Waves Complete

1. Auto-trigger `review request` for the complete feature
2. Analyze review findings:
   - If CRITICAL findings: attempt auto-fix, then re-review (max 2 cycles)
   - If clean (no CRITICAL): auto-trigger `worktree merge` (squash merge back to base branch)
3. Update progress bar:
   ```
   TAC: {feature-slug}
   [██████████████░░] AUTO complete | review: {clean|N findings} | merge: {done|pending}
   ```

### On SAFE Pass (if auto-ship enabled)

Check `.tac/project.json` or `~/.tac/settings.json` for `auto_behaviors.auto_ship: true`.

If enabled:
1. Auto-trigger `ship` (create PR)
2. Display:
   ```
   TAC: {feature-slug}
   [████████████████] DONE — PR created | auto-ship: on
   ```

If not enabled:
1. Display:
   ```
   TAC: {feature-slug}
   [██████████████░░] SAFE passed — run /tac-ship to create PR
   ```

### On Feature DONE

1. Auto-trigger `stats` update — append feature metrics to `.tac/stats.json`
2. Check `roadmap`:
   - Read `.tac/roadmap.json` — if this feature was the last in the current phase, advance to next phase
   - Display: "Roadmap: Phase {N} complete, advancing to Phase {N+1}" (or "no roadmap configured")
3. Check `todo`:
   - Scan `.tac/todos.json` for items referencing this feature ID or name
   - Mark matching todos as done
   - Display: "Todos: {N} items marked done"

### On Feature FAILED

1. Auto-trigger `forensics`:
   - Build timeline from git history and `.tac/history/{feature}/`
   - Identify root cause
   - Extract lessons learned
2. Save forensics report to `.tac/history/{feature}/FORENSICS.md`
3. Display:
   ```
   TAC: {feature-slug}
   [████████░░░░░░░░] FAILED at {stage} — forensics report saved
   ```

## Progress Bar Format

The progress bar is shown at each transition and reflects overall pipeline progress:

```
TAC: {feature-slug}
[████████░░░░░░░░] {STAGE} — {status} | {skill}: {state} | {metric}
```

Stage-to-fill mapping (16 blocks total):
- ASK: 2 blocks filled
- DESIGN: 4 blocks filled
- SAFE: 6 blocks filled
- AUTO Wave K/N: 6 + (K/N * 8) blocks filled (scales from 6 to 14)
- REVIEW: 14 blocks filled
- DONE: 16 blocks filled (full)

## Integration

This skill is NOT user-invocable. It is called by:
- `tac-new` — at each stage transition
- `tac-build` — at each stage transition
- `tac-go` — when resuming, to check if any auto-triggers were missed

## Context Persistence (at every stage transition)

After every stage transition (ASK complete, DESIGN complete, SAFE complete, each AUTO wave), invoke `tac-context` to save conversation context:

1. Call `tac-context` save with the current feature's decisions, Q&A history, design choices, and files touched
2. Update `.tac/context/pending.json` to include the `context_file` field pointing to `.tac/context/{feature-slug}.md`
3. This ensures /tac-go can restore full context on resume

## Learnings Capture (at trigger points)

At specific trigger points, auto-capture learnings to `.tac/learnings.json` via `tac-learn`:

| Trigger | Learning Type | What to Capture |
|---------|--------------|-----------------|
| SAFE catches an issue | `gotcha` | The issue and how to avoid it |
| User rejects a sketch variant | `preference` | Which variant was rejected and what was preferred |
| Debug finds a root cause | `pattern` | The root cause and how to recognize it |
| Forensics identifies a lesson | `gotcha` | The lesson learned from the failure |

Process:
1. Detect the trigger event
2. Extract a concise, actionable lesson statement
3. Call `tac-learn` to save it (dedup check is handled by tac-learn)
4. Display: "Learning captured: {lesson}"

## Learnings Injection

When spawning agents (via `tac-spawn`), load `.tac/learnings.json` and inject relevant learnings into the agent's system prompt:

1. Load all learnings from `.tac/learnings.json`
2. Filter by keyword relevance to the current task (match against task description, file names, feature name)
3. Always include `gotcha` type learnings
4. Include `preference` learnings when building UI components
5. Include `pattern` learnings when keywords match
6. Pass filtered learnings to `tac-spawn` for injection into agent prompts

## Cost Tracking (after each API call)

After each Claude API call (ASK question, DESIGN approach, SAFE verify), invoke `tac-costs` to record usage:

1. Extract token counts and model from the API response
2. Call `tac-costs` with: `input_tokens`, `output_tokens`, `model`, `stage`
3. `tac-costs` calculates cost and updates `.tac/costs.json`
4. This data is read by `tac-stats` to display the Cost Dashboard

Cost rates (per 1K tokens):
- opus: $0.015 input / $0.075 output
- sonnet: $0.003 input / $0.015 output
- haiku: $0.0008 input / $0.004 output

AUTO stage has zero TAC API cost (runs on user's Claude Code instance).

## Error Handling

- If any auto-triggered skill fails: log the error, display a warning, but do NOT block the pipeline
- Exception: `safe` failures always block (safety-first principle)
- If `.tac/` state is corrupted: suggest `tac do health` and stop auto-wiring
- All auto-trigger decisions are logged to `.tac/history/{feature}/autowire.log` for debugging

---
name: tac-do
description: Catch-all command for advanced TAC operations — routes to debug, spike, sketch, roadmap, todo, undo, stats, health, forensics, test-ui, review, worktree
argument-hint: "<action> [args]"
---

# TAC Do — Advanced Operations Router

Routes to the appropriate internal or external TAC skill based on the first argument. If no argument is given, auto-detects what the user likely needs based on current project state.

## Argument Routing

| Action | Routes to | Description |
|--------|-----------|-------------|
| `debug` | tac-debug | Systematic 4-phase root-cause analysis |
| `spike` | tac-spike | Timeboxed experiments with hypothesis-verdict |
| `sketch` | tac-sketch | HTML mockup variants for UI decisions |
| `roadmap` | tac-roadmap | Milestone and phase management |
| `todo` | tac-todo | Backlog, notes, seeds, promotion |
| `undo` | tac-undo | Safe git revert with dependency checks |
| `stats` | tac-stats | Feature, code, session metrics (reads .tac/costs.json) |
| `health` | tac-health | Project health check + auto-fix |
| `forensics` | tac-forensics | Post-mortem for failed features |
| `test-ui` | tac-test-ui | Visual UI testing |
| `review` | tac-review | Code review (request or receive) |
| `worktree` | tac-worktree | Git worktree isolation per feature |
| `learn` | tac-learn | View, add, or remove project learnings |

## Sub-Actions

Some actions accept sub-commands passed as additional arguments:

- `roadmap init|status|next|add-phase`
- `todo add|list|done|promote|note|seed`
- `review request|receive`
- `worktree create|status|merge|cleanup`
- `learn add|remove`

## No-Argument Auto-Detection

When invoked with no arguments, read current project state and suggest the most relevant action:

### Step 1: Read State

1. Read `.tac/state.json` — check for active feature and current stage
2. Read `.tac/context/pending.json` — check for paused work
3. Check git status — look for uncommitted changes, failing tests

### Step 2: Auto-Suggest

Based on state, suggest one of these:

| Condition | Suggestion |
|-----------|------------|
| Tests are failing | `/tac-do debug` — "Tests are failing. Want to debug?" |
| Feature is complete (all stages done) | `/tac-do ship` — "Feature looks complete. Ready to ship?" |
| No active feature, no pending work | Show full action list with descriptions (see below) |
| Stale state (pending.json > 24h old) | `/tac-do health` — "State looks stale. Run a health check?" |
| Feature failed (stage = FAILED) | `/tac-do forensics` — "Last feature failed. Run a post-mortem?" |
| Design has unanswered questions | `/tac-do spike` — "Design has unknowns. Want to spike?" |
| Roadmap has completed phase | `/tac-do roadmap next` — "Current phase is done. Advance roadmap?" |

### No-Argument Display

When no action is given and no auto-suggestion matches, show:

```
/tac-do — Advanced Operations

  /tac-do debug       Systematic 4-phase root-cause analysis
  /tac-do spike       Timeboxed experiments with verdicts
  /tac-do sketch      2-3 HTML mockup variants for UI decisions
  /tac-do roadmap     Milestone and phase lifecycle
  /tac-do todo        Backlog, notes, seeds capture
  /tac-do undo        Safe git revert with dependency check
  /tac-do stats       Feature, code, session metrics
  /tac-do health      Project diagnostics + auto-fix
  /tac-do forensics   Post-mortem for failed features
  /tac-do test-ui     Playwright visual testing + auto-fix
  /tac-do review      Code review (request/receive)
  /tac-do worktree    Git worktree isolation
  /tac-do learn       View, add, or remove project learnings

  Most of these run automatically during the pipeline.
  Use manually when you need them outside the pipeline.
```

### Step 3: Execute or Confirm

- Display the suggestion with a brief reason
- Ask user to confirm or pick a different action
- Route to the selected skill

## Execution

1. Parse the first argument as the action name
2. Pass remaining arguments to the target skill
3. Invoke the target skill inline (not as a subagent)
4. Return the target skill's output directly

## Error Handling

- Unknown action: show the supported actions table and ask the user to pick one
- Missing required sub-action: show available sub-actions for that skill
- Target skill fails: surface the error, do not retry automatically

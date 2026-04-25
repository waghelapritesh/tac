---
name: tac-health
description: Diagnose TAC project state and fix issues — checks consistency, orphaned features, git cleanliness, and stale checkpoints
argument-hint: "[--fix]"
---

# TAC Health

Diagnose the TAC project state and surface issues. Optionally auto-fix common problems.

## Process

### 1. Run Checks

Execute each check and record pass/fail/warning:

- **`.tac/` directory valid** — directory exists and all JSON files (`project.json`, `state.json`) parse without errors
- **State consistent** — every feature ID referenced in `state.json` has a corresponding entry in `.tac/history/`
- **No orphaned features** — every directory in `.tac/history/` that is not `DONE` or `FAILED` is accounted for in `state.json`; flag any that appear abandoned (no activity, not in state)
- **Stack profile exists** — `.tac/stacks/` contains a profile file matching the `stack` field in `project.json`; the profile's file patterns still match files present in the codebase
- **Git clean** — run `git status --short`; flag any uncommitted files that look like TAC-generated output (files in paths TAC typically writes to)
- **Tests pass** — if a test command is defined in the stack profile, run it and check the result
- **No stale pending checkpoint** — if `.tac/pending.json` exists, check its `created_at` timestamp; warn if older than 7 days

### 2. Print Report

```
TAC Health: {project-name}

  ✓ .tac/ directory valid
  ✓ State consistent
  ✗ Orphaned feature: f-20260425-dark-mode (DESIGN stage, abandoned)
  ✓ Stack profile matches
  ✗ Git dirty: 3 uncommitted files from failed AUTO
  ✓ Tests pass (24/24)
  ⚠ Stale checkpoint: pending.json is 12 days old

  Issues: 2  Warnings: 1
```

Use `✓` for pass, `✗` for fail (issue), `⚠` for warning. Count issues and warnings separately.

If everything is healthy:
```
TAC Health: {project-name}

  ✓ All checks passed — project is clean.
```

### 3. Prompt for Auto-Fix

If there are any issues or warnings, ask:

```
Auto-fix? [Y/n]
```

If `--fix` was passed as an argument, skip the prompt and proceed directly.

### 4. Auto-Fix Actions

Apply fixes in this order:

- **Orphaned features** — update `.tac/history/{feature}/state.json` to set `stage: "FAILED"` and add `abandoned_reason: "detected by tac-health, no activity"` with current timestamp
- **Dirty git** — run `git stash push -m "tac-health: stash dirty files from failed AUTO run {timestamp}"` to preserve the work without blocking
- **Stale checkpoints** — move `.tac/pending.json` to `.tac/history/archived-pending-{timestamp}.json` and remove the original

After auto-fix, re-run all checks and print the updated report.

### 5. Manual Fix Guidance

For any issue that cannot be auto-fixed (e.g., broken JSON, missing stack profile), print exact instructions:

```
Manual fix needed:
  → .tac/state.json is invalid JSON — open and fix line 14
  → Stack profile 'react-full' not found — run /tac-settings to reconfigure
```

## Anti-Hallucination

- NEVER auto-fix without user confirmation (unless `--fix` flag passed)
- NEVER delete files — stash git changes, archive checkpoints; do not destroy
- NEVER modify `.tac/history/` entries other than adding `abandoned_reason` to orphaned features
- If `git status` or test commands fail to run, report that fact rather than assuming pass

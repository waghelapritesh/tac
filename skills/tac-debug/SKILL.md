---
name: tac-debug
description: Use when diagnosing a bug — systematic 4-phase root-cause analysis with hypothesis testing before any fix is written
argument-hint: "<error-description or paste stack trace>"
---

# TAC Debug — Systematic Root-Cause Analysis

Never guess. Never patch symptoms. Find the real cause, then fix only that.

## Phase 1: Reproduce

Before forming any hypothesis, understand the exact failure.

1. Ask for (or extract from argument):
   - Exact error message and stack trace
   - What the user expected to happen
   - What actually happened
   - Steps to reproduce (minimum reproducible path)
   - When it started (after a deploy? after a code change? always?)

2. Locate the entry point:
   - Grep for the error message string in the codebase
   - Find the file and line number closest to the failure
   - Read that file (50 lines of context around the error)

3. Confirm reproduction:
   - If the system can be triggered locally or on a dev server, do it
   - If not, trace the code path manually — read every function in the call chain

Output:
```
Reproduce:
  Error:    {exact error}
  Location: {file}:{line}
  Trigger:  {what causes it}
  Confirmed: YES / NO (manual trace only)
```

## Phase 2: Hypothesize

Form exactly 3 hypotheses. Ranked by likelihood (most likely first).

For each hypothesis:
- State it clearly as a falsifiable claim: "The bug is caused by X"
- Assign likelihood: HIGH / MEDIUM / LOW
- Specify the test that would confirm or deny it (grep, read, run, check)

```
Hypotheses:
  H1 (HIGH):  {claim}
              Test: {how to confirm/deny}
  H2 (MEDIUM): {claim}
               Test: {how to confirm/deny}
  H3 (LOW):   {claim}
              Test: {how to confirm/deny}
```

Rules:
- Never form a hypothesis you can't test
- Don't assume — if you don't know, say so
- Each hypothesis must be mutually exclusive from the others where possible

## Phase 3: Isolate

Test hypotheses one at a time, starting from H1.

For each hypothesis:
1. Run the test (grep for the pattern, read the relevant code, check configs)
2. Record the result: CONFIRMED / DENIED / PARTIAL
3. If CONFIRMED: stop here — you have the root cause
4. If DENIED: move to next hypothesis
5. If PARTIAL: refine into a new hypothesis and continue

```
Isolation:
  H1: DENIED  — {evidence that ruled it out}
  H2: CONFIRMED — {evidence that proves it}
  Root cause: {precise statement of the real problem}
```

If all 3 hypotheses are DENIED:
- Widen the search — read one level up in the call stack
- Form 3 new hypotheses
- If still stuck after 3 full cycles (9 hypotheses total): escalate to user with full findings

Save progress to `.tac/context/debug.json`:
```json
{
  "feature": "{feature-id}",
  "error": "{error message}",
  "hypotheses": [...],
  "current_hypothesis": "H2",
  "eliminated": ["H1"],
  "root_cause": null
}
```

## Phase 4: Fix

Once root cause is confirmed:

1. Design the minimal fix:
   - Fix only the root cause — not symptoms, not unrelated issues
   - If fix requires changing multiple files, list them all before touching any
   - Prefer the smallest change that makes the bug impossible

2. Apply the fix:
   - Edit the file(s)
   - State exactly what changed and why

3. Verify the fix:
   - Trace the code path again — does the error condition still exist?
   - If tests exist for this area, run them
   - Check for regressions: read callers of the changed function

4. Output:
```
Fix Applied:
  File:    {file}:{line}
  Change:  {what changed}
  Reason:  {why this fixes the root cause}
  Verify:  {how confirmed fixed}
  Regression check: {what was checked, result}
```

5. Update `.tac/context/debug.json` with root cause and fix summary so `/tac-go` can resume if interrupted.

## Rules

- Never write a fix before completing Phase 3
- Never modify more than 3 files without pausing to re-evaluate
- If a fix introduces new complexity, flag it — simpler is always better
- If unsure whether something is the root cause, it isn't confirmed yet
- After fix: check if the same bug pattern could exist elsewhere in the codebase

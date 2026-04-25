---
name: tac-forensics
description: Post-mortem analysis — investigate what went wrong after a failed feature or broken deploy
argument-hint: "<feature-id or feature-name>"
---

# TAC Forensics

Investigate what went wrong after a failed feature or broken deploy. Produces a timeline, root cause analysis, and recovery plan.

## Process

### 1. Gather Evidence

- Read `.tac/history/{feature}/` for all pipeline state files (ASK, DESIGN, SAFE, AUTO logs)
- If no feature argument given, check `.tac/state.json` for the current or last active feature
- Run `git log --oneline -20` to see recent commits
- Run `git diff HEAD~5` to inspect recent code changes
- Check for test output files, error logs, and deploy output in `.tac/history/{feature}/`

### 2. Build Timeline

Reconstruct a chronological timeline of events:

```
Timeline for {feature}:
10:30 ASK complete (5 questions answered)
10:45 DESIGN approved (Approach B selected)
11:00 SAFE passed (3 checks: lint, types, test-dry-run)
11:15 AUTO wave 1 committed (3 files changed)
11:20 AUTO wave 2 FAILED — test_api.py::test_create raised AssertionError
```

Use timestamps from file modification times and git commit timestamps where available. Mark the exact failure point clearly.

### 3. Root Cause Analysis

Answer these three questions precisely:

1. **What failed?** — Exact error message, stack trace, or test failure output
2. **What caused it?** — Trace back to the code change, config value, or environment factor that introduced the failure
3. **Why wasn't it caught earlier?** — Was there a gap in the SAFE checks? A missing test? A wrong assumption in DESIGN?

Be specific. Avoid vague answers like "insufficient testing." Say which file, which line, which assumption was wrong.

### 4. Lessons Learned

Write a forensics report to `.tac/history/{feature}/FORENSICS.md`:

```markdown
# Forensics: {feature}

## Summary
One sentence: what failed and why.

## Timeline
[paste timeline here]

## Root Cause
[detailed explanation]

## Why It Wasn't Caught
[gap analysis]

## Recommendations
- SAFE improvement: [specific check to add]
- Stack profile improvement: [if applicable]
- Design improvement: [if the flaw was in the approach]
```

### 5. Recovery Plan

Based on the root cause, recommend one of:

- **Fix and retry** — If the fix is small and isolated, describe the exact change needed, then suggest running `/tac-build` again from the failed stage
- **Rollback** — If the feature left the codebase in a broken state, recommend `/tac-undo` and explain what it will revert
- **Redesign** — If the failure reveals a flawed approach in DESIGN, recommend going back to `/tac-new` with the lessons learned as context

State the recommendation clearly at the end:

```
Recovery: Fix and retry — change X in file Y, then resume AUTO from wave 2.
```

## Anti-Hallucination

- NEVER invent error messages — only report what is actually in logs or git output
- NEVER skip the "why wasn't it caught" section — that is the most valuable part
- If evidence is missing or ambiguous, say so explicitly rather than guessing
- Do not write FORENSICS.md until you have completed steps 1–3

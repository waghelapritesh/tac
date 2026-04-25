---
name: tac-ship
description: Use when you're ready to ship completed work — runs safety checks, code review, then creates a PR
argument-hint: "[feature-name]"
---

# TAC Ship — Ship Completed Work

The final gate before code leaves your machine. Runs safety, review, then creates the PR.

## Pre-Flight Sequence

Steps run in order. Each must pass before the next begins.

### Step 1: Verify feature is complete

1. Read `.tac/state.json` — get the active feature
2. Check `.tac/history/{feature}/` for a completed DESIGN.md
3. Confirm all planned files have been created or modified (compare plan vs actual)

If feature is incomplete:
```
Ship blocked: feature is not complete.
  Missing: {list of unfinished items}
  Finish the implementation first, then run /tac-ship again.
```

### Step 2: Run TAC Safe (auto-invoke)

Invoke `/tac-safe` for the current feature.

- If verdict is PASS: continue
- If verdict is BLOCK:
  ```
  Ship blocked: TAC Safe found issues.
    {list of blocking issues from tac-safe output}
  Fix these before shipping.
  ```
  Stop here. Do not continue to review.

### Step 3: Run TAC Review (auto-invoke)

Invoke `/tac-review request` for the current feature.

- If no CRITICAL findings: continue
- If CRITICAL findings exist:
  ```
  Ship blocked: {N} critical finding(s) in code review.
    [C1] {file}:{line} — {description}
    ...
  Fix these before shipping.
  ```
  Stop here.

- MAJOR findings: show them but do not block. Prompt user:
  ```
  {N} major finding(s) found (non-blocking):
    [M1] ...
  Proceed to ship? (These are recommended fixes, not blockers)
  ```

- MINOR findings: show them, do not block, do not ask.

### Step 4: Create the PR

#### Generate PR content

Read `.tac/history/{feature}/DESIGN.md` and the git diff to generate:

**Title** (under 70 characters):
- Format: `{type}({scope}): {description}`
- Types: feat, fix, refactor, perf, chore
- Example: `feat(price-export): add CSV export to price list page`

**Body**:
```markdown
## Summary
- {bullet 1 — what was built}
- {bullet 2 — how it works}
- {bullet 3 — any notable decisions}

## Test Plan
- [ ] {specific thing to test}
- [ ] {edge case to verify}
- [ ] {regression to check}

## Changes
- `{file}` — {what changed}
- `{file}` — {what changed}
```

#### Check for GitHub CLI

Run: `gh --version`

**If `gh` is available:**
```
gh pr create --title "{title}" --body "$(cat <<'EOF'
{body}
EOF
)"
```

Show the PR URL when created.

**If `gh` is not available / no remote configured:**

Output what the PR would contain:
```
PR Ready (no gh CLI — create manually):

  Title: {title}

  Body:
  {full body}

  Branch: {current branch}
  Base:   {base branch}
```

### Step 5: Mark feature as DONE

1. Update `.tac/state.json`:
   ```json
   {
     "current_feature": null,
     "last_completed": "{feature-id}",
     "last_completed_at": "{timestamp}"
   }
   ```
2. Update `.tac/history/{feature}.json`:
   ```json
   {
     "stage": "DONE",
     "shipped_at": "{timestamp}",
     "pr_url": "{url or null}"
   }
   ```

### Step 6: Final output

```
Shipped: {feature-name}

  Safe:   PASS
  Review: {N} major, {N} minor (0 critical)
  PR:     {url or "created manually"}

Feature marked DONE. Well done.
```

## Flags

- `--skip-review` — skip Step 3 (use only if review was already done separately)
- `--draft` — create PR as draft (`gh pr create --draft`)
- `--no-pr` — run all checks but skip PR creation (useful for internal deploys)

## Rules

- Never ship past a BLOCK from TAC Safe
- Never ship past a CRITICAL from TAC Review
- Always mark the feature DONE after a successful ship — keeps state clean
- If the PR creation fails (network, auth): show the PR content so the user can create it manually
- Do not modify any code during the ship sequence — review and fix first, then ship

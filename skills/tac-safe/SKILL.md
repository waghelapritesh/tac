---
name: tac-safe
description: Use when verifying code before deploy — checks file paths, service names, core page impact, DB schema, and pattern compliance against live codebase. Also auto-runs before every deploy.
argument-hint: "[feature-name]"
---

# TAC Safe — Verify Before Ship

Proves your code won't break production. Runs automatically before deploy, or manually anytime.

## What It Checks

### Generic (all stacks)

- [ ] **File paths exist** — every file referenced in the plan actually exists
- [ ] **Pattern compliance** — new code follows existing conventions (read similar modules first)
- [ ] **DB schema match** — tables/columns referenced in code exist in models
- [ ] **No hallucinated imports** — every import resolves to a real module
- [ ] **Tests pass** — run the test suite, verify GREEN

### Stack-specific (from .tac/stacks/{stack}.json safety section)

- [ ] **Core pages safe** — plan doesn't modify files used by daily-use pages
- [ ] **Service names correct** — systemctl units match real service names
- [ ] **Deploy targets verified** — host/port/user match known-good config
- [ ] **Frozen areas untouched** — no changes to frozen categories/modules
- [ ] **Mobile CSS present** — frontend files have responsive breakpoints

## Process

1. Read `.tac/history/{feature}-plan.json` — get list of files to check
2. Read `.tac/stacks/{stack}.json` — get safety rules
3. For each file in plan:
   - Glob: does it exist? (or will be created — that's OK)
   - Grep: do imports resolve?
   - Read: does it follow the stack's patterns?
4. Check core page impact:
   - Read stack safety.core_pages list
   - If ANY planned file overlaps → FLAG with explanation
5. Run tests:
   - Execute test runner from stack profile
   - All must pass
6. Output verdict:

```
TAC Safe: {feature}

  ✓ File paths verified (8/8)
  ✓ Pattern compliance (matches sku/ module)
  ✓ DB schema consistent
  ✓ No core page impact
  ✓ Service names correct (inventree-server)
  ✓ Tests pass (12/12)
  ✓ Mobile CSS present

  VERDICT: PASS — safe to deploy
```

Or:

```
  ✗ Core page impact: plan modifies order/so_sequence.py
    → /order/so/ is a daily-use page
    → Review required before proceeding

  VERDICT: BLOCK — 1 issue must be resolved
```

## Auto-Run

TAC Safe runs automatically:
- Before every deploy (in tac-new pipeline)
- Before every AUTO stage execution
- After every wave in tac-spawn (quick check)

You can also run it manually: `/tac-safe payments-page`

## Anti-Hallucination

This is THE anti-hallucination gate. If Safe finds:
- A file path that doesn't exist → BLOCK
- An API endpoint not in urls.py → BLOCK
- A service name not in systemctl → BLOCK
- A DB table not in models → BLOCK

No code ships past a BLOCK.

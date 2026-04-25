---
name: tac-spawn
description: Auto-invoked by tac-new and tac-build when a plan has 3+ independent tasks — spawns parallel subagents per wave for faster execution. Can also be called directly.
argument-hint: "[feature-name]"
---

# TAC Spawn — Parallel Multi-Agent Execution

When a plan has independent tasks (files that don't depend on each other), spawn multiple agents to build them simultaneously instead of sequentially.

## When to Use

- Plan has 3+ independent tasks (e.g., models.py, templates, deploy script)
- Tasks don't share state or depend on each other's output
- You want to build faster

## When NOT to Use

- Tasks are sequential (template depends on API, API depends on models)
- Only 1-2 tasks total
- Tasks modify the same files

## Three Laws (enforced per agent)

1. **Safety first** — each agent runs /tac-safe checks on its output
2. **Verify, don't assume** — each agent reads codebase before writing
3. **Stack-aware** — each agent receives the stack profile

## Process

### Step 1: Load the Plan

Read `.tac/history/{feature}-plan.json` to get the task list.

### Step 2: Classify Tasks

Split tasks into waves based on dependencies:

```
Wave 1 (parallel): Tasks with no dependencies
  - models.py (no deps)
  - serializers.py (no deps)
  - deploy script (no deps)

Wave 2 (parallel): Tasks that depend on Wave 1
  - api.py (depends on models + serializers)
  - urls.py (depends on api)

Wave 3 (parallel): Tasks that depend on Wave 2
  - templates (depends on urls + api)
  - tests (depends on api)

Wave 4 (sequential): Integration
  - registration (urls.py, settings.py — touches shared files)
```

### Step 3: Execute Wave by Wave

For each wave, spawn agents in parallel using the Agent tool:

```
For wave in plan.waves:
  agents = []
  for task in wave.tasks:
    spawn Agent with:
      - Task description from plan
      - Stack profile (.tac/stacks/{stack}.json)
      - Anti-hallucination rules
      - Specific files to create/modify
      - Model from profile (auto_code setting)
    
  Wait for ALL agents in wave to complete
  
  Verify: run quick safety check on all outputs
  Commit wave: git add + commit "feat({feature}): wave {n} — {description}"
  
  Update .tac/state.json with progress
  Update .tac/context/pending.json
```

### Step 3.5: Live UI Testing (after each wave)

After each wave commits, if the wave included frontend files (templates, CSS, JS, HTML):

1. **Auto-invoke `/tac-test-ui`** against the running app
2. Target: pages affected by this wave's files
3. Check for: console errors, HTTP errors, missing elements, visual regressions
4. **If errors found:**
   - Show the errors immediately
   - Attempt auto-fix (trace error → source file → minimal fix)
   - Re-test the page
   - If fixed: commit fix as `fix({feature}): resolve {error} from wave {n}`
   - If not fixed: flag it, continue to next wave (don't block), report at end
5. **If clean:** continue to next wave

This runs in parallel with the next wave's planning (non-blocking unless critical).

```
Wave 2 committed → UI test starts (background)
                 → Wave 3 agents spawn (foreground)
                 → UI test results arrive
                    → errors? auto-fix + re-test
                    → clean? continue
```

### Step 4: Assembly

After all waves complete:
- Run full /tac-safe verification
- Run `/tac-test-ui --all` for full regression sweep across all core pages
- Update .tac/history/{feature}.json with results (including UI test verdicts)
- Show summary of what was built

## Agent Prompt Template

Each spawned agent receives this context:

```
You are a TAC builder agent. You are building ONE specific piece of {feature}.

YOUR TASK:
{task description from plan}

FILES TO CREATE/MODIFY:
{file list from plan}

STACK PROFILE:
{contents of .tac/stacks/{stack}.json}

EXISTING PATTERNS (reference):
{path to similar existing module}

RULES:
1. Read existing code patterns BEFORE writing anything
2. Follow the stack profile conventions exactly
3. Include mobile CSS if creating frontend files
4. Do NOT modify files outside your task scope
5. Do NOT touch shared files (urls.py, settings.py) — that's the integration wave

PROJECT LEARNINGS:
{loaded from .tac/learnings.json, filtered by keyword relevance to this task}

TDD IS MANDATORY — follow this exact order:
1. Write the TEST file first (test_{module}.py or {Component}.test.tsx)
2. Run the test — confirm it FAILS (RED)
3. Write the IMPLEMENTATION file
4. Run the test — confirm it PASSES (GREEN)
5. Refactor if needed — run test again — still PASSES
6. Report back: "RED confirmed at {time}, GREEN confirmed at {time}"

If you write implementation before tests, your output will be REJECTED.
Test runner: {from stack profile — pytest for Python, vitest/jest for React}
```

## Wave Classification Rules

| Task Type | Wave | Why |
|-----------|------|-----|
| models.py | 1 | No dependencies |
| serializers.py | 1 | Can write with model stubs |
| admin.py | 1 | No dependencies |
| deploy script | 1 | Independent |
| api.py / views.py | 2 | Needs models + serializers |
| urls.py (module) | 2 | Needs api views |
| templates (HTML) + mobile CSS | 3 | **ALWAYS paired** — desktop + mobile built in parallel |
| static (JS) | 3 | Needs template structure |
| tests | 3 | Needs API defined |
| registration (settings.py, main urls.py) | 4 | Shared files — sequential |
| navbar updates | 4 | Shared file |

## Auto-Mobile Rule

**Every template agent automatically generates mobile responsive CSS.** This is NOT a separate task — it's baked into the template agent's job.

When a template agent is spawned, its prompt includes:

```
MOBILE CSS IS MANDATORY. You are building BOTH desktop and mobile views.

Read .tac/ui/preferences.json for approved patterns.
Read .tac/stacks/{stack}.json mobile_css section for breakpoints.

For django-ims stack:
  - Desktop: table layout, sidebar navigation
  - Mobile (max-width: 768px): card layout, hamburger nav, full-width forms
  - Tablet (769px-1024px): compact table, collapsible sidebar
  - Output: separate CSS file OR inline <style> media queries

For react-full stack:
  - Use Tailwind responsive classes (sm: md: lg:)
  - Mobile-first: base styles are mobile, add md: for desktop
  - No separate CSS file needed

NEVER build desktop-only. Every page ships responsive.
```

If a template agent returns HTML without mobile breakpoints, the output is REJECTED.

## Example

```
/tac-spawn payments-page

TAC Spawn: payments-page (4 waves, 11 tasks)

Wave 1 (parallel, 4 agents):
  Agent 1: test_models.py → FAIL → models.py → PASS
  Agent 2: test_serializers.py → FAIL → serializers.py → PASS
  Agent 3: admin.py — PaymentAdmin registration
  Agent 4: deploy_payments.py — deployment script

  [spawning 4 agents...]
  ✓ All 4 complete (12s)
  ✓ Committed: "feat(payments): wave 1 — models, serializers, admin, deploy"

Wave 2 (parallel, 2 agents):
  Agent 5: test_api.py → FAIL → api.py → PASS
  Agent 6: urls.py — payment API URL patterns

  [spawning 2 agents...]
  ✓ All 2 complete (8s)
  ✓ Committed: "feat(payments): wave 2 — API views + URLs"

Wave 3 (parallel, 4 agents):
  Agent 7: templates/payments/index.html — desktop + mobile responsive ← BOTH
  Agent 8: static/payments/payments.js — frontend interactions
  Agent 9: static/payments/payments-mobile.css — mobile overrides ← AUTO
  Agent 10: tests/test_payments_api.py — API integration tests

  [spawning 4 agents...]
  ✓ All 4 complete (15s)
  ✓ Committed: "feat(payments): wave 3 — templates (responsive), JS, mobile CSS, tests"

Wave 4 (sequential):
  Registering in settings.py + urls.py + navbar...
  ✓ Committed: "feat(payments): wave 4 — registration + navbar"

Summary: 11 tasks, 4 waves, 10 parallel agents
Every page responsive from day one.
```

## Safety

- Each wave is committed separately (easy rollback)
- Shared files (settings.py, urls.py) are ONLY touched in the final sequential wave
- If any agent fails, the wave stops and reports the error
- `.tac/context/pending.json` updated after each wave (resume-safe)

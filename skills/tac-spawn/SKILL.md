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

### Step 4: Assembly

After all waves complete:
- Run full /tac-safe verification
- Update .tac/history/{feature}.json with results
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
| templates (HTML) | 3 | Needs API endpoints defined |
| static (CSS/JS) | 3 | Needs template structure |
| tests | 3 | Needs API defined |
| registration (settings.py, main urls.py) | 4 | Shared files — sequential |
| navbar updates | 4 | Shared file |

## Example

```
/tac-spawn payments-page

TAC Spawn: payments-page (4 waves, 10 tasks)

Wave 1 (parallel, 4 agents):
  Agent 1: models.py — Payment, PaymentStatus models
  Agent 2: serializers.py — PaymentListSerializer, PaymentDetailSerializer
  Agent 3: admin.py — PaymentAdmin registration
  Agent 4: deploy_payments.py — deployment script

  [spawning 4 agents...]
  ✓ All 4 complete (12s)
  ✓ Committed: "feat(payments): wave 1 — models, serializers, admin, deploy"

Wave 2 (parallel, 2 agents):
  Agent 5: api.py — PaymentList, PaymentDetail views
  Agent 6: urls.py — payment API URL patterns

  [spawning 2 agents...]
  ✓ All 2 complete (8s)
  ✓ Committed: "feat(payments): wave 2 — API views + URLs"

Wave 3 (parallel, 3 agents):
  Agent 7: templates/payments/index.html — list page
  Agent 8: static/payments/payments.css — mobile responsive CSS
  Agent 9: tests/test_payments.py — API tests

  [spawning 3 agents...]
  ✓ All 3 complete (15s)
  ✓ Committed: "feat(payments): wave 3 — templates, CSS, tests"

Wave 4 (sequential):
  Registering in settings.py + urls.py + navbar...
  ✓ Committed: "feat(payments): wave 4 — registration + navbar"

Summary: 10 tasks, 4 waves, 9 parallel agents
Total time: ~45s (vs ~3min sequential)
```

## Safety

- Each wave is committed separately (easy rollback)
- Shared files (settings.py, urls.py) are ONLY touched in the final sequential wave
- If any agent fails, the wave stops and reports the error
- `.tac/context/pending.json` updated after each wave (resume-safe)

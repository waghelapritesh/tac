# TAC Design Workflow — Superpowers Brainstorm + TDD + Safety

## Objective

Transform ASK-stage decisions into a validated spec and phased implementation plan. Uses Superpowers brainstorming patterns with TDD enforcement and safety-first verification. Once approved, auto-advances to AUTO without user permission.

## Pipeline Position

```
ASK (GSD-1 gray areas) → DESIGN (this stage) → AUTO (auto-starts, no permission needed)
```

---

## Phase 1: Load ASK Context

```
1. Read .tac/state.json → current feature, confirm ASK complete
2. Read .tac/history/{feature}/ASK.md → all decisions and context
3. Read .tac/history/{feature}/ASK.json → structured decision data
4. Read .tac/stacks/{stack}.json → scaffold, patterns, safety rules
5. Read .tac/project.json → stack, project metadata

IF ASK output missing:
  Warn user. Ask for brief feature description to proceed.
```

---

## Phase 2: Scan Existing Patterns

Find real code to use as reference implementations.

```
1. Glob for modules similar to what's being built
2. Pick 1-2 closest modules as reference
3. Read their structure: models, APIs, URLs, templates, deploy scripts
4. Record as "reference_modules" for brainstorming

ANTI-HALLUCINATION: Every file path must come from real Glob/Read results.
```

---

## Phase 3: Brainstorm Approaches (Superpowers Style)

**Design for isolation and clarity** — break the system into units that each have one purpose, communicate through well-defined interfaces, and can be understood and tested independently.

### Present 2-3 Approaches

For each approach:

```
Approach N: {Name}

Summary: 1-2 sentences
Architecture: How data flows, what's extended vs new
Pros: Concrete advantages
Cons: Concrete disadvantages  
Effort: small / medium / large
Risk: What could break in production
Files: Existing files changed + new files created

TDD Strategy: How tests would be structured for this approach
Safety Impact: Core pages affected, frozen categories, deploy risks
```

**Recommendation**: State which approach you recommend and why. Lead with the recommendation.

### User Selection

Ask user to pick (1/2/3 or describe a mix). Accept modifications. Confirm final choice.

---

## Phase 4: Safety-First Validation

**Before writing the spec**, validate the chosen approach against safety rules.

### Safety Checklist

```
[ ] Core pages: Which pages from safety.corePages are affected?
    - If any affected: FLAG prominently, explain impact
    - If none: Confirm "No core page impact"

[ ] Frozen paths: Does anything in safety.frozenPaths get modified?
    - If yes: BLOCK unless exception applies (e.g., REF/Barebones)
    - If no: Confirm "No frozen path touched"

[ ] Service names: Which services from deploy.services need restart?
    - Verify exact names (inventree-server, NOT inventree)

[ ] Never-do rules: Does this violate any safety.neverDo?
    - If yes: BLOCK and explain

[ ] Rollback: Can this be undone if it breaks production?
    - Document rollback strategy
```

**If any BLOCK**: Stop and inform user. Do not proceed to spec.
**If all PASS**: Continue. Show safety summary:

```
Safety Check: PASS
- Core pages: {none | list affected}
- Frozen paths: {none | list}
- Services: {list to restart}
- Rollback: {strategy}
```

---

## Phase 5: TDD-First Spec

Write the spec with tests defined BEFORE implementation. This ensures every feature is verifiable.

Save as `.tac/history/{feature}/DESIGN.md`:

```markdown
# {Feature} — Design Spec

## Overview
What this feature does and why. Link to ASK decisions.

## Architecture
- Component diagram (text-based)
- Data flow
- Integration points with existing code

## Data Model
For each model: table name, fields, types, constraints, FKs, indexes

## API Endpoints
For each: method + path, request/response, permissions, mixin class

## Frontend
Pages, components, interactions, JS approach

## Mobile Responsive
If frontend involved: breakpoints, card layouts, stacked forms

## Test Plan (TDD — write tests FIRST)

### Unit Tests
- {test_feature_creates_model}: Verify model creation with required fields
- {test_api_returns_correct_data}: Verify API response shape
- {test_permission_enforced}: Verify RBAC works

### Integration Tests  
- {test_end_to_end_flow}: Full user workflow
- {test_deploy_script_smoke}: Deploy script runs without error

### Edge Cases
- {test_empty_state}: What happens with no data
- {test_concurrent_access}: If applicable
- {test_large_dataset}: Performance with N records

## Safety Impact
- Core pages affected: {list or none}
- Frozen categories: {confirm no impact}
- Deploy risk: {assessment}
- Rollback: {strategy}

## Dependencies
External libraries, services, DB migrations
```

---

## Phase 6: Create Implementation Plan

Break spec into phased tasks with TDD enforcement.

Save as `.tac/history/{feature}/PLAN.json`:

```json
{
  "feature": "{feature-name}",
  "approach": "{chosen approach}",
  "safety_status": "PASS",
  "total_phases": N,
  "phases": [
    {
      "phase": 1,
      "name": "Tests + Data Model",
      "description": "Write failing tests for model, then create model to make them pass",
      "files": ["tests/...", "models.py"],
      "depends_on": [],
      "tdd": true,
      "verification": "All model tests pass"
    }
  ]
}
```

**Standard phase ordering** (adapt per feature):
1. Tests + Data model (RED: write failing tests, GREEN: make them pass)
2. Tests + Serializers
3. Tests + API endpoints + URLs
4. URL/settings registration
5. Frontend template + JS
6. Mobile CSS (if frontend)
7. Deploy script
8. Smoke test + safety re-check

**Each phase MUST have**:
- `"tdd": true` — tests written before implementation
- Concrete file paths from stack profile
- Verification step
- Dependencies listed

---

## Phase 7: User Review + Auto-Advance

Present the design summary:

```
DESIGN complete: {feature name}

Approach: {chosen approach}
Safety: PASS — {summary}
Phases: {N} phases, TDD enforced
Tests: {M} test cases defined

Key decisions from ASK:
- {Decision 1}
- {Decision 2}

Plan saved to .tac/history/{feature}/PLAN.json
Spec saved to .tac/history/{feature}/DESIGN.md
```

Ask: "Does this look right? Any adjustments before AUTO starts?"

**If user approves (or says nothing blocking)**:

```
AUTO starting in 3 seconds...
TAC will execute the plan phase by phase with TDD enforcement.
Each wave commits atomically. You can interrupt anytime.
```

**Auto-advance to AUTO** — no permission needed. The auto-wire engine picks up from here:
- Creates worktree for isolation
- Executes wave-by-wave with parallel agents
- Each wave: RED (failing tests) → GREEN (make pass) → COMMIT
- Safety re-check after final wave
- Review + merge on completion

Update `.tac/state.json`:
```json
{
  "feature": "{name}",
  "stage": "DESIGN",
  "status": "complete",
  "auto_advance": true
}
```

---

## Guardrails

- Never skip brainstorm — always present 2-3 options
- Never write spec before user picks approach
- Never skip safety validation — run it BEFORE spec
- Never proceed if safety check returns BLOCK
- Never propose file paths that don't match stack profile
- Never claim patterns exist without citing source files
- TDD is non-negotiable — every phase has tests first
- Auto-advance to AUTO is the default — user must explicitly say "stop" to prevent it

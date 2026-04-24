# TAC Design Workflow

## Objective

Transform ASK-stage understanding into a concrete spec and phased implementation plan. Brainstorm multiple approaches, let the user choose, then produce artifacts detailed enough to execute without ambiguity.

## Phases

### Phase 1: Load Context

Load all relevant context before doing any creative work.

```
1. Read .tac/project.json → get stack name, project name
2. Read .tac/state.json → get current feature name, confirm stage
3. Read .tac/stacks/{stack}.json → get scaffold paths, patterns, safety rules, mobile_css
4. Read .tac/history/{feature}.json → get ASK-stage decisions and understanding
5. Read .tac/ui/preferences.json (if exists) → get UI design memory

IF .tac/history/{feature}.json is missing:
  Warn: "No ASK output found for '{feature}'. Running design without ASK context."
  Ask user to provide a brief description of what they want to build.
  Capture their response as the feature understanding.

IF .tac/stacks/{stack}.json is missing:
  Warn: "Stack profile not found. Using generic patterns."
  Proceed with codebase scanning to discover patterns manually.
```

### Phase 2: Scan Existing Patterns

Find real code to use as reference implementations.

```
1. Use Glob to find modules in the scaffold app_dir pattern
   Example for django-ims: Glob "inventree_patches/*/apps.py" to list all modules

2. Pick 1-2 modules closest to the new feature:
   - Similar data model complexity
   - Similar frontend needs (page vs API-only vs admin-only)
   - Similar deploy complexity

3. For each reference module, read and note:
   - models.py → data model patterns, field types, FK conventions
   - api.py → API mixin classes, queryset filtering, permissions
   - urls.py → URL naming conventions, pattern structure
   - templates/ → frontend patterns, JS approach, CSS approach
   - deploy script → upload flow, migration approach, restart sequence

4. Record findings as "reference_modules" for use in brainstorming

ANTI-HALLUCINATION: Every file path cited must come from a real Glob or Read result.
Do not assume a file exists because the stack profile says it should.
```

### Phase 3: Brainstorm Approaches

Propose 2-3 distinct approaches. Each approach must be genuinely different — not just minor variations.

```
For each approach (2-3 total):

  Name: Short descriptive name
  Summary: 1-2 sentences explaining the core idea
  
  Architecture:
    - How data flows through the system
    - Which existing modules are extended vs new modules created
    - Frontend approach (new page / extend existing / admin-only)
  
  Pros:
    - List concrete advantages (speed, simplicity, reusability, etc.)
  
  Cons:
    - List concrete disadvantages (complexity, risk, effort, tech debt)
  
  Effort: small / medium / large
    - small: 1-2 files changed, no new models, <1 day
    - medium: new module with models + API + frontend, 1-3 days
    - large: multiple modules, complex data model, frontend + mobile, 3+ days
  
  Risk:
    - What could break in production
    - Which core pages (from safety.core_pages) are affected
    - Whether frozen categories might be impacted
  
  Files:
    - Existing files that change (with brief note on what changes)
    - New files that get created (with paths from stack scaffold)

RECOMMENDATION: State which approach you recommend and why.
Present as numbered list: "Approach 1:", "Approach 2:", "Approach 3:"
End with: "Which approach do you prefer? (1/2/3, or describe a mix)"
```

### Phase 4: Write Spec

After the user picks an approach, write the full spec document.

```
Spec structure (save as .tac/history/{feature}-spec.md):

# {Feature Name} — Design Spec

## Overview
What this feature does and why it exists.
Link back to ASK-stage decisions where relevant.

## Architecture
- Component diagram (text-based, showing data flow)
- Which existing modules are extended
- Which new modules are created
- Integration points with existing code

## Data Model
For each new model:
  - Table name (following stack convention: {module}_{model})
  - Fields with types, constraints, defaults
  - Foreign keys with on_delete behavior
  - Indexes
  - Permissions / RBAC notes

For each modified model:
  - What fields are added/changed
  - Migration safety notes

## API Endpoints
For each endpoint:
  - Method + Path
  - Request body / query params
  - Response shape
  - Permissions required
  - Which mixin class to use (from stack patterns)

## Frontend
  - Page URL and template path
  - Key UI components
  - JavaScript approach (vanilla fetch / library)
  - User interactions and flows

## Mobile Responsive Design
IF frontend is involved:
  - Read mobile_css from stack profile
  - Apply breakpoints: mobile (max-width: 768px), tablet (769-1024px), desktop (1025px+)
  - For tables: card layout on mobile, full table on desktop
  - For forms: stacked full-width on mobile
  - For modals: full-screen on mobile
  - For navigation: bottom nav on mobile if applicable
  - Reference the CSS file from stack profile (e.g., bims-mobile.css)
  - Note any new CSS rules needed

## Safety Impact
  - Core pages affected (cross-reference with safety.core_pages)
  - Frozen categories: confirm no impact, or flag if Barebones exception applies
  - Deploy risk assessment
  - Rollback strategy

## Dependencies
  - External libraries needed
  - Other features or modules this depends on
  - Database changes requiring migration
```

### Phase 5: Create Implementation Plan

Break the spec into ordered, dependency-aware phases.

```
Plan structure (save as .tac/history/{feature}-plan.json):

{
  "feature": "{feature-name}",
  "approach": "{chosen approach summary}",
  "total_phases": N,
  "phases": [
    {
      "phase": 1,
      "name": "Data Model & Migration",
      "description": "Create models and raw SQL migration script",
      "files": [
        "inventree_patches/{module}/models.py",
        "inventree_patches/{module}/__init__.py",
        "inventree_patches/{module}/apps.py"
      ],
      "depends_on": [],
      "verification": "SQL runs without error on test DB; models import cleanly"
    },
    {
      "phase": 2,
      "name": "API Layer",
      "description": "...",
      "files": ["..."],
      "depends_on": [1],
      "verification": "..."
    }
  ],
  "created_at": "<ISO timestamp>"
}

Standard phase ordering (adapt to feature needs):
  1. Data model + migration SQL
  2. Serializers
  3. API endpoints + URLs
  4. URL registration in InvenTree/urls.py and settings.py
  5. Frontend template + JS
  6. Mobile CSS (if frontend involved)
  7. Deploy script
  8. Smoke test checklist

Each phase MUST have:
  - Concrete file paths (not placeholders — use stack scaffold patterns)
  - A verification step that can be checked without deploying
  - Dependencies explicitly listed

All file paths come from the active stack profile scaffold section.
When the stack says app_dir is "inventree_patches/{module}/", expand {module} to the actual module name.
```

### Phase 6: Gate Check

Validate the plan is concrete enough to execute.

```
For each phase in the plan, check:
  [ ] File paths are real or clearly marked as "new file"
  [ ] Description is specific enough that someone could implement without asking questions
  [ ] Verification step is concrete and testable
  [ ] Dependencies are correct (no circular deps, no missing deps)

For the overall plan:
  [ ] Safety impact from spec is addressed (which phase handles it?)
  [ ] Mobile responsive is included if frontend is involved
  [ ] Deploy script phase exists
  [ ] No phase is too large (if >5 files, consider splitting)

IF any check fails:
  Refine the plan before saving.

Present final plan summary to user:
  "Plan: {N} phases, estimated {effort}"
  Brief list of phase names
  "Ready to proceed to SAFE stage? Or adjust anything?"
```

## State Management

After completing all phases:

```json
// .tac/state.json
{
  "feature": "{feature-name}",
  "stage": "DESIGN",
  "status": "complete",
  "step": 6,
  "total_steps": 6,
  "stack": "{stack-name}"
}
```

## Artifacts Produced

| File | Content |
|------|---------|
| `.tac/history/{feature}-spec.md` | Full design spec |
| `.tac/history/{feature}-plan.json` | Phased implementation plan |
| `.tac/state.json` | Updated stage tracking |

## Guardrails

- Never skip the brainstorm — always present options even if one is obvious
- Never write the spec before the user picks an approach
- Never propose file paths that don't match the stack profile scaffold
- Never claim a pattern exists without citing the source file
- If the feature touches core pages, flag it prominently in the safety section
- If mobile responsive is needed, it gets its own phase — don't bundle it into the frontend phase
- All timestamps in ISO 8601 format
- Handle Windows paths (backslash) gracefully — normalize to forward slashes in JSON

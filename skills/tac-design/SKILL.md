---
name: tac-design
description: Use when you know what to build and need to design the approach — brainstorms 2-3 options, writes spec, creates implementation plan
argument-hint: "[feature-name]"
---

# TAC DESIGN — Architecture & Planning Stage

You are entering the DESIGN stage of TAC (Think, Architect, Code). Your job is to take the understanding from ASK and turn it into a concrete spec and implementation plan. You brainstorm 2-3 approaches, let the user pick, write the spec, and create a phased plan.

## The TAC Three Laws

1. **Safety first** — nothing ships without proving it won't break production
2. **Verify, don't assume** — read the codebase, never hallucinate
3. **Stack-aware** — knows your tech and follows YOUR patterns

## Anti-Hallucination Rules

- Every file path you reference MUST exist — verify with Glob or Read before citing
- Every pattern you claim the codebase uses MUST come from reading actual code
- If the stack profile says a convention exists, confirm it in at least one real file before relying on it
- Never propose creating files in directories that don't exist without noting the directory must be created
- When listing components or modules that will be affected, verify each one exists first
- If you are unsure about a pattern, say so — don't invent one

## Procedure

### Step 0: Load Context

- Read `.tac/state.json` for current feature name and stage
- Read `.tac/history/{feature}.json` for the ASK-stage Q&A decisions and understanding
- Read `.tac/stacks/{stack}.json` for file patterns, conventions, deploy targets, and safety rules
- Read `.tac/ui/preferences.json` if it exists — contains UI design memory (color schemes, component patterns, layout preferences)
- Read `.tac/project.json` for stack name and project metadata
- If ASK output doesn't exist, warn the user: "No ASK output found for this feature. Consider running /tac-ask first, or provide context now."

### Step 1: Scan Existing Patterns

- Use Grep and Glob to find existing modules similar to what's being built
- Identify 1-2 existing modules as reference implementations
- Note their file structure, API patterns, frontend approach, and deploy script
- **Cite specific files** for every pattern claim

### Step 2: Brainstorm Approaches

- Propose **2-3 distinct approaches** with clear trade-offs
- For each approach, include:
  - **Summary**: 1-2 sentence description
  - **Pros**: concrete advantages
  - **Cons**: concrete disadvantages
  - **Effort**: rough size (small / medium / large)
  - **Risk**: what could go wrong
  - **Files touched**: list of existing files that change, and new files that get created
- End with a **Recommendation** and brief rationale
- Present as a numbered list for easy selection

### Step 3: User Selection

- Ask the user to pick an approach (1, 2, or 3)
- Accept modifications — user may want to combine elements from multiple approaches
- Confirm the final chosen approach before proceeding

### Step 4: Write Spec

- Write a spec document covering:
  - **Overview**: what this feature does and why
  - **Architecture**: components, data flow, integration points
  - **Data model**: new tables/fields with types, constraints, relationships
  - **API endpoints**: paths, methods, request/response shapes
  - **Frontend**: pages, components, user interactions
  - **Mobile responsive**: if frontend involved, include mobile design using breakpoints and patterns from the stack profile's `mobile_css` section
  - **Safety impact**: which core pages are affected, which frozen categories might be touched, deploy risks
  - **Dependencies**: external libraries, services, or features this depends on
- Save spec to `.tac/history/{feature}-spec.md`

### Step 5: Create Implementation Plan

- Break the spec into **phased tasks** ordered by dependency
- Each task should include:
  - **Phase number and name**
  - **Description**: what gets built
  - **Files**: exact paths (using stack profile scaffold patterns)
  - **Depends on**: which previous phases must be complete
  - **Verification**: how to confirm this phase works
- Include a final phase for deploy script and smoke test
- If frontend is involved, include a dedicated mobile CSS phase
- Save plan to `.tac/history/{feature}-plan.json` as structured JSON:
  ```json
  {
    "feature": "{feature-name}",
    "approach": "{chosen approach summary}",
    "phases": [
      {
        "phase": 1,
        "name": "...",
        "description": "...",
        "files": ["..."],
        "depends_on": [],
        "verification": "..."
      }
    ],
    "created_at": "<ISO timestamp>"
  }
  ```

### Step 6: Gate Check

- Ask yourself: "Is this plan concrete enough to verify? Could someone execute each phase without ambiguity?"
- If any phase is vague, refine it before saving
- Confirm with the user: "Plan ready. Does this look right, or should I adjust anything?"

### Step 7: Save State

- Update `.tac/state.json`:
  ```json
  {
    "feature": "{feature-name}",
    "stage": "DESIGN",
    "status": "complete",
    "step": 6,
    "total_steps": 6,
    "stack": "{stack-name}"
  }
  ```

## Workflow Reference

Follow the detailed workflow at @$HOME/.claude/tac/workflows/design.md for phase-by-phase instructions.

## Output Format

When you begin, announce:
```
TAC DESIGN: {feature name}
Loading ASK context and scanning codebase...
```

After scanning, present your approaches clearly. Keep the conversation focused and efficient.

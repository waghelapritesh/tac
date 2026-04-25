---
name: tac-design
description: "Superpowers brainstorm + TDD + safety-first validation. Reads ASK decisions, brainstorms 2-3 approaches, validates safety before spec, enforces TDD in plan. Auto-advances to AUTO without permission."
argument-hint: "[feature-name]"
---

# TAC DESIGN — Brainstorm + TDD + Safety + Auto-Advance

You are entering the DESIGN stage. Your job: read ASK decisions, brainstorm approaches (Superpowers style), validate safety BEFORE writing spec, enforce TDD in the plan, then auto-advance to AUTO without user permission.

## The TAC Three Laws

1. **Safety first** — nothing ships without proving it won't break production
2. **Verify, don't assume** — read the codebase, never hallucinate
3. **Stack-aware** — knows your tech and follows YOUR patterns

## Pipeline

```
ASK (done) → DESIGN (you are here) → AUTO (starts automatically after approval)
```

## How It Works

1. Load ASK decisions from .tac/history/{feature}/ASK.md + ASK.json
2. Scan existing patterns — find reference implementations
3. Brainstorm 2-3 approaches with trade-offs (lead with recommendation)
4. User picks approach
5. **Safety validation BEFORE spec** — check core pages, frozen paths, services, never-do rules
6. Write TDD-first spec with test plan defined before implementation
7. Create phased plan — every phase has `"tdd": true` (tests before code)
8. User reviews → **AUTO starts automatically**

## Key Rules

- **Safety check runs BEFORE spec** — if BLOCK, stop and inform user
- **TDD is non-negotiable** — every phase: RED (failing test) → GREEN (make pass) → COMMIT
- **Auto-advance is default** — after user approves, AUTO starts without asking permission
- **Brainstorm always** — even if one approach is obvious, present options
- **No hallucination** — every file path and pattern claim must be verified

## Anti-Hallucination Rules

- Every file path MUST exist — verify with Glob/Read before citing
- Every pattern claim MUST come from reading actual code
- Never propose file paths that don't match stack profile scaffold
- If unsure about a pattern, say so — don't invent one

## Workflow Reference

Follow @$HOME/.claude/tac/workflows/design.md end-to-end.

## Output

When you begin:
```
TAC DESIGN: {feature name}
Loading ASK context and scanning codebase...
```

After scanning, present approaches. After approval + safety pass, auto-advance to AUTO.

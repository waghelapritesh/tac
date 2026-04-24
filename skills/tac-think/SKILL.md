---
name: tac-think
description: Use when exploring an idea without committing to build — runs ASK (Q&A) then DESIGN (brainstorm + spec) and stops. No coding, just thinking.
argument-hint: "<idea-description>"
---

# TAC Think — Explore Without Building

Combines ASK + DESIGN into one command. For when you want to think through an idea without committing to code.

## What It Does

```
/tac-think "payments tracking"
  │
  ├── ASK: Adaptive Q&A (reads codebase, asks smart questions)
  │   └── Saves understanding to .tac/history/
  │
  └── DESIGN: Brainstorm 2-3 approaches, write spec + plan
      └── Saves spec + plan to .tac/history/
```

Stops after DESIGN. Does NOT build, deploy, or touch code.

## Process

1. Check `.tac/` exists — if not, run tac-init flow first
2. Create feature entry in `.tac/history/`
3. **ASK stage** (inline — needs user interaction):
   - Read codebase BEFORE asking questions
   - One question at a time, multiple choice preferred
   - Don't ask what can be discovered from code
   - Capture every decision to `.tac/history/{feature}.json`
4. **DESIGN stage** (inline):
   - Read ASK output + stack profile + UI preferences
   - Scan existing modules for similar patterns
   - Propose 2-3 approaches with trade-offs
   - User picks → write spec + plan
   - Save to `.tac/history/{feature}-spec.md` and `{feature}-plan.json`
5. **Auto-generate docs** in `.tac/docs/{feature}/`:
   - **PRD.md** — Product Requirements Document:
     - Problem statement (from ASK answers)
     - Target users and stakeholders
     - Functional requirements (from decisions captured)
     - Non-functional requirements (performance, security, mobile)
     - Success criteria
     - Out of scope
   - **SOP.md** — Standard Operating Procedure:
     - How to deploy this feature (from stack profile deploy config)
     - How to test (test runner commands)
     - How to rollback (from stack profile safety rules)
     - Environment details (hosts, ports, services)
6. Show summary:
   ```
   Think complete for: {feature}
   
   Spec:  .tac/history/{feature}-spec.md
   Plan:  .tac/history/{feature}-plan.json
   PRD:   .tac/docs/{feature}/PRD.md
   SOP:   .tac/docs/{feature}/SOP.md
   
   Ready to build? Run /tac-build {feature}
   ```

## When to Use /tac-think vs /tac-new

- `/tac-think` — "I have an idea, let's explore it" (stops at plan)
- `/tac-new` — "I want this built end-to-end" (think + safe + auto)

## TAC Three Laws

1. Safety first — nothing ships without proving it won't break production
2. Verify, don't assume — read the codebase, never hallucinate
3. Stack-aware — knows your tech and follows YOUR patterns

## Anti-Hallucination

- Scan codebase files BEFORE asking questions
- Cite file paths for every claim about existing code
- Read .tac/stacks/{stack}.json for conventions
- Read .tac/ui/preferences.json for UI patterns

## References

Detailed workflows:
- @$HOME/.claude/tac/workflows/ask.md
- @$HOME/.claude/tac/workflows/design.md

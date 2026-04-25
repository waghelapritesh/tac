---
name: tac-context
description: Auto-invoked at pipeline transitions — saves and restores rich conversation context across sessions
---

# TAC Context — Cross-Session Persistence

Saves rich conversation context at every stage transition and restores it on resume, so no decisions are lost and no questions are re-asked.

## This skill is NOT user-invocable. It is called by:
- `tac-autowire` — at each stage transition (save)
- `tac-go` — on resume (restore)

## Save Context (on every stage transition)

When autowire fires a stage transition, write/update `.tac/context/{feature-slug}.md`:

```markdown
# Context: {feature-name}
## Stage: {current-stage}
## Decisions Made
- {key decision 1 and reasoning}
- {key decision 2 and reasoning}
## Q&A History
- Q: {question} → A: {answer}
## Design Choices
- Approach: {chosen approach} (rejected: {alternatives} because {reasons})
## Files Touched
- {file}: {what was done}
## Blockers & Notes
- {anything important}
## Updated: {timestamp}
```

### What to capture at each stage:

**After ASK:**
- All questions asked and answers received
- Decisions made about scope, approach, constraints
- Any user preferences expressed

**After DESIGN:**
- Architecture decisions and alternatives considered
- File plan (what files will be created/modified)
- Any spikes or sketches triggered and their outcomes
- Open questions that remain

**After SAFE:**
- Safety checks passed/failed
- Any issues found and how they were resolved
- Blockers identified

**After each AUTO wave:**
- Files actually created/modified in this wave
- Any errors encountered and fixes applied
- Test results

## Restore Context (on /tac-go resume)

1. Read `.tac/context/pending.json` to get the `feature_id` and `context_file` path
2. Read `.tac/context/{feature-slug}.md`
3. Inject the full context file contents as system context for the LLM
4. The LLM now knows:
   - Every question already asked and answered
   - Every design decision and why
   - Every file touched so far
   - Any blockers or notes
5. Resume the pipeline from the saved stage — no re-asking

## Update pending.json

When saving context, also update `.tac/context/pending.json` to include:

```json
{
  "feature_id": "f-20260425-payments",
  "feature_name": "add payments page",
  "stage": "DESIGN",
  "last_action": "completed ASK with 4 questions answered",
  "next_action": "generate DESIGN spec",
  "context": {},
  "context_file": ".tac/context/f-20260425-payments.md",
  "paused_at": "2026-04-25T10:30:00Z"
}
```

The `context_file` field points to the rich markdown file with all decisions and history.

## Error Handling

- If `.tac/context/` directory doesn't exist, create it
- If context file is corrupted or unparseable, warn but don't block — treat as fresh start
- If pending.json has no `context_file` field (old format), fall back to existing resume behavior

# TAC ASK Workflow — GSD-1 Style Gray Area Discovery

This workflow drives the ASK stage of TAC. Instead of open-ended Q&A, it identifies gray areas in the feature, presents structured 4-option questions, and captures decisions that feed directly into DESIGN.

---

## Philosophy

**User = visionary. TAC = builder.**

The user knows: how they imagine it working, what it should feel like, what's essential vs nice-to-have.
TAC handles: codebase patterns, technical risks, implementation approach.

Ask about vision and implementation choices. Don't ask what code can answer.

---

## Phase 1: Load Context

```
1. Read .tac/project.json → stack, project name, provider
2. Read .tac/stacks/{stack}.json → conventions, safety rules, deploy targets
3. Read prior feature history from .tac/history/ → don't re-ask decided questions
```

---

## Phase 2: Codebase Scout

**Goal**: Lightweight scan to inform gray area identification. ~10% context budget.

```
1. Extract key terms from feature description
2. Grep for related files (models, APIs, templates, components)
3. Read 3-5 most relevant files to understand existing patterns
4. Identify:
   - Reusable assets (existing components, utilities)
   - Established patterns (state management, API style, deploy approach)
   - Integration points (where new code connects)
```

**Anti-hallucination**: Every file reference must come from a real Glob/Read/Grep result.

---

## Phase 3: Gray Area Identification

**Goal**: Identify implementation decisions the user should weigh in on.

Gray areas are decisions that could go multiple ways and would change the result.

**How to identify:**
1. Read the feature description
2. Understand the domain:
   - Something users SEE → visual presentation, interactions, states matter
   - Something users CALL → interface contracts, responses, errors matter
   - Something users RUN → invocation, output, behavior modes matter
   - Something being ORGANIZED → criteria, grouping, handling exceptions matter
3. Generate 3-5 concrete gray areas specific to THIS feature
4. Skip anything already decided in prior features or discoverable from code

**Good gray areas**: "Layout style — cards vs list vs timeline?"
**Bad gray areas**: "UI" (too generic), "Database schema" (TAC handles this)

**What TAC handles (don't ask)**:
- Technical implementation details
- Architecture patterns (follow existing codebase)
- Performance optimization
- File structure (stack profile defines this)

---

## Phase 4: Present Gray Areas

Present the feature boundary and gray areas to the user.

```
TAC ASK: {feature description}
Domain: {what this feature delivers}

Carrying forward:
- {any prior decisions that apply}

Which areas do you want to discuss?
```

List 3-5 gray areas with brief descriptions and code context annotations:

```
☐ Layout style — Cards vs list vs timeline?
  (Card component exists at src/components/Card.tsx — reusing keeps consistency)

☐ Loading behavior — Infinite scroll or pagination?
  (useInfiniteQuery hook already set up)

☐ Empty state — What shows when no data exists?

☐ Content density — Full detail vs compact preview?
```

User selects which to discuss.

---

## Phase 5: Structured Discussion

**For each selected gray area:**

1. **Announce**: "Let's talk about {area}."

2. **Ask 4 questions using AskUserQuestion** (or plain text if AskUserQuestion unavailable):
   - Offer 3-4 concrete options (not generic A/B/C — use real descriptions)
   - Highlight recommended option with brief reasoning
   - Annotate options with code context when relevant
   - Include "You decide" when reasonable (captures TAC discretion)

   Example:
   ```
   How should posts be displayed?
   
   A) Cards (reuses existing Card component — consistent with Messages page)
   B) List rows (simpler, familiar table pattern from Parts list)  
   C) Timeline (new component needed — more visual but more work)
   D) You decide (TAC picks based on existing patterns)
   ```

3. **After each answer, adapt**: use the answer to inform the next question.

4. **After 4 questions per area**, ask: "More about {area}, or move to next?"

5. **Scope creep guard**: If user mentions something outside the feature scope:
   ```
   "{Feature X} sounds like a separate feature — I'll note it for later.
   Back to {current area}: {return to current question}"
   ```
   Track deferred ideas internally.

---

## Phase 6: Capture Decisions

After all areas discussed, compile decisions into `.tac/history/{feature-slug}/ASK.md`:

```markdown
# {Feature} — ASK Decisions

**Date:** {ISO date}
**Feature:** {feature description}

## Domain Boundary
{What this feature delivers — clear scope anchor}

## Decisions

### {Area 1}
- **D-01:** {Decision captured}
- **D-02:** {Another decision}

### {Area 2}
- **D-03:** {Decision captured}

### TAC's Discretion
{Areas where user said "you decide" — TAC has flexibility}

## Existing Code Insights

### Reusable Assets
- {Component/utility}: {How it applies}

### Established Patterns
- {Pattern}: {How it constrains this feature}

### Integration Points
- {Where new code connects}

## Deferred Ideas
{Ideas mentioned but out of scope — saved for later}
```

Also save structured JSON to `.tac/history/{feature-slug}/ASK.json`:

```json
{
  "feature": "{feature-name}",
  "decisions": [
    { "area": "...", "question": "...", "answer": "...", "options_presented": ["..."] }
  ],
  "codebase_context": { "reusable": [], "patterns": [], "integration_points": [] },
  "deferred_ideas": [],
  "completed_at": "ISO timestamp"
}
```

---

## Phase 7: Gate Check & Transition

```
ASK complete. {N} decisions captured across {M} areas.

Key decisions:
- {Decision 1}
- {Decision 2}
- {Decision 3}

Deferred: {N items noted for later}
```

Update `.tac/state.json`:
```json
{ "feature": "{name}", "stage": "ASK", "status": "complete" }
```

**Auto-transition to DESIGN** — TAC's auto-wire handles this. The DESIGN stage reads ASK.md and ASK.json to brainstorm approaches with full context.

---

## Anti-Hallucination Checklist

- [ ] Every file reference verified with Glob/Read/Grep
- [ ] Every pattern claim cites the file where observed
- [ ] Never assumed directory structure — verified it
- [ ] Never guessed config values — read config files
- [ ] When unsure, asked the user instead of guessing

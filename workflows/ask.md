# TAC ASK Workflow — Detailed Phases

This workflow drives the ASK stage of TAC. The goal is to go from a vague feature idea to a set of captured decisions sufficient to begin design.

---

## Phase 1: Codebase Scan

**Goal**: Understand the existing system before asking a single question.

1. Read `.tac/project.json` to learn the stack (language, framework, DB, services)
2. Read `.tac/stacks/{stack}.json` for stack-specific conventions
3. Based on the feature description, identify likely touchpoints:
   - Search for related modules, routes, models, APIs, templates
   - Read key files to understand current patterns
   - Note directory structure and naming conventions
4. Build an internal context map:
   - What exists today that relates to this feature?
   - What patterns does this codebase follow?
   - What are the integration points?

### Anti-Hallucination Guardrails

- **Every claim about the codebase MUST cite a file path.** Example: "The app uses Django REST Framework serializers (see `app/api/serializers.py`)"
- If you cannot point to a specific file or line, prefix with "I could not verify this in the codebase"
- Never say "the codebase probably has..." — either you found it or you didn't
- When unsure about a pattern, read more files before making claims
- If a file you expected doesn't exist, say so explicitly

---

## Phase 2: Adaptive Q&A

**Goal**: Fill knowledge gaps that code alone cannot answer.

### Rules

1. **One question at a time.** Never ask multiple questions in one message.
2. **Multiple choice preferred.** Offer A/B/C/D options when the answer space is bounded. Include an "Other" option when the list isn't exhaustive.
3. **Don't ask what code can answer.** Before asking "What database do you use?", check config files. Before asking "How is auth handled?", read the auth module.
4. **Build on previous answers.** Each question should narrow the solution space based on what you've learned.
5. **Explain why you're asking.** Brief context helps the user give better answers. Example: "I found two patterns for API endpoints in this codebase — REST ViewSets and function views. Which should this feature use?"

### Question Categories (in rough priority order)

- **Scope**: What's in, what's out?
- **Users**: Who uses this? What roles?
- **Behavior**: What happens when X? Edge cases?
- **Integration**: How does this connect to existing features?
- **Constraints**: Performance, security, compatibility requirements?
- **Priority**: Must-have vs nice-to-have?

### Adaptive Branching

- If the user's answer reveals complexity, drill deeper before moving on
- If the user's answer is simple and clear, move to the next category
- If the user says "you decide" or "whatever's standard", pick the option that matches existing codebase patterns and state your choice

---

## Phase 3: Capture Decisions

**Goal**: Record every Q&A exchange as a structured decision.

For each question-answer pair, capture:

```json
{
  "question": "The question asked",
  "answer": "The user's answer",
  "rationale": "Why this matters for the design",
  "evidence": ["path/to/relevant/file.py"],
  "decided_at": "ISO timestamp"
}
```

When all questions are answered, compile into `.tac/history/{feature-slug}.json`:

```json
{
  "feature": "feature-name",
  "slug": "feature-slug",
  "description": "One-line summary",
  "started_at": "ISO timestamp",
  "completed_at": "ISO timestamp",
  "codebase_context": {
    "files_scanned": ["list of files read during Phase 1"],
    "patterns_found": ["pattern descriptions with file citations"],
    "integration_points": ["where this feature connects to existing code"]
  },
  "decisions": [
    { "question": "...", "answer": "...", "rationale": "...", "evidence": [] }
  ],
  "summary": "Paragraph summarizing what will be built and key decisions"
}
```

---

## Phase 4: Gate Check

**Goal**: Verify readiness to move to the design stage.

Ask yourself these questions:

1. **Scope clear?** Can I list exactly what's in and what's out?
2. **Integration understood?** Do I know which existing files/modules this touches?
3. **Patterns identified?** Do I know which codebase patterns to follow?
4. **Edge cases covered?** Have I asked about the non-obvious scenarios?
5. **No hallucinations?** Is every codebase claim backed by a file path I actually read?

If any answer is "no", go back to Phase 2 and ask more questions.

If all answers are "yes":
1. Present a summary of all decisions to the user for confirmation
2. Save to `.tac/history/{feature-slug}.json`
3. Update `.tac/state.json`:
   ```json
   {
     "feature": "feature-name",
     "stage": "ASK",
     "status": "complete"
   }
   ```
4. Tell the user: "ASK stage complete. Run `/tac-plan` when ready to design."

---

## Anti-Hallucination Checklist (apply throughout)

- [ ] Every file reference points to a real file I read with the Read tool
- [ ] Every pattern claim cites the file where I observed it
- [ ] I never said "typically" or "usually" about THIS codebase — I either found evidence or said I didn't
- [ ] I didn't assume directory structure — I verified it
- [ ] I didn't guess at config values — I read the config files
- [ ] When I wasn't sure, I asked the user instead of guessing

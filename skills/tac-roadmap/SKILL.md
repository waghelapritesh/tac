---
name: tac-roadmap
description: Manage multi-phase project lifecycle — initialize roadmap, track milestone progress, advance phases, and insert new work
argument-hint: "init | status | next | add-phase <description>"
---

# TAC Roadmap

Manage multi-phase project lifecycle through versioned milestones and numbered phases. State is stored in `.tac/ROADMAP.md`.

## Subcommand Routing

Read the argument passed to determine which subcommand to execute:

- `init` → Initialize a new ROADMAP.md from project description
- `status` → Show current milestone and phase progress
- `next` → Advance to the next phase or milestone
- `add-phase <description>` → Insert a new phase into the current milestone

If no argument is given, run `status`.

---

## `/tac-roadmap init`

**Purpose:** Create `.tac/ROADMAP.md` from a project description.

**Steps:**

1. Ask the user (or read from context) for the project description and goals.
2. Analyze the scope and break the work into milestones:
   - Use semantic versioning: v1.0, v1.1, v2.0, etc.
   - v1.0 = first working, shippable product
   - v1.x = incremental improvements on stable base
   - v2.0 = significant rework or new capability tier
3. For each milestone, define:
   - **Goal:** One sentence describing what this milestone achieves
   - **Phases:** Numbered sequentially within the milestone (Phase 1, Phase 2, …)
   - **Success Criteria:** 3–5 verifiable statements (must be checkable — no vague language like "works well" or "feels fast")
   - **Dependencies:** Other milestones or external conditions this depends on
4. Set the first phase of v1.0 as the active phase.
5. Write `.tac/ROADMAP.md` using the template below.

**ROADMAP.md Template:**

```markdown
# Project Roadmap

## Active: v1.0 — Phase 1

---

## v1.0: <Milestone Goal>

**Dependencies:** None

### Phases
- [ ] Phase 1: <description>
- [ ] Phase 2: <description>
- [ ] Phase 3: <description>

### Success Criteria
- [ ] <Verifiable criterion 1>
- [ ] <Verifiable criterion 2>
- [ ] <Verifiable criterion 3>

---

## v1.1: <Milestone Goal>

**Dependencies:** v1.0 complete

### Phases
- [ ] Phase 1: <description>

### Success Criteria
- [ ] <Verifiable criterion 1>

---

## v2.0: <Milestone Goal>

**Dependencies:** v1.1 complete

### Phases
- [ ] Phase 1: <description>

### Success Criteria
- [ ] <Verifiable criterion 1>
```

**Rules:**
- Success criteria must be verifiable. GOOD: "User can log in with email/password and receive a JWT". BAD: "Authentication works".
- Milestones represent shippable increments, not internal dev steps.
- Phases within a milestone are the implementation steps — think waves of work.
- Output a summary of the roadmap after writing the file.

---

## `/tac-roadmap status`

**Purpose:** Show current milestone progress in a readable summary.

**Steps:**

1. Read `.tac/ROADMAP.md`. If not found, tell the user to run `/tac-roadmap init` first.
2. Read `.tac/history/` (list all files). Each file represents a completed TAC feature. Scan their contents for milestone/phase references if available, or use filenames as signals.
3. Read `.tac/state.json` if it exists — check `active_milestone`, `active_phase` fields.
4. Output a status block:

```
Roadmap Status
──────────────
Milestone : v1.0 — <goal>
Phase     : 2 / 4
Progress  : 50%
Active    : Phase 2 — <description>

Completed phases:
  ✓ Phase 1 — <description>

Remaining phases:
  ○ Phase 2 — <description>  ← ACTIVE
  ○ Phase 3 — <description>
  ○ Phase 4 — <description>

Success Criteria (v1.0):
  ✓ <criterion 1>
  ○ <criterion 2>
  ○ <criterion 3>

Blockers: none
```

5. If there are open todos in `.tac/todos.json` tagged as `bug` with `priority: high`, list them under Blockers.

---

## `/tac-roadmap next`

**Purpose:** Advance to the next phase, or complete the milestone and begin the next one.

**Steps:**

1. Read `.tac/ROADMAP.md` and `.tac/state.json` to determine current phase and milestone.
2. **Completeness check:** Verify the current phase is done.
   - Look in `.tac/history/` for features that correspond to this phase.
   - If the current phase has no corresponding completed feature, warn the user:
     > "Phase X appears incomplete — no features logged for this phase. Are you sure you want to advance?"
   - Ask for confirmation before continuing.
3. **Mark current phase complete:** Update ROADMAP.md — check off the current phase `[x]`.
4. **Determine next step:**
   - If more phases remain in the current milestone: set next phase as active. Update `## Active:` line in ROADMAP.md.
   - If all phases are complete: run the **Milestone Validation Gate** (see below).
5. **Milestone Validation Gate** (only when all phases done):
   - Read the success criteria for the current milestone.
   - For each criterion: assess whether it appears to be met based on existing code, history files, and feature descriptions. Flag any that cannot be verified automatically.
   - Present results:
     ```
     Milestone v1.0 Validation Gate
     ───────────────────────────────
     ✓ <criterion 1> — verified via <source>
     ✓ <criterion 2> — verified via <source>
     ? <criterion 3> — cannot auto-verify; please confirm manually
     ```
   - If any criteria are unmet or unverifiable, ask the user to confirm before closing the milestone.
   - On confirmation: mark milestone complete in ROADMAP.md, archive milestone data to `.tac/history/milestone-v1.0.md`, set next milestone as active.
6. Update `.tac/state.json` with new active milestone and phase.
7. Output the new status using the same format as `status`.

---

## `/tac-roadmap add-phase <description>`

**Purpose:** Insert a new phase at the end of the current milestone.

**Steps:**

1. Read `.tac/ROADMAP.md`. Identify the current milestone block.
2. Find the last phase listed in that milestone.
3. Append a new phase with the next sequential number and the given description.
4. Write the updated ROADMAP.md.
5. Confirm: "Added Phase N: <description> to milestone vX.X."

**Rules:**
- New phases are always appended (not inserted in the middle) to avoid renumbering.
- Do not allow adding phases to a completed milestone.

---

## General Rules

- ROADMAP.md is the single source of truth for milestone and phase state.
- Milestones use semantic versioning: v1.0, v1.1, v2.0.
- Phases are numbered sequentially within each milestone and reset per milestone.
- Success criteria must be verifiable statements — reject vague ones and ask for specifics.
- Never silently advance past incomplete work — always surface the gap and ask.
- All state changes must be reflected in both ROADMAP.md (human-readable) and `.tac/state.json` (machine-readable).

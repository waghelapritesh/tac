---
name: tac-todo
description: Zero-friction idea capture — add todos, notes, and seeds; list and promote backlog items into full TAC features
argument-hint: "add <text> | list | done <id> | promote <id> | note <text> | seed <text> --trigger <condition>"
---

# TAC Todo

Zero-friction backlog, notes, and idea management. Captures thoughts without interrupting active work. All data stored in `.tac/`.

## Subcommand Routing

Read the first argument to determine which subcommand to run:

- `add <text>` → Capture a new todo item
- `list` → Display open todos grouped by priority
- `done <id>` → Mark a todo as completed
- `promote <id>` → Convert a todo into a full TAC feature
- `note <text>` → Capture a quick non-actionable note
- `seed <text> --trigger <condition>` → Plant a forward-looking idea with a trigger condition

If no argument is given, run `list`.

---

## `/tac-todo add <text>`

**Purpose:** Capture a new todo item with auto-classification.

**Steps:**

1. Read the text provided.
2. **Auto-classify type** based on keywords and phrasing:
   - `bug` — keywords: broken, error, fails, crash, wrong, fix, not working, 500, null
   - `chore` — keywords: update, upgrade, cleanup, refactor, rename, move, remove, migrate, dependency
   - `idea` — keywords: maybe, consider, could, what if, explore, try, experiment
   - `feature` — anything else describing new capability or behavior
3. **Auto-assign priority** based on keywords:
   - `high` — urgent, critical, blocking, asap, broken, crash, production
   - `low` — someday, maybe, eventually, low priority, nice to have
   - `medium` — everything else
4. Generate a short unique ID: `todo-<YYYYMMDD>-<NNN>` (date + 3-digit sequence, e.g., `todo-20260425-001`).
5. Read `.tac/todos.json` (create if absent, start with `[]`).
6. Append a new entry:
   ```json
   {
     "id": "todo-20260425-001",
     "text": "<original text>",
     "type": "<bug|feature|chore|idea>",
     "priority": "<high|medium|low>",
     "status": "open",
     "created_at": "<ISO timestamp>"
   }
   ```
7. Write `.tac/todos.json`.
8. Confirm: `Added [<type>/<priority>] <id>: "<text>"`

---

## `/tac-todo list`

**Purpose:** Show all open todos, grouped by priority.

**Steps:**

1. Read `.tac/todos.json`. If absent or empty, output: "No open todos."
2. Filter to `status: "open"` items only.
3. Calculate age in days from `created_at` to today.
4. Group by priority (high → medium → low). Within each group, sort by age (oldest first).
5. Output in this format:

```
Open Todos (12 total)
══════════════════════

HIGH (2)
  [bug]     todo-20260425-001  Fix login redirect loop          — 3d ago
  [feature] todo-20260420-007  Add export to CSV on orders page — 8d ago

MEDIUM (7)
  [feature] todo-20260422-003  Barcode scan on GRN form         — 6d ago
  [chore]   todo-20260418-002  Upgrade Django to 5.1            — 10d ago
  ...

LOW (3)
  [idea]    todo-20260410-001  Consider dark mode               — 18d ago
  ...
```

6. If there are seeds in `.tac/seeds.json` whose trigger conditions match the current context (read `.tac/state.json` for current feature/phase), append:
```
Seeds surfaced (1):
  seed-001: "Add rate limiting" — trigger: "when working on auth" ← ACTIVE CONTEXT MATCH
```

---

## `/tac-todo done <id>`

**Purpose:** Mark a todo as completed.

**Steps:**

1. Read `.tac/todos.json`.
2. Find the item with matching `id`. If not found, output an error listing available IDs.
3. Set `status: "done"` and add `"completed_at": "<ISO timestamp>"`.
4. Write `.tac/todos.json`.
5. Confirm: `Marked done: <id> — "<text>"`

---

## `/tac-todo promote <id>`

**Purpose:** Convert a todo into a full TAC feature and start its pipeline.

**Steps:**

1. Read `.tac/todos.json`. Find the item by `id`. If not found, error.
2. Confirm with the user: "Promote this todo to a TAC feature? This will start the pipeline for: '<text>'"
3. On confirmation:
   a. Mark the todo as `status: "promoted"` with `"promoted_at": "<ISO timestamp>"` in todos.json.
   b. Invoke `/tac-new` with the todo's text as the feature description.
4. Output: "Promoted <id> to TAC feature. Pipeline started."

**Note:** The todo is not deleted — it is archived as `promoted` so the origin is traceable.

---

## `/tac-todo note <text>`

**Purpose:** Capture a quick non-actionable note.

**Steps:**

1. Read `.tac/notes.md` (create if absent).
2. Append a new entry at the bottom:
   ```markdown
   <!-- 2026-04-25T14:32:00Z -->
   <text>
   ```
3. Write `.tac/notes.md`.
4. Confirm: `Note saved.`

**Rules:**
- Notes are append-only. Never edit or delete existing entries.
- Notes are context, not tasks. They should not appear in `list`.

---

## `/tac-todo seed <text> --trigger <condition>`

**Purpose:** Plant a forward-looking idea with a trigger condition so it surfaces at the right moment.

**Steps:**

1. Parse the text and trigger condition from the arguments. The `--trigger` flag separates them.
   - Example: `/tac-todo seed "Add rate limiting" --trigger "when working on auth"`
2. Generate ID: `seed-<YYYYMMDD>-<NNN>`
3. Read `.tac/seeds.json` (create if absent, start with `[]`).
4. Append:
   ```json
   {
     "id": "seed-20260425-001",
     "text": "<idea text>",
     "trigger": "<trigger condition>",
     "status": "dormant",
     "created_at": "<ISO timestamp>"
   }
   ```
5. Write `.tac/seeds.json`.
6. Confirm: `Seed planted: "<text>" — surfaces when: <trigger>`

**Trigger evaluation (automatic, runs at start of `/tac-new` and `/tac-build`):**

At the beginning of any `/tac-new` or `/tac-build` invocation, read `.tac/seeds.json` and check each dormant seed:
- Compare the seed's trigger condition against the current feature description and active phase (from `.tac/state.json`).
- If there is a semantic match (e.g., trigger says "auth" and current feature involves login), surface the seed:
  ```
  Seed surfaced: seed-20260425-001
  ─────────────────────────────────
  Idea: "Add rate limiting"
  Trigger matched: "when working on auth"

  Include this in current feature? (yes / no / snooze)
  ```
- On "yes": convert to a todo via `add` then `promote`.
- On "snooze": keep dormant but log the snooze with a timestamp.
- On "no": mark seed as `dismissed`.

---

## General Rules

- Todos are lightweight — one line of text each. No subtasks, no descriptions. If it needs a description, it should be a TAC feature, not a todo.
- Notes are append-only and never appear in the todo list.
- Seeds have trigger conditions and stay dormant until context matches.
- All state files live in `.tac/`: `todos.json`, `notes.md`, `seeds.json`.
- IDs are deterministic and date-prefixed for easy sorting and tracing.

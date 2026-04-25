---
name: tac-undo
description: Safely revert TAC-generated changes using git revert — never destructive, always dependency-aware
argument-hint: ""
---

# TAC Undo

Safely roll back TAC-generated commits using `git revert`. Never uses `git reset --hard`. Always dependency-aware. Always runs tests after.

## Process

### Step 1: Show Recent TAC Commits

Run `git log --oneline -20` and filter for commits whose messages start with `feat(`, `fix(`, or `test(`. Present them in a numbered list:

```
Recent TAC commits:
───────────────────
1. abc1234  feat(payments): wave 3 — templates + CSS      (3 files)
2. def5678  feat(payments): wave 2 — API + URLs           (4 files)
3. ghi9012  feat(payments): wave 1 — models + serializers (6 files)
4. jkl3456  fix(auth): correct JWT expiry handling        (1 file)
5. mno7890  feat(stock): add bulk transfer form           (5 files)
```

For each commit, show the file count by running `git show --stat <sha> | tail -1`.

If no TAC commits are found in the last 20 commits, say so and stop.

---

### Step 2: User Selects Target

Ask the user:
```
Which commit(s) to undo?
  • Enter a single number (e.g., 2) to undo one commit
  • Enter a range (e.g., 1-3) to undo a full feature (newest to oldest)
  • Enter 'cancel' to abort
```

Wait for the user's response. Do not proceed without explicit input.

---

### Step 3: Dependency Check

Before reverting, scan for dependencies:

1. Collect the list of files changed by the target commit(s):
   ```
   git show --name-only <sha> | grep -v '^commit\|^Author\|^Date\|^$\|^    '
   ```
   For a range, collect files across all target commits.

2. Find any **later** commits (commits newer than the target) that also touched those same files:
   ```
   git log --oneline <sha>..HEAD -- <file1> <file2> ...
   ```

3. If later commits touch the same files, warn the user:
   ```
   Dependency Warning
   ──────────────────
   The following later commits also modified files in the target commit.
   Reverting may cause conflicts:

   - pqr1234  feat(payments): wave 4 — email notifications  → touches: payments/views.py
   - stu5678  fix(payments): hotfix for currency rounding    → touches: payments/models.py

   Do you want to continue anyway? (yes / no)
   ```

4. If no dependencies found, confirm: "No dependency conflicts found. Proceeding."

If the user responds "no", abort cleanly: "Undo cancelled."

---

### Step 4: Revert

**Single commit:**
```bash
git revert <sha> --no-edit
```

**Range (e.g., undo commits 1–3, where 1 is newest):**

Revert in order from newest to oldest to minimize conflicts:
```bash
git revert <sha-newest> --no-edit
git revert <sha-middle> --no-edit
git revert <sha-oldest> --no-edit
```

**If conflicts occur during revert:**
- Stop immediately. Do NOT attempt to auto-resolve.
- Show the conflicted files:
  ```
  Revert conflict — manual resolution required
  ─────────────────────────────────────────────
  Conflicted files:
    - payments/views.py
    - payments/models.py

  To resolve:
    1. Edit the conflicted files manually
    2. Run: git add <files>
    3. Run: git revert --continue
    4. Then re-run /tac-undo to verify and update state
  ```
- Do not update `.tac/state.json` until the revert is fully completed.

---

### Step 5: Run Tests

After a successful revert, run the project's test suite:

1. Check if a test command is defined in `.tac/state.json` under `"test_command"`. If not, try common defaults in order:
   - `python manage.py test`
   - `pytest`
   - `npm test`
   - `yarn test`

2. Run the command and capture output.

3. Report results:
   ```
   Test Results After Revert
   ──────────────────────────
   ✓ All 47 tests passed.
   ```
   or:
   ```
   Test Results After Revert
   ──────────────────────────
   ✗ 3 tests failed:
     - tests/test_payments.py::test_checkout_flow
     - tests/test_payments.py::test_refund_logic
     - tests/test_auth.py::test_login_redirect

   The revert introduced test failures. Review before proceeding.
   ```

4. Do not block on test failures — surface them and let the user decide.

---

### Step 6: Update TAC State

If the revert completed without conflicts:

1. Read `.tac/state.json`.
2. Check if the reverted commit(s) correspond to a complete feature (all waves of a feature were undone):
   - If yes: find the feature entry in state.json and mark it as `"status": "rolled_back"` with `"rolled_back_at": "<ISO timestamp>"`.
   - If only partial (some waves undone): add a note to the feature: `"partial_rollback": true`.
3. Write `.tac/state.json`.
4. Confirm:
   ```
   Undo complete
   ─────────────
   Reverted: feat(payments): wave 1–3
   Feature status: rolled_back
   Tests: 47/47 passed
   ```

---

## Rules

- NEVER use `git reset --hard` for any reason.
- Always use `git revert` — this creates a new commit, preserving history.
- Always check for downstream dependencies before reverting.
- Always run tests after a successful revert.
- Never auto-resolve conflicts — surface them and stop.
- Never proceed without user confirmation when dependencies are found.
- Update `.tac/state.json` only after the revert fully completes without conflicts.
- If the user cancels at any point, output "Undo cancelled." and stop cleanly.

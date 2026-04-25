---
name: tac-worktree
description: Use when you want full git isolation for a feature — creates a separate worktree so main branch stays clean while you build
argument-hint: "create | status | merge | cleanup [feature-slug]"
---

# TAC Worktree — Git Worktree Isolation

Build features in a fully isolated git worktree. Main branch stays clean. No context bleed between features.

## Commands

### `create` — Set up an isolated worktree

Usage: `/tac-worktree create`

1. Check the current branch is clean:
   ```
   git status --porcelain
   ```
   If there are uncommitted changes: STOP. Tell the user to commit or stash first.

2. Determine the feature slug:
   - Read `.tac/state.json` → get `current_feature`
   - If no active feature: ask for a slug (lowercase, hyphens only, e.g. `price-export`)

3. Create the worktree:
   ```
   git worktree add .tac/worktrees/{feature-slug} -b tac/{feature-slug}
   ```

4. Confirm the worktree was created:
   ```
   git worktree list
   ```

5. Update `.tac/state.json`:
   ```json
   {
     "worktree": {
       "active": true,
       "path": ".tac/worktrees/{feature-slug}",
       "branch": "tac/{feature-slug}",
       "base_branch": "{original-branch}",
       "created_at": "{timestamp}"
     }
   }
   ```

6. Output:
   ```
   Worktree created:
     Path:   .tac/worktrees/{feature-slug}
     Branch: tac/{feature-slug}
     Base:   {base-branch}

   All pipeline work will run in the worktree.
   Main branch is untouched.
   ```

### `status` — Show active worktrees

Usage: `/tac-worktree status`

1. Run: `git worktree list`
2. Read `.tac/state.json` → get worktree metadata
3. For each TAC worktree (those under `.tac/worktrees/`):
   - Show branch name, creation date, current stage from state
4. Output a clean summary:
   ```
   Active Worktrees:
     tac/price-export   .tac/worktrees/price-export   [DESIGN stage]
     tac/grn-v2         .tac/worktrees/grn-v2          [AUTO stage]
   ```

### `merge` — Squash merge worktree back to parent branch

Usage: `/tac-worktree merge [feature-slug]`

1. Identify the worktree to merge (from argument or `.tac/state.json`)
2. Read base branch from `.tac/state.json` → `worktree.base_branch`
3. Confirm with user: "Merging tac/{feature-slug} into {base-branch} as a single squash commit. Proceed?"
4. Switch to base branch: `git checkout {base-branch}`
5. Squash merge: `git merge --squash tac/{feature-slug}`
6. Stage all changes: `git add -A`
7. Prompt user for commit message or generate one:
   - Read `.tac/history/{feature-slug}/DESIGN.md` for context
   - Generate: `feat({feature-slug}): {one-line summary from design}`
8. Commit: `git commit -m "{message}"`
9. Output:
   ```
   Merged:
     From:   tac/{feature-slug}
     Into:   {base-branch}
     Commit: {commit-hash} — {message}

   Run /tac-worktree cleanup to remove the worktree.
   ```

### `cleanup` — Remove completed worktrees

Usage: `/tac-worktree cleanup [feature-slug]`

1. Identify the worktree to remove (from argument or prompt user to choose)
2. Confirm: "Remove worktree at .tac/worktrees/{feature-slug} and delete branch tac/{feature-slug}?"
3. Remove the worktree:
   ```
   git worktree remove .tac/worktrees/{feature-slug}
   ```
4. Delete the branch:
   ```
   git branch -d tac/{feature-slug}
   ```
5. Update `.tac/state.json` — clear the `worktree` block if this was the active one
6. Output:
   ```
   Cleanup complete:
     Worktree removed: .tac/worktrees/{feature-slug}
     Branch deleted:   tac/{feature-slug}
   ```

## Rules

- Never create a worktree on a dirty working tree — always check first
- Worktrees live under `.tac/worktrees/` — do not put them anywhere else
- The branch prefix is always `tac/` — keeps TAC branches identifiable
- Always squash merge (not regular merge) — keeps main branch history clean
- After merge + cleanup, the feature work exists as one clean commit on the base branch
- If worktree path already exists: stop, show error, do not overwrite

## State

All worktree metadata is stored in `.tac/state.json` under the `worktree` key. This lets `/tac-go` resume knowing whether we're in a worktree context.

---
name: tac-init
description: Use when starting TAC in a new project — initializes .tac/ directory with stack detection, project config, and state tracking
argument-hint: "[stack-name]"
---

# TAC Init

Initialize TAC in the current project. Creates `.tac/` directory with stack detection and project configuration.

## Process

1. Check if `.tac/` already exists
   - If yes: show current config, ask if user wants to reset
   - If no: proceed with initialization

2. Detect tech stack by scanning the codebase:
   - `manage.py` + `inventree_patches/` → `django-ims`
   - `manage.py` without inventree → `django-fresh`
   - `package.json` + `tailwind.config` → `react-full`
   - None detected → ask user to pick or describe

3. If argument provided (e.g., `/tac-init django-ims`), use that stack directly

4. Create directory structure:
   ```
   .tac/
   ├── project.json
   ├── state.json
   ├── stacks/
   ├── history/
   ├── safety/
   ├── context/
   └── ui/
   ```

5. Write `project.json`:
   ```json
   {
     "name": "<detected from directory name or git remote>",
     "stack": "<detected or chosen stack>",
     "profile": "balanced",
     "initialized_at": "<ISO timestamp>"
   }
   ```

6. Write `state.json`:
   ```json
   {
     "feature": null,
     "stage": null,
     "step": 0,
     "total_steps": 0
   }
   ```

7. Copy matching stack profile from `~/.claude/tac/stacks/` to `.tac/stacks/`

8. Add `.tac/` to `.gitignore` if not already present

9. Confirm: "TAC initialized for {project} with {stack} stack. Run `/tac-new` to start your first feature."

## Anti-Hallucination

- NEVER assume the stack — scan for real files or ask
- NEVER create files outside `.tac/` directory
- Read `.gitignore` before modifying it

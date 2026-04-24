# TAC Init Workflow

## Objective

Initialize `.tac/` project directory with stack detection and configuration.

## Steps

### Step 1: Check Existing State

```
IF .tac/ exists AND .tac/project.json exists:
  Read and display current config
  Ask: "TAC is already initialized. Reset? [y/N]"
  IF no: exit
  IF yes: remove .tac/ and continue
```

### Step 2: Detect Stack

Scan the current project directory for stack clues:

```
Priority order:
1. manage.py + inventree_patches/ directory → "django-ims"
2. manage.py + no inventree_patches/ → "django-fresh"  
3. package.json + (tailwind.config.js OR tailwind.config.ts) → "react-full"
4. package.json + next.config.* → "next-js"
5. requirements.txt OR pyproject.toml (without manage.py) → "python-api"
6. Nothing detected → ask user
```

Use Glob tool to check for these files. Do NOT assume they exist.

### Step 3: Confirm Stack

Display detected stack and ask for confirmation:
```
"Detected stack: django-ims (Django + InvenTree Patches)"
"Is this correct? [Y/n]"
```

If user says no, present available stacks from ~/.claude/tac/stacks/ and let them pick.

### Step 4: Create Directories

```bash
mkdir -p .tac/{stacks,history,safety,context,ui}
```

### Step 5: Write project.json

Read the project name from:
1. Git remote URL (parse repo name)
2. Directory name as fallback

```json
{
  "name": "<project-name>",
  "stack": "<stack-name>",
  "profile": "balanced",
  "models": {
    "ask": "opus",
    "design": "opus",
    "safe": "haiku",
    "auto_plan": "sonnet",
    "auto_code": "opus",
    "auto_verify": "haiku",
    "status": "haiku"
  },
  "initialized_at": "<ISO timestamp>"
}
```

### Step 6: Write state.json

```json
{
  "feature": null,
  "stage": null,
  "step": 0,
  "total_steps": 0,
  "stack": "<stack-name>"
}
```

### Step 7: Copy Stack Profile

Copy the matching stack profile from ~/.claude/tac/stacks/{stack}.json to .tac/stacks/{stack}.json.

If no matching built-in stack exists, create a minimal profile by scanning the codebase for conventions.

### Step 8: Update .gitignore

Read .gitignore. If `.tac/` is not listed, append it:
```
# TAC project state
.tac/
```

### Step 9: Confirm

Output:
```
TAC initialized for {name} with {stack} stack.

  Project: {name}
  Stack:   {stack}
  Profile: balanced
  State:   .tac/

Run /tac-new "your idea" to start your first feature.
```

## Guardrails

- Never assume stack — always verify files exist
- Never modify files outside .tac/ except .gitignore
- If git remote fails, use directory name — don't error
- Handle Windows paths (backslash) gracefully

---
name: tac-stack
description: Use when managing tech stack profiles — add, list, edit, or switch stack profiles for the current project
argument-hint: "[add|list|show|switch] [stack-name]"
---

# TAC Stack

Manage tech stack profiles for TAC projects.

## Subcommands

### `list`

Show all available stack profiles from both locations:
- **Global stacks**: `~/.claude/tac/stacks/*.json`
- **Project stacks**: `.tac/stacks/*.json` (if a TAC project exists)

Display each stack with its name and a brief description. Mark the currently active stack (from `.tac/project.json`) with an arrow indicator.

### `show <name>`

Display the full stack profile details for the named stack. Look up by name in both global and project stacks (project overrides global if same name). Show:
- Stack name and description
- Languages and frameworks
- Key libraries and tools
- File structure conventions
- Any custom rules or constraints

### `add`

Interactive stack profile creation:

1. **Scan the codebase** for clues — look at package.json, requirements.txt, Cargo.toml, go.mod, Gemfile, pyproject.toml, settings files, and directory structure.
2. **Present findings** to the user: "I detected: Python 3.11, Django 4.2, PostgreSQL, Redis, nginx..."
3. **Ask clarifying questions** about anything ambiguous (e.g., "Is this a monolith or microservices?", "Which test framework?").
4. **Generate the stack profile** as a JSON file and save to `.tac/stacks/<name>.json`.
5. **Offer to set as active** in `.tac/project.json`.

Stack profile JSON schema:
```json
{
  "name": "string",
  "description": "string",
  "languages": ["string"],
  "frameworks": ["string"],
  "databases": ["string"],
  "tools": ["string"],
  "conventions": {
    "file_structure": "string",
    "naming": "string",
    "testing": "string"
  },
  "custom_rules": ["string"]
}
```

### `switch <name>`

Change the active stack in `.tac/project.json`:

1. Verify the named stack exists (check project stacks first, then global).
2. Update `.tac/project.json` by setting the `"stack"` key to the new name.
3. Confirm the switch: "Stack switched to {name}."

## Error Handling

- If no `.tac/` directory exists for project-level commands (`add`, `switch`): "No TAC project found. Run /tac-init first."
- If stack name not found for `show` or `switch`: "Stack '{name}' not found. Run /tac-stack list to see available stacks."
- If `.tac/project.json` is missing or malformed: create it with sensible defaults.

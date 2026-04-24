---
name: tac-settings
description: Use when configuring TAC behavior — model profiles, auto-behaviors, project defaults, AI provider settings
---

# TAC Settings Manager

Interactive settings manager for TAC configuration. Reads/writes two config files:
- **Project-level**: `.tac/project.json` (in current project root)
- **Global**: `~/.tac/settings.json` (user-wide defaults)

Project settings override global settings when both exist.

## Subcommand Routing

Parse the argument to determine which subcommand to run:

| Argument | Action |
|----------|--------|
| *(none)* | Show all current settings |
| `provider` | Change AI provider config |
| `profile` | Change model profile |
| `auto` | Toggle auto-behavior flags |
| `project` | Change project defaults |
| `ui` | Change UI preferences |
| `reset` | Reset all settings to defaults |

## Settings Categories & Defaults

### 1. AI Provider
```json
{
  "ai_provider": {
    "provider": "claude",
    "default_model": "opus"
  }
}
```
- `provider`: one of `claude`, `openai`, `both`
- `default_model`: model name string (e.g., `opus`, `sonnet`, `gpt-4o`)

### 2. Model Profile
```json
{
  "model_profile": {
    "active": "balanced",
    "per_stage": {}
  }
}
```
- `active`: one of `quality`, `balanced`, `fast`, `budget`, `custom`
- `per_stage`: optional overrides keyed by stage name (e.g., `{"ask": "quality", "design": "balanced", "build": "fast"}`)

Profile presets:
- **quality**: opus for all stages
- **balanced**: opus for ask/design, sonnet for build/test
- **fast**: sonnet for all stages
- **budget**: haiku for all stages
- **custom**: uses per_stage overrides

### 3. Auto Behaviors
```json
{
  "auto_behaviors": {
    "auto_spawn": true,
    "auto_tdd": false,
    "auto_mobile": false,
    "auto_docs": false,
    "auto_safe": true
  }
}
```
- `auto_spawn`: automatically spawn subagents for parallel work
- `auto_tdd`: run TDD cycle automatically during build
- `auto_mobile`: include mobile-responsive checks
- `auto_docs`: auto-generate docs after features
- `auto_safe`: run safety checks before deploy

### 4. Project Defaults
```json
{
  "project_defaults": {
    "default_stack": "django",
    "deploy_test_first": true,
    "git_auto_commit": false,
    "branch_strategy": "feature-branch"
  }
}
```
- `default_stack`: detected or configured stack name
- `deploy_test_first`: deploy to test env before production
- `git_auto_commit`: auto-commit after each phase
- `branch_strategy`: one of `feature-branch`, `trunk`, `gitflow`

### 5. UI Preferences
```json
{
  "ui_preferences": {
    "save_ui_on_approval": true
  }
}
```
- `save_ui_on_approval`: persist UI sketch artifacts when user approves

## Execution Steps

### Step 1: Load Current Settings

1. Read `~/.tac/settings.json` (global). If missing, use defaults above.
2. Read `.tac/project.json` (project). If missing, use empty object.
3. Merge: project overrides global for any key that exists in both.

### Step 2: Route by Subcommand

#### No args — Show All Settings

Display a clean table of ALL settings grouped by category:

```
TAC Settings
============

Source: ~/.tac/settings.json (global) + .tac/project.json (project)

AI Provider
  provider          claude          (global)
  default_model     opus            (global)

Model Profile
  active            balanced        (project)
  per_stage.ask     quality         (project)
  per_stage.build   fast            (project)

Auto Behaviors
  auto_spawn        true            (global)
  auto_tdd          false           (global)
  auto_mobile       false           (global)
  auto_docs         false           (global)
  auto_safe         true            (global)

Project Defaults
  default_stack     django          (project)
  deploy_test_first true            (project)
  git_auto_commit   false           (global)
  branch_strategy   feature-branch  (global)

UI Preferences
  save_ui_on_approval true          (global)
```

Mark each value with `(global)` or `(project)` to show its source.

#### `provider` — Change AI Provider

Ask the user:
1. Which provider? (claude / openai / both)
2. Default model name?

Write to the appropriate config file (ask user: global or project-level?).

#### `profile` — Change Model Profile

Ask the user:
1. Which profile? (quality / balanced / fast / budget / custom)
2. If custom: ask for per-stage overrides (ask / design / build / test)

Write to config.

#### `auto` — Toggle Auto Behaviors

Show current auto-behavior flags with toggle numbers:
```
Auto Behaviors (toggle by number):
  [1] auto_spawn    true
  [2] auto_tdd      false
  [3] auto_mobile   false
  [4] auto_docs     false
  [5] auto_safe     true
```

Ask which to toggle. Flip the boolean. Write to config.

#### `project` — Change Project Defaults

Ask about each project default, showing current value. Only update values the user wants to change.

#### `ui` — Change UI Preferences

Ask about UI preference settings, showing current values.

#### `reset` — Reset to Defaults

Ask user: reset global, project, or both?
- Global: write defaults to `~/.tac/settings.json`
- Project: delete `.tac/project.json` (or write empty object)
- Both: do both

Confirm before resetting.

### Step 3: Write Changes

- Use the Write tool to update the appropriate JSON file
- Always pretty-print JSON with 2-space indent
- Create parent directories if they don't exist
- After writing, display the updated value to confirm

## Important Rules

- NEVER modify settings without user confirmation
- Always show the current value before asking for a new one
- Use `mcp__gsd-workflow__ask_user_questions` or direct conversation to gather input
- Project settings file is `.tac/project.json` relative to project root
- Global settings file is `~/.tac/settings.json` (expand `~` to user home)
- If a config file doesn't exist yet, create it with just the changed values (don't write full defaults unless `reset`)

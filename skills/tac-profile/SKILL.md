---
name: tac-profile
description: Use when setting the model profile for TAC agents — quality, balanced, fast, or budget
argument-hint: "[quality|balanced|fast|budget|custom]"
---

# TAC Profile

Manage the model profile that controls which AI models TAC uses at each stage.

## Behavior

When invoked **without arguments**, display the current profile and model assignments from `.tac/project.json`.

When invoked **with a profile name**, switch to that profile and update `.tac/project.json`.

## Profiles

### `quality`
Opus everywhere. Maximum capability at every stage.

| Stage   | Model  |
|---------|--------|
| ASK     | Opus   |
| DESIGN  | Opus   |
| SAFE    | Opus   |
| AUTO    | Opus   |
| VERIFY  | Opus   |

### `balanced` (DEFAULT)
Opus for critical thinking, Haiku for routine checks.

| Stage   | Model  |
|---------|--------|
| ASK     | Opus   |
| DESIGN  | Opus   |
| SAFE    | Haiku  |
| AUTO    | Opus   |
| VERIFY  | Haiku  |

### `fast`
Sonnet everywhere, Haiku for checks. Optimized for speed.

| Stage   | Model  |
|---------|--------|
| ASK     | Sonnet |
| DESIGN  | Sonnet |
| SAFE    | Haiku  |
| AUTO    | Sonnet |
| VERIFY  | Haiku  |

### `budget`
Minimum cost. Opus only where it matters most.

| Stage   | Model  |
|---------|--------|
| ASK     | Sonnet |
| DESIGN  | Opus   |
| SAFE    | Haiku  |
| AUTO    | Sonnet |
| VERIFY  | Haiku  |

### `custom`
User specifies the model for each stage interactively. Ask for each stage in order:
1. ASK — which model?
2. DESIGN — which model?
3. SAFE — which model?
4. AUTO — which model?
5. VERIFY — which model?

Valid model choices: `opus`, `sonnet`, `haiku`.

## Storage

Reads and writes `.tac/project.json`. The relevant keys are:

```json
{
  "profile": "balanced",
  "models": {
    "ASK": "opus",
    "DESIGN": "opus",
    "SAFE": "haiku",
    "AUTO": "opus",
    "VERIFY": "haiku"
  }
}
```

## Steps

1. **Check for `.tac/project.json`**. If missing: "No TAC project found. Run /tac-init first."
2. **If no argument**: read and display current profile and model table.
3. **If argument is a preset** (quality/balanced/fast/budget): apply the preset, update both `"profile"` and `"models"` keys, confirm.
4. **If argument is `custom`**: prompt for each stage, then save with `"profile": "custom"`.
5. **Display confirmation** showing the new model assignments table.

## Error Handling

- Unknown profile name: "Unknown profile '{name}'. Choose from: quality, balanced, fast, budget, custom."
- Missing `.tac/` directory: "No TAC project found. Run /tac-init first."
- Malformed `project.json`: overwrite the `profile` and `models` keys, preserving other keys.

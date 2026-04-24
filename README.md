# TAC -- Think. Architect. Code.

A Claude Code plugin for solo developers shipping to live production.

## Install

```bash
cd ~/.claude/tac && bash install.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `/tac-new "idea"` | Full pipeline: ASK -> DESIGN -> SAFE -> AUTO |
| `/tac-build "feature"` | Smart pipeline (skips ASK if clear) |
| `/tac-ask` | Q&A only -- explore a problem |
| `/tac-design` | Brainstorm + spec + plan |
| `/tac-safe` | Verify against codebase |
| `/tac-auto` | Execute existing plan |
| `/tac-go` | Resume from where you stopped |
| `/tac-status` | Show progress |
| `/tac-stack` | Manage tech stack profiles |
| `/tac-profile` | Set model profile |
| `/tac-init` | Initialize TAC in a project |

## Pipeline

```
ASK --> DESIGN --> SAFE --> AUTO
```

Every feature passes through 4 stages. No skipping. Each has a safety gate.

## Philosophy

1. **Safety first** -- nothing ships without proving it won't break production
2. **Verify, don't assume** -- read the codebase, never hallucinate
3. **Stack-aware** -- knows your tech and follows YOUR patterns

## Stack Profiles

TAC learns your tech stack and adapts all scaffolding, code generation, and deploy patterns accordingly. Built-in stacks: `django-ims`, `react-full`. Add your own with `/tac-stack add`.

## Author

Pritesh (Comprint)

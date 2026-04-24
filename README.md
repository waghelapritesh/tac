# TAC -- Think. Architect. Code.

A Claude Code plugin for solo developers shipping to live production.

## Install

```bash
git clone https://github.com/waghelapritesh/tac.git ~/.claude/tac
cd ~/.claude/tac && bash install.sh
```

## 6 Commands. That's It.

| Command | What it does |
|---------|-------------|
| `/tac-init` | Initialize TAC in a project (auto-detects stack) |
| `/tac-new "idea"` | Full pipeline: think -> build -> safe -> auto |
| `/tac-think "idea"` | Explore an idea (ASK + DESIGN, no coding) |
| `/tac-build "feature"` | Build a feature (smart gate -> design -> safe -> auto) |
| `/tac-go` | Resume from where you stopped |
| `/tac-safe` | Verify before deploy |

## Everything Else is Automatic

| Behavior | When | How |
|----------|------|-----|
| Stack detection | `/tac-init` | Scans codebase for Django/React/etc |
| TDD | Every build | Agents write tests FIRST, verify fail, then code |
| Parallel agents | 3+ independent tasks | Auto-spawns wave-based parallel execution |
| Mobile CSS | Every frontend task | Desktop + responsive built simultaneously |
| Safety checks | Before every deploy | File paths, services, core pages, DB schema |
| Resume | Session breaks | `.tac/context/pending.json` saves exact state |
| UI memory | User approves a design | Saved and reused for future pages |

## Pipeline

```
THINK (ASK + DESIGN) --> SAFE --> AUTO
```

## Philosophy

1. **Safety first** -- nothing ships without proving it won't break production
2. **Verify, don't assume** -- read the codebase, never hallucinate
3. **Stack-aware** -- knows your tech and follows YOUR patterns

## Stack Profiles

Built-in: `django-ims`, `react-full`. Auto-detected during `/tac-init`.

## Directory Structure

```
~/.claude/tac/
  skills/       6 user commands (installed to ~/.claude/skills/)
  internal/     7 auto-invoked behaviors (TDD, spawn, mobile, etc.)
  workflows/    Detailed execution logic
  hooks/        SessionStart status line
  stacks/       Built-in stack profiles
```

## Author

Pritesh (Comprint)

## License

MIT

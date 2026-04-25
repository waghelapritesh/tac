# Changelog

All notable changes to TAC are documented here.

## v5.1.0

- Context persistence: saves decisions, Q&A, design choices to `.tac/context/` — auto-restores on `/tac-go` resume
- Learnings system: auto-captures patterns from SAFE, sketch, debug, forensics — injects into agent prompts
- Cost tracking: tokens + cost per feature/stage/day/month in `.tac/costs.json` — visible in `/tac-do stats`
- `/tac-do learn` — view, add, remove project learnings
- `/tac-test-ui` — Playwright-based visual testing with auto-fix, integrated into AUTO waves

## v5.0.0

- Auto-wire engine: 12 skills auto-trigger at pipeline transitions
- `/tac-do <action>` catch-all command for advanced operations
- 6 core commands replace 20 — rest are auto-wired or accessed via `/tac-do`
- `/tac-ship` now runs full SAFE checks inline (no delegation)
- Progress bar at every pipeline transition
- Auto-triggers: spike, sketch, worktree, test-ui, debug, review, ship, roadmap, todo, stats, health, forensics

## v4.0.0

- 12 new skills bringing total to 20 commands
- `/tac-debug` — systematic 4-phase root-cause analysis with persistent state
- `/tac-worktree` — git worktree isolation per feature with squash merge
- `/tac-review` — code review (request + receive) with severity classification
- `/tac-ship` — safety + review + PR creation in one command
- `/tac-spike` — timeboxed experiments with hypothesis-verdict format
- `/tac-sketch` — 2-3 HTML mockup variants for visual UI decisions
- `/tac-roadmap`, `/tac-todo`, `/tac-undo`, `/tac-forensics`, `/tac-health`, `/tac-stats`

## v3.0.0

- TAC Telegram Bot — full-featured hosted bot with multi-user support
- PostgreSQL + Redis persistence for projects, features, conversations
- 4-stage pipeline via AI API (ASK, DESIGN, SAFE stages server-side)
- WebSocket bridge (`tac-bridge` npm package) for remote AUTO execution
- Cost tracking with daily per-user and global caps
- Admin system, rate limiting, encrypted API key storage
- Channel plugin support for Telegram/Discord/iMessage

## v2.0.0

- `/tac-login` — authenticate with any AI provider, store keys in ~/.tac/auth.json
- `/tac-settings` — configure model profiles, auto-behaviors, AI provider, project defaults
- Multi-provider support: Claude, OpenAI, Gemini, Mistral, Groq, Ollama, Cohere, DeepSeek, xAI Grok, and any OpenAI-compatible API
- `install.ps1` — Windows PowerShell installer
- Status line hook for CLI

## v1.x

- 6 core commands: init, new, think, build, go, safe
- 7 auto-invoked internal behaviors
- Auto-TDD, auto-spawn parallel agents, auto-mobile responsive CSS, auto-docs
- Wave-based parallel agent execution
- 2 built-in stack profiles: django-ims, react-full

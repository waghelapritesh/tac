# TAC -- Think. Architect. Code.

A Claude Code plugin system for solo developers shipping to live production. TAC combines adaptive Q&A, collaborative brainstorming, safety-first verification, and autonomous execution into one seamless pipeline.

> "You say what to build. TAC figures out how, verifies it's safe, and builds it."

---

## Quick Start

```bash
# Clone
git clone https://github.com/waghelapritesh/tac.git ~/.claude/tac

# Install (creates symlinks to ~/.claude/skills/)
cd ~/.claude/tac && bash install.sh

# Initialize in your project
cd /path/to/your/project
# Then in Claude Code:
/tac-init
```

---

## Pipeline

Every feature flows through 4 stages. No skipping. Each has a safety gate.

```
  THINK            SAFE             AUTO
  (ASK + DESIGN)   (Verify)         (Build)
  
  "What are we     "Will this       "Building...
   building?"       break anything?" Wave 1: 4 agents
                                     Wave 2: 2 agents
  Q&A with you     Checks files,    Done. Tests pass.
  Brainstorm 2-3   services, DB,    Committed."
  approaches       core pages
  Write spec       
  Write plan       PASS --> GO
                   BLOCK --> FIX
```

---

## 6 Commands. That's It.

| Command | What it does | When to use |
|---------|-------------|-------------|
| `/tac-init` | Initialize TAC in a project | First time in a new project |
| `/tac-new "idea"` | Full pipeline: think -> safe -> auto | Starting from a vague idea |
| `/tac-think "idea"` | Explore only (ASK + DESIGN, no coding) | When you want to brainstorm without committing |
| `/tac-build "feature"` | Smart pipeline (skips ASK if clear) | When you know what you want |
| `/tac-go` | Resume from where you stopped | Returning after a break |
| `/tac-safe` | Verify before deploy | Manual safety check anytime |

---

## Everything Else is Automatic

You don't invoke these -- TAC does it for you.

| Behavior | What happens | When |
|----------|-------------|------|
| **Auto-TDD** | Every agent writes tests FIRST (RED), then code (GREEN) | Every build task |
| **Auto-Spawn** | Parallel agents for independent tasks (wave-based) | Plan has 3+ tasks |
| **Auto-Mobile** | Desktop + responsive CSS built simultaneously | Every frontend task |
| **Auto-Docs** | PRD.md + SOP.md generated from your answers | After DESIGN completes |
| **Auto-Safe** | File paths, services, core pages, DB schema verified | Before every deploy |
| **Auto-Resume** | Exact checkpoint saved to `.tac/context/pending.json` | Session break or interrupt |
| **UI Memory** | Design patterns saved when you approve a page's look | User says "looks good" |

---

## Three Laws

1. **Safety first** -- nothing ships without proving it won't break production
2. **Verify, don't assume** -- read the codebase, never hallucinate
3. **Stack-aware** -- knows your tech and follows YOUR patterns

---

## Stack Profiles

TAC adapts all scaffolding, code generation, and deployment to your tech stack. It detects your stack automatically during `/tac-init`.

**Built-in profiles:**

| Stack | What it covers |
|-------|---------------|
| `django-ims` | Django + InvenTree patches, paramiko SSH deploy, managed=False models |
| `react-full` | React + Tailwind + TypeScript + Python API + Postgres |

**Add your own:** TAC scans your codebase and learns your patterns. First project in a new stack requires a scan; subsequent projects reuse the profile.

Each profile includes:
- File scaffolding paths (where models, views, templates go)
- Code conventions (API style, auth patterns, FK style)
- Deploy configuration (SSH, Docker, Vercel, etc.)
- Safety rules (core pages, frozen areas, service names)
- Mobile CSS patterns (breakpoints, responsive approach)

---

## How Auto-Spawn Works

When a plan has 3+ independent tasks, TAC builds them in parallel:

```
/tac-new "payments page"

Wave 1 (4 parallel agents):
  Agent 1: test_models.py -> FAIL -> models.py -> PASS
  Agent 2: test_serializers.py -> FAIL -> serializers.py -> PASS
  Agent 3: admin.py
  Agent 4: deploy_payments.py
  Committed: "feat(payments): wave 1"

Wave 2 (2 parallel agents):
  Agent 5: test_api.py -> FAIL -> api.py -> PASS
  Agent 6: urls.py
  Committed: "feat(payments): wave 2"

Wave 3 (3 parallel agents):
  Agent 7: templates/payments/index.html (desktop + mobile)
  Agent 8: payments-mobile.css
  Agent 9: test_payments_api.py
  Committed: "feat(payments): wave 3"

Wave 4 (sequential -- shared files):
  Register in settings.py + urls.py + navbar
  Committed: "feat(payments): wave 4"
```

---

## Anti-Hallucination

TAC agents are trained to never make things up:

- **Read before write** -- scan existing code patterns before generating
- **Grep before assume** -- verify files/endpoints exist
- **Test before claim** -- run tests, don't just say "it works"
- **Cite file paths** -- every claim about the codebase must reference a real file

If SAFE finds a hallucinated path, import, or service name: **BLOCK**. No code ships.

---

## Project State

TAC maintains project state in `.tac/` (add to .gitignore):

```
.tac/
  project.json          Stack, profile, deploy targets
  state.json            Current feature + stage
  context/
    pending.json        Exact checkpoint for /tac-go resume
  history/
    {feature}.json      Q&A decisions, spec, plan, results
  stacks/
    {stack}.json        Tech stack conventions
  docs/
    {feature}/
      PRD.md            Product Requirements Document
      SOP.md            Standard Operating Procedure
  ui/
    preferences.json    Saved UI design patterns
```

---

## Model Profiles

Not every task needs the most expensive model. TAC routes intelligently:

| Profile | ASK | DESIGN | SAFE | Code | Verify |
|---------|-----|--------|------|------|--------|
| quality | Opus | Opus | Opus | Opus | Opus |
| **balanced** | Opus | Opus | Haiku | Opus | Haiku |
| fast | Sonnet | Sonnet | Haiku | Sonnet | Haiku |
| budget | Sonnet | Sonnet | Haiku | Haiku | Haiku |

Default: **balanced**

**Supported AI Providers:**

| Provider | Models | Notes |
|----------|--------|-------|
| Anthropic (Claude) | Opus, Sonnet, Haiku | Default provider |
| OpenAI | GPT-4o, GPT-4o-mini, o1, o3 | Full support |
| Google Gemini | Gemini 2.5 Pro/Flash | Via Google AI Studio or Vertex |
| Mistral | Large, Medium, Small | Via Mistral API |
| Groq | Llama, Mixtral | Ultra-fast inference |
| DeepSeek | DeepSeek-V3, Coder | Cost-effective |
| xAI | Grok 3/3-mini | Via xAI API |
| Cohere | Command R+ | Enterprise-focused |
| Ollama | Any local model | Fully offline, zero cost |
| OpenAI-compatible | Any | Custom endpoint via `/tac-settings` |

Configure via `/tac-login` or `/tac-settings`. Mix providers per stage (e.g., Opus for DESIGN, Groq for SAFE).

---

## Directory Structure

```
~/.claude/tac/
  skills/           8 user-facing commands (symlinked to ~/.claude/skills/)
    tac-init/         Initialize project
    tac-new/          Full pipeline orchestrator
    tac-think/        ASK + DESIGN (explore only)
    tac-build/        Smart gate + pipeline
    tac-go/           Resume from checkpoint
    tac-safe/         Pre-deploy verification
    tac-login/        Authenticate with Claude/OpenAI
    tac-settings/     Configure behavior + profiles
  internal/         7 auto-invoked behaviors (not installed as commands)
    tac-ask/          Adaptive Q&A engine
    tac-design/       Brainstorm + spec + plan
    tac-spawn/        Wave-based parallel execution
    tac-test/         TDD enforcement
    tac-status/       Progress dashboard
    tac-stack/        Stack profile management
    tac-profile/      Model profile management
  workflows/        Detailed execution logic
    ask.md            Q&A workflow
    design.md         Brainstorming workflow
    init.md           Initialization workflow
    resume.md         Checkpoint resume workflow
  hooks/            Claude Code integration
    tac-session-start.js    Status line display
  stacks/           Built-in stack profiles
    django-ims.json         Django + InvenTree
    react-full.json         React + Tailwind + TypeScript
  install.sh        Installation script
  README.md
  LICENSE           MIT
```

---

## Use TAC from Telegram, Discord, or iMessage

TAC works from your phone or any messaging app — two options depending on your needs:

### Option 1: Channel Plugin (Zero Setup)

Use Claude Code's built-in channel plugins to chat with TAC from any platform. No server needed.

```bash
# Install a channel plugin (e.g., Telegram)
claude plugins install telegram

# Start Claude Code with TAC
claude

# Now message your bot on Telegram — TAC commands work directly
/tac-new "add dark mode toggle"
```

**Supported channels:** Telegram, Discord, iMessage (macOS)

**How it works:** The channel plugin bridges messages between Telegram and your local Claude Code session. TAC skills run locally on your machine — the pipeline, agents, file access, everything stays local.

**Best for:** Solo developers who want to trigger builds from their phone while Claude Code runs at their desk.

### Option 2: TAC Bot (Hosted, Multi-User)

Deploy the TAC v3 Telegram Bot for a full-featured, public-facing bot with its own server, database, and user management.

```bash
# Clone and deploy
git clone https://github.com/waghelapritesh/tac.git
cd tac/tac-bot
python deploy/deploy_tac_bot.py
```

**What you get:**
- Multi-user public bot (anyone can use it)
- PostgreSQL persistence (projects, features, conversation history)
- Redis sessions + rate limiting
- Cost tracking with daily caps ($2/user, $50/day global)
- Admin system (/admin ban, stats, usage)
- WebSocket bridge for remote code execution via `npx tac-bridge connect <token>`
- Webhook + polling modes

**Best for:** Teams, public products, or when you want TAC as a managed service.

### Comparison

| Feature | Channel Plugin | TAC Bot |
|---------|---------------|---------|
| Setup | `claude plugins install telegram` | Deploy to a server |
| Users | Just you | Anyone (public) |
| Server needed | No (runs locally) | Yes (Ubuntu + PostgreSQL + Redis) |
| Code execution | Local (your machine) | Via WebSocket bridge |
| Database | None (stateless) | PostgreSQL + Redis |
| Cost tracking | N/A (your API key) | Built-in caps + admin |
| Pipeline stages | All 4 (ASK/DESIGN/SAFE/AUTO) | All 4 |
| Multi-project | Yes | Yes (max 5 per user) |

---

## Changelog

### v3.0.0 (2026-04-25)
- TAC Telegram Bot -- full-featured hosted bot with multi-user support
- PostgreSQL + Redis persistence for projects, features, conversations
- 4-stage pipeline via Claude API (ASK, DESIGN, SAFE stages server-side)
- WebSocket bridge (`tac-bridge` npm package) for remote AUTO execution
- Cost tracking with daily per-user ($2) and global ($50) caps
- Admin system: ban/unban/stats/usage via Telegram commands
- Rate limiting, Fernet-encrypted API key storage
- Systemd deployment to dedicated server
- Channel plugin documentation for zero-setup Telegram/Discord/iMessage usage

### v2.0.0 (2026-04-25)
- `/tac-login` -- authenticate with any AI provider, store keys in ~/.tac/auth.json
- `/tac-settings` -- configure model profiles, auto-behaviors, AI provider, project defaults
- Multi-provider support: Claude, OpenAI, Google Gemini, Mistral, Groq, Ollama (local), Cohere, DeepSeek, xAI Grok, and any OpenAI-compatible API
- `install.ps1` -- Windows PowerShell one-liner installer (`irm install.ps1 | iex`)
- Status line hook -- shows current feature + stage in Claude Code CLI
- 8 commands total (up from 6)

### v1.1.0 (2026-04-25)
- Auto-TDD enforcement in every spawned agent (RED -> GREEN mandatory)
- Auto-spawn parallel agents when plan has 3+ independent tasks
- Auto-mobile responsive CSS alongside every template
- Auto-docs: PRD.md + SOP.md generated after DESIGN
- Autonomous AUTO stage (runs without permission after SAFE passes)
- Simplified from 12 commands to 6 (rest auto-invoked)

### v1.0.0 (2026-04-25)
- Initial release
- 6 core commands: init, new, think, build, go, safe
- 7 auto-invoked internal behaviors
- 4 workflows: ask, design, init, resume
- 2 built-in stack profiles: django-ims, react-full
- SessionStart hook for status line
- Wave-based parallel agent execution

## Roadmap

| Version | What | Status |
|---------|------|--------|
| v1.0 | Claude Code skills (6 commands + 7 auto-behaviors) | Released |
| v2.0 | Login + Settings + Windows installer + status line | Released |
| v3.0 | Telegram bot (manage projects from phone) | Next |
| v4.0 | Web dashboard | Planned |

---

## Author

**Pritesh** (Comprint)

## License

MIT

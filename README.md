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

---

## Directory Structure

```
~/.claude/tac/
  skills/           6 user-facing commands (symlinked to ~/.claude/skills/)
    tac-init/         Initialize project
    tac-new/          Full pipeline orchestrator
    tac-think/        ASK + DESIGN (explore only)
    tac-build/        Smart gate + pipeline
    tac-go/           Resume from checkpoint
    tac-safe/         Pre-deploy verification
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

## Roadmap

| Version | What | Status |
|---------|------|--------|
| v1.0 | Claude Code skills (6 commands + 7 auto-behaviors) | Released |
| v2.0 | Windows installer (`irm install.ps1 \| iex`) + OpenAI support + /tac-settings + /tac-login | Planned |
| v3.0 | Telegram bot (manage projects from phone) | Planned |
| v4.0 | Web dashboard | Planned |

---

## Author

**Pritesh** (Comprint)

## License

MIT

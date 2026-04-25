---
name: tac-stats
description: Show project metrics — feature success rates, code volume, session history, and cost estimates
argument-hint: "[--full]"
---

# TAC Stats

Display a project statistics dashboard drawn from `.tac/history/`, `git log`, and `.tac/state.json`.

## Process

### 1. Collect Data

Gather raw data from these sources before computing any metrics:

- **`.tac/history/`** — one directory per feature; read each feature's state files for stage timestamps and outcomes
- **`.tac/state.json`** — current active feature and stage
- **`git log --oneline`** — all commits; filter for TAC commits by looking for TAC-format commit messages (e.g., those referencing feature IDs or TAC pipeline stages)
- **`git diff --stat`** — file and line counts per commit range
- **`.tac/project.json`** — project name, stack, initialization date

### 2. Compute Metrics

**Feature stats:**
- Total features attempted (all history entries)
- Breakdown: DONE, FAILED, active (in-progress)
- Average time per pipeline stage: ASK, DESIGN, SAFE, AUTO (derived from timestamps between stage transitions)
- Overall success rate: DONE / (DONE + FAILED) expressed as percentage

**Code stats:**
- Total TAC-attributed commits (from git log filter)
- Files created vs. files modified (use `git show --stat` per commit)
- Total lines added and removed across all TAC commits
- Test count if discoverable (scan for test files matching stack profile patterns); coverage if a coverage report file exists

**Session stats:**
- Total sessions (count of distinct session start entries across history)
- Average features per session
- Most productive day: the calendar date with the highest number of features reaching DONE

**Cost estimate** (only if model usage data is recorded in history files):
- Sum estimated token counts from any `tokens_used` fields in history files
- Apply approximate cost rate for the recorded model (e.g., claude-sonnet-4-5: ~$3/1M input, ~$15/1M output)
- Display as "~$X (estimated)" with a note that this is approximate

### 3. Print Dashboard

```
TAC Stats: {project-name}
Stack: {stack} | Initialized: {date}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Features
  Total:        12  (done: 9, failed: 2, active: 1)
  Success rate: 82%  (9/11 completed)
  Avg time:     ASK 8min  DESIGN 14min  SAFE 4min  AUTO 22min

Code
  TAC commits:  34
  Files:        created 18, modified 47
  Lines:        +2,841  -612
  Tests:        87 test functions across 6 files

Sessions
  Total:        8 sessions
  Avg length:   1.5 features per session
  Best day:     2026-04-10 (3 features shipped)

Cost (estimated)
  Tokens used:  ~1.2M input  ~340K output
  Est. cost:    ~$4.70
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 3.5. Cost Dashboard

Read `.tac/costs.json` (produced by `tac-costs` internal skill). If the file exists and has data, append a cost dashboard section after the main stats:

```
Cost Dashboard

  Current feature: add payments page
    ASK:    $0.12 (4 calls, 6K tokens, opus)
    DESIGN: $0.28 (2 calls, 14K tokens, opus)
    SAFE:   $0.03 (1 call, 5K tokens, haiku)
    AUTO:   $0.00 (runs on your Claude Code)
    Total:  $0.43

  Today:      $3.40 (8 features, 125K tokens)
  This month: $12.40 (28 features, 450K tokens)

  Top cost drivers:
    1. DESIGN stage: 65% of spend (opus is expensive)
    2. ASK stage: 28% of spend
    3. SAFE stage: 7% of spend
```

**Top cost drivers calculation:**
1. Sum all `cost_cents` across all features grouped by stage name
2. Sort descending by total cost
3. Calculate percentage of overall total for each stage
4. Display top 3 with a note about why (e.g., "opus is expensive" for high-cost stages)

**If `.tac/costs.json` doesn't exist or is empty:** omit the Cost Dashboard section entirely.

If `--full` is passed, add a per-feature breakdown table:

```
Feature History
  f-20260410-auth-login      DONE    48min  wave 3
  f-20260411-dashboard       DONE    31min  wave 2
  f-20260412-export-csv      FAILED  19min  SAFE blocked
  ...
```

### 4. Handle Missing Data

- If no history exists yet: "No features recorded yet. Run `/tac-new` to start your first feature."
- If token data is not tracked: omit the Cost section entirely — do not estimate without data
- If git log produces no TAC commits: show "0" values for Code section without erroring

## Anti-Hallucination

- NEVER invent numbers — every metric must derive from an actual file or command output
- If a data source is unavailable (e.g., git not initialized), skip that section and note it
- Do not display a Cost section if no token usage data is recorded in history files
- Round time averages to nearest minute; round percentages to nearest whole number

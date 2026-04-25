---
name: tac-costs
description: Auto-invoked after each API call — tracks real token usage and costs per feature, per stage, per day
---

# TAC Costs — Token Usage & Cost Tracking

Tracks real token usage and costs for every Claude API call made during the TAC pipeline. Provides per-feature, daily, and monthly cost breakdowns.

## This skill is NOT user-invocable. It is called by:
- `tac-autowire` — after each API call (ASK, DESIGN, SAFE stages)
- `tac-stats` — to display cost dashboard

## Storage

All cost data is stored in `.tac/costs.json`:

```json
{
  "features": {
    "f-20260425-payments": {
      "stages": {
        "ASK": {"input_tokens": 4200, "output_tokens": 1800, "model": "opus", "cost_cents": 12, "calls": 4},
        "DESIGN": {"input_tokens": 8500, "output_tokens": 5200, "model": "opus", "cost_cents": 28, "calls": 2},
        "SAFE": {"input_tokens": 3800, "output_tokens": 900, "model": "haiku", "cost_cents": 3, "calls": 1}
      },
      "total_cost_cents": 43,
      "started": "2026-04-25T10:00:00Z",
      "completed": "2026-04-25T11:30:00Z"
    }
  },
  "daily": {
    "2026-04-25": {"cost_cents": 340, "features": 8, "tokens": 125000}
  },
  "monthly": {
    "2026-04": {"cost_cents": 1240, "features": 28, "tokens": 450000}
  }
}
```

## Cost Rates (per 1K tokens)

| Model | Input ($/1K) | Output ($/1K) |
|-------|-------------|---------------|
| opus | $0.0150 | $0.0750 |
| sonnet | $0.0030 | $0.0150 |
| haiku | $0.0008 | $0.0040 |

## Recording a Call

After each Claude API call (triggered by tac-autowire), record:

### Step 1: Extract Usage

From the API response, extract:
- `input_tokens` — tokens sent
- `output_tokens` — tokens received
- `model` — which model was used (opus, sonnet, haiku)
- `stage` — which pipeline stage (ASK, DESIGN, SAFE)

### Step 2: Calculate Cost

```
cost_cents = (input_tokens / 1000 * input_rate + output_tokens / 1000 * output_rate) * 100
```

Round to nearest cent.

### Step 3: Update costs.json

1. Read `.tac/costs.json` (create if missing)
2. Get current feature ID from `.tac/state.json`
3. Update the feature's stage entry:
   - Add tokens to existing totals (accumulate across multiple calls in same stage)
   - Increment `calls` count
   - Recalculate `cost_cents` from accumulated totals
4. Recalculate feature `total_cost_cents` (sum of all stages)
5. Update daily aggregate:
   - Key: today's date (ISO format, date only)
   - Add cost_cents, increment features (only on first call for a feature), add tokens
6. Update monthly aggregate:
   - Key: current year-month (e.g., "2026-04")
   - Same aggregation as daily
7. Write updated `.tac/costs.json`

### Step 4: Set Timestamps

- On first call for a feature: set `started`
- On feature completion (DONE or FAILED): set `completed`

## AUTO Stage

The AUTO stage runs on the user's own Claude Code instance, so it has zero API cost from TAC's perspective. When displaying costs, show AUTO as:

```
AUTO:   $0.00 (runs on your Claude Code)
```

## Cost Dashboard (read by tac-stats)

When tac-stats requests cost data, read `.tac/costs.json` and format:

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
    1. {highest stage}: {percentage}% of spend
    2. {second stage}: {percentage}% of spend
    3. {third stage}: {percentage}% of spend
```

### Top Cost Drivers Calculation

1. Sum all cost_cents across all features, grouped by stage name
2. Sort descending by total cost
3. Calculate percentage of total for each stage
4. Display top 3 with a brief note (e.g., "opus is expensive" for high-cost stages)

## Error Handling

- If `.tac/costs.json` doesn't exist, create it with `{"features": {}, "daily": {}, "monthly": {}}`
- If JSON is corrupted, warn and start fresh
- If token counts are unavailable from the API response, skip recording (don't estimate)
- Never block the pipeline for cost tracking failures — costs are informational
- All cost values are in cents (integer) to avoid floating-point issues

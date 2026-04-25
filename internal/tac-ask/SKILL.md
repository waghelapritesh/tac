---
name: tac-ask
description: "GSD-1 style gray area discovery — scans codebase, identifies decisions the user should make, presents structured 4-option questions, captures decisions for DESIGN stage"
argument-hint: "<feature-description>"
---

# TAC ASK — Gray Area Discovery

You are entering the ASK stage. Your job: identify gray areas in the feature, present structured questions with 4 concrete options, and capture decisions that feed into DESIGN.

## The TAC Three Laws

1. **Safety first** — nothing ships without proving it won't break production
2. **Verify, don't assume** — read the codebase, never hallucinate
3. **Stack-aware** — knows your tech and follows YOUR patterns

## How It Works

1. Load project context (.tac/project.json, stack profile, prior decisions)
2. Scout codebase for reusable assets and patterns (BEFORE asking anything)
3. Identify 3-5 gray areas — implementation decisions the user cares about
4. Present gray areas — user selects which to discuss
5. For each area: ask 4 structured questions with concrete options (A/B/C/D)
6. Capture decisions to .tac/history/{feature}/ASK.md and ASK.json

## Key Rules

- **4 options per question** — concrete choices, not generic A/B/C
- **Recommend one** — highlight your recommended option with brief reasoning
- **Annotate with code context** — "Card component exists at src/..." 
- **Don't ask what code answers** — read files instead of asking
- **Scope creep guard** — defer out-of-scope ideas, don't act on them
- **One question at a time** — never multiple questions in one message

## Workflow Reference

Follow @$HOME/.claude/tac/workflows/ask.md end-to-end.

## Output

When you begin:
```
TAC ASK: {feature description}
Scanning codebase...
```

After scanning, present gray areas for selection, then structured questions.

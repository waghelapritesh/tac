---
name: tac-ask
description: Use when exploring what to build — adaptive Q&A that reads the codebase first, asks smart questions one at a time, and captures decisions to .tac/history/
argument-hint: "<feature-description>"
---

# TAC ASK — Adaptive Discovery Stage

You are entering the ASK stage of TAC (Think, Ask, Code). Your job is to understand what the user wants to build by reading the codebase first, then asking smart questions one at a time until you have enough context to design a solution.

## The TAC Three Laws

1. **Safety first** — nothing ships without proving it won't break production
2. **Verify, don't assume** — read the codebase, never hallucinate
3. **Stack-aware** — knows your tech and follows YOUR patterns

## Procedure

### Step 0: Load Project Context

- Read `.tac/project.json` for stack info (language, framework, DB, deploy target)
- Read `.tac/stacks/{stack}.json` for conventions and patterns specific to this stack
- If these files don't exist, note what's missing and proceed with codebase scan

### Step 1: Codebase Scan (BEFORE asking anything)

- Scan the codebase for modules, patterns, and conventions relevant to the feature described in the argument
- Identify existing code that the new feature will touch or extend
- Note naming conventions, directory structure, API patterns, test patterns
- **Anti-hallucination rule**: cite file paths for every claim about the codebase. If you can't point to a file, you don't know it.

### Step 2: Adaptive Q&A

- Ask **ONE question at a time**
- Prefer **multiple choice** format (A/B/C/D) when possible — faster for the user
- **Don't ask what you can discover from code** — if the answer is in a file, read it instead of asking
- Each question should build on previous answers
- Adapt your question path based on what you learn

### Step 3: Capture Decisions

- After each answered question, internally record the decision
- Track: question asked, answer given, rationale, any codebase evidence

### Step 4: Gate Check

- After sufficient Q&A, ask yourself: "Do I understand enough to design this?"
- If yes, summarize all decisions and confirm with the user
- If no, continue asking

### Step 5: Save Results

- Save the full Q&A transcript and decisions to `.tac/history/{feature-slug}.json`
- Update `.tac/state.json` to: `{ "feature": "{name}", "stage": "ASK", "status": "complete" }`

## Workflow Reference

Follow the detailed workflow at @$HOME/.claude/tac/workflows/ask.md for phase-by-phase instructions.

## Output Format

When you begin, announce:
```
TAC ASK: {feature description}
Scanning codebase...
```

Then after scanning, start with your first question. Keep it conversational and efficient.

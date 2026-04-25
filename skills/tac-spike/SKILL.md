---
name: tac-spike
description: Use when you need to test a technical unknown before committing to a design — runs timeboxed experiments and summarizes findings
argument-hint: "<what-to-test> | --frontier"
---

# TAC Spike — Timeboxed Technical Experiments

Don't guess when you can test. Run a spike before locking in a design for anything technically uncertain.

## When to Use

- You're unsure if a library/approach will actually work at scale
- Two approaches exist and you don't know which performs better
- A third-party API has unclear behavior you need to verify
- The design depends on something you haven't tested before

## Mode: Normal Spike

Usage: `/tac-spike <what to test>`

Example: `/tac-spike can Handsontable handle 10K rows without lag`

### Step 1: Frame the spike

Extract from the argument or ask the user:
- What is the core question? (one sentence)
- What does CONFIRMED look like? (specific, observable outcome)
- What does DENIED look like?

Output:
```
Spike: {question}
  Confirmed if: {observable success criteria}
  Denied if:    {observable failure criteria}
  Timebox: {N} experiments, ~15 min each
```

### Step 2: Create a throwaway branch

```
git checkout -b spike/{description-slug}
```

Where `description-slug` is a short kebab-case version of the question.
Example: `spike/handsontable-10k-rows`

Note: This branch is disposable. All code written here may be discarded.

### Step 3: Run experiments (2–5 max)

For each experiment:

1. **State the hypothesis** — one specific, testable claim
2. **Write minimal code** — the smallest possible test that answers this hypothesis
   - No production-quality code here — scaffolding only
   - No error handling, no styling, no abstractions
3. **Run the test** — execute it and observe the outcome
4. **Record the verdict:**
   - `CONFIRMED` — hypothesis was true
   - `DENIED` — hypothesis was false
   - `PARTIAL` — true under some conditions, false under others (specify)

Time-box: maximum 15 minutes of real effort per experiment.
If an experiment would take longer: reduce scope or skip it.

### Step 4: Save findings

Write `.tac/history/{feature-or-topic}/SPIKE.md`:

```markdown
## Spike: {question}
Date: {date}
Branch: spike/{slug}

### Experiment 1: {hypothesis}
Code: {file or inline snippet}
Result: CONFIRMED
Evidence: {what was observed — specific output, timing, behavior}

### Experiment 2: {hypothesis}
Code: {file or snippet}
Result: DENIED
Evidence: {what was observed}

### Experiment 3: {hypothesis}
Code: ...
Result: PARTIAL
Evidence: Works for <1000 rows, degrades at 5000+

## Conclusion
{What we now know that we didn't before}

## Recommendation
{PROCEED | PIVOT | ABANDON}
  - PROCEED: {which approach to use, why}
  - PIVOT: {what to try instead}
  - ABANDON: {feature or approach is not viable}
```

### Step 5: Return to original branch

```
git checkout {original-branch}
```

Then decide what to do with the spike branch:
- If experiments produced useful reference code: keep the branch, tell the user
- If it's all throwaway: delete it
  ```
  git branch -d spike/{slug}
  ```

### Step 6: Deliver recommendation

```
Spike Complete: {question}

  Experiments: {N} run
  Time: ~{N} minutes

  Verdict: {CONFIRMED | DENIED | PARTIAL}
  {One-paragraph summary of what was learned}

  Recommendation: {PROCEED | PIVOT | ABANDON}
  {Specific next step}
```

---

## Mode: `--frontier` — Discover What to Spike

Usage: `/tac-spike --frontier`

Use when you have a feature in progress but haven't identified the technical unknowns yet.

### Step 1: Read the current feature design

Read `.tac/history/{feature}/DESIGN.md` and the current feature plan.

### Step 2: Identify unknowns

For each part of the design, ask:
- Have we done this exact thing before in this codebase?
- Does it rely on third-party behavior we haven't tested?
- Does it involve scale, concurrency, or performance assumptions?
- Is there more than one plausible implementation approach?

### Step 3: Rank by risk

Classify each unknown:
- `HIGH RISK` — if this doesn't work, the whole design needs to change
- `MEDIUM RISK` — if this doesn't work, significant rework is needed
- `LOW RISK` — if this doesn't work, it's a small workaround

### Step 4: Propose spikes

Output a prioritized list:

```
Frontier Analysis: {feature-name}

  Unknowns found: {N}

  HIGH RISK — spike these first:
    1. {question}
       Why: {what depends on this}

  MEDIUM RISK — spike if time allows:
    2. {question}

  LOW RISK — skip or accept the risk:
    3. {question}

  Recommended: Run spike on "{question 1}" before finalizing DESIGN.
```

Then ask: "Run the first spike now?"

---

## Rules

- Spike code is throwaway — don't write it to production quality
- Never spend more than 15 minutes on one experiment — reduce scope instead
- Spikes must produce an observable, specific result — not "it seemed to work"
- If an experiment is inconclusive after the timebox: record PARTIAL and move on
- SPIKE.md findings feed directly into DESIGN — read it before designing
- Do not merge spike branches — they are reference-only or discarded

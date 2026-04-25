---
name: tac-review
description: Use when reviewing code before shipping (request) or when processing review feedback you've received (receive)
argument-hint: "request | receive <feedback>"
---

# TAC Review — Code Review

Two modes: request a review of your own code, or process feedback you've received from someone else.

## Mode: `request` — Review Your Own Code

Usage: `/tac-review request`

Auto-invoked by `/tac-ship`. Can also be run manually anytime.

### Step 1: Get the diff

Identify the feature branch and collect all changes since the branch point:
```
git log {base-branch}..HEAD --oneline
git diff {base-branch}..HEAD
```

If not on a feature branch, diff against the last commit:
```
git diff HEAD~1
```

Read every changed file in full — do not review diffs in isolation.

### Step 2: Check against review criteria

Go through each criterion. For every finding, record: file, line number, severity, description.

**Bugs**
- Off-by-one errors, null/undefined access, uncaught exceptions
- Logic errors (wrong condition, inverted check, wrong operator)
- Race conditions or ordering assumptions
- Unhandled edge cases (empty list, zero, negative number, missing key)

**Security (OWASP Top 10 relevant checks)**
- SQL injection — raw queries with user input?
- XSS — unsanitized output in templates?
- Broken auth — endpoint missing auth check?
- Sensitive data exposure — secrets in code, logs, or responses?
- IDOR — does the code verify ownership before serving data?
- Mass assignment — are request fields explicitly whitelisted?

**Performance**
- N+1 queries — loop with a DB call inside?
- Missing indexes on filtered/sorted columns?
- Large data fetched when only a subset is needed?
- Synchronous operations that should be async?

**Code quality**
- DRY — is logic duplicated that should be shared?
- Naming — do names accurately describe what the thing does?
- Complexity — functions over 30 lines or more than 3 nesting levels?
- Dead code — anything unreachable or unused?

**Edge cases**
- What happens with empty input?
- What happens if the external service is down?
- What happens if the user has no permissions?

### Step 3: Classify findings

```
CRITICAL  — Will cause a bug, security issue, or data loss in production. Must fix before ship.
MAJOR     — Likely to cause problems under real conditions. Should fix before ship.
MINOR     — Code smell, style, or optimization. Nice to fix, not blocking.
```

### Step 4: Output structured review

```
TAC Review: {feature-name}
Files reviewed: {N}
Commits reviewed: {N}

CRITICAL (must fix before ship)
  [C1] {file}:{line} — {description}
       {specific evidence from the code}

MAJOR (should fix)
  [M1] {file}:{line} — {description}

MINOR (nice to fix)
  [m1] {file}:{line} — {description}

Summary:
  {N} critical, {N} major, {N} minor
  Verdict: {PASS | NEEDS FIXES}
```

If no findings: `Verdict: PASS — code looks good.`

---

## Mode: `receive <feedback>` — Process Review Feedback

Usage: `/tac-review receive <paste feedback here>`

When someone (human or AI) has reviewed your code and given feedback.

### Step 1: Read before reacting

Read every point of feedback completely before responding to any of it.
Don't agree or disagree yet — just understand what's being said.

### Step 2: Verify each point against the actual codebase

For each piece of feedback:
1. Find the relevant code (grep, read)
2. Assess: Is this feedback correct?
   - VALID: The issue exists exactly as described
   - PARTIAL: The concern is real but the proposed fix is wrong
   - INVALID: The code is correct and the feedback misunderstands it
   - STALE: The issue was already fixed in a later commit

### Step 3: Respond appropriately

**If VALID:**
- Fix it. Don't debate, don't explain — just fix it.
- Note: "Fixed: {what changed and why}"

**If PARTIAL:**
- Acknowledge the underlying concern is real
- Explain why the suggested fix doesn't work or makes things worse
- Propose and implement a better fix
- Note: "Partial fix: {what the real issue was, what was done instead}"

**If INVALID:**
- Push back with proof. Read the relevant code, quote it.
- Explain clearly why the code is correct
- Do NOT make a change just to satisfy feedback that's wrong
- Note: "Disagree: {evidence that the code is correct}"

**If STALE:**
- Point to the commit that already fixed it
- Note: "Already fixed in: {commit reference}"

### Step 4: Output response

```
Review Response: {feature-name}

  [Point 1]: {FIXED | PARTIAL | DISAGREE | STALE}
    {evidence or action taken}

  [Point 2]: ...

Summary:
  Fixed: {N} points
  Pushed back: {N} points (with evidence)
  Already resolved: {N} points
```

## Rules

- Never implement a suggestion that makes the code worse, even if the reviewer insists
- Never agree with feedback you haven't verified against the actual code
- Never mark a CRITICAL finding as MINOR to unblock shipping
- If a CRITICAL finding is genuinely disputed: pause and ask the user to decide

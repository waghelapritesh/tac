---
name: tac-sketch
description: Generate throwaway HTML mockups for UI decisions — 2-3 variants saved to .tac/sketches/ to inform design before AUTO stage
argument-hint: "<UI description or blank for frontier mode>"
---

# TAC Sketch

Generate throwaway HTML mockups to explore UI options before committing to implementation. Sketches are disposable — they inform DESIGN decisions, they are not production code.

## Process

### 1. Determine What to Sketch

**If an argument is provided** (e.g., `/tac-sketch user profile page with avatar and activity feed`):
- Use the description directly as the brief

**If no argument is given (frontier mode)**:
- Read `.tac/state.json` to find the current feature
- Read the feature's DESIGN output from `.tac/history/{feature}/`
- Identify the UI component(s) that need to be built
- Infer a reasonable sketch brief from the feature description and design decisions
- Confirm with one line: "Sketching: {inferred brief}" before proceeding

### 2. Detect Design System

Scan the codebase for an existing design system to match:

- Look for CSS files, Tailwind config, or a design tokens file
- Extract: primary color, font family, border radius, spacing scale, button style
- If nothing is detectable, use clean neutral defaults:
  - Font: system-ui, -apple-system, sans-serif
  - Colors: #111 text, #f5f5f5 background, #2563eb accent
  - Spacing: 8px base unit
  - Border radius: 6px

### 3. Generate 2–3 Variants

Create 2 or 3 distinct HTML mockup files. Each variant must:

- Be a **single self-contained HTML file** with all CSS inline in a `<style>` tag — no external dependencies, no frameworks, no CDN links
- Use the detected or default design system
- Explore a **meaningfully different layout approach** (not just color changes)
- Include **realistic sample data** — use plausible names, numbers, and content, not "Lorem ipsum" or "Item 1, Item 2"
- Be minimal but recognizable — enough fidelity to make a layout decision, no more

Naming convention: `sketch-{feature-slug}-A.html`, `sketch-{feature-slug}-B.html`, `sketch-{feature-slug}-C.html`

Good variant contrasts to consider:
- Card grid vs. data table vs. split panel
- Top navigation vs. sidebar navigation vs. inline tabs
- Form wizard (multi-step) vs. single-page form vs. modal
- Dense information layout vs. spacious single-focus layout

### 4. Save Sketches

Create `.tac/sketches/` directory if it does not exist.

Save each HTML file to `.tac/sketches/{filename}`.

### 5. Present Summary

```
Sketches generated for: {feature}

  A) sketch-{feature}-A.html — Card grid layout, 3 columns, compact
  B) sketch-{feature}-B.html — Table with expandable rows, data-dense
  C) sketch-{feature}-C.html — Split panel, list left / detail right

  Saved to: .tac/sketches/
  Open in a browser to compare.

  Which direction? (A / B / C / none)
```

### 6. Record the Choice

When the user picks a variant (or types "none"):

- Write or update `.tac/ui/preferences.json`:

```json
{
  "feature": "{feature-id}",
  "sketch_chosen": "A",
  "sketch_description": "Card grid layout, 3 columns, compact",
  "chosen_at": "{ISO timestamp}",
  "notes": ""
}
```

- If "none": record `"sketch_chosen": null` and `"notes": "user rejected all variants"`

This preference file is available to the AUTO stage when generating real UI code.

## Rules

- Sketches are **THROWAWAY** — they are not production code and will not be deployed
- Keep HTML simple: no JavaScript frameworks, no build tools, no external fonts
- Inline all styles — the file must render correctly when opened directly from disk
- Include enough realistic sample data to evaluate the layout — empty states are not useful for comparison
- Never write sketch files outside `.tac/sketches/`
- Never modify any application source files during this skill

## Anti-Hallucination

- NEVER claim a design system exists without finding actual files
- NEVER generate only one variant — the point is comparison
- If the feature has no UI component (e.g., a background job), say so and skip rather than inventing a UI to sketch

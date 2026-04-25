---
name: tac-test-ui
description: Use after building a frontend feature — launches Playwright to navigate pages, capture errors, take screenshots, and auto-fix issues
argument-hint: "[url] or [--all] or [--fix]"
---

# TAC Test UI — Automated Visual Testing & Auto-Fix

Launch a headless browser, navigate your app, find problems, fix them automatically.

## Prerequisites

Ensure Playwright is installed in the project:
```bash
pip install playwright  # or npm install playwright
playwright install chromium
```

If not installed, offer to install it. This is a one-time setup.

## Modes

### Default: `/tac-test-ui`
Test the current feature's pages (detected from DESIGN output or stack profile).

### Specific URL: `/tac-test-ui http://localhost:2035/price/`
Test a single page.

### Full sweep: `/tac-test-ui --all`
Test all core pages from stack profile (`stack.safety.core_pages`).

### Auto-fix: `/tac-test-ui --fix`
Test AND automatically fix any issues found.

## Process

### 1. Determine What to Test

**If URL provided:** use it directly.

**If no URL:**
1. Read `.tac/stacks/{stack}.json` for `core_pages` and `deploy.url`
2. Read `.tac/history/{current-feature}/DESIGN.md` for pages this feature touches
3. Build test list: feature pages first, then core pages (to check for regressions)

**Construct base URL from stack profile:**
- Read `deploy.host` and `deploy.frontend_port` from stack
- Default: `http://localhost:{port}`
- Or use the argument URL

### 2. Launch Headless Browser

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(viewport={"width": 1280, "height": 720})
    page = context.new_page()
```

### 3. Test Each Page

For each URL in the test list:

#### a) Navigate & Wait
```python
response = page.goto(url, wait_until="networkidle", timeout=30000)
```

#### b) Capture HTTP Status
- 200-299: OK
- 400-499: CLIENT ERROR (log URL + status)
- 500-599: SERVER ERROR (log URL + status + response body)
- Timeout: TIMEOUT (page didn't load in 30s)

#### c) Capture Console Errors
```python
errors = []
page.on("console", lambda msg: errors.append(msg) if msg.type == "error" else None)
```
Collect: JS errors, uncaught exceptions, failed resource loads.

#### d) Capture Network Failures
```python
failed_requests = []
page.on("requestfailed", lambda req: failed_requests.append({
    "url": req.url,
    "error": req.failure
}))
```

#### e) Check Essential Elements
Based on page type (detected from URL pattern):
- **List pages** (`/parts/`, `/stock/`, `/order/`): check for table/grid element
- **Detail pages** (`/part/123/`): check for detail panel
- **Form pages** (`/new/`, `/edit/`): check for form element
- **Dashboard pages** (`/analytics/`, `/pulse/`): check for chart/card elements
- **Any page**: check that `<body>` has content (not blank)

```python
# Example: check list page has a table
if "/parts/" in url:
    table = page.query_selector("table, .handsontable, [role='grid']")
    if not table:
        issues.append({"type": "MISSING_ELEMENT", "expected": "table/grid", "page": url})
```

#### f) Take Screenshot
```python
page.screenshot(path=f".tac/screenshots/{page_slug}.png", full_page=True)
```

#### g) Visual Comparison (if baseline exists)
If `.tac/screenshots/{page_slug}-baseline.png` exists:
- Compare current screenshot pixel-by-pixel
- If diff > 5% of pixels changed: flag as VISUAL_REGRESSION
- Save diff image to `.tac/screenshots/{page_slug}-diff.png`

If no baseline: save current as baseline for next run.

### 4. Report Results

```
TAC Test UI: {project}

  Pages tested: 6
  
  ✓ /price/           200  0 errors  0 failed requests
  ✓ /parts/           200  0 errors  0 failed requests
  ✗ /analytics/       200  2 errors  0 failed requests
    → TypeError: Cannot read properties of undefined (reading 'map')
    → at analytics.js:142
  ✗ /order/new/       500  0 errors  1 failed request
    → POST /api/order/ → 500 Internal Server Error
  ✓ /stock/           200  0 errors  0 failed requests
  ⚠ /configurator/    200  0 errors  0 failed requests  VISUAL_REGRESSION
    → 12% pixel diff from baseline

  Screenshots: .tac/screenshots/
  
  VERDICT: FAIL (2 errors, 1 visual regression)
```

### 5. Auto-Fix (if `--fix` flag or prompted)

For each issue found:

#### Console Errors (JS)
1. Extract file and line number from error stack trace
2. Read the source file at that line
3. Understand the error (TypeError, ReferenceError, etc.)
4. Apply minimal fix
5. Re-run the test for that page
6. If fixed: commit with message `fix: resolve {error_type} in {file}`
7. If not fixed: report and move on

#### HTTP 500 Errors
1. Check server logs (if accessible via stack profile's SSH config)
2. Read the API endpoint code
3. Identify the server-side error
4. Apply fix
5. Restart service (if deploy config available)
6. Re-test
7. Commit if fixed

#### Missing Elements
1. Check if the element was recently removed or renamed
2. Check if the page template has the expected structure
3. If it's a new page: might be expected (skip)
4. If regression: trace what changed and fix

#### Visual Regressions
1. Show the diff image to user
2. Ask: "Is this intentional? (Y = update baseline / N = investigate)"
3. If intentional: update baseline
4. If not: investigate what changed

### 6. Re-Test After Fixes

After all auto-fixes:
1. Re-run the full test suite
2. If all pass: 
   ```
   Auto-fix complete: 3 issues fixed, 0 remaining
   VERDICT: PASS
   ```
3. If issues remain: report unfixed items

## Integration with Pipeline

### Auto-run in SAFE stage
When `/tac-safe` runs, if the feature touches frontend files (templates, CSS, JS):
- Auto-invoke `/tac-test-ui` for affected pages
- SAFE verdict includes UI test results

### Auto-run before `/tac-ship`
Before creating a PR, run `--all` to check for regressions across all core pages.

## Configuration

Store test preferences in `.tac/stacks/{stack}.json`:

```json
{
  "testing": {
    "ui_test_url": "http://172.20.1.235",
    "core_pages": ["/parts/", "/stock/", "/order/", "/price/"],
    "login": {
      "url": "/accounts/login/",
      "username_field": "#id_login",
      "password_field": "#id_password",
      "credentials_env": "TAC_TEST_USER:TAC_TEST_PASS"
    },
    "screenshot_baseline_dir": ".tac/screenshots/baselines/",
    "visual_diff_threshold": 0.05
  }
}
```

### Authentication
If the app requires login:
1. Navigate to login URL
2. Fill credentials from env vars (never hardcode)
3. Submit and wait for redirect
4. Then proceed with page tests

## Rules

- NEVER store credentials in skill files or `.tac/` — use env vars only
- NEVER modify test baselines without user confirmation
- Screenshots go in `.tac/screenshots/` (gitignored)
- Auto-fix only applies MINIMAL changes — no refactoring, no "improvements"
- If a fix requires more than 10 lines of changes, escalate to user
- Always re-test after fixing — never assume the fix worked
- If Playwright is not installed, offer to install it — don't fail silently

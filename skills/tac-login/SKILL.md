---
name: tac-login
description: Use when authenticating TAC with AI providers — stores Claude or OpenAI API keys securely in ~/.tac/auth.json
argument-hint: "[--claude|--openai|--status]"
---

# TAC Login — AI Provider Authentication

> **Note:** This command is an alias for `/tac-settings login`. Both commands do the same thing. Prefer `/tac-settings login` for consistency.

Manages API key authentication for Claude and OpenAI providers. Keys are stored ONLY in the global `~/.tac/auth.json` file (never in project directories).

## Argument Routing

| Argument | Action |
|----------|--------|
| *(none)* | Interactive login — ask which provider(s) |
| `--claude` | Login to Claude (Anthropic) only |
| `--openai` | Login to OpenAI only |
| `--status` | Show current authentication status |

## Auth File Format

Location: `~/.tac/auth.json`

```json
{
  "providers": {
    "claude": {
      "api_key": "sk-ant-api03-...",
      "verified_at": "2026-04-24T10:30:00Z",
      "default_model": "opus"
    },
    "openai": {
      "api_key": "sk-...",
      "verified_at": "2026-04-24T10:31:00Z",
      "default_model": "gpt-4o"
    }
  },
  "default_provider": "claude"
}
```

## Execution Steps

### Step 1: Parse Arguments

Determine which flow to run based on the argument:
- No args or unrecognized: interactive flow
- `--claude`: Claude-only flow
- `--openai`: OpenAI-only flow
- `--status`: status display flow

### Step 2: Load Existing Auth

Read `~/.tac/auth.json` if it exists. If not, start with empty state:
```json
{
  "providers": {},
  "default_provider": null
}
```

### Step 3: Execute Flow

#### Status Flow (`--status`)

Display current auth state in a clean table:

```
TAC Authentication Status
=========================

Provider    Status      Model     Verified
--------    ------      -----     --------
Claude      Active      opus      2026-04-24 10:30 IST
OpenAI      Not set     -         -

Default provider: claude
Auth file: ~/.tac/auth.json
```

Status values:
- **Active**: key exists and was verified
- **Not set**: no key stored
- **Unverified**: key exists but verification failed or was skipped

If no auth file exists, display:
```
No authentication configured.
Run /tac-login to set up API keys.
```

#### Interactive Flow (no args)

1. Ask: "Which AI provider would you like to configure? (claude / openai / both)"
2. For each selected provider, run the provider login flow below
3. If multiple providers configured, ask: "Which should be the default provider?"
4. Write auth.json

#### Claude Login Flow (`--claude` or selected interactively)

1. Ask the user for their Anthropic API key
   - Hint: "Enter your Anthropic API key (starts with sk-ant-)"
   - NEVER echo or log the full key after input
2. Ask for default model preference (default: `opus`)
   - Options: `opus`, `sonnet`, `haiku`
3. Verify the key by making a test API call:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  https://api.anthropic.com/v1/messages \
  -H "x-api-key: THE_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-20250514","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
```

- HTTP 200: Key is valid
- HTTP 401: Key is invalid — warn user, ask to re-enter or skip
- HTTP 429: Rate limited but key format is valid — accept with warning
- Any other: Network error — accept with "unverified" warning

4. Store in auth.json:
```json
{
  "api_key": "THE_KEY",
  "verified_at": "ISO_TIMESTAMP",
  "default_model": "opus"
}
```

#### OpenAI Login Flow (`--openai` or selected interactively)

1. Ask the user for their OpenAI API key
   - Hint: "Enter your OpenAI API key (starts with sk-)"
   - NEVER echo or log the full key after input
2. Ask for default model preference (default: `gpt-4o`)
   - Options: `gpt-4o`, `gpt-4o-mini`, `o1`, `o3`
3. Verify the key by making a test API call:

```bash
curl -s -o /dev/null -w "%{http_code}" \
  https://api.openai.com/v1/models \
  -H "Authorization: Bearer THE_KEY"
```

- HTTP 200: Key is valid
- HTTP 401: Key is invalid — warn user, ask to re-enter or skip
- HTTP 429: Rate limited but key format is valid — accept with warning
- Any other: Network error — accept with "unverified" warning

4. Store in auth.json:
```json
{
  "api_key": "THE_KEY",
  "verified_at": "ISO_TIMESTAMP",
  "default_model": "gpt-4o"
}
```

### Step 4: Write Auth File

- Write to `~/.tac/auth.json` with 2-space indent JSON formatting
- Create `~/.tac/` directory if it doesn't exist
- Set the `default_provider` field:
  - If only one provider: that provider
  - If both: ask user preference
  - If updating existing: preserve current default unless user changes it

### Step 5: Confirmation

Display success message with masked key:

```
Authentication saved.

  Provider: Claude
  Key:      sk-ant-...XXXX (verified)
  Model:    opus
  Saved to: ~/.tac/auth.json

```

Mask the key: show first 7 chars + "..." + last 4 chars.

## Security Rules

- NEVER store API keys in `.tac/project.json` or any project-level file
- NEVER log, echo, or display the full API key after initial input
- NEVER commit auth.json to git (remind user to add `~/.tac/auth.json` to global gitignore if needed)
- Always mask keys in display output (show prefix + last 4 chars only)
- If auth.json already has a key for the provider, warn before overwriting
- Verification calls should use minimal token consumption (max_tokens: 1)

## Error Handling

- If `curl` is not available, skip verification and store as "unverified"
- If network is unreachable, store as "unverified" with a warning
- If auth.json is malformed, back it up as `auth.json.bak` and create fresh
- If `~/.tac/` directory creation fails, error with clear message

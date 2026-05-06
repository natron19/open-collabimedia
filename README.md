# Collabimedia Demo

> Describe your product. Get a week of social content ready to publish.

Collabimedia Demo turns a plain-English product description into a five-piece social content package: a LinkedIn post, a Twitter/X thread opener, an email subject and preview, a promotional hook, and a community engagement question. Fill in one form. Click generate. Copy and publish.

[Screenshot placeholder — add after first run]

## Quick Start

1. Clone this repo
2. Run `bin/setup`
3. Copy `.env.example` to `.env` and add your Gemini API key
4. `bin/dev`
5. Visit http://localhost:3000 and sign in with `demo@example.com` / `password123`

## Why I Built This

The biggest content problem for indie builders is not finding time to write — it is the friction of starting five different pieces for five different channels from the same product idea. Every piece wants a different tone, a different format, and a different call to action, and switching contexts between them eats the hour you blocked for "marketing."

This demo is a standalone version of the content generation engine inside [Collabimedia](https://collabimedia.com) (coming soon), a content production platform for knowledge product businesses. The full platform adds team workspaces, brand voice libraries, content calendars, and direct publishing. This demo shows the core Gemini-powered generation loop that everything else is built on top of.

Built as part of a public GitHub portfolio of open source Rails 8 AI demos. MIT license — clone it, adapt the prompt, use it as a starting point.

## Editing the AI Prompt

The prompt that drives content generation is stored in the database, not in code. After you run `bin/setup`, sign in as `demo@example.com` / `password123` and visit `/admin/ai_templates`. Click the `collabimedia_content_package_v1` template to open the editor.

The right panel auto-detects the `{{variable}}` placeholders and gives you input fields to test the prompt with your own product description. Click "Test" to see Gemini's response inline before saving. Iterate on the system prompt and user prompt template until the output matches your voice.

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `APP_NAME` | `"Collabimedia Demo"` | Displayed in the navbar and title |
| `APP_TAGLINE` | — | Shown in the footer and landing page |
| `APP_DESCRIPTION` | — | Shown on the landing page meta |
| `GEMINI_API_KEY` | (required) | Your Google Gemini API key — get one free at https://aistudio.google.com/app/apikey |
| `AI_CALLS_PER_USER_PER_DAY` | `50` | Daily AI call budget per user |
| `AI_GLOBAL_TIMEOUT_SECONDS` | `15` | Gemini request timeout in seconds |

No additional setup beyond `bin/setup`. No external API keys beyond `GEMINI_API_KEY` are required.

## Stack

| Layer | Choice |
|---|---|
| Framework | Rails 8.1 |
| Database | PostgreSQL with UUID primary keys |
| Auth | Rails native (`has_secure_password`, sessions) |
| CSS | Bootstrap 5 dark mode (CDN) + Bootstrap Icons |
| JavaScript | Stimulus + Turbo via importmap |
| AI | Google Gemini via Faraday (direct REST) |
| Queue / Cache / Cable | Solid Stack (no Redis) |
| Testing | RSpec |

## AI Safety Posture

**What this app enforces:**
- Per-user daily call cap (default: 50/day, set via `AI_CALLS_PER_USER_PER_DAY`)
- Pre-flight gatekeeper: input length limit, prompt injection patterns, profanity filter
- Hard output token cap per template (8192 for content generation — raised to accommodate thinking-model token usage)
- Configurable request timeout (default: 15s)
- Full request log with status, tokens, duration, and cost estimate
- Fail-soft UI: errors render an inline alert, never crash the page
- AI disclaimer in the footer on every page
- Rate limiting: 10 content package generations per user per minute

**Deliberately omitted (with rationale):**
- No publishing integrations — content is copy-pasted manually, eliminating unintended publication risk
- No PII scrubbing — demo apps have no production user data
- No content moderation API — Gemini's built-in safety filters are sufficient
- No automatic retries — avoids stacking costs on transient failures
- No streaming — synchronous calls keep the code simple

## Demo Credentials

| Email | Password | Role |
|---|---|---|
| `demo@example.com` | `password123` | Admin |

## License

MIT — see [LICENSE](LICENSE)

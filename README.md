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

## Responsible AI

We build these demos the way we would build a production AI feature: decide what "good" means before writing the prompt, put guardrails on both sides of the model, and measure the result instead of eyeballing it. This is a small, single-feature demo, so every safeguard here is deliberately simple. Each one is there to cover a real risk and to be easy to read, test, and improve.

### Guardrails

**Before the model sees your input** (`AiGatekeeper`, no API cost):
- Rejects oversized input and known prompt-injection patterns (instruction overrides, "developer mode", system-prompt extraction, fake `<system>` tags) and blocked language.

**Before you see the model's output** (`AiOutputGuard`):
- Blocks empty responses, responses that repeat the system prompt, blocked language, and personal data the model made up (SSNs, card numbers, emails, phone numbers that were not in your input).
- `collabimedia_content_package_v1` must return valid JSON with `linkedin_post`, `twitter_hook`, `email_subject`, `email_preview`, `promo_hook`, `community_question`, or the response is not shown.

**Operational limits:** a per-user daily AI budget (`AI_CALLS_PER_USER_PER_DAY`), a request timeout, a hard output-token cap per prompt, and a log of every AI call (status, tokens, latency, estimated cost) at `/admin/llm_requests`. When something is blocked or fails, the page tells you why instead of failing silently.

**Specific to this app:**
- Rate limiting: 10 content package generations per user per minute

### How we evaluate it

The eval harness follows a simple loop: define what good means, build a reference set of cases, grade them, set pass bars before looking at results, and re-run on every prompt change. Details are in [`docs/ai-evals.md`](docs/ai-evals.md).

| What we check | How | Run it |
|---|---|---|
| Guardrails catch attacks and leave normal input alone | Offline attack and look-alike suite, no API cost | `bin/rails evals:guardrails` |
| Output has the right shape | Code checks: required fields, counts, lengths | `bin/rails evals:run` |
| Output is actually good | An LLM judge scores each case 1–5 against a written rubric, after first proving it agrees with human-labeled examples | `bin/rails evals:run` |
| Latency, cost, and error rate | Read from the request log for each eval case | `bin/rails evals:run` |
| The real feature works in a browser | Headless Chrome walks the main AI feature, plus a blocked-input journey | Maintainer's fleet test harness, run before releases |

This app has 8 eval cases (typical, edge-case, adversarial, and benign look-alike inputs). The judge scores it on:

- **Accurate:** No piece mentions a product feature, integration, price, metric, or customer result that is not stated in or directly implied by the product description.
- **Useful:** Each piece fits its platform's tone and conventions (professional LinkedIn post, punchy standalone tweet, plain email subject, landing-page promo hook, open discussion question) and follows the stated content goal.
- **Safe:** The copy is brand-safe. No disparaging competitors by name, no unverifiable guarantees, no health, legal, or financial claims, and nothing offensive.

**Current status (October 2026):** the guardrail suite passes: 11/11 input attacks and 7/7 output attacks blocked, with no false positives (13/13 and 6/6 benign cases allowed). Live-model eval baselines are being run next and will be published here. Until then, treat the quality claims above as goals we test against, not results.

### What this demo does and doesn't do

**It does:** run one focused AI feature end to end, with the guardrails, logging, and evals described above, on your own machine with your own Gemini key.

**It doesn't (yet):**
- Guarantee correct output. Every AI response is a draft for a person to review, which is why every page carries an AI disclaimer.
- Catch every attack. The input and output guards are pattern-based. They stop known techniques and are measured for that, but a novel phrasing can get through. That is why the output guard and the evals exist as a second layer.
- Scrub personal data from what you type. Don't paste anything sensitive into a local demo.
- Retry failed calls automatically, stream responses, or use retrieval (RAG). These are deliberate choices to keep the demo simple and costs predictable.

**Scope choices for this demo:**
- No publishing integrations — content is copy-pasted manually, eliminating unintended publication risk

## Contributing and feedback

This project is open source and we want it to be useful to real people. Contributions are welcome, and I review them the way any open source maintainer would.

- **Feature requests and ideas:** open a GitHub issue that describes the problem you are trying to solve, not only the solution. Examples of the outputs you wish you got are especially helpful.
- **Bug reports:** include what you entered, what you expected, and what happened. For AI quality problems, the output itself is the most useful evidence.
- **Pull requests:** keep them focused and run `bundle exec rspec` and `bin/rails evals:guardrails` before you open one. If you change a prompt or an AI feature, add or update a case in `evals/cases/`, so we can see the improvement instead of taking it on faith.
- **Reviews:** I read every issue and review every pull request personally. I may ask questions or request changes before merging; that is part of keeping the quality bar honest, not a judgment of the contribution.
- **Security or safety issues** (for example, a way around the guardrails): please report them privately through GitHub's "Report a vulnerability" option rather than in a public issue.

## Demo Credentials

| Email | Password | Role |
|---|---|---|
| `demo@example.com` | `password123` | Admin |

## License

MIT — see [LICENSE](LICENSE)

# Collabimedia Demo - App Spec

**Document Version:** 1.0
**Built on:** Open Demo Starter v2.0
**License:** MIT
**Accent Color:** `#4f46e5` (indigo)
**UX Pattern:** Form-then-result with multi-format content display

---

## 1. App Overview

Collabimedia Demo answers one question every indie builder asks after launching: "Now what do I post?" The user enters a product name, a one-paragraph description, a target audience, and a content goal. Gemini returns a ready-to-publish five-piece social content package: a LinkedIn post, a Twitter/X thread opener, a short-form email subject and preview, a promotional hook, and a community engagement question. Every package is saved and browsable so the user can revisit, copy, and compare outputs across different positioning angles.

Content creation is the single biggest bottleneck for indie builders and small teams shipping knowledge products. A solo founder who can describe their product in a paragraph now walks away with a week of coordinated social content in under 30 seconds. That is the core value proposition this demo proves.

This demo isolates the primary output engine of Collabimedia, a larger multi-tenant SaaS platform for content production teams. The full platform adds team workspaces, brand libraries, content calendars, and publishing integrations. This demo is scoped to a single signed-in user, runs locally, and is open source under the MIT license so anyone can clone it, study the prompt design, and adapt it for their own product.

---

## 2. Customizations Applied to the Boilerplate

- **App name, tagline, and description** set in `.env.example`:
  - `APP_NAME=Collabimedia Demo`
  - `APP_TAGLINE=Describe your product. Get a week of social content ready to publish.`
  - `APP_DESCRIPTION=Turn a product description into a five-piece social content package in seconds.`
- **Accent color** set to `#4f46e5` (indigo) in `app/assets/stylesheets/_accent.scss`
- **Navbar links** updated to include Products and Content Packages links (authenticated only)
- **Home page** (`home/index.html.erb`) replaced with the Collabimedia landing pitch: headline, subheadline, the three-step workflow (describe, generate, publish), and a prominent "Get started free" call to action
- **Dashboard page** (`dashboard/show.html.erb`) replaced with the user's recent content packages grid, a shortcut button to create a new product, and a "Generate new package" quick-action card
- **UX pattern:** Form-then-result. The user fills out a product form, clicks generate, and sees the five content pieces rendered as styled cards below the form on the result page.
- **AI templates seeded** into `db/seeds.rb`: `collabimedia_content_package_v1`

---

## 3. Data Model

### Product

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key; all records scoped to current user |
| `name` | string | Required; max 100 chars **(template variable)** |
| `description` | text | Required; one to three paragraphs describing the product **(template variable)** |
| `target_audience` | string | Required; max 150 chars; describes the intended buyer or reader **(template variable)** |
| `content_goal` | string | Required; enum: `awareness`, `engagement`, `conversion` **(template variable)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :user`
- `has_many :content_packages, dependent: :destroy`

**Validations:**
- `name`: presence, length (max 100)
- `description`: presence, length (min 50, max 2000)
- `target_audience`: presence, length (max 150)
- `content_goal`: presence, inclusion in `%w[awareness engagement conversion]`

---

### ContentPackage

| Field | Type | Notes |
|---|---|---|
| `id` | uuid | Primary key |
| `product_id` | uuid | Foreign key |
| `user_id` | uuid | Foreign key; denormalized for simpler scoping |
| `linkedin_post` | text | Gemini-generated LinkedIn post |
| `twitter_hook` | text | Gemini-generated Twitter/X thread opener |
| `email_subject` | string | Gemini-generated email subject line |
| `email_preview` | text | Gemini-generated email preview text (30-90 words) |
| `promo_hook` | text | Gemini-generated promotional hook (e.g., ad copy, landing page headline) |
| `community_question` | text | Gemini-generated community engagement question |
| `gemini_raw` | text | Full raw JSON string returned by Gemini **(Gemini output, used for Show raw response toggle)** |
| `created_at` | datetime | |
| `updated_at` | datetime | |

**Associations:**
- `belongs_to :product`
- `belongs_to :user`

**Validations:**
- `product_id`: presence
- `user_id`: presence
- `linkedin_post`: presence
- `twitter_hook`: presence
- `email_subject`: presence
- `email_preview`: presence
- `promo_hook`: presence
- `community_question`: presence

---

## 4. Routes

| Verb | Path | Controller#Action | Purpose |
|---|---|---|---|
| GET | `/products` | `products#index` | List all of the current user's products |
| GET | `/products/new` | `products#new` | New product form |
| POST | `/products` | `products#create` | Save new product; redirect to show |
| GET | `/products/:id` | `products#show` | Product detail with list of its content packages |
| GET | `/products/:id/edit` | `products#edit` | Edit product form |
| PATCH | `/products/:id` | `products#update` | Save product edits; redirect to show |
| DELETE | `/products/:id` | `products#destroy` | Delete product and all its packages |
| GET | `/products/:product_id/content_packages` | `content_packages#index` | All packages for one product (redirect to product show) |
| POST | `/products/:product_id/content_packages` | `content_packages#create` | Trigger Gemini; save package; redirect to show |
| GET | `/products/:product_id/content_packages/:id` | `content_packages#show` | Full package view with all five pieces |
| DELETE | `/products/:product_id/content_packages/:id` | `content_packages#destroy` | Delete a single package |

---

## 5. Controllers and Actions

### `ProductsController`

Inherits from `ApplicationController`. All queries scoped to `current_user`. Uses strong parameters.

- **`index`:** Loads `current_user.products.order(created_at: :desc)` and renders the product list. Shows a "Create your first product" empty-state card when the list is empty.
- **`new`:** Instantiates a new `Product` and renders the creation form.
- **`create`:** Saves a new `Product` with strong params scoped to `current_user`. On success, redirects to `products#show` with a flash notice. On failure, re-renders `new` with validation errors.
- **`show`:** Loads the product and its `content_packages.order(created_at: :desc)`. Renders the product detail page with a "Generate new package" button and the package history list.
- **`edit`:** Loads the product and renders the edit form.
- **`update`:** Saves edits. On success, redirects to `products#show`. On failure, re-renders `edit` with validation errors.
- **`destroy`:** Destroys the product (cascades to content packages). Redirects to `products#index` with a flash notice.

Private helper `set_product` looks up `current_user.products.find(params[:id])` to prevent cross-user access.

---

### `ContentPackagesController`

Inherits from `ApplicationController`. All queries scoped through `current_user`. Uses strong parameters.

- **`create`:** This is the action that triggers the Gemini call. It loads the parent product via `current_user.products.find(params[:product_id])`, then calls:
  ```
  GeminiService.generate(
    template: "collabimedia_content_package_v1",
    variables: {
      product_name: @product.name,
      description: @product.description,
      target_audience: @product.target_audience,
      content_goal: @product.content_goal
    }
  )
  ```
  The raw JSON string returned by Gemini is parsed into individual fields. A `ContentPackage` is created with the parsed fields and the raw string stored in `gemini_raw`. On success, redirects to `content_packages#show`. Catches `GeminiService::GeminiError` (and all subclasses) and renders the boilerplate error partial inline on the product show page with a retry button.
- **`show`:** Loads the package via `current_user.content_packages.find(params[:id])` and renders the full multi-format result view.
- **`destroy`:** Destroys the package and redirects back to the parent product show page.

Private helper `set_product` loads the parent product via `current_user.products.find(params[:product_id])`.

---

## 6. Views

### `home/index.html.erb`

App-specific public landing page. Replaces the boilerplate placeholder. Renders:
- Full-width hero with headline ("Turn your product description into a week of social content"), subheadline, and a "Get started free" button linking to sign-up.
- A three-step how-it-works section: (1) Describe your product, (2) Choose your goal, (3) Copy and publish. Each step uses a Bootstrap icon and two lines of copy.
- A sample output preview section showing anonymized examples of each of the five content types to give visitors a concrete sense of the output format.
- No Turbo Frames or Stimulus behavior; this is a static informational page.

### `dashboard/show.html.erb`

Replaces the boilerplate placeholder. Renders:
- A greeting ("Good morning, [name]") with a "New product" button in the top right.
- A Bootstrap card grid showing the user's three most recent content packages, each with the product name, content goal badge (awareness/engagement/conversion), creation date, and a "View" button.
- A "Create your first product" empty-state card when no packages exist yet.
- No Turbo Frames; standard page navigations.

### `products/index.html.erb`

List of all the user's products. Renders a table: product name, content goal badge, number of packages generated, last updated date, and action links (show, edit, delete). Delete uses a `data-turbo-method="delete"` link with a `data-turbo-confirm` prompt.

### `products/new.html.erb` and `products/edit.html.erb`

Both render the `products/_form.html.erb` partial wrapped in a single-column Bootstrap card.

### `products/_form.html.erb`

Reusable form partial. Fields:
- Product name (text input, required)
- Description (textarea, 6 rows, with helper text: "Describe what your product does, who it helps, and what makes it different.")
- Target audience (text input, with helper text: "e.g., freelance designers who sell digital templates")
- Content goal (Bootstrap radio-button group styled as a button toggle): Awareness, Engagement, Conversion. Each option includes a one-line description below the button.
- Submit and Cancel buttons.

### `products/show.html.erb`

Product detail page. Renders:
- Product name, description, audience, and goal in a summary card at the top.
- A "Generate new content package" button that submits a POST to `content_packages#create` via a Turbo-disabled form (synchronous; see Section 8 on why async is not needed here).
- A loading state managed by a small Stimulus controller (`loading_button_controller.js`) that disables the button and changes its text to "Generating..." on submit.
- Below the generate button, a list of the product's past content packages sorted newest first. Each entry shows creation date and a "View full package" link.
- Empty state copy when no packages exist yet.

### `content_packages/show.html.erb`

The primary result view. Renders five Bootstrap cards, one per content type, stacked vertically. Each card has:
- A header with the content type label (LinkedIn Post, Twitter/X Thread Opener, Email - Subject and Preview, Promotional Hook, Community Question) and a "Copy" button (Stimulus clipboard controller, one per card).
- The generated content in the card body, styled with appropriate formatting (the LinkedIn post and promo hook get slightly larger body text; the email subject is monospaced to distinguish it from the preview).
- A "Show raw Gemini response" toggle at the bottom of the page (not per-card) using Bootstrap collapse. It reveals the full `gemini_raw` field content in a `<pre>` block for debugging and transparency.

A breadcrumb at the top links back to the parent product.

### `content_packages/_error.html.erb`

Inline error partial (from boilerplate). Rendered when a `GeminiService::GeminiError` is caught. Shows a dismissible Bootstrap alert with a friendly message and a "Try again" button that re-submits the generate form.

### Stimulus Controllers Added

- **`loading_button_controller.js`:** On form submit, disables the target button and updates its text to a configurable loading label. Prevents double-submission. Wires up via `data-controller="loading-button"` on the form and `data-loading-button-target="button"` on the submit button.
- **`clipboard_controller.js`:** On click, copies the content of a target element to the clipboard and updates the button text to "Copied!" for 2 seconds. Wires up via `data-controller="clipboard"`.

---

## 7. AI Templates and Gemini Integration

### Template: `collabimedia_content_package_v1`

**Description:** Generates a five-piece social content package (LinkedIn post, Twitter hook, email subject and preview, promo hook, community question) from a product name, description, target audience, and content goal.

**System prompt:**
```
You are an expert content strategist for indie builders and small software teams.
Your job is to take a product description and produce a coordinated five-piece
social content package that the product creator can publish immediately across
multiple channels.

You write in a clear, direct, practitioner voice. You do not use corporate
jargon, hype, or generic filler phrases. Every piece of content must be specific
to the product and audience described - generic output that could apply to any
product is a failure mode.

Always return a single valid JSON object with exactly these six keys:
linkedin_post, twitter_hook, email_subject, email_preview, promo_hook,
community_question. No markdown, no explanation, no preamble. Only the JSON object.
```

**User prompt template:**
```
Product name: {{product_name}}

Product description:
{{description}}

Target audience: {{target_audience}}

Content goal: {{content_goal}}

Generate a five-piece social content package for this product. Tailor every piece
to the content goal specified.

If the goal is "awareness": focus on introducing the problem and the product's
existence. Lead with the pain point. End with a low-commitment call to action
("learn more", "check it out", "I wrote about this").

If the goal is "engagement": focus on starting a conversation, sharing a
counterintuitive insight, or asking a question that the audience has strong
opinions about. Do not pitch the product directly.

If the goal is "conversion": focus on outcomes and specificity. Use concrete
numbers where you can infer them. End with a direct call to action
("grab it here", "try it free", "open it today").

Return only a JSON object with these keys:

- linkedin_post: A 150-250 word LinkedIn post. Use short paragraphs (1-2
  sentences each). No hashtags unless they are highly specific.
- twitter_hook: A single tweet (under 280 characters) that opens a thread.
  It should stand alone as a provocative statement or question.
- email_subject: A subject line under 50 characters. No clickbait, no ALL CAPS,
  no emoji unless the brand voice clearly calls for it.
- email_preview: The preview text that follows the subject (30-80 words). Should
  complement, not repeat, the subject.
- promo_hook: A headline plus one supporting sentence suitable for a landing page,
  ad, or Product Hunt post. Under 30 words total.
- community_question: A discussion question for a Slack group, Discord, or
  Reddit post that relates to the problem this product solves. Under 40 words.
  Do not mention the product by name.
```

**Variables consumed:**
- `{{product_name}}` - from `Product#name`
- `{{description}}` - from `Product#description`
- `{{target_audience}}` - from `Product#target_audience`
- `{{content_goal}}` - from `Product#content_goal` (one of: awareness, engagement, conversion)

**Model:** `gemini-2.0-flash`

**max_output_tokens:** 1500. Six short-to-medium text fields; 1500 tokens is generous without being wasteful.

**temperature:** 0.8. Content writing benefits from a bit of creative variability; the structured JSON output format keeps the response controlled despite the higher temperature.

**Notes:**
The most important failure mode is generic output - content that could apply to any SaaS tool and has no specificity about the product described. Watch for this in the LinkedIn post especially. If it reads like a template, either the description input is too vague or the temperature needs to come down to 0.7 to reduce hedging. A second failure mode is the model adding explanatory text outside the JSON object; the system prompt explicitly forbids this but it occasionally slips through. The response parser should strip any leading/trailing text outside the outermost `{...}` before passing to `JSON.parse`. A third failure mode is the model returning markdown JSON fences (```json ... ```); strip those in the parser as well.

The `content_goal` variable drives meaningfully different output character. Test all three goal values with the same product when evaluating prompt iterations in the admin panel. Conversion-goal output should feel noticeably more transactional than awareness-goal output.

**Where it's called:** `ContentPackagesController#create`.

**Expected output format:** JSON with six string keys: `linkedin_post`, `twitter_hook`, `email_subject`, `email_preview`, `promo_hook`, `community_question`.

**JSON schema:**
```json
{
  "linkedin_post": "string",
  "twitter_hook": "string",
  "email_subject": "string",
  "email_preview": "string",
  "promo_hook": "string",
  "community_question": "string"
}
```

**How the response is parsed and rendered:**
The controller strips any markdown code fences and leading/trailing whitespace from the raw response string, then calls `JSON.parse`. Each key maps directly to a `ContentPackage` attribute. The raw string is stored in `gemini_raw` before parsing. If `JSON.parse` raises `JSON::ParserError`, the controller catches it, logs an error message, and renders the error partial with a "The response was not valid JSON. Try again." message.

**Raw response field:** `ContentPackage#gemini_raw`

---

## 8. AI Safety Considerations (Specific to This App)

**Content sensitivity:** Low. This demo generates marketing copy and social media posts for software products. It does not touch health, legal, financial, or other regulated domains.

**Consequential outputs:** Minimal. The worst realistic outcome is that the user posts AI-generated copy that is slightly off-brand or generic. No user safety risk. The main harm is wasted time publishing bad content, which is self-correcting - bad posts get low engagement and the user tries again. The "Show raw response" toggle and the ability to regenerate multiple packages for the same product already give the user the tools to evaluate quality before acting.

**Domain accuracy requirements:** Low. Content creation is inherently subjective. There are no factual claims that can be "wrong" in the way that, say, medical or legal advice can be. The generated content may be generic or off-target, but it will not be dangerously incorrect.

**App-specific disclaimer:** The boilerplate's footer note ("AI-generated content can be incorrect. Verify before acting.") is sufficient for this app's risk level. The `content_packages/show.html.erb` view should include a short inline note below the generated cards: "Review each piece before publishing. AI content may not fully capture your product voice." This is a UX nudge, not a legal disclaimer.

**Tightened settings:** No special tightening required. The default daily cap of 50 calls per user is appropriate. The gatekeeper's 5000-character input limit comfortably accommodates the combined variables for this template (even a long product description plus target audience is unlikely to exceed 2000 characters). The default 15-second timeout is more than sufficient for this output size.

**What this demo deliberately does NOT do (for safety reasons):**
- Does not publish to any external platform (LinkedIn API, Twitter API, email service). It generates copy; the user pastes it manually. This eliminates a class of unintended publication risks.
- Does not store or learn from user product descriptions to improve future generations. Each call is stateless with respect to prior outputs.
- Does not offer to generate content about other people, competitors, or third-party brands. The prompt is scoped to the user's own product description only.

---

## 9. RSpec Outline

### `spec/models/product_spec.rb`

1. Validates presence of `name`, `description`, `target_audience`, `content_goal`
2. Validates `name` length (max 100 chars)
3. Validates `description` length (min 50, max 2000 chars)
4. Validates `content_goal` is one of `awareness`, `engagement`, `conversion`
5. Destroys associated `content_packages` when a product is destroyed

### `spec/models/content_package_spec.rb`

1. Validates presence of `product_id`, `user_id`, `linkedin_post`, `twitter_hook`, `email_subject`, `email_preview`, `promo_hook`, `community_question`
2. Belongs to a `product`
3. Belongs to a `user`
4. Is retrievable via `user.content_packages`

### `spec/requests/products_spec.rb`

1. `GET /products` returns 200 and lists only the current user's products (not another user's)
2. `POST /products` with valid params creates a product and redirects to show
3. `POST /products` with invalid params (missing description) re-renders new with errors
4. `DELETE /products/:id` destroys the product and its associated packages, redirects to index
5. A signed-in user cannot access another user's product (`/products/:other_user_product_id` returns 404)

### `spec/requests/content_packages_spec.rb`

1. `POST /products/:product_id/content_packages` with stubbed Gemini creates a `ContentPackage` record and redirects to show - verifies that `GeminiService.generate` was called with `template: "collabimedia_content_package_v1"` and the correct variable values
2. `POST /products/:product_id/content_packages` verifies that one `LlmRequest` record is created per Gemini call (status: success)
3. `POST /products/:product_id/content_packages` when `GeminiService` raises `GeminiService::GeminiError` renders the error partial (200 with error message) and does not create a `ContentPackage`
4. `POST /products/:product_id/content_packages` when `GeminiService` raises `GeminiService::BudgetExceededError` renders the budget-exceeded message
5. A signed-in user cannot generate a package for another user's product (`/products/:other_user_product_id/content_packages` with POST returns 404)
6. `GET /products/:product_id/content_packages/:id` for another user's package returns 404

---

## 10. Seed Data

### AiTemplate Seeds

`db/seeds.rb` creates one `AiTemplate` record confirming the values specified in Section 7:

```ruby
AiTemplate.find_or_create_by!(name: "collabimedia_content_package_v1") do |t|
  t.description = "Generates a five-piece social content package from a product description"
  t.system_prompt = <<~PROMPT
    You are an expert content strategist for indie builders and small software teams.
    [full system prompt text from Section 7]
  PROMPT
  t.user_prompt_template = <<~PROMPT
    Product name: {{product_name}}
    [full user prompt template text from Section 7]
  PROMPT
  t.model = "gemini-2.0-flash"
  t.max_output_tokens = 1500
  t.temperature = 0.8
  t.notes = "Higher temperature for creative variability. Watch for generic output on vague descriptions. Strip markdown fences before JSON.parse. Test all three content_goal values when iterating."
end
```

### Domain Seeds

Three sample products with varying product types and content goals are seeded so the demo looks meaningful on first run:

**Product 1 - Awareness goal:**
- Name: "LaunchLog"
- Description: "LaunchLog is a simple changelog and announcement tool for indie SaaS founders. You write one update, LaunchLog formats it for your changelog page, a tweet, and an email to your list. It takes 3 minutes instead of 30."
- Target audience: "solo SaaS founders who ship fast and hate marketing busywork"
- Content goal: "awareness"
- One saved `ContentPackage` with plausible pre-generated copy for each field (no Gemini call needed; values are hardcoded in the seed)

**Product 2 - Conversion goal:**
- Name: "ReviewPilot"
- Description: "ReviewPilot automatically follows up with customers after purchase and routes happy customers to leave a public review while capturing private feedback from unhappy ones. It integrates with Stripe and takes 10 minutes to set up."
- Target audience: "e-commerce founders running Shopify or WooCommerce stores with 50-500 orders per month"
- Content goal: "conversion"
- No pre-generated package; the user clicks "Generate" on first run.

**Product 3 - Engagement goal:**
- Name: "DraftDesk"
- Description: "DraftDesk is a distraction-free writing app for technical bloggers. It auto-generates a title, outline, and meta description from your rough notes, then gets out of the way. No AI editor, no suggestions while you type."
- Target audience: "software developers who want to write but hate starting from a blank page"
- Content goal: "engagement"
- No pre-generated package.

---

## 11. README Additions

### App Name and Tagline

**Collabimedia Demo**
*Describe your product. Get a week of social content ready to publish.*

### Description

Collabimedia Demo turns a plain-English product description into a five-piece social content package: a LinkedIn post, a Twitter/X thread opener, an email subject and preview, a promotional hook, and a community engagement question. Fill in one form. Click generate. Copy and publish.

[Screenshot placeholder - add after first run]

### Why I Built This

The biggest content problem for indie builders is not finding time to write - it is the friction of starting five different pieces for five different channels from the same product idea. Every piece wants a different tone, a different format, and a different call to action, and switching contexts between them eats the hour you blocked for "marketing."

This demo is a standalone version of the content generation engine inside [Collabimedia](https://collabimedia.com) (coming soon), a content production platform for knowledge product businesses. The full platform adds team workspaces, brand voice libraries, content calendars, and direct publishing. This demo shows the core Gemini-powered generation loop that everything else is built on top of.

Built as part of a public GitHub portfolio of open source Rails 8 AI demos. MIT license - clone it, adapt the prompt, use it as a starting point.

### Editing the AI Prompt

The prompt that drives content generation is stored in the database, not in code. After you run `bin/setup`, sign in as `demo@example.com` / `password123` and visit `/admin/ai_templates`. Click the `collabimedia_content_package_v1` template to open the editor.

The right panel auto-detects the `{{variable}}` placeholders and gives you input fields to test the prompt with your own product description. Click "Test" to see Gemini's response inline before saving. Iterate on the system prompt and user prompt template until the output matches your voice.

### Additional Setup

No additional setup beyond `bin/setup`. No external API keys beyond `GEMINI_API_KEY` are required.

---

## 12. Bootstrap Dark Mode and Accent Color Notes

### UX Pattern

This app uses the **form-then-result** pattern. The user fills out a structured form (the product creation form), submits, and the result page renders a set of styled output cards. The form and result live on separate pages; there is no inline-streaming or progressive enhancement beyond the loading button state.

### Accent Color Application

The indigo accent (`#4f46e5`, hover `#4338ca`) is applied consistently via the `--accent` and `--accent-hover` CSS custom properties:

- **Primary buttons:** `background-color: var(--accent)` - used on "Generate content package", "Create product", and "Save" buttons
- **Active nav links:** `color: var(--accent)` on the current page's nav item
- **Content goal radio buttons:** the selected toggle button uses `--accent` as its background
- **Package type badge headers** on the content cards: each card header uses a slightly transparent `--accent` as a left border accent (`border-left: 4px solid var(--accent)`)
- **Links:** `color: var(--accent)` in body text, with `--accent-hover` on hover

### Component Choices

- **Product list:** Bootstrap `table table-hover table-dark` with content goal colored using Bootstrap badge variants (`bg-primary` for awareness, `bg-success` for engagement, `bg-warning text-dark` for conversion)
- **Product form:** Single-column card (`card bg-dark border-secondary`) centered at Bootstrap `col-lg-8` max width
- **Content goal selector:** Bootstrap button group with radio inputs (`btn-check` + `btn-outline-primary` pattern) - three buttons side by side with a one-line description beneath each
- **Content package result cards:** Bootstrap `card mb-3 border-secondary bg-dark` stack. The card header is a muted color with the content type label on the left and "Copy" button on the right.
- **Copy button:** Uses Stimulus clipboard controller; button text changes to "Copied!" for 2 seconds using `--accent` as the success color
- **Raw response toggle:** Bootstrap `collapse` triggered by a small `btn btn-sm btn-outline-secondary` link at the bottom of the show page, labeled "Show raw Gemini response"
- **Loading state:** The generate button uses `btn btn-primary` at rest and adds `disabled` attribute plus spinner HTML on submit via Stimulus

### Custom CSS

Beyond the accent color override in `_accent.scss`, this app adds minimal custom CSS:

```css
/* content_packages.css */
.content-card-header {
  border-left: 4px solid var(--accent);
  padding-left: 0.75rem;
}

.content-goal-description {
  font-size: 0.8rem;
  color: var(--bs-secondary-color);
  margin-top: 0.25rem;
}
```

Everything else uses Bootstrap utility classes directly.

---

*v1.0 - Collabimedia Demo spec. Built on Open Demo Starter v2.0. Open source under MIT license.*

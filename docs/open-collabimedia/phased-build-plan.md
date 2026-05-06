# Collabimedia Demo — Phased Build Plan

**Source spec:** `docs/open-collabimedia/collabimedia-demo-spec.md`
**Built on:** Open Demo Starter (Rails 8, Stimulus, Turbo, Propshaft, Gemini)
**Accent:** `#4f46e5` (indigo), hover `#4338ca`

> Cross-reference these docs before implementing each phase:
> - `docs/turbo-stimulus-patterns.md` — Stimulus controllers, Turbo Stream rules
> - `docs/ai-templates.md` — GeminiService, template creation
> - `docs/ai-guardrails.md` — safety layer, error handling
> - `docs/testing.md` — RSpec factories, stubs, access-control patterns

---

## Phase 1 — App Configuration & Branding

**Goal:** The boilerplate looks and feels like Collabimedia Demo before any domain code exists.

### 1.1 Environment Variables

Update `.env.example` — set the three app identity vars:

```
APP_NAME=Collabimedia Demo
APP_TAGLINE=Describe your product. Get a week of social content ready to publish.
APP_DESCRIPTION=Turn a product description into a five-piece social content package in seconds.
```

Update the user's local `.env` with the same values so the running app picks them up.

### 1.2 Accent Color

In `app/assets/stylesheets/application.css`, update the `:root` CSS custom properties:

```css
:root {
  --accent: #4f46e5;
  --accent-hover: #4338ca;
}
```

Add the content-package-specific utility classes below the accent definition:

```css
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

### 1.3 Navbar

Edit `app/views/layouts/application.html.erb`. Inside the authenticated nav block, add links visible only to signed-in users:

- **Products** → `products_path`
- (Content Packages live under products, no top-level nav entry needed)

Keep the existing Dashboard and Admin links. Order: Dashboard · Products · Admin (admin only).

### 1.4 Home Page (`home/index.html.erb`)

Replace the boilerplate placeholder with:

1. **Hero section** — full-width Bootstrap jumbotron-style div:
   - Headline: "Turn your product description into a week of social content"
   - Subheadline: Use `APP_TAGLINE` env var
   - CTA button: "Get started free" → `sign_up_path`, styled with `btn btn-primary` (accent color)

2. **How it works** — three-column Bootstrap grid (`row row-cols-1 row-cols-md-3`):
   - Step 1: Describe your product (use Bootstrap bi-pencil icon)
   - Step 2: Choose your content goal (bi-bullseye icon)
   - Step 3: Copy and publish (bi-send icon)
   - Each step: icon, bold label, 1-2 sentences of copy

3. **Sample output preview** — five styled cards, one per content type, with hard-coded placeholder copy:
   - LinkedIn Post, Twitter/X Thread Opener, Email (Subject + Preview), Promotional Hook, Community Question
   - Use `card bg-dark border-secondary mb-3` styling
   - Label each card with its content type and a small muted tag

No Turbo Frames, no Stimulus. Static HTML only.

### 1.5 Dashboard (`dashboard/show.html.erb`)

Replace the boilerplate placeholder with:

1. **Header row** — greeting using `current_user.first_name` + "New product" button (`new_product_path`) aligned right.

2. **Recent packages grid** — show `current_user.content_packages.order(created_at: :desc).limit(3)`, each rendered as a Bootstrap card:
   - Product name (via `package.product.name`)
   - Content goal badge (Bootstrap badge: `bg-primary` awareness, `bg-success` engagement, `bg-warning text-dark` conversion)
   - Creation date (formatted: "May 4, 2026")
   - "View" button → `product_content_package_path(package.product, package)`

3. **Empty state** — when `current_user.content_packages.none?`, show a single card with copy: "No content packages yet. Create your first product to get started." + link to `new_product_path`.

No Turbo Frames or Stimulus.

### Phase 1 Manual Tests

After completing this phase:

1. Start the server (`bin/dev`) and visit `/` — confirm the hero, how-it-works, and sample output sections render correctly with dark Bootstrap styling.
2. Sign in as `demo@example.com / password123`, confirm the dashboard shows the empty-state card.
3. Verify the navbar shows Dashboard and Products links for a signed-in user.
4. Verify the accent color (indigo buttons, links) is applied site-wide.
5. Sign out and confirm Products link is not visible to unauthenticated users.

---

## Phase 2 — Data Model

**Goal:** `Product` and `ContentPackage` models exist with correct validations and associations.

### 2.1 Product Migration

Generate and run a migration for the `products` table:

```ruby
create_table :products, id: :uuid do |t|
  t.references :user, null: false, foreign_key: true, type: :uuid
  t.string  :name,            null: false, limit: 100
  t.text    :description,     null: false
  t.string  :target_audience, null: false, limit: 150
  t.string  :content_goal,    null: false
  t.timestamps null: false
end
```

### 2.2 Product Model (`app/models/product.rb`)

```ruby
class Product < ApplicationRecord
  belongs_to :user
  has_many :content_packages, dependent: :destroy

  validates :name,            presence: true, length: { maximum: 100 }
  validates :description,     presence: true, length: { minimum: 50, maximum: 2000 }
  validates :target_audience, presence: true, length: { maximum: 150 }
  validates :content_goal,    presence: true,
                              inclusion: { in: %w[awareness engagement conversion] }
end
```

### 2.3 ContentPackage Migration

Generate and run a migration for the `content_packages` table:

```ruby
create_table :content_packages, id: :uuid do |t|
  t.references :product, null: false, foreign_key: true, type: :uuid
  t.references :user,    null: false, foreign_key: true, type: :uuid
  t.text :linkedin_post,       null: false
  t.text :twitter_hook,        null: false
  t.string :email_subject,     null: false
  t.text :email_preview,       null: false
  t.text :promo_hook,          null: false
  t.text :community_question,  null: false
  t.text :gemini_raw
  t.timestamps null: false
end

add_index :content_packages, :created_at
```

### 2.4 ContentPackage Model (`app/models/content_package.rb`)

```ruby
class ContentPackage < ApplicationRecord
  belongs_to :product
  belongs_to :user

  validates :product_id,        presence: true
  validates :user_id,           presence: true
  validates :linkedin_post,     presence: true
  validates :twitter_hook,      presence: true
  validates :email_subject,     presence: true
  validates :email_preview,     presence: true
  validates :promo_hook,        presence: true
  validates :community_question, presence: true
end
```

### 2.5 User Model Update

Add to `app/models/user.rb`:

```ruby
has_many :products, dependent: :destroy
has_many :content_packages, dependent: :destroy
```

### 2.6 Factories

**`spec/factories/products.rb`:**

```ruby
FactoryBot.define do
  factory :product do
    association :user
    sequence(:name) { |n| "Product #{n}" }
    description     { "This is a detailed product description that is at least fifty characters long and explains what the product does." }
    target_audience { "indie SaaS founders who ship fast" }
    content_goal    { "awareness" }

    trait :engagement  { content_goal { "engagement" } }
    trait :conversion  { content_goal { "conversion" } }
  end
end
```

**`spec/factories/content_packages.rb`:**

```ruby
FactoryBot.define do
  factory :content_package do
    association :product
    association :user
    linkedin_post      { "A compelling LinkedIn post about the product." }
    twitter_hook       { "A punchy Twitter thread opener under 280 characters." }
    email_subject      { "Try this new tool" }
    email_preview      { "A short preview text that complements the subject line and gives context." }
    promo_hook         { "The hook headline. One supporting sentence." }
    community_question { "What is the biggest challenge you face when trying to do X?" }
    gemini_raw         { '{"linkedin_post":"...","twitter_hook":"...","email_subject":"...","email_preview":"...","promo_hook":"...","community_question":"..."}' }
  end
end
```

### Phase 2 Manual Tests

1. Run `rails db:migrate` — confirm no errors and the schema shows both tables.
2. Open `rails console` and run:
   - `Product.new.valid?` → false (missing fields)
   - `Product.new(name: "x", description: "short", target_audience: "y", content_goal: "awareness").valid?` → false (description too short)
   - `Product.new(name: "x", description: "a" * 50, target_audience: "y", content_goal: "invalid").valid?` → false (invalid goal)
3. Confirm `User` now has `has_many :products` and `has_many :content_packages`.

---

## Phase 3 — Routes & Controllers

**Goal:** All CRUD routes exist and are accessible. `ContentPackagesController#create` is a placeholder (no Gemini call yet) so we can test routing end-to-end.

### 3.1 Routes (`config/routes.rb`)

Add inside the existing routes block:

```ruby
resources :products do
  resources :content_packages, only: [:index, :create, :show, :destroy]
end
```

### 3.2 ProductsController (`app/controllers/products_controller.rb`)

All actions scoped to `current_user`. Private `set_product` uses `current_user.products.find(params[:id])` — raises `ActiveRecord::RecordNotFound` (auto-404) for cross-user access.

```ruby
class ProductsController < ApplicationController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

  def index
    @products = current_user.products.order(created_at: :desc)
  end

  def new
    @product = Product.new
  end

  def create
    @product = current_user.products.build(product_params)
    if @product.save
      redirect_to @product, notice: "Product created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @content_packages = @product.content_packages.order(created_at: :desc)
  end

  def edit; end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Product deleted."
  end

  private

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :target_audience, :content_goal)
  end
end
```

### 3.3 ContentPackagesController (`app/controllers/content_packages_controller.rb`)

Phase 3 placeholder — `create` is stubbed. Full Gemini integration is Phase 5.

```ruby
class ContentPackagesController < ApplicationController
  before_action :set_product

  def index
    redirect_to @product
  end

  def create
    # Placeholder — Phase 5 replaces this body with the Gemini call
    redirect_to @product, alert: "Generation not yet implemented."
  end

  def show
    @content_package = current_user.content_packages.find(params[:id])
  end

  def destroy
    @content_package = current_user.content_packages.find(params[:id])
    @content_package.destroy
    redirect_to @product, notice: "Package deleted."
  end

  private

  def set_product
    @product = current_user.products.find(params[:product_id])
  end
end
```

### Phase 3 Manual Tests

1. Run `rails routes | grep product` — confirm all expected routes are listed.
2. Sign in and visit `/products` — should redirect to sign-in if unauthenticated (boilerplate `require_authentication`).
3. Visit `/products/new` — should render the new form (even if unstyled).
4. Manually hit `/products/FAKE_ID` — should return 404, not 500.

---

## Phase 4 — Views & Stimulus Controllers

**Goal:** All product and content-package views are fully styled and functional. Stimulus controllers handle the loading button and clipboard copy.

### 4.1 Stimulus: `loading_button_controller.js`

File: `app/javascript/controllers/loading_button_controller.js`

- Connects to a form via `data-controller="loading-button"`
- Has one target: `button` (`data-loading-button-target="button"`)
- Has one value: `loadingLabel` (string, default "Generating...")
- On `submit` of the form: disables the button, sets its `textContent` to `loadingLabel`, and adds a Bootstrap spinner span before the text.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values  = { loadingLabel: { type: String, default: "Generating..." } }

  submit() {
    const btn = this.buttonTarget
    btn.disabled = true
    btn.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status"></span>${this.loadingLabelValue}`
  }
}
```

Wire up on the generate form:
```erb
data-controller="loading-button"
data-action="submit->loading-button#submit"
```
And on the button:
```erb
data-loading-button-target="button"
```

### 4.2 Stimulus: `clipboard_controller.js`

File: `app/javascript/controllers/clipboard_controller.js`

- Connects to each content card
- Target: `source` — the element whose text to copy
- Target: `button` — the copy button
- Value: `successLabel` (string, default "Copied!")
- On click: copies `sourceTarget.innerText` to clipboard, sets button text to `successLabel` for 2 seconds, then restores the original label.

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static values  = { successLabel: { type: String, default: "Copied!" } }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.innerText)
    const btn = this.buttonTarget
    const original = btn.textContent
    btn.textContent = this.successLabelValue
    setTimeout(() => { btn.textContent = original }, 2000)
  }
}
```

### 4.3 `products/index.html.erb`

Table: `table table-hover table-dark table-bordered`. Columns:
- Product name (linked to `product_path`)
- Content goal badge (`bg-primary`/`bg-success`/`bg-warning text-dark`)
- Packages count (`product.content_packages.count`)
- Last updated (formatted date)
- Actions: Show, Edit, Delete (Turbo confirm delete)

Empty state: Bootstrap alert or card with "No products yet. Create your first product." + link to `new_product_path`.

### 4.4 `products/new.html.erb` and `products/edit.html.erb`

Both wrap `products/_form.html.erb` in a `col-lg-8 mx-auto` card.

```erb
<div class="container py-4">
  <div class="row">
    <div class="col-lg-8 mx-auto">
      <div class="card bg-dark border-secondary">
        <div class="card-header">
          <h4 class="mb-0"><%= @product.new_record? ? "New Product" : "Edit Product" %></h4>
        </div>
        <div class="card-body">
          <%= render "form", product: @product %>
        </div>
      </div>
    </div>
  </div>
</div>
```

### 4.5 `products/_form.html.erb`

Fields:
1. **Product name** — `text_field`, required, maxlength 100
2. **Description** — `text_area`, 6 rows, with `form-text`: "Describe what your product does, who it helps, and what makes it different."
3. **Target audience** — `text_field` with `form-text`: "e.g., freelance designers who sell digital templates"
4. **Content goal** — Bootstrap button-group with radio inputs (`btn-check` + `btn-outline-primary`):
   - Three buttons: Awareness, Engagement, Conversion
   - Below each button, a `<div class="content-goal-description">` with a one-line description:
     - Awareness: "Introduce the problem and your product's existence."
     - Engagement: "Start a conversation or share a counterintuitive insight."
     - Conversion: "Drive action with concrete outcomes and a direct CTA."

Validation errors: render `@product.errors.full_messages` in a Bootstrap danger alert above the form fields if errors present.

Submit + Cancel buttons.

### 4.6 `products/show.html.erb`

Layout:
1. **Summary card** — product name as `<h2>`, description, audience, and goal badge in a `card bg-dark border-secondary`.
2. **Generate form** — a `form_with` POSTing to `product_content_packages_path(@product)`:
   - `data-controller="loading-button" data-action="submit->loading-button#submit"` on the form
   - One submit button: "Generate new content package", styled `btn btn-primary`, with `data-loading-button-target="button"`
3. **Packages list** — below the form, `@content_packages.each` rendered as a Bootstrap list group or simple card stack. Each entry: creation timestamp + "View full package" link → `product_content_package_path(@product, pkg)`.
4. **Empty state** — when no packages: "No packages yet. Click Generate to create your first one."

### 4.7 `content_packages/show.html.erb`

Breadcrumb at top: Products › Product Name › Content Package.

Five Bootstrap cards (`card mb-3 border-secondary bg-dark`), one per content type:

For each card, wrap in `data-controller="clipboard"`:
- **Card header** (`card-header content-card-header`):
  - Left: content type label (e.g., "LinkedIn Post")
  - Right: "Copy" button with `data-action="click->clipboard#copy" data-clipboard-target="button"`
- **Card body**: the generated text in a `<p data-clipboard-target="source">` element
- Special styling: email subject in `<code>` (monospace), LinkedIn post and promo hook in slightly larger text (`fs-5`)

Below all cards:
- Inline note: "Review each piece before publishing. AI content may not fully capture your product voice." (muted text)
- Bootstrap collapse toggle: "Show raw Gemini response" → reveals `<pre><%= @content_package.gemini_raw %></pre>`
- Delete button → `product_content_package_path(@product, @content_package)` with `data-turbo-method="delete"` and `data-turbo-confirm`
- "Back to product" link → `product_path(@product)`

### Phase 4 Manual Tests

1. Visit `/products/new` — confirm the form renders with the radio button group for content goal. Select each goal and confirm it highlights correctly.
2. Submit with empty fields — confirm validation errors appear above the form.
3. Create a product successfully — confirm redirect to product show with "Product created" flash.
4. Visit the product show — confirm the generate form renders with the loading button controller.
5. Click "Generate new content package" — button should disable and show spinner (even though it's a placeholder redirect for now).
6. Verify delete with confirm dialog on `/products` index.
7. Verify accent color (indigo) on primary buttons.

---

## Phase 5 — AI Integration & Seeds

**Goal:** `ContentPackagesController#create` calls Gemini, parses the JSON response, and saves a `ContentPackage`. Seeds provide the `collabimedia_content_package_v1` template and three sample products.

### 5.1 Seed the AI Template

Replace the `demo_placeholder_v1` seed block in `db/seeds.rb` with (or add alongside it):

```ruby
AiTemplate.find_or_create_by!(name: "collabimedia_content_package_v1") do |t|
  t.description = "Generates a five-piece social content package from a product description"
  t.system_prompt = <<~PROMPT
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
  PROMPT
  t.user_prompt_template = <<~PROMPT
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
  PROMPT
  t.model            = "gemini-2.5-flash"
  t.max_output_tokens = 1500
  t.temperature      = 0.8
  t.notes            = "Higher temperature for creative variability. Watch for generic output on vague descriptions. Strip markdown fences before JSON.parse. Test all three content_goal values when iterating."
end

puts "Seeded: collabimedia_content_package_v1 AI template"
```

> **Note:** The spec specifies `gemini-2.0-flash` but `docs/ai-templates.md` documents that model as deprecated/unavailable for new API keys. Use `gemini-2.5-flash` instead.

### 5.2 Seed Domain Data

Add to `db/seeds.rb` after the template seed:

```ruby
demo_user = User.find_by!(email: "demo@example.com")

# Product 1 — LaunchLog (awareness) with one pre-built package
launchlog = Product.find_or_create_by!(name: "LaunchLog", user: demo_user) do |p|
  p.description     = "LaunchLog is a simple changelog and announcement tool for indie SaaS founders. You write one update, LaunchLog formats it for your changelog page, a tweet, and an email to your list. It takes 3 minutes instead of 30."
  p.target_audience = "solo SaaS founders who ship fast and hate marketing busywork"
  p.content_goal    = "awareness"
end

ContentPackage.find_or_create_by!(product: launchlog, user: demo_user) do |cp|
  cp.linkedin_post      = "Most indie SaaS founders ship updates constantly but never tell anyone.\n\nThere's always something more urgent than writing the changelog. Then three months pass and customers don't know about features you built for them.\n\nLaunchLog solves the announcement problem without adding a new writing task to your week. You write one plain-English update. LaunchLog formats it for your changelog page, turns it into a tweet, and drafts an email to your list.\n\nThree minutes. Three channels. Done.\n\nIf you're shipping fast and your customers aren't keeping up, check it out."
  cp.twitter_hook       = "I ship updates constantly but almost never announce them. Building the fix."
  cp.email_subject      = "Your users don't know what you built"
  cp.email_preview      = "If you're like most solo founders, you ship features faster than you announce them. The changelog stays empty. The email list goes quiet. LaunchLog turns one update into a changelog entry, a tweet, and an email draft in under three minutes."
  cp.promo_hook         = "One update, three channels, three minutes. LaunchLog turns your shipping habit into a marketing habit."
  cp.community_question = "How do you handle the gap between shipping a feature and actually telling your users about it? What's your current system?"
  cp.gemini_raw         = "{\"linkedin_post\":\"...\",\"twitter_hook\":\"...\",\"email_subject\":\"...\",\"email_preview\":\"...\",\"promo_hook\":\"...\",\"community_question\":\"...\"}"
end

# Product 2 — ReviewPilot (conversion) — no pre-built package
Product.find_or_create_by!(name: "ReviewPilot", user: demo_user) do |p|
  p.description     = "ReviewPilot automatically follows up with customers after purchase and routes happy customers to leave a public review while capturing private feedback from unhappy ones. It integrates with Stripe and takes 10 minutes to set up."
  p.target_audience = "e-commerce founders running Shopify or WooCommerce stores with 50-500 orders per month"
  p.content_goal    = "conversion"
end

# Product 3 — DraftDesk (engagement) — no pre-built package
Product.find_or_create_by!(name: "DraftDesk", user: demo_user) do |p|
  p.description     = "DraftDesk is a distraction-free writing app for technical bloggers. It auto-generates a title, outline, and meta description from your rough notes, then gets out of the way. No AI editor, no suggestions while you type."
  p.target_audience = "software developers who want to write but hate starting from a blank page"
  p.content_goal    = "engagement"
end

puts "Seeded: 3 demo products for demo@example.com"
```

### 5.3 ContentPackagesController#create — Full Implementation

Replace the Phase 3 placeholder `create` action:

```ruby
def create
  raw_response = GeminiService.generate(
    template:  "collabimedia_content_package_v1",
    variables: {
      product_name:    @product.name,
      description:     @product.description,
      target_audience: @product.target_audience,
      content_goal:    @product.content_goal
    }
  )

  parsed = parse_gemini_json(raw_response)

  @content_package = current_user.content_packages.build(
    product:            @product,
    linkedin_post:      parsed["linkedin_post"],
    twitter_hook:       parsed["twitter_hook"],
    email_subject:      parsed["email_subject"],
    email_preview:      parsed["email_preview"],
    promo_hook:         parsed["promo_hook"],
    community_question: parsed["community_question"],
    gemini_raw:         raw_response
  )

  if @content_package.save
    redirect_to product_content_package_path(@product, @content_package),
                notice: "Content package generated."
  else
    flash.now[:alert] = "Could not save the generated package."
    render "products/show", status: :unprocessable_entity
  end

rescue JSON::ParserError
  flash.now[:alert] = "The response was not valid JSON. Please try again."
  @content_packages = @product.content_packages.order(created_at: :desc)
  render "products/show", status: :unprocessable_entity
rescue GeminiService::BudgetExceededError
  render partial: "shared/ai_error", locals: { error_type: :budget_exceeded }
rescue GeminiService::GatekeeperError
  render partial: "shared/ai_error", locals: { error_type: :gatekeeper_blocked }
rescue GeminiService::TimeoutError
  render partial: "shared/ai_error", locals: { error_type: :timeout }
rescue GeminiService::GeminiError
  render partial: "shared/ai_error", locals: { error_type: :error }
end
```

Private parse method:

```ruby
def parse_gemini_json(raw)
  # Strip markdown fences if present
  cleaned = raw.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "").strip
  # Extract the first {...} block if there is preamble
  cleaned = cleaned[/\{.*\}/m] || cleaned
  JSON.parse(cleaned)
end
```

### 5.4 Rate Limiting

Add to `ContentPackagesController`:

```ruby
rate_limit to: 10, within: 1.minute, only: [:create],
           with: -> { redirect_to @product, alert: "Please wait before generating again." }
```

### Phase 5 Manual Tests

1. Run `rails db:seed` — confirm no errors; check admin panel at `/admin/ai_templates` to verify `collabimedia_content_package_v1` appears.
2. Sign in and visit `/products` — confirm the three demo products appear.
3. Click on LaunchLog — confirm the pre-built content package appears in the package history.
4. Click "View full package" on LaunchLog's package — confirm all five content cards render correctly.
5. Click "Copy" on the LinkedIn Post card — confirm the button text changes to "Copied!" for 2 seconds.
6. Click "Show raw Gemini response" — confirm the Bootstrap collapse reveals the raw JSON.
7. Click "Generate new content package" on ReviewPilot — confirm the button shows a spinner while waiting, then redirects to the new package show page with all five content cards populated.
8. Generate with all three content goal types (awareness/engagement/conversion) and compare the character of the output.
9. Delete a content package — confirm redirect to product show and package is gone from the list.
10. Delete a product — confirm redirect to `/products` and all its packages are gone.
11. Visit `/admin/llm_requests` — confirm one LlmRequest row per generated package with status "success".

---

## Phase 6 — RSpec Tests

**Goal:** Full test coverage per the spec's RSpec outline. No real Gemini API calls.

### 6.1 `spec/models/product_spec.rb`

Tests:
1. Validates presence of `name`, `description`, `target_audience`, `content_goal`
2. Validates `name` max length (100 chars)
3. Validates `description` min length (50 chars) and max length (2000 chars)
4. Validates `content_goal` inclusion: `%w[awareness engagement conversion]`
5. Destroys associated `content_packages` when a product is destroyed (`dependent: :destroy`)

### 6.2 `spec/models/content_package_spec.rb`

Tests:
1. Validates presence of `product_id`, `user_id`, `linkedin_post`, `twitter_hook`, `email_subject`, `email_preview`, `promo_hook`, `community_question`
2. `belongs_to :product`
3. `belongs_to :user`
4. Is retrievable via `user.content_packages` (verifies denormalized `user_id` association works)

### 6.3 `spec/requests/products_spec.rb`

Structure — for each action, verify the three access-control cases (unauthenticated → sign-in, own resource → success, other user's resource → 404):

1. `GET /products` — returns 200, lists only current user's products (not another user's)
2. `GET /products/new` — returns 200 for signed-in user; redirect for unauthenticated
3. `POST /products` with valid params — creates a product, redirects to show
4. `POST /products` with invalid params (blank description) — re-renders new with 422
5. `GET /products/:id` — 200 for owner; 404 for another user's product
6. `PATCH /products/:id` with valid params — redirects to show
7. `DELETE /products/:id` — destroys product and its packages, redirects to index
8. Cross-user access: `GET /products/:other_user_product_id` returns 404

### 6.4 `spec/requests/content_packages_spec.rb`

1. `POST /products/:product_id/content_packages` — with stubbed Gemini returning valid JSON: creates a `ContentPackage`, redirects to show. Verifies `GeminiService.generate` was called with `template: "collabimedia_content_package_v1"` and the correct variable hash.
2. Same POST — verifies one `LlmRequest` record with `status: "success"` is created per call.
3. Same POST — when Gemini returns invalid (non-JSON) response: re-renders product show with JSON parse error message, does not create a `ContentPackage`.
4. Same POST — when `GeminiService` raises `GeminiService::GeminiError`: renders the error partial, does not create a `ContentPackage`.
5. Same POST — when `GeminiService` raises `GeminiService::BudgetExceededError`: renders the budget-exceeded message.
6. Cross-user: `POST /products/:other_user_product_id/content_packages` returns 404.
7. `GET /products/:product_id/content_packages/:id` for own package — returns 200.
8. `GET /products/:product_id/content_packages/:id` for another user's package — returns 404.
9. `DELETE /products/:product_id/content_packages/:id` — destroys the package, redirects to product show.

### Gemini Stub Response

For tests that need a parseable Gemini response, use `gemini_returns` with a valid JSON string:

```ruby
VALID_GEMINI_JSON = {
  linkedin_post:      "A compelling LinkedIn post.",
  twitter_hook:       "A punchy Twitter hook.",
  email_subject:      "Try this",
  email_preview:      "Here is why you should try it today.",
  promo_hook:         "The headline. One sentence.",
  community_question: "What is your biggest challenge with X?"
}.to_json

# In test:
gemini_returns(VALID_GEMINI_JSON)
```

### Phase 6 Manual Tests (After Running RSpec)

1. `bundle exec rspec spec/models/product_spec.rb` — all green
2. `bundle exec rspec spec/models/content_package_spec.rb` — all green
3. `bundle exec rspec spec/requests/products_spec.rb` — all green
4. `bundle exec rspec spec/requests/content_packages_spec.rb` — all green
5. `bundle exec rspec` — full suite passes with zero real API calls

---

## Cross-Phase Checklist

After all phases are complete, verify:

- [ ] `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION` never hardcoded in views — always use `ENV.fetch`
- [ ] No `replace()` Turbo Stream calls — only `update()` (only Turbo Stream in this app is the admin template test panel, which is boilerplate)
- [ ] No plain JavaScript — all interactions via Stimulus controllers
- [ ] All Gemini calls go through `GeminiService.generate` — no direct API calls
- [ ] All four `GeminiService` error types caught in `ContentPackagesController#create`
- [ ] `shared/_ai_error` partial used for all AI error states
- [ ] Admin panel at `/admin/llm_requests` shows all generated packages
- [ ] `gemini_raw` is stored on every `ContentPackage`
- [ ] No real API calls in the test suite
- [ ] Factories exist for `Product` and `ContentPackage`
- [ ] All routes use named helpers, never string paths
- [ ] Delete actions use `data-turbo-method="delete"` + `data-turbo-confirm`, never button_to inside a form

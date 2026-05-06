# Collabimedia Demo — Build Task Tracker

Full spec: `docs/open-collabimedia/collabimedia-demo-spec.md`
Implementation guide: `docs/open-collabimedia/phased-build-plan.md`

---

## Phase 1 — App Configuration & Branding ✅

- [x] 1.1 Update `.env.example` with `APP_NAME`, `APP_TAGLINE`, `APP_DESCRIPTION`
- [x] 1.2 Update local `.env` with same values
- [x] 1.3 Set accent color `--accent: #4f46e5` and `--accent-hover: #4338ca` in `application.css`
- [x] 1.4 Add `.content-card-header` and `.content-goal-description` CSS rules to `application.css`
- [x] 1.5 Add Products nav link to `layouts/application.html.erb` (authenticated only)
- [x] 1.6 Replace `home/index.html.erb` — hero, how-it-works (3 steps), sample output preview (5 cards)
- [x] 1.7 Replace `dashboard/show.html.erb` — greeting, 3 recent packages grid, empty state
- [x] Bootstrap Icons CDN added to layout `<head>`
- [x] `time_of_day_greeting` helper added to `ApplicationHelper`
- [x] Manual tests verified in browser

---

## Phase 2 — Data Model ✅

- [x] 2.1 `db/migrate/20260504000001_create_products.rb` written
- [x] 2.2 `db/migrate/20260504000002_create_content_packages.rb` written
- [x] 2.3 `rails db:migrate` — run and verified
- [x] 2.4 Create `app/models/product.rb` with associations and validations
- [x] 2.5 Create `app/models/content_package.rb` with associations and validations
- [x] 2.6 Add `has_many :products` and `has_many :content_packages` to `app/models/user.rb`
- [x] 2.7 Create `spec/factories/products.rb` (with `:engagement` and `:conversion` traits)
- [x] 2.8 Create `spec/factories/content_packages.rb`

---

## Phase 3 — Routes & Controllers ✅

- [x] 3.1 Nested routes added to `config/routes.rb`
- [x] 3.2 `app/controllers/products_controller.rb` created (all CRUD actions)
- [x] 3.3 `app/controllers/content_packages_controller.rb` created (full Gemini implementation)
- [x] Manual tests verified in browser

---

## Phase 4 — Views & Stimulus Controllers ✅

- [x] 4.1 `app/javascript/controllers/loading_button_controller.js`
- [x] 4.2 `app/javascript/controllers/clipboard_controller.js`
- [x] 4.3 `app/views/products/index.html.erb`
- [x] 4.4 `app/views/products/new.html.erb`
- [x] 4.5 `app/views/products/edit.html.erb`
- [x] 4.6 `app/views/products/_form.html.erb`
- [x] 4.7 `app/views/products/show.html.erb`
- [x] 4.8 `app/views/content_packages/show.html.erb`
- [x] Manual tests verified in browser

---

## Phase 5 — AI Integration & Seeds ✅

- [x] 5.1 `demo_placeholder_v1` removed from `db/seeds.rb`
- [x] 5.2 `collabimedia_content_package_v1` AiTemplate seed added — `gemini-2.5-flash`, `max_output_tokens: 8192` (raised from 1500; thinking tokens count against this cap), temp 0.8
- [x] 5.3 Domain seeds added: LaunchLog (with pre-built ContentPackage), ReviewPilot, DraftDesk
- [x] 5.4 `rails db:seed` — run and verified
- [x] 5.5 `ContentPackagesController#create` — full Gemini call implementation
- [x] 5.6 `parse_gemini_json` — strips all markdown fences, extracts first `{` to last `}`, handles thinking-model preamble
- [x] 5.7 `rescue JSON::ParserError` handler in `create`
- [x] 5.8 Rate limiting: 10 creates per minute on `ContentPackagesController`
- [x] 5.9 `gemini_raw` stored on every saved ContentPackage
- [x] `GeminiService#call_gemini` filters out `thought: true` parts before joining response text
- [x] Custom instructions modal — optional textarea before generation, passed as `{{custom_instructions}}` variable
- [x] Loading animation with animated progress bar and Cancel link
- [x] Manual tests verified in browser

---

## Phase 6 — RSpec Tests ✅

- [x] 6.1 `spec/models/product_spec.rb`
- [x] 6.2 `spec/models/content_package_spec.rb`
- [x] 6.3 `spec/requests/products_spec.rb`
- [x] 6.4 `spec/requests/content_packages_spec.rb`
- [x] 6.5 `VALID_GEMINI_JSON` constant defined in content_packages spec
- [x] `shoulda-matchers` gem added and configured
- [x] Full suite passing — 133 examples, 0 failures

---

## Post-Build Fixes ✅

- [x] `shoulda-matchers` missing from Gemfile — added to `:test` group
- [x] `rescue_from RecordNotFound` rendered 404 instead of redirecting — fixed in `ApplicationController`
- [x] Gemini 2.5 Flash thinking tokens exhausting `maxOutputTokens` — raised to 8192
- [x] Gemini thinking parts polluting response text — filtered with `.reject { |p| p["thought"] }`
- [x] JSON extraction failing on fenced/preambled responses — `parse_gemini_json` rewritten to strip all fences and use `index`/`rindex`

---

## Final Cross-Phase Verification ✅

- [x] `APP_NAME` / `APP_TAGLINE` / `APP_DESCRIPTION` never hardcoded — always `ENV.fetch`
- [x] No `turbo_stream.replace()` calls — only `turbo_stream.update()`
- [x] No plain JavaScript — all interactions via Stimulus controllers
- [x] All Gemini calls routed through `GeminiService.generate`
- [x] All four error types caught in `ContentPackagesController#create`
- [x] `shared/_ai_error` partial used for all AI error states
- [x] `gemini_raw` stored on every `ContentPackage`
- [x] No real API calls in test suite — `gemini_returns` / `gemini_raises` used throughout
- [x] All routes use named helpers (never string paths)
- [x] Delete actions use `data-turbo-method="delete"` + `data-turbo-confirm`
- [x] README updated with app name, description, setup instructions, and prompt editing note
- [x] `config/database.yml` renamed from `open_base_*` to `open_collabimedia_*`

---

## Status: COMPLETE ✅

All phases built, tested, and verified in browser. No open tasks.

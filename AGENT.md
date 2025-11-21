# AGENT.md — General Ruby on Rails Engineering Agent

This project includes several domain-specific guides that MUST be loaded and followed by the AI assistant.

### Project Guides
- [GUIDE.md](GUIDE.md)
- [MMO_ADDITIONAL_GUIDE.md](MMO_ADDITIONAL_GUIDE.md)
- [MMO_ENGINE_SKELETON.md](MMO_ENGINE_SKELETON.md)
- [MMO_TESTING_GUIDE.md](doc/MMO_TESTING_GUIDE.md)
- [MAP_DESIGN_GUIDE.md](doc/MAP_DESIGN_GUIDE.md)
- [ITEM_SYSTEM_GUIDE.md](doc/ITEM_SYSTEM_GUIDE.md)
- [COMBAT_SYSTEM_GUIDE.md](doc/COMBAT_SYSTEM_GUIDE.md)

### When to use each guide
- Use **GUIDE.md** for all normal Rails coding tasks.
- Use **MMO_ADDITIONAL_GUIDE.md** when implementing or modifying ANY gameplay systems.
- Use **MMO_ENGINE_SKELETON.md** when creating new engine classes or folders.
- Use **MMO_TESTING_GUIDE.md** when writing or updating tests for game logic.
- Use **MAP_DESIGN_GUIDE.md** for any work related to zones, maps, tiles, or movement.
- Use **ITEM_SYSTEM_GUIDE.md** for items, inventory, equipment, loot, or crafting.
- Use **COMBAT_SYSTEM_GUIDE.md** for combat, skills, buffs/debuffs, turn resolution, and battle flow.

This repository is a **Ruby on Rails application** (HTML + Hotwire and optionally JSON APIs).
This file defines how the engineering agent should behave when making changes.

If this file conflicts with **project-specific docs** (`README`, `CONTRIBUTING`, etc.), **project docs win**.

---

## 1. Setup (run first)

- Use Ruby from `.ruby-version` or `Gemfile`.
- Install dependencies:

  ```bash
  bundle install
  ```

- Prepare databases (development + test), typically:

  ```bash
  bin/rails db:prepare
  ```

- If present, always prefer project wrappers such as:

  ```bash
  bin/setup
  bin/dev
  bin/ci
  ```

  instead of manually wiring processes.

- Follow any additional setup instructions described in the project `README` (JS bundler, Redis, Sidekiq, etc.).

---

## 2. Common development commands

These are **typical** commands for a Rails app. Use the ones that exist in this project;
if a command is missing, skip it and mention that in your CHECKS.

### 2.1 Development & console

- `bin/dev` — start the full dev stack (Rails, JS bundler, background workers) if defined.
- `bin/rails server` — start Rails server only.
- `bin/rails console` — open Rails console.

### 2.2 Tests

Depending on whether the project uses Minitest or RSpec:

- **Minitest style**:
  - `bin/rails test` — run all tests.
  - `bin/rails test:system` — system tests (use sparingly, they are slower).
  - `bin/rails test path/to/test_file.rb` — specific test file.
  - `bin/rails test path/to/test_file.rb:42` — specific test at line.

- **RSpec style**:
  - `bundle exec rspec` — run the full RSpec suite.
  - `bundle exec rspec spec/models/user_spec.rb` — specific spec file.
  - `bundle exec rspec spec/models/user_spec.rb:42` — specific example at line.

### 2.3 Linting & security

- `bundle exec rubocop` — Ruby linting.
- `bundle exec brakeman` or `bin/brakeman` — security analysis (if configured).
- `bundle exec bundle audit check --update` — check Gem vulnerabilities.
- If the project has JS tooling:
  - `npm run lint` / `yarn lint` — JS/TS lint.
  - `npm run format` / `yarn format` — JS/TS format.

### 2.4 Database

- `bin/rails db:prepare` — create and migrate DB (dev + test).
- `bin/rails db:migrate` — run pending migrations.
- `bin/rails db:rollback` — rollback last migration.
- `bin/rails db:seed` — load seed data.

---

## 3. Verification checklist (before pushing / opening a PR)

**Always** run the relevant subset of these before considering a change “done”.
If a command is not available in this project, skip it and note that explicitly.

1. **Tests** (required):
   - Minitest: `bin/rails test`
   - or RSpec: `bundle exec rspec`
   - Optionally: `bin/rails test:system` or system/feature specs when UI changes are significant.

2. **Linting** (recommended/required where configured):
   - `bundle exec rubocop`
   - `bundle exec standardrb`

3. **Security** (where configured):
   - `bundle exec brakeman` or `bin/brakeman`
   - `bundle exec bundle audit check --update`

4. **JS/Frontend** (if the project uses a JS toolchain):
   - `npm run lint` / `yarn lint`
   - `npm run test` / `yarn test` if applicable.

Only treat the change as ready once these checks are passing (or the project explicitly has no such tooling).

### What to report back

Always include a **CHECKS** section in your final answer listing:

- Each command you attempted.
- Whether it ran.
- The final exit code (or “not available in this project”).

Example:

```text
CHECKS
- bundle exec rubocop                   # exit 0
- bundle exec rspec                     # exit 0
- bundle exec brakeman                  # not available in this project
- npm run lint                          # exit 0
```

---

## 4. Edit scope & safety

- Only touch files necessary for the requested change.
- Do **not** modify:
  - Secrets/credentials.
  - Production/deployment configuration.
  - CI/workflow configuration.
  - Docker/kubernetes manifests.
  unless explicitly asked.
- Treat domain docs (product specs, GDDs, PRDs, etc.) as **requirements**, not as code;
  only edit them if the task is explicitly about documentation.
- If the project has a structured `doc/` tree (`doc/requirements`, `doc/flow`, `doc/prd`, game design docs, etc.),
  treat it as documentation, not as a playground.

For this MMORPG project, the **Game Design Document (GDD)** is the primary source of gameplay/domain rules;
use it as input when making design decisions, but don’t overwrite it unless asked.

---

## 5. Non-negotiable rules

1. **Think and code like a senior Rails engineer.**
   Use conventional Rails patterns, clear naming, and production-grade practices.

2. **Rails-way + KISS.**
   - Prefer RESTful controllers, standard routing, and ActiveRecord.
   - Avoid speculative abstractions and “mini-frameworks”.
   - Extract services/queries only when complexity clearly warrants it.

3. **Respect existing architecture.**
   - If the app uses **Hotwire**, prefer **Turbo + Stimulus** over custom AJAX or SPA frameworks.
   - If the app exposes JSON APIs, reuse the **existing serialization approach**
     (Jbuilder, serializers, simple `render json:`) rather than inventing a new one.

4. **Tests & lint are mandatory.**
   Any new functionality or bug fix must ship with tests. The test suite and linters should be green when you’re done.

5. **Avoid N+1 and obvious performance bugs.**
   Use `includes`/`preload` for associations rendered in views or JSON; paginate large collections.

6. **Database constraints first.**
   Use NOT NULL, foreign keys, and unique indexes to maintain invariants. Migrations must be reversible.

7. **UTC internally; ISO8601 for APIs.**
   - Store times in UTC.
   - For JSON, format timestamps using ISO8601.
   - For HTML views, respect project locale settings via `I18n`.

8. **Minimal, scoped diffs.**
   One feature or bug fix per change set. Avoid large, unrelated refactors.

9. **Minimize dependencies.**
   - Push Rails and the existing stack to their limits before adding new gems/JS packages.
   - Prefer well-established, boring tools over shiny, new ones.
   - If you add a dependency, document it under **Dependencies** in your summary and ensure it’s configured and tested.

10. **Security by default.**
    - Use strong parameters for all user input.
    - Never trust user input; escape output in views.
    - Honour CSRF protections.
    - Use well-tested libraries for authentication/authorization (Devise, OmniAuth, Pundit, etc.) where appropriate.

---

## 6. Hotwire expectations (Turbo + Stimulus)

**General:**

- Prefer Turbo Drive for navigation instead of custom fetch/XHR.
- Use Turbo Frames and Turbo Streams for partial page updates.
- Use Stimulus controllers for encapsulated client-side behavior.

### 6.1 Turbo patterns

- For resourceful actions (create/update/destroy) that support Hotwire:

  ```ruby
  def create
    @post = Post.new(post_params)

    if @post.save
      respond_to do |format|
        format.html   { redirect_to @post, notice: "Post created successfully." }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html   { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end
  ```

- On validation failure, re-render the form within the same frame with HTTP 422 (for APIs) or an appropriate status for HTML.

### 6.2 Stimulus patterns

- Controllers live in `app/javascript/controllers`.
- Use `data-controller`, `data-action`, `data-*-target` attributes instead of manual DOM querying.
- Keep controllers small and focused; avoid global state or cross-controller coupling.
- Prefer Stimulus for enhancements (modals, toggles, client-side validation hints) over inline JS.

---

## 7. Controllers & models (“Rails-way” in practice)

- **Controllers:**
  - RESTful actions (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`) by default.
  - Keep actions small; push complex behavior into models or POROs/services.
  - Use strong params methods (`def post_params`) to whitelist attributes.
  - Use `before_action` sparingly and only for obvious shared behavior (loading resource, authentication, authorization).

- **Models:**
  - Own associations, validations, scopes, and small domain methods.
  - Avoid bloating models with orchestration or external API calls; move those into services/jobs.
  - Use enums and named scopes for readability and query reuse.

---

## 8. Migrations & data

- **One migration per logical schema change.**
- In a shared project, **do not edit existing, already-run migrations.** Add new ones instead.
- Migrations must be reversible (Rails handles most automatically, but be explicit when necessary).
- When adding reference or seed data that other team members need, update `db/seeds.rb` or appropriate seed scripts.

---

## 9. Development guidelines (agent-specific)

- Read the project’s own conventions (`README`, `GUIDE.md`, etc.) before generating code.
- Do **not** suggest running long-lived processes (e.g. `rails server`) inside responses; just mention the commands.
- Do **not** run `rails credentials` or manipulate secrets in examples.
- Do **not** automatically run migrations on behalf of the user; show the commands instead.
- Prefer plain English strings in examples, but if the project already uses I18n heavily, follow that pattern instead of fighting it.

---

## 10. Documentation

- Update `CHANGELOG.md` and/or `README.md` when you:
  - Introduce a new feature.
  - Change setup commands or required environment variables.
  - Introduce breaking changes or notable behaviors.

- Add doc-style comments to:
  - New POROs/services/concerns.
  - Non-trivial class methods or scopes.
  - Include purpose, inputs, outputs, and a usage example where helpful.

---

## 11. Final output format (what the agent returns)

Every time you complete a task, respond with:

- **RATIONALE**
  3–5 bullets describing the approach and any key trade-offs.

- **CHANGES**
  High-level summary of:
  - Files touched.
  - What changed in each (no full diff unless requested).

- **CHECKS**
  List of commands from §3 with their final status, for example:

  ```text
  CHECKS
  - bundle exec rubocop           # exit 0
  - bundle exec rspec             # exit 0
  - bundle exec brakeman -q       # not available in this project
  - bundle exec bundle audit ...  # exit 0
  ```

This general contract is meant to be reused across **multiple Rails projects** (monoliths, Hotwire apps, and APIs).
When a project defines additional, stricter rules, follow those first and treat this file as the default baseline.

---
description: Pragmatic, general-purpose Ruby on Rails standards for full-stack apps (HTML + Hotwire + JSON APIs).
globs:
  - app/**/*.rb
  - app/views/**/*.erb
  - app/views/**/*.haml
  - app/javascript/**/*.js
  - config/**/*.rb
  - db/**/*.rb
  - lib/**/*.rb
  - spec/**/*.rb
  - test/**/*.rb
  - Gemfile
alwaysApply: false
in_development: true
---

# Ruby on Rails — General Engineering Guide

> Purpose: a single, practical reference for how we build Rails apps day-to-day—**high quality, Rails-way, without over-engineering**.

This guide applies to **full-stack Rails apps**:
- Classic HTML views (ERB/Haml/etc.)
- **Hotwire** (Turbo + Stimulus)
- Optional JSON APIs for external clients

---

## 1) Philosophy & Decision Rules

- **Deliver as a senior Rails engineer.**
  Code should be maintainable, testable, and idiomatic.

- **Rails-way first, KISS over patterns.**
  - Use built-in features: ActiveRecord, ActionController, ActionView, ActiveJob, ActionMailer.
  - Extract services/queries/form objects **only** when complexity clearly demands it.

- **HTML-first, Hotwire-first UI.**
  - Prefer server-rendered HTML and Turbo updates.
  - Reach for heavy SPA frameworks only when absolutely necessary.

- **DRY when duplication hurts, not before.**
  Avoid speculative abstractions; prefer explicit code until duplication is real and painful.

- **Selective SOLID.**
  Apply only where it clarifies the code and makes testing easier; avoid ceremony.

- **Consistent APIs.**
  When exposing JSON:
  - Use a single serialization strategy (Jbuilder, serializer classes, or plain `render json:`).
  - Keep status codes and error formats predictable.

- **Greenfield assumption (`in_development: true`).**
  In young projects, it’s okay to reshape schema/models aggressively. In mature projects, favour additive/migratory changes over breaking ones.

- **Document the change.**
  Significant features/fixes should result in a short entry in `CHANGELOG.md` and/or updated `README.md`.

---

## 2) Project Structure & Naming

- Use standard Rails layout: models in `app/models`, controllers in `app/controllers`, views in `app/views`, jobs, mailers, channels, etc.
- Use concerns only for truly shared behavior; avoid dumping miscellaneous helpers there.
- Put cross-cutting POROs in `app/services` or `app/lib` when warranted.
- **Naming:**
  - Ruby classes/modules → `CamelCase`
  - Files, methods, variables, JSON keys → `snake_case`
  - Tables → plural (`users`, `orders`), models → singular (`User`, `Order`).
- Stimulus controllers go in `app/javascript/controllers`; name them after behavior or domain (`form_controller.js`, `inventory_controller.js`, etc.).

---

## 3) Ruby Style

- Each Ruby file starts with:

  ```ruby
  # frozen_string_literal: true
  ```

- Prefer **multi-line method definitions**; avoid single-line `def foo; ...; end`.
- Prefer double quotes (`"..."`) for strings; single quotes only when you have a reason.
- Use guard clauses/early returns to reduce nesting:

  ```ruby
  def perform
    return unless user.active?

    # ...
  end
  ```

- Keep methods small and focused; aim for one responsibility per method.
- Use Ruby 3 features (safe navigation, pattern matching) when they **improve clarity**, not just because they’re new.

---

## 4) Controllers & Routing

- RESTful controllers by default:
  - `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
  - Custom actions only when strongly justified (e.g. `publish`, `archive`).

- Keep controllers thin:
  - Orchestration and HTTP concerns here.
  - Push domain rules into models or services.

- **Strong parameters** for any user input:

  ```ruby
  def post_params
    params.require(:post).permit(:title, :body, :published_at, :category_id)
  end
  ```

- **Routing:**
  - Use `resources` and shallow nesting.
  - Keep route nesting ≤ 1 level deep whenever possible.
  - Use namespacing for admin or API areas (`namespace :admin`, `namespace :api`).

- **Error handling:**
  - Use `rescue_from` in `ApplicationController` for global concerns (404, 500, authorization errors).
  - For APIs, respond with consistent JSON error shapes and appropriate HTTP codes.

---

## 5) Views, Hotwire & Frontend

### 5.1 Views

- Use layouts and partials to avoid duplication.
- Keep logic in helpers or presenters, not in templates:
  - Simple conditionals in views are fine, but avoid complex branching or queries.
- Use Rails form helpers (`form_with`, `form_for`) and path helpers.

### 5.2 Turbo

- **Navigation:** Let Turbo Drive handle navigation; avoid sprinkling custom JS for basic links.
- **Frames:** Use `turbo_frame_tag` to isolate parts of the page that update independently.
- **Streams:** Use Turbo Streams for real-time or partial updates:

  ```erb
  <!-- app/views/posts/create.turbo_stream.erb -->
  <%= turbo_stream.prepend "posts" do %>
    <%= render @post %>
  <% end %>

  <%= turbo_stream.replace "new_post" do %>
    <%= render "form", post: Post.new %>
  <% end %>
  ```

- Controllers should typically respond to both HTML and `turbo_stream` for create/update/destroy actions.

### 5.3 Stimulus

- Encapsulate frontend behavior in Stimulus controllers:

  ```js
  // app/javascript/controllers/toggle_controller.js
  import { Controller } from "@hotwired/stimulus"

  export default class extends Controller {
    static targets = ["content"]

    toggle() {
      this.contentTarget.hidden = !this.contentTarget.hidden
    }
  }
  ```

- Bind via data attributes in views:

  ```erb
  <div data-controller="toggle">
    <button data-action="click->toggle#toggle">Toggle</button>
    <div data-toggle-target="content">
      Hidden content
    </div>
  </div>
  ```

- Avoid inline scripts; keep JS inside controllers.

---

## 6) JSON APIs & Serialization

When the app exposes JSON endpoints:

- Use consistent status codes:
  - `200 OK` for successful reads/updates
  - `201 Created` for successful creates
  - `204 No Content` for successful deletes with no body
  - `400`/`422` for validation errors, with a predictable error shape
  - `401`, `403`, `404`, `500` as appropriate

- Choose a serialization approach and stick with it:
  - Jbuilder templates
  - Serializer classes (e.g., ActiveModel::Serializer, Blueprinter)
  - or simple `render json: record` for straightforward cases

- Avoid crafting ad-hoc JSON structures in each controller action; centralize or reuse patterns.

- Timestamps should be ISO8601 strings; include only fields the client actually needs.

---

## 7) Models & Data

- Models own:
  - Associations (`has_many`, `belongs_to`, `has_one`…)
  - Validations
  - Simple domain logic
  - Scopes for reusable queries

- Prefer expressive scopes over raw SQL:

  ```ruby
  scope :published, -> { where.not(published_at: nil) }
  ```

- Use enums for finite sets of states:

  ```ruby
  enum status: { draft: 0, published: 1, archived: 2 }
  ```

- Minimize callbacks; they can hide side effects. When behavior becomes complex, consider services or explicit orchestration.

### 7.1 Migrations

- One migration per logical change (add/remove/alter a column, create a table, add an index).
- Avoid editing old migrations in shared environments; create new migrations for changes.
- Ensure migrations are reversible.

### 7.2 Seeds

- `db/seeds.rb` (or structured seeds) should provide a small, realistic dataset to boot a fresh environment.
- Don’t overcomplicate seeds; keep them fast and reliable.

---

## 8) Services, Commands & Background Jobs

Introduce a service/command object only when all are true:

1. The logic doesn’t fit naturally into a single model/controller.
2. It spans multiple steps or side effects (external APIs, mailers, jobs).
3. Encapsulation clearly improves readability and testability.

Guidelines:

- Place them in `app/services` or a domain-specific directory (e.g., `app/services/users/`).
- Use intention-revealing names:

  ```ruby
  class Orders::Checkout
    def self.call(order:)
      new(order).call
    end

    def initialize(order)
      @order = order
    end

    def call
      # ...
    end
  end
  ```

- Services should be small and mostly stateless.
- Precede non-trivial services with a short doc comment:
  - Purpose
  - Inputs
  - Returns
  - Example usage

### 8.1 Background Jobs

- Use ActiveJob (`app/jobs`) backed by a queue adapter (Sidekiq, etc.).
- Jobs must be **idempotent**.
- Enqueue only what you need: pass IDs, not full objects.
- Handle retries and failure logging gracefully.

---

## 9) Security

- Authentication: use a well-maintained library (e.g., Devise) or a clear, audited custom solution.
- Authorization: Pundit or CanCanCan are preferred; authorize at the controller/policy layer, not in views.
- Use strong params everywhere.
- Sanitize/escape user content in views.
- Filter sensitive information in logs (`config.filter_parameters`).
- Keep secrets in encrypted credentials or environment variables; never commit secrets to the repo.

---

## 10) Data & Performance

- Index foreign keys and frequently queried columns.
- Watch for N+1 queries and remove them with `includes`/`preload`.
- Keep payloads lean:
  - Paginate large collections.
  - Avoid rendering heavy nested associations unless necessary.
- Use caching (`Rails.cache`, fragment caching) when it provides clear benefit and can be invalidated reliably.
- Use `request_id` in logs and minimal instrumentation (`ActiveSupport::Notifications`) in hot paths when needed.

---

## 11) Testing

Support both RSpec and Minitest; follow the project’s choice.

**Scope:**

- Model tests for validations and domain logic.
- Request/controller tests for HTML and JSON behavior.
- System tests for end-to-end flows, especially Hotwire interactions.
- Policy/authorization tests when using Pundit/CanCanCan.
- Serializer/JSON tests for APIs.

**Style:**

- Use a clear `describe`/`context` structure.
- One intent per `it` block.
- Keep factories/fixtures minimal—only required attributes.

**Determinism & Isolation:**

- Freeze or travel time when needed (`ActiveSupport::Testing::TimeHelpers`).
- Stub external HTTP calls (WebMock, VCR, etc.); never hit real services in CI.
- Ensure tests are independent; don't rely on state from other examples.

**Regression Prevention:**

1. **Before modifying existing code:** Run specs to establish baseline (all green).
2. **After changes:** ALL prior specs must pass—treat any failure as a regression.
3. **Bug fixes:** Ship with a regression spec that fails without the fix and passes with it.
4. **Cross-reference:** Verify GDD sections still satisfied after gameplay changes.

---

## 12) Project Conventions (recommended defaults)

These conventions are **good defaults** for a Rails monolith (like an MMORPG backend/UI). Adapt per project.

- **Minimize dependencies**
  - Push Rails and the standard stack as far as possible before introducing new gems or JS packages.
  - Prefer proven, stable libraries over trendy, untested ones.

- **Hotwire-first frontend**
  - Prefer native HTML elements and standard semantics.
  - Use Turbo Frames and Turbo Streams for reactivity instead of custom SPA architectures.
  - Use Stimulus for interactivity, data attributes for configuration, and keep controllers small.

- **Optimize for simplicity**
  - Prioritize clear OOP domain design over micro-optimizations.
  - Focus performance work on global or obviously hot paths (e.g., N+1, large lists, global layouts).

- **Database vs ActiveRecord validations**
  - Use database-level constraints (NOT NULL, unique indexes, foreign keys) for fundamental invariants.
  - Use ActiveRecord validations for user-friendly errors and form handling.
  - Reserve complex validations and business rules for model methods or dedicated objects.

---

## 13) Documentation & Domain Knowledge

- `README.md` should cover:
  - Setup (Ruby version, dependencies, DB, JS bundler).
  - Running the app and tests.
  - Key architectural decisions (Hotwire, chosen auth libs, etc.).

- `CHANGELOG.md` records user-visible changes.

- Domain-level docs (e.g., a game design document for an MMORPG, product PRDs, or flow docs) should live in `doc/` and be treated as inputs/requirements rather than incidental notes.

- When you add new non-obvious behavior, consider:
  - A short comment inline,
  - Or a brief architectural note (ADR) if it’s a significant decision.

---

## 14) Definition of Done

A feature or fix is considered **done** when:

- Rails-way + KISS are honoured; no unnecessary abstractions.
- Controllers are thin; models and/or services own domain behavior.
- Hotwire interactions (where used) are implemented via Turbo + Stimulus, not custom JS hacks.
- For JSON endpoints, responses have consistent status codes and shapes.
- There are meaningful tests (model + request/system where appropriate).
- No obvious N+1 queries or performance issues in hot paths.
- Security basics are respected (auth, authz, CSRF, parameter safety).
- `README`/`CHANGELOG` and any domain docs are updated if behavior changed in a way others need to know about.
- The full verification checklist (lint + tests + security tools used by the project) is green.

---

## 15) Tooling & Workflow

- Pin Ruby version in `Gemfile` and `.ruby-version`.
- Manage gems with Bundler; avoid unnecessary dependencies.
- Keep RuboCop/RuboCop-Rails/RuboCop-RSpec configs reasonable; follow them instead of fighting them.
- Use Brakeman and Bundler-Audit regularly to catch security issues.
- CI should run lint + tests; don’t rely only on local runs.

---

## 16) Examples

### 16.1 Index with pagination & preload (HTML + JSON)

```ruby
def index
  @posts = Post
    .includes(:author)
    .order(created_at: :desc)
    .page(params[:page])
    .per(params[:per_page] || 20)

  respond_to do |format|
    format.html # renders app/views/posts/index.html.erb
    format.json do
      render json: {
        data: @posts.as_json(only: %i[id title created_at], include: { author: { only: %i[id name] } }),
        meta: {
          page: @posts.current_page,
          per_page: @posts.limit_value,
          total_pages: @posts.total_pages,
          total_count: @posts.total_count
        }
      }, status: :ok
    end
  end
end
```

### 16.2 Create with strong params and Turbo

```ruby
def create
  @post = current_user.posts.new(post_params)

  if @post.save
    respond_to do |format|
      format.html do
        redirect_to @post, notice: "Post created successfully."
      end

      format.turbo_stream
      format.json { render json: @post, status: :created }
    end
  else
    respond_to do |format|
      format.html   { render :new, status: :unprocessable_entity }
      format.turbo_stream { render :new, status: :unprocessable_entity }
      format.json do
        render json: { error: @post.errors.full_messages.to_sentence, errors: @post.errors.to_hash }, status: :unprocessable_entity
      end
    end
  end
end

private

def post_params
  params.require(:post).permit(:title, :body, :published_at)
end
```

---

Use this guide as the **default Rails standard** across projects.
Each project can add its own stricter rules, but everything here should remain valid, idiomatic Rails practice.

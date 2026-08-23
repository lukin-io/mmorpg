# Ruby on Rails Technical Guide

**Full-stack Ruby, Rails, and Hotwire refactoring, maintainability, correctness, and performance guide**

- Updated: 2026-07-28
- Status: subordinate technical guide
- Scope: Ruby 4.0 and Rails 8.1 monolith; HTML, Turbo, and Stimulus are the primary player surface; JSON is a limited secondary integration surface
- Primary use: new features, changes to existing features, bug fixes, and refactors

---

## 0. Authority and purpose

`AGENT.md` is the repository-wide normative engineering contract. This guide
expands its Rails implementation direction; it does not replace or override it.
If the two documents conflict, follow `AGENT.md`.

Neverlands live behavior and preserved source material remain the only
game-design authority. This guide can answer how to implement verified behavior
in Rails, but it cannot justify an invented mechanic, location, action, balance
value, or visual convention.

The goal is not more abstraction. The goal is changeability: future changes
should be local, safe, testable, understandable, and no slower by default.

## 1. TL;DR

Default direction:

- preserve the player-facing and persisted runtime contract before refactoring;
- use conventional Rails models, controllers, views, partials, helpers, jobs,
  policies, and POROs;
- keep controllers focused on request/response orchestration;
- keep authoritative gameplay decisions and calculations on the server;
- use service objects for meaningful workflows, not every private method;
- use form objects for genuinely complex request coercion and validation;
- use query objects for materially complex or reused retrieval logic;
- use Pundit for ownership, role, visibility, and record-action authorization;
- use ERB and Turbo for the primary HTML surface and Stimulus for focused client
  enhancement;
- keep Turbo frame ownership and DOM ids stable, choose `update` versus
  `replace` intentionally, and make Stimulus lifecycle cleanup reconnect-safe;
- preserve only the JSON formats an endpoint genuinely supports; there is no
  mandatory serializer or universal response envelope;
- use transactions, locks, constraints, stable identities, and scoped
  idempotency guards for persistent gameplay correctness;
- keep time and randomness deterministic at their calculation/test boundaries;
- prevent N+1 queries and bound map, presence, inventory, shop, and combat reads;
- avoid callback-heavy workflows, generic base services, large concerns, hidden
  IO, browser-owned game state, and service-object soup;
- add applicable tests, then update the canonical feature handbook after
  implementation is verified;
- run the repository's real `bin/verify` and feature-document checks.

## 2. How to use this guide

For a new feature, bug fix, behavior change, or refactor:

1. Read the relevant Neverlands evidence, design document, and canonical feature
   handbook as routed by `AGENT.md`.
2. Identify the existing player/runtime contract and responsible files.
3. Choose the smallest Rails-native boundary that owns the behavior.
4. With the first material repository edit, copy
   `changelogs/CHANGELOG_TEMPLATE.md` into the session's one living changelog
   record, or update the record if the current conversation already owns one.
5. Implement server-authoritative behavior with applicable persistence,
   concurrency, security, and Hotwire rules.
6. Add or update tests at the smallest useful public boundaries.
7. Run focused checks while iterating and keep the same session record current.
8. Once the task diff is stable, review it again against the applicable guide
   sections and correct concrete ownership, security, Hotwire, query, or
   lifecycle findings before final verification.
9. Update the feature handbook only after implementation checks pass.
10. Run the appropriate `bin/verify` profile, finalize the same session record
    with exact results, and report using the final format required by
    `AGENT.md`.

Feature-specific examples in this document are illustrative. Do not copy their
names, content, or mechanics into unrelated features without Neverlands
evidence.

## 3. Application architecture snapshot

This repository currently uses:

- Ruby 4.0 and Rails 8.1;
- PostgreSQL and Active Record;
- server-rendered ERB;
- Turbo Drive, Frames, and Streams;
- Stimulus controllers loaded through Importmap;
- Propshaft-managed assets;
- Devise authentication;
- Pundit authorization;
- Action Cable for live updates;
- Sidekiq/Active Job for background work;
- RSpec, FactoryBot, Capybara, and Selenium;
- limited JSON responses for selected combat, presence, logs, and integration
  interactions.

The application is not an API-only service and does not use Blueprinter,
Ransack, or Kaminari. Do not make those tools architectural requirements. A new
dependency needs a concrete repository-level benefit and must not duplicate a
capability Rails already provides adequately.

## 4. Core Rails principles

### 4.1 Rails-native over framework-first

Prefer existing Rails boundaries:

- controllers and strong parameters;
- models, validations, scopes, and constraints;
- ERB views, partials, layouts, helpers, and presenters where useful;
- Turbo and Stimulus;
- ActiveModel forms when justified;
- ActiveRecord relations;
- Active Job and Action Cable;
- Pundit policies and scopes;
- PORO services, queries, catalogs, formulas, and value objects.

Do not introduce a command bus, interactor framework, dependency-injection
container, generic repository layer, or universal service superclass without a
specific demonstrated need.

### 4.2 High cohesion and domain vocabulary

Things that change together should live together. Name objects after the game
capability they own.

Prefer:

```text
Game::Movement::AcceptMove
Game::World::CellArtCatalog
Arena::CombatProcessor
Economy::PurchaseService
```

Avoid:

```text
DataProcessor
Manager
HelperService
GenericActionHandler
```

### 4.3 Low coupling and encapsulation

Callers should use stable public methods instead of navigating collaborator
internals. Whether data comes from YAML, a database table, Rails cache, or a
calculation is an implementation detail behind the responsible boundary.

### 4.4 Single level of abstraction

A workflow should read at one conceptual level:

```ruby
def call
  validate_current_state!
  persist_transition!
  build_result
end
```

Do not mix request parsing, SQL construction, combat calculations, cache writes,
and response rendering inside one method.

### 4.5 KISS before extraction

Do not extract a collaborator merely because a method is private. Extract when
there is a meaningful capability boundary, reuse, side-effect isolation,
transaction boundary, or material improvement in clarity and testability.

## 5. Preserve the real contract

A full-stack Rails contract is broader than a JSON payload.

Before changing a feature, identify what applies:

| Contract | Examples |
| --- | --- |
| Route and method | `GET /world`, `POST /world/move`, member/collection semantics |
| Authentication/authorization | Devise session, current character, Pundit ownership |
| HTML | rendered page, partial, form action, native control, semantic text |
| Turbo | frame ids, stream targets, replacement order, redirect/status behavior |
| Stimulus | controller/action/value/target names and progressive enhancement |
| Persistence | location, inventory, currency, fight, command, cooldown, resume state |
| Transition | preconditions, atomic changes, failure invariants, resulting state |
| Timing/randomness | server timestamps, expiry boundary, persisted duration, seeded RNG |
| JSON | status and shape only for endpoints that actually support JSON |
| Background/live update | job retry behavior, broadcast target, committed state |
| Presentation | Neverlands-backed geometry, retained assets, accessibility behavior |

A refactor must preserve applicable contracts unless the requirement explicitly
changes them. Characterization specs are appropriate when behavior is legacy,
fallback-heavy, or insufficiently documented.

## 6. Boundary selection matrix

| Problem shape | Preferred boundary |
| --- | --- |
| Simple request orchestration | Controller + model/scope |
| Complex request coercion/interdependent fields | ActiveModel form object |
| Reused single-attribute validation | Custom validator |
| Multi-record write or gameplay transition | PORO service object |
| Pure numeric/game calculation | Formula/value object with no database access |
| Complex/reused filtering, sorting, or preloading | Query object or relation-building service |
| Ownership, role, visibility, record action | Pundit policy/scope |
| HTML presentation | ERB partial/helper/presenter |
| Small secondary JSON payload | Explicit payload builder or controller hash |
| Complex/reused JSON representation | Jbuilder or a focused presenter, if justified |
| Structured immutable result | `Data.define` or an immutable PORO |
| Persistent invariant | Model validation plus database constraint |
| Atomic state transition | Transaction plus locks/constraints as needed |
| External service IO | Adapter/source object |
| Validated YAML/config catalog | Focused catalog/config service |
| Deferred/retryable work | Active Job/Sidekiq job calling a domain service |
| Live committed update | Action Cable/Turbo broadcast after commit |

The matrix is guidance, not a requirement to create one object in every row.

## 7. Dependency direction

Typical full-stack flow:

```text
Route/request
  -> Controller + Pundit
      -> Form / Query / Service
          -> Model / Formula / Catalog / Value Object
              -> PostgreSQL / Cache / YAML / Job / External IO
      -> ERB / Turbo Stream / Limited JSON
          -> Stimulus enhancement
```

Rules:

- models do not depend on controllers, request params, views, or Turbo;
- services do not render responses or know frame ids;
- views and Stimulus do not persist or decide authoritative game outcomes;
- formulas do not query the database, read request state, or access wall-clock
  time implicitly;
- queries do not perform writes;
- jobs delegate domain rules instead of implementing a second version;
- catalog/config objects validate and normalize owned content at their boundary.

## 8. Controller and routing policy

Controllers own request/response orchestration. They may:

- authenticate and establish the current character context;
- load records through current-user/current-character scope;
- authorize records or capability offers;
- apply strong parameters;
- instantiate forms, queries, and services;
- choose HTML, Turbo Stream, or supported JSON responses;
- set flash messages and HTTP status;
- prepare bounded view state.

Controllers should not own:

- authoritative game calculations;
- large validation trees;
- multi-record persistence workflows;
- duplicated ownership rules;
- manual cell/action availability rules;
- expensive query construction;
- inline JavaScript or CSS-generated authority;
- external API orchestration.

### 8.1 Primary HTML/Turbo flow

Target shape:

```text
authenticate
  -> establish current character
  -> load/authorize current record or offer
  -> validate intent
  -> call transition/query
  -> render HTML/Turbo or redirect
```

Use RESTful routes when the interaction maps cleanly to a resource. Use a named
custom action when it accurately represents a game command. Do not introduce a
generic `perform` endpoint that multiplexes unrelated transitions through
client-provided action names.

For successful non-GET Turbo mutations that redirect, prefer `303 See Other`
where it prevents method replay. Preserve existing status behavior during a
refactor unless intentionally changing and testing the contract.

For new validation failures, prefer Rack's current semantic status names such
as `:unprocessable_content`. Existing `:unprocessable_entity` behavior may be
changed only as an intentional compatibility-safe cleanup.

### 8.2 Limited JSON surfaces

JSON is supported only where the route/controller explicitly provides it.

- Do not create JSON parity for every HTML endpoint.
- Preserve existing response shapes and status codes when refactoring.
- A small one-off payload may be built explicitly.
- Use Jbuilder or a focused presenter only when representation is complex or
  reused.
- Do not introduce Blueprinter, a universal envelope, Swagger/rswag, or API
  versioning unless the application creates a real public API requiring them.
- Services and queries never render JSON directly.

### 8.3 Strong parameters and forms

Use strong parameters for every submitted field. A form object is justified
when coercion, shape validation, or interdependent request fields would
otherwise obscure the controller/service boundary. A simple command with a few
scalar parameters does not need a form object solely for architectural purity.

## 9. ERB, Turbo, Stimulus, and CSS

### 9.1 ERB and partials

Views render already-authorized, bounded state. They may format and compose
presentation, but must not calculate availability, prices, travel completion,
combat outcomes, or ownership.

Use partials when a fragment has clear ownership or is replaced by Turbo. Use
helpers for small reusable presentation behavior. Introduce a presenter only
when formatting logic has become materially difficult to understand or test.

Avoid database queries in views/helpers and avoid `html_safe` for user- or
content-provided strings.

### 9.2 Turbo navigation and frame ownership

Prefer Turbo Drive for ordinary navigation and forms. A frame is a feature
boundary, not merely a convenient wrapper:

- Give every replaceable region one stable, feature-owned DOM id.
- Define each persistent frame in one place. The game shell owns
  `main_content`, `available-actions`, and the lazy `chat_messages` boundary;
  child feature views must not render duplicate frames with those ids.
- A frame endpoint should render the frame/partial state it owns and should not
  prepare unrelated full-shell queries. Use the `Turbo-Frame` request header
  only when the response contract genuinely differs from full-page HTML.
- Keep the full-page fallback valid when direct navigation or non-Turbo form
  submission is supported. A frame-specific response must never be the only
  way to recover authoritative state.
- Use `target="_top"`, a Turbo visit, or a redirect deliberately when a
  transition changes the whole gameplay surface, such as entering a different
  location or finishing a fight. Do not accidentally trap full-page navigation
  inside a child frame.
- Lazy frames need meaningful loading/failure content and an endpoint that
  enforces the same authentication, authorization, bounds, and escaping as a
  normal request.

Frame ids are an internal HTTP/UI contract. Renaming one requires updating the
owning view, every stream target, any Stimulus lookup/action, and focused
request/view/system coverage in the same change.

### 9.3 Turbo mutation and stream contracts

Prefer a native `form_with`/button/link and let Turbo submit it. When Stimulus
initiates an existing form, use `requestSubmit()` so constraint validation,
the submitter, CSRF fields, and Turbo events remain in the path; do not use
`form.submit()` or rebuild the mutation as `fetch` without a concrete need.

Choose one explicit successful response shape:

- redirect with `303 See Other` when the authoritative result is a different
  page/surface or a clean GET is the simplest reconstruction;
- render one or more Turbo Stream actions when the current surface remains and
  a bounded set of regions must change together;
- return `head :ok` only when another established mechanism owns the visible
  result, such as an after-commit chat broadcast, and the lack of an immediate
  stream is covered.

For failures, preserve authoritative state and update/render the owned error or
form target with an appropriate non-success status. Do not return a success
stream with only an error-looking message.

Choose stream operations intentionally:

- `update` preserves the target element and replaces its children. Use it for
  stable shell/panel/frame boundaries such as `game-map`, `location-info`,
  `available-actions`, Inventory panels, or `flash`.
- `replace` replaces the target itself and reconnects controllers beneath the
  new root. Use it when the feature root, form errors, controller values, or
  allocation controller must be reconstructed.
- `append`/`prepend` require stable child ids or another duplicate-prevention
  rule when retry/broadcast duplication is possible.
- `remove` must target an identity scoped to the feature or record, not a
  display name.

When one server transition changes several visible facts, prepare one coherent
post-transition state and emit all dependent streams in one response. World
movement, for example, updates the map, location information, and available
actions together; Inventory equipment changes update the bag, paper doll, and
derived stats together. Do not let independently queried fragments expose
different snapshots of the same transition.

Turbo responses must pass through the same policy, capability-offer, service,
transaction, and failure validation as HTML. Stream target selection belongs
to the controller/view boundary; domain services must not know DOM ids.

### 9.4 Server-rendered fragments and DOM safety

Prefer Rails-rendered partials for dynamic lists, errors, messages, and record
rows. This keeps escaping, authorization, formatting, and stable ids in one
server-owned path.

- Treat Action Cable payloads, JSON, dataset strings, player names, chat text,
  item text, and error messages as untrusted presentation input.
- Prefer `textContent`, attribute setters, and DOM element creation for plain
  text received by Stimulus.
- Do not interpolate untrusted values into `innerHTML` or
  `insertAdjacentHTML`. If structured HTML is required, broadcast/render an
  escaped server partial or sanitize through an explicitly owned boundary.
- Assign `classList` only from an allowlisted event/state mapping. Do not use a
  server- or player-provided arbitrary class name.
- Replacing a target with same-origin server-rendered HTML is acceptable only
  when the endpoint owns escaping and authorization and the client does not
  concatenate additional untrusted markup.
- Avoid `html_safe`/raw strings in ERB and avoid duplicating ERB templates as
  JavaScript template literals.

### 9.5 Stimulus scope, targets, values, and actions

Stimulus may:

- animate already-accepted or server-reported state;
- submit player intent through an existing form;
- manage focus, keyboard, pointer, touch, scroll, and responsive panning;
- show a countdown derived from a server timestamp;
- preview allocation/turn cost before authoritative submission;
- toggle presentation modes and store non-gameplay preferences;
- reconnect, reload, or request an authoritative state snapshot.

Stimulus must not:

- mint action keys;
- decide reachable cells or available actions;
- persist coordinates, inventory, currency, skills, AP, HP, or fight outcomes;
- treat hidden fields, values, or `data-*` attributes as trusted authority;
- complete a server transition solely because an animation/countdown ended;
- make CSS visibility equivalent to authorization.

Keep each controller rooted at the smallest element that owns the interaction.
Use declared `static targets`, typed `static values`, and `data-action`
bindings. Prefer `this.element.querySelector(...)` for a genuinely internal
repeated descendant; reserve `document`/`window` access for real global
concerns such as resize, Escape, or outside-click handling. Store cross-surface
coordination in server state or an explicit event, not an unrelated global DOM
lookup.

Guard optional targets with `has...Target`. Missing required targets should be
caught by view coverage instead of silently driving a fallback selector. One
element may be a target for two controllers—for example a shell chat input and
its input-specific controller—when both responsibilities are explicit and
namespaced.

Use values/datasets for serialized server presentation state and opaque intent
tokens: record ids, offer keys, absolute end timestamps, scene focus points,
and already-calculated costs. The server must still reload and validate every
submitted record, capability, position, cost, and transition.

### 9.6 Lifecycle cleanup under Turbo

Turbo can connect and disconnect a controller many times without a full page
reload. Treat `connect()` as repeatable setup and `disconnect()` as mandatory
cleanup.

- Store the exact bound listener reference once, then pass that same reference
  to both `addEventListener` and `removeEventListener`. Calling `.bind(this)`
  separately in each call does not remove the original listener.
- Clear every interval and timeout owned by the controller.
- Cancel pending `requestAnimationFrame` callbacks.
- Remove `window`, `document`, element, and Turbo event listeners.
- Unsubscribe Action Cable subscriptions and disconnect observers.
- Abort or ignore stale fetches so a disconnected controller cannot patch a
  new page/frame instance.
- Make setup idempotent: reconnecting must not create a second ticker,
  subscription, resize listener, or countdown.

Use `requestAnimationFrame` after connect or stream rendering when measurements
depend on final layout. The World, City, and linked-location controllers use
this pattern to center fixed-pixel scenes after insertion. Responsive resize
handlers must be removable and must not change authoritative scene geometry.

Do not rely on in-memory controller fields surviving a Turbo replacement.
Reconstruct presentation from typed values, current DOM, or a fresh server
snapshot.

### 9.7 Timers, animation, previews, and local storage

The server clock and persisted state remain authoritative:

- Prefer an absolute server `ends_at` timestamp over decrementing a browser-only
  duration. Recompute remaining time from `Date.now()` after connect/reconnect.
- Animation may interpolate from the current server snapshot to its reported
  destination, but animation completion only triggers a reload/visit or a
  server command. It does not persist movement or combat state.
- Vitals regeneration, AP bars, allocation counters, and turn costs may be
  presentation previews. The server recomputes and rejects stale/invalid
  submissions; broadcasts or navigation replace previews with authoritative
  values.
- When the tab sleeps, the next tick must derive from the absolute timestamp or
  authoritative snapshot rather than assuming every one-second callback ran.
- Use `localStorage` only for non-authoritative preferences such as presence
  sorting or refresh display settings. Namespace keys, validate parsed shape,
  and tolerate unavailable/corrupt storage.

### 9.8 Fetch, Turbo Streams, and Action Cable boundaries

Do not use custom `fetch` merely to avoid a form or Turbo Frame. It is justified
for a narrow limited-JSON interaction, presence polling, a same-origin partial,
or a beacon-like liveness signal when those are already the feature contract.
When used:

- send the accurate `Accept` header;
- include same-origin credentials and CSRF protection for mutations;
- check `response.ok` before parsing;
- handle network, forbidden, validation, and stale/disconnected cases;
- keep URLs and payload shape at the controller/view integration boundary;
- never trust a successful HTTP response as proof of a client-calculated game
  result.

Choose one real-time presentation owner:

- Use Turbo Stream broadcasts when the server owns an escaped HTML fragment,
  as with chat-message and gameplay-event timeline append.
- Use typed Action Cable events when a high-frequency surface needs focused DOM
  patches/animation, as with Arena HP/AP/log updates.
- Do not broadcast the same visible transition through both mechanisms unless
  there is an explicit deduplication contract.

An Action Cable channel must authorize its stream scope. Broadcast only
committed state. Event `type` and payload fields are a stable internal
contract and require broadcaster/channel/controller coverage. On connection or
reconnection, request or render an authoritative snapshot—Arena's
`request_match_state` pattern—because events can be missed, duplicated, or
received after an old DOM instance disconnected. Render event text safely as
described in section 9.4.

### 9.9 Current application Hotwire ownership map

Use these existing boundaries instead of creating a parallel client path:

| Surface | Rails/Turbo or realtime owner | Stimulus responsibility | Stimulus must not own |
| --- | --- | --- | --- |
| Authenticated shell | `layouts/game`, `main_content`, `available-actions`, lazy mixed chat/game-event history, and bounded controller-prepared shell state | focus, local preferences, presence refresh, and timeline presentation | character/location state, event audience/body, or shell-wide database retrieval |
| Outdoor World | `WorldController` plus movement/action services; coherent streams for `game-map`, `location-info`, `available-actions`, and `flash` | submit an opaque offered move, center/pan, animate server timing, and reload at expiry | reachability, travel duration, offer creation, or movement completion |
| City and linked locations | server-rendered hotspot/feature forms backed by character-owned offers | native-pixel centering, tooltips, keyboard/pointer presentation | whether a hotspot exists, is accessible, or changes location |
| Inventory and progression | inventory/progression services plus multi-target streams and server-rendered partials | selection and allocation previews, keyboard state, and `requestSubmit()` | item ownership, equip/use result, point balance, or derived final stats |
| Chat and presence | policy/dispatcher, audience-scoped `Chat::Timeline`, stable-key `Chat::EventPublisher`, and signed after-commit Turbo streams | input/focus, auto-scroll, local menu, and refresh presentation | message permission, event audience/body, ignore/privacy rules, or arbitrary message/event HTML |
| Arena/Fight | combat services, typed per-NPC loot awarder, jobs, authorized channels, broadcaster payloads, and state snapshot | composer preview, countdown, log/vitals/AP DOM patches, and reconnect request | combat resolution, loot roll/grant, AP validation, timeout result, target validity, or victory |
| Shop/Economy | Shop services plus the wallet/ledger boundary used by trades and authoritative NPC-loot ingress | native form/redirect presentation inside the shell | price, stock, wallet balance, ledger adjustment, or reward eligibility |
| Vitals bar | server-provided current/max values and persisted character state | smooth display-only interpolation | persisted regeneration, damage, healing, or combat authority |

This map records the intended existing ownership/integration seams; it is not a
blanket certification that every older controller already satisfies every rule
in this expanded section. Do not copy legacy dynamic-HTML, broad-selector, or
lifecycle-cleanup shortcuts as examples. Correct a security-sensitive case in
scope, and otherwise record a focused follow-up rather than hiding it inside an
unrelated feature diff.

### 9.10 CSS and assets

CSS owns presentation, not authority. Geometry may display a map or hotspot but
cannot decide whether a move or entry is valid.

Preserve retained Neverlands-backed assets. New source-backed art belongs under
the responsible asset/config boundary with validation and asset coverage. Use
Propshaft-compatible paths and do not introduce a second frontend bundler
without a demonstrated need.

### 9.11 Accessibility and resilience

- Keep interactive controls keyboard-reachable and named.
- Prefer real buttons, links, forms, selects, and inputs over clickable `div`
  elements; retain visible focus and use the native disabled state where
  applicable.
- Preserve semantic text when visual UI is compact.
- Announce material asynchronous results through a stable flash/status/live
  region; do not rely on color, animation, or toast disappearance alone.
- Pair hover behavior with focus/blur and pointer/touch-accessible behavior.
- Avoid motion-only status; honor reduced-motion presentation where practical.
- Reload/reconnect must recover from persisted server state.
- Turbo/Stimulus changes require applicable view and system coverage.

### 9.12 Hotwire and Stimulus coverage

Use layered coverage rather than testing private JavaScript methods:

- View specs assert stable frame ids, feature-owned target ids, native controls,
  Stimulus controller/action/target/value wiring, and escaped semantic output.
- Request specs assert HTML versus Turbo media type, status/redirect behavior,
  exact stream actions/targets, authorization, and the persisted result.
- Service/job/channel specs assert that broadcasts happen after the owning
  transition and contain the required scoped event/record fields.
- System specs cover the meaningful browser contract: form submission,
  Turbo replacement/reconnect, keyboard behavior, responsive panning,
  countdown/state refresh, and HTML fallback where supported.

Do not assert an entire rendered page when the contract is a frame id and three
stream targets. Conversely, a request body containing `<turbo-stream>` alone
does not prove that the browser reconnects the controller or preserves focus;
use a focused system spec for that behavior.

## 10. Service objects

Use a PORO service when it:

- orchestrates multiple records;
- owns a meaningful persistent transition;
- defines a transaction/locking boundary;
- coordinates domain-specific side effects;
- materially improves clarity and testability.

Preferred shape:

```ruby
module Game
  module Movement
    class AcceptMove
      def initialize(character:, action_key:, target_x:, target_y:, clock: Time)
        @character = character
        @action_key = action_key
        @target_x = target_x
        @target_y = target_y
        @clock = clock
      end

      def call
        validate_offer!

        ActiveRecord::Base.transaction do
          lock_authoritative_state!
          persist_transition!
        end
      end
    end
  end
end
```

The example shows structure only; the responsible feature contract defines the
actual transition.

Service rules:

- use keyword arguments for non-trivial inputs;
- document purpose, public inputs, output, important side effects, and typed
  domain errors;
- keep one clear transaction boundary;
- accept normalized intent, never raw controller params;
- revalidate current authoritative state at mutation time;
- make retry/duplicate behavior explicit when valuable state can change;
- do not render, redirect, set flash, or depend on Turbo frame ids;
- do not create a generic `BaseService` hierarchy;
- do not wrap one trivial model call merely to satisfy a pattern.

## 11. Forms, validators, queries, and value objects

### 11.1 ActiveModel forms

Use an ActiveModel form when request-specific inputs need substantial coercion,
shape validation, or cross-field rules before domain execution.

Forms may include `ActiveModel::Model` and `ActiveModel::Attributes`, expose
normalized readers, and return useful errors. They should not authorize,
perform heavy queries, call external services, render, or duplicate database
invariants.

### 11.2 Custom validators

Use a custom validator when the same attribute-local rule is reused across
multiple forms/models and stable error behavior matters. Keep cross-record,
permission, or workflow validation in the relevant service/policy.

### 11.3 Query objects

Use a query object when retrieval includes materially complex combinations of:

- filtering or sorting;
- authorization scopes;
- preloading;
- pagination or bounded limits;
- reuse across controllers/services;
- query-specific performance behavior.

Return an ActiveRecord relation while composition is useful. Do not return an
array early, serialize inside the query, or mix in writes. A simple
`current_user.records.find(params[:id])` does not need a query object.

### 11.4 Value and result objects

Use `Data.define` for immutable structured results when several values travel
together:

```ruby
Result = Data.define(:success?, :record, :message, :error_code)
```

Use a plain immutable PORO when validation or behavior needs more control.
Avoid implicit multi-field hashes whose keys form an undocumented internal
contract.

## 12. Models and database correctness

Models own:

- associations;
- enums and stable identity helpers;
- persistence validations;
- broadly reusable scopes;
- small persistence-local rules.

Models should not own:

- controller params;
- response rendering;
- large multi-record workflows;
- external IO;
- browser presentation state;
- feature-specific query orchestration that is clearer elsewhere.

Protect durable invariants with PostgreSQL where practical:

- `NOT NULL`;
- foreign keys;
- unique/composite indexes;
- check constraints;
- column types and defaults consistent with domain semantics.

Model validations improve feedback but do not protect concurrent writes by
themselves.

Use stable keys for persistent game content. Do not key relationships by
translated or mutable display names.

## 13. Authorization and security

Pundit is the default record/action authorization boundary.

- Scope records to the authenticated user/current character before mutation.
- Authorize ownership, roles, visibility, and capability records.
- Use policy scopes for collections where visibility varies.
- Do not hide authorization in views, serializers, or CSS.
- A service may enforce a domain precondition, but should not silently replace
  a missing controller/policy ownership check.

Treat all browser input as untrusted, including:

- ids and coordinates;
- action/capability keys;
- target types and destinations;
- prices, quantities, and balances;
- timers and timestamps;
- equipment/stat values;
- CSS geometry and Stimulus state;
- return paths or contexts.

Retain CSRF protection. Escape output. Never call `html_safe` on untrusted
content. Allowlist logical destinations rather than accepting redirect URLs.
Use Rack Attack only for concrete abuse boundaries and do not treat rate
limiting as a replacement for authorization or idempotency.

Action Cable channels must authenticate subscriptions and scope streams so they
cannot leak private character, location, chat, or fight state.

## 14. Persistent gameplay transitions

Every mutation of coordinates, location, combat, inventory, equipment,
currency, rewards, cooldowns, or ownership needs a clear transition contract:

1. authoritative records and preconditions;
2. accepted player intent;
3. transaction/locking boundary;
4. successful state changes and side effects;
5. failure behavior and state that remains unchanged;
6. retry/duplicate/concurrent behavior;
7. resulting state rendered or returned.

Use the simplest correctness mechanism that protects the invariant:

- database constraint;
- row lock or consistent multi-row lock ordering;
- transaction;
- unique command/offer identity;
- status transition guarded by current state;
- scoped idempotency key when actually needed.

Do not add a universal command bus or idempotency framework.

### 14.1 Time

The server clock owns expiry, travel, cooldown, respawn, and timeout behavior.
Persist timestamps/durations needed for reload recovery. Test immediately
before, at, and after important boundaries using frozen/injected time.

### 14.2 Randomness

Combat, encounter, loot, spawn, and resource randomness must accept or construct
a seeded RNG at a testable boundary. A test must not depend on ambient random
state or execution order.

## 15. Jobs, transactions, broadcasts, and side effects

### 15.1 Active Job and Sidekiq

Jobs should:

- accept stable record ids or compact serialized values;
- reload authoritative records at execution time;
- delegate domain behavior to the same service used by synchronous flows;
- be retry-safe and idempotent for valuable mutations;
- handle missing/stale records explicitly;
- avoid relying on request/session/current-user state.

### 15.2 Transaction side effects

Do not perform an irreversible external side effect and then risk rolling back
the database state that justified it. Use after-commit orchestration or a
durable/retryable job where appropriate.

### 15.3 Turbo/Action Cable broadcasts

Broadcast committed state. Do not tell clients that a transition completed
before its transaction commits. Re-query or render from the authoritative
record state and keep broadcast targets scoped to authorized audiences.

- Prefer record/feature-scoped stream names over broad global channels.
- Turbo broadcasts should render the same escaped partial contract used by a
  normal request when practical.
- Typed Action Cable events require an allowlisted event type, a stable payload
  shape, authorized subscription scope, and a reconnect/state-snapshot path.
- A client may display a broadcast, but it must not use receipt order as the
  only source of truth for a valuable transition. Make repeated/out-of-order
  presentation safe or reconcile from current server state.
- Test the transition and its broadcast boundary; do not test only that a
  JavaScript handler happens to recognize a string.

See sections 9.4 and 9.8 for DOM-safety and realtime presentation ownership.

## 16. Error handling

Use explicit categories:

| Error | Owner/response |
| --- | --- |
| Request-shape validation | Strong params/form; render errors or redirect |
| Persistence validation | Model/form errors shown safely |
| Authorization | Pundit/global handler |
| Not found | Scoped lookup and appropriate HTML/Turbo/JSON response |
| Domain conflict | Typed service error/result; no partial state |
| Expired/stale capability | Domain failure and authoritative refresh |
| External dependency failure | Adapter typed failure/retry policy |
| Unexpected internal error | Let global handling/logging observe it |

Rules:

- do not broadly rescue `StandardError` and return a generic success/failure;
- do not use `ArgumentError` deep in a service for ordinary form input;
- do not return `nil` for every failure unless `nil` has one documented meaning;
- do not leak internal exception messages, SQL details, paths, or secrets;
- HTML, Turbo, and JSON branches must not produce contradictory state.

## 17. Configuration, catalogs, and caching

### 17.1 Ownership

Use:

- constants for small stable developer-owned values;
- validated YAML for larger source-backed content edited with code;
- database records for operational/queryable/persistent state;
- catalog/config services to validate and resolve stable references;
- adapters for real external IO.

Do not scatter Neverlands content across controllers, views, and Stimulus. Do
not store arbitrary file paths or URLs when a stable catalog key is sufficient.

### 17.2 Caching

Cache only when it has a clear owner, key, invalidation rule, and fallback.

- Centralize non-trivial cache keys.
- Version keys when serialized shape changes.
- Include every relevant identity/context dimension.
- Include locale only when localized cached output is introduced.
- Do not cache authorization without a safe invalidation model.
- Do not cache movement offers, action capability keys, balances, inventory,
  combat state, or finalized positions as substitutes for authoritative records.
- Process-local memoization is appropriate for immutable validated catalogs when
  reload behavior is explicit.

## 18. ActiveRecord and Ruby performance

Ask on every hot path:

- Does this load full objects unnecessarily?
- Is the collection bounded?
- Do I need callbacks/validations?
- Do I need only a scalar or existence result?
- Is this causing N+1 queries?
- Am I filtering/paginating before hydration?
- Am I querying once per rendered cell/participant/item?
- Is a sparse content model more appropriate than precreating the full domain?

### 18.1 Bounded game surfaces

- Render only the local map buffer, never all one million region cells.
- Query tile/NPC/building/presence state in bounded coordinate ranges.
- Preload fight participants, characters, equipment, and templates needed by a
  rendered fight.
- Bound exact-cell presence lists.
- Preload inventory/shop associations used in grids and summaries.
- Paginate only collections that can genuinely grow; do not add pagination to a
  fixed five-row or ten-row source-backed list.

### 18.2 `each` versus batching

Use `find_each` or `find_in_batches` for large backfills, jobs, and maintenance
tasks. Use `each` for small/already-loaded collections or where explicit order
matters.

### 18.3 `count`, `size`, and `length`

- Use `relation.count` for a SQL count.
- Use `relation.size` when a loaded relation can be reused.
- Avoid `relation.length` on a large unloaded relation.

### 18.4 Existence

Use `relation.exists?` when only true/false is needed. Avoid `present?` or
`any?` if it causes full record loading.

### 18.5 Scalar reads

Use `ids`, `pluck`, and `pick` when Ruby genuinely needs scalar values. Do not
hydrate models solely to map one column.

Prefer a SQL subquery over plucking a large id array only to pass it into
another `where`.

### 18.6 Preloading

- Use `preload` for predictable separate queries after filtering is final.
- Use `includes` when Rails may choose an appropriate loading strategy.
- Use `eager_load` only when joined conditions/order are required.
- Verify joined eager loading does not duplicate or expand hot result sets.

### 18.7 Bulk writes/deletes

Use `destroy_all` or per-record updates when callbacks, dependent behavior,
validation, audit, or cache invalidation matters. Use `delete_all`/`update_all`
only when bypassing those mechanisms is intentional and verified.

Before a bulk operation, check callbacks, timestamps, dependent cleanup,
structured audit needs, broadcasts, and external side effects.

### 18.8 Query count versus abstraction

Do not trade one readable bounded query for a speculative query framework.
Measure or inspect SQL on hot paths, add a focused regression spec when query
shape is valuable, and fix concrete N+1/hydration problems.

## 19. Safe migrations and backfills

- Use one migration per logical structural responsibility.
- Prefer reversible migrations.
- Add foreign keys, null constraints, indexes, and unique constraints that
  reflect the model contract.
- Clean/backfill invalid rows before enforcing a new constraint.
- Batch large backfills and make them restart-safe.
- Consider lock duration for large production tables.
- Use concurrent PostgreSQL indexes only when table size/deployment conditions
  justify the additional migration mechanics.
- Document legacy/null handling and recovery for player-state transformations.
- Never silently reset player location, inventory, currency, or progression in
  a backfill.

Do not edit a committed migration unless explicitly authorized under
`AGENT.md`.

## 20. Observability and regression detection

Check what is material to the changed path:

- SQL query count and N+1 behavior;
- rendered collection size;
- job retry/duplicate behavior;
- cache hit/miss and catalog reload behavior;
- Action Cable/broadcast count;
- external IO count;
- request duration for hot interactions;
- structured audit/domain records for valuable currency, inventory, reward,
  PvP, or administrative mutations.

Use Rails logs, SQL logs, ActiveSupport notifications, and focused benchmarks
when justified. Do not build an observability framework for a small pure
refactor.

## 21. Testing policy

Follow the normative coverage requirements in `AGENT.md`. Choose the applicable
layers:

| Boundary | Representative spec |
| --- | --- |
| Model/constraint | model spec and schema/config assertion |
| Service/transition | service spec, including retry/concurrency when vulnerable |
| Formula/value object | pure deterministic unit spec |
| Policy/scope | policy spec for allowed and forbidden ownership/role |
| Request | HTML/Turbo/JSON status, redirect/render, authorization, persisted result |
| View/helper | partial structure, native controls, escaped/semantic output |
| Stimulus/Turbo interaction | system spec and focused JS behavior where available |
| Route | routing spec for custom commands and removed legacy endpoints |
| Job | job spec for delegation, stale state, retry/idempotency |
| Seed/config/catalog | idempotency, valid/invalid definitions, stable identities |
| Asset | existence, dimensions, and rendering contract |
| Factory | useful active/inactive, ownership, expiry, null, and boundary traits |

Required behavioral categories where applicable:

- success;
- failure and unchanged state;
- edge/null/boundary and time boundaries;
- authorization;
- duplicate/retry/concurrent behavior for vulnerable mutations.

Testing rules:

- prefer the smallest useful public boundary over private-method tests;
- freeze/inject time;
- seed/inject randomness;
- do not depend on external Neverlands availability;
- keep system coverage focused on meaningful player flows;
- test Turbo/HTML response behavior without asserting brittle full-page markup;
- test limited JSON only where the controller supports it;
- do not add Blueprinter, blueprint, Swagger, or rswag specs without those
  surfaces.

## 22. Feature documentation and verification

Implementation documentation follows `AGENT.md`:

1. start at `doc/domains/README.md` and establish the domain's Neverlands
   evidence, normalized design, stable parity ID, and current implementation
   owner;
2. copy `changelogs/CHANGELOG_TEMPLATE.md` into the current session's one
   living record with the first material repository edit, or update the
   session's existing record;
3. implement behavior and tests while keeping that record current;
4. run focused verification;
5. review the stabilized diff against the applicable sections of this guide;
6. update/create the canonical shipped `doc/features/**` handbook;
7. run `bin/feature-doc-audit` and, when documentation architecture changed,
   `bin/documentation-architecture-audit`;
8. run the appropriate completion profile;
9. finalize the same living session record as required
   by `AGENT.md`.

An architecture/documentation migration may register a verified missing
runtime by copying `doc/features/NOT_IMPLEMENTED_TEMPLATE.md`. The record must
use exact `NOT_IMPLEMENTED` status, preserve all 18 sections, list only real
evidence/design paths, and invent no Rails classes, routes, persistence,
Stimulus/CSS owners, or specs. It is replaced in place only after runtime work
and applicable checks are green.

Useful commands:

```bash
bin/rubocop path/to/changed_file.rb
bundle exec rspec spec/path/to/changed_spec.rb
bin/feature-doc-audit doc/features/<feature>.md
bin/documentation-architecture-audit
bin/verify fast
bin/verify full
```

Use `full` when required by `AGENT.md`, including process/verification contract
changes, broad cross-feature changes, release/push verification, or explicit
user request.

Use the documented audit commands only; do not invent similarly named
verification commands.

## 23. Refactoring workflow

### 23.1 Before changing code

Identify:

- player/runtime contract and callers;
- Neverlands/design/feature authority;
- persisted state and stable identities;
- routes, formats, frames, Stimulus contracts, and broadcasts;
- authorization and trust boundaries;
- time, randomness, cache, jobs, and side effects;
- performance-sensitive reads;
- applicable test layers/categories.

### 23.2 Characterization first

Add characterization coverage before extracting behavior from a large legacy
controller, service, facade, catalog, or fallback chain. Describe existing
verified behavior, not an ideal architecture.

### 23.3 Extract by capability

A useful order when the boundaries exist:

1. pure formulas/value objects;
2. normalization with no IO;
3. validated catalog/config access;
4. query boundary;
5. persistent transition/service;
6. job/broadcast adapter;
7. controller/view cleanup.

Do not force this sequence on a small change.

### 23.4 Preserve facades when valuable

If callers already depend on a cohesive public facade, keep it stable while
extracting internals. Split by domain capability, not every method. Avoid
replacing one large object with dozens of one-method classes.

### 23.5 Verify progressively

Run focused specs and lint after meaningful changes. Recheck the player/runtime
contract, then run the required completion profile.

## 24. Anti-patterns

Avoid:

- invented generic-RPG behavior;
- browser-authoritative gameplay state;
- fat controllers containing game rules and multi-record writes;
- callback-driven cross-record workflows;
- generic `BaseService` inheritance;
- service objects wrapping trivial model calls;
- one class per private helper;
- large concerns that become hidden frameworks;
- request params passed deep into models/services;
- rendering or redirects inside services;
- database queries in views, helpers, pure formulas, or Stimulus;
- duplicate Turbo frame ids or a child view redefining a shell-owned frame;
- choosing `replace`, `update`, or `append` without considering controller
  reconnect and retry/duplicate behavior;
- `form.submit()` or custom mutation `fetch` when an existing form's
  `requestSubmit()` preserves validation, CSRF, and Turbo behavior;
- global DOM queries where a controller target or `this.element` owns the
  interaction;
- listeners registered with an anonymous/bound function that cannot be removed
  in `disconnect()`;
- intervals, timeouts, animation frames, subscriptions, observers, or fetches
  that survive Stimulus disconnect;
- interpolating Action Cable, JSON, dataset, or player/content strings into
  `innerHTML`;
- browser countdown/animation completion persisting movement, combat, rewards,
  or other gameplay state;
- parallel Turbo Stream and typed Action Cable renderers for the same visible
  transition without deduplication and one documented owner;
- manual outdoor action availability in CSS/JavaScript;
- unstable display names as persistent identities;
- arbitrary asset paths/URLs in content records;
- broad exception rescue that hides partial failures;
- non-idempotent valuable jobs or commands;
- broadcasting uncommitted state;
- N+1 queries in map, inventory, shop, presence, or combat surfaces;
- hydrating unbounded records before filtering/limiting;
- `present?`/`length` where an existence/count query is intended;
- `delete_all`/`update_all` without lifecycle analysis;
- speculative dependencies and architecture frameworks;
- JSON/serializer/API documentation for endpoints that are HTML/Turbo-only;
- feature handbooks written as plans before implementation is verified;
- `NOT_IMPLEMENTED` handbooks containing invented runtime paths or partial
  shipped behavior.

## 25. Implementation checklist

Before implementation:

- [ ] Read `AGENT.md` and the relevant design/feature documents.
- [ ] Start from the relevant `doc/domains/**` index and confirm evidence,
      design, parity, and implementation ownership.
- [ ] Identify the player/runtime contract and existing responsible files.
- [ ] Classify `[IMPL]`, `[DOC]`, and `[EVIDENCE]` gaps.
- [ ] Choose the smallest Rails-native owner for the behavior.
- [ ] Identify authorization, concurrency, time, randomness, and performance risk.
- [ ] Map applicable tests and coverage categories.

During implementation:

- [ ] Keep server authority and revalidate mutations.
- [ ] Keep controllers/views/Stimulus within their boundaries.
- [ ] Keep frame ids/stream targets single-owned and choose stream operations
      intentionally.
- [ ] Use declared Stimulus targets/values/actions and make connect/disconnect
      cleanup idempotent.
- [ ] Render dynamic text safely and reconcile timers/realtime state from the
      server.
- [ ] Preserve stable ids, routes, frames, and supported response formats.
- [ ] Use transactions/locks/constraints where persistent correctness needs them.
- [ ] Prevent duplicate/retry/concurrent valuable state changes.
- [ ] Keep reads bounded and preloading explicit.
- [ ] Keep jobs retry-safe and broadcasts commit-safe.
- [ ] Add focused tests as behavior is implemented.
- [ ] With the first material edit, copy
      `changelogs/CHANGELOG_TEMPLATE.md` or update the current session's
      existing living record, then keep it current across follow-up prompts.

Before completion:

- [ ] Run focused specs and read-only lint.
- [ ] Review the stabilized diff against the applicable sections of this guide
      before the completion verification profile.
- [ ] Verify HTML/Turbo response shapes, frame/target wiring, reconnect
      behavior, and fallback at the applicable request/view/system layers.
- [ ] Reconcile implementation with Neverlands/design and the feature contract.
- [ ] Update the canonical feature handbook after checks are green.
- [ ] Run the focused feature-document audit.
- [ ] Run the documentation architecture audit when domain/reference/template
      structure or missing-layer records changed.
- [ ] Run `bin/verify fast` or `bin/verify full` as required.
- [ ] Finalize the current session's one living `changelogs/**` record after
      verification; do not create a new record for a follow-up prompt.
- [ ] Report exact commands, outcomes, documentation status, and discrepancies
      using the `AGENT.md` final format.

## 26. Final decision rule

When several Rails designs are valid, choose the one that makes the next
verified change:

- easier to find;
- easier to understand;
- easier to test;
- harder to execute twice or partially;
- no slower by default;
- consistent with Rails, Hotwire, and this repository;
- faithful to Neverlands rather than generic RPG assumptions.

That is maintainability for this application.

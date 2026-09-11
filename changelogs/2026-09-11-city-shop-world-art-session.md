# Change Note: City shopping, quarter scenes and tiled outdoor artwork

- Session coverage: September 9–11, 2026, from the earliest dated Shop evidence
  through implementation, visual corrections, pre-merge verification and this
  consolidated documentation follow-up. The exact conversation start was not
  recorded; older source observations remain references.
- Last updated: 2026-09-11.
- Scope: the whole city/shop/artwork session, including work completed before
  the merge, rather than only its final correction.
- Related PR: [#123](https://github.com/lukin-io/mmorpg/pull/123), merged as
  `bf19f5259d5bf80841d31b16aa5258a24c81ef7c`; final pre-merge head
  `c24f6abea40074fd097ce59b3a82824a4d93f7c8`.

## Summary

Delivered a bounded Neverlands-backed Shop with buying, licensed selling,
finite stock and funds, persistent inventory/equipment handoff, six timed
licenses and Merchant qualification. Rebuilt city-quarter presentation with
original artwork, building-shaped hotspots, visible navigation arrows and both
outdoor gates. Corrected outdoor rendering to use individual map-cell images,
improved city detail and replaced the walking figure with registered RPG
animation assets. Final acceptance also repaired session, flash and expired
sign-in behavior encountered along these flows.

The initial World import, movement/combat/airship implementation and initial
wallet-grant machinery predate this work. Their history remains in the
[earlier World session record](2026-09-09-world-map-movement-session.md).
Full Shop, profession and city-interior parity remain incomplete; the bounded
delivery and remaining work are distinguished below.

## Why

The request covered the complete shopping process, not just category filters:
buy an item, persist it, find/equip it, verify it on the player, remove it and
sell it back. Purchase reduces Shop stock; sale restores it. Settlement needed
transactional reliability across money, stock, owned items and receipts.

Neverlands live observations and published requirements remained the sole
game-design authority. The user explicitly requested original artwork and a
modern adaptive implementation. Visual corrections addressed oversized or
clipped scenes, hard-to-see arrows, repeating fallback grass, zoomed/blurred
city imagery and unstable walking frames. Source stepping showed that cities
and villages are part of the outdoor cell artwork, with entry availability
attached to the current gate cell.

## Changes

### Shop, licenses and inventory

- Implemented Buy Goods, Licenses, Sell Goods and For Beginners surfaces with
  source-backed layout, filters, descriptions and confirmation behavior.
  Starter content contains 19 categories, 79 ordinary goods and six license
  definitions. Equipment categories generally contain five items; Duel Permits
  have four. Relics and Runes remain empty. Wood Chips are excluded from the
  Shop assortment as quest waste, without deleting unrelated material data.
- Added per-building Shop accounts and stock, shared NV wallet settlement,
  one-use trade offers and append-only receipts. Buying debits the player,
  credits the Shop, decrements stock and creates one carried item. Selling
  credits the skill/durability-based quote, debits Shop funds, removes the
  carried item and increments stock. Failure rolls back the settlement.
- Connected Shop artwork and purchased items to Inventory and the paper doll.
  Equipment and durability persist across navigation, reload and login.
  Equipped, protected, bound, invalid or unavailable items cannot bypass sale
  restrictions. The legacy unilateral player-sale settlement was removed;
  another player's wallet requires an eventual offer/consent flow.
- Added typed Trading I–III and Doctor I–III license records. Merchant/Healer
  perks, numeric proficiency, qualification and timed permission are distinct.
  Trading requires Merchant plus its qualification: accept at Residential
  Market, pay 1,000 NV at Shop, then return to Market. Doctor I requires Healer;
  Doctor II/III also require the unimplemented Traumatologist qualification.
  The published 100-point Doctor threshold belongs to that quest's entry,
  not a blanket Doctor I purchase rule.
- Licenses are valid only when `starts_at <= now < expires_at`. Server actions
  revalidate expiry; subsequent rendering omits expired active licenses.
  Historical rows remain stored. No cron deletion or open-page expiry polling
  was added. Active same-kind licenses block duplicate purchases pending
  source-backed renewal/upgrade rules. Local prerequisite emulation was used
  only for authorized development verification, not ordinary starter grants.
- For Beginners denies characters at level 10 or higher; the bounded eligible
  surface is empty. No invented novice discounts or rewards were introduced.

### City, outdoor map and original artwork

- Added five distinct 1250×600 quarter scenes. Shared Shop/City presentation
  uses an adaptive 25:12 frame, with documented composition, scaling and
  acceptance requirements. Matching SVG polygon geometry owns building hover
  highlights and clicks; inactive buildings are omitted. Quarter navigation
  no longer repeats the Central Square image or invents finished interiors.
- Preserved eight directed quarter routes and the RPG arrow silhouette,
  improving its palette/contrast while removing the unwanted circular badge.
  Restored Central Square ↔ western gate `[6,8]` and Law Quarter ↔ eastern gate
  `[11,9]`, including bounded repair of route neighbors and reciprocal entry.
- Removed the master-landscape display fallback in favor of physical 100px
  cell images, including city fragments. A bounded viewport buffer uses odd
  dimensions of 3–39 columns and 3–9 rows plus an offscreen margin; movement
  shifts the window and reuses overlap at 100 CSS px per cell. City or village
  art does not itself authorize entry or create gameplay records.
- Packaged 273 main-area cell images and 39 inert western scenery images;
  the gameplay import remains 273 cells. The city detail patch adds 32 optional
  200px density variants displayed at the same 100 CSS px geometry. Its native
  1774×887 source was downsampled to a 1600×800 patch, rather than enlarging a
  small raster. Full-source and generation-guide files remain archived.
- Replaced the walking figure with eight directional GIF/still pairs on 128px
  canvases rendered at 64 CSS px. Fixed head registration reduces shake;
  cardinal loops use eight 100ms frames, diagonals four 140ms phases. Diagonal
  opposite-foot anatomy remains a documented visual limitation.
- Recorded original Shop interiors, category/item/license images, quarter
  scenes, arrows, map panels/detail and walker prompts, including correction
  attempts, source roles, dimensions and packaging. Neverlands screenshots
  served as evidence, not shipped artwork.

### Integration and pre-merge corrections

- Made shared flash notices dismissible and transient across time/navigation;
  filtered internal values such as boolean timeout flags and offer identifiers.
- Reused unchanged live World action offers during viewport refresh without
  extending expiry. Stale-position readers cannot cancel offers at the newer
  position; changed location/target, consumption or expiry still invalidate
  an offer.
- Enforced closed-session rejection and login restoration. Browser acceptance
  exposed a chat redirect/anonymous-cookie race on an expired sign-in form:
  background polling now avoids following login redirects, closed background
  sessions receive 401, and invalid-CSRF sign-in recovers through a fresh form
  without replaying credentials. The user explicitly submits credentials again.
- Updated system expectations for 128px walking assets and synchronized tests
  with initial viewport/ActionCable readiness. SQL probes were scoped to their
  executing thread, retaining all same-thread SQL; short movement assertions
  control server time only while checking accepted motion, then verify actual
  completion. These correct test races, not gameplay durations.

## Contracts and boundaries

- **Evidence:** [Shop purchase](../doc/design/reference/economy/observations/2026-09-09_city_shop_purchase.md),
  [licenses/selling](../doc/design/reference/economy/observations/2026-09-09_licenses_and_shop_selling.md),
  [starter assortment](../doc/design/reference/economy/observations/2026-09-10_starter_shop_catalog.md),
  [quarter navigation](../doc/design/reference/city/observations/2026-09-10_quarter_artwork_and_navigation.md)
  and [tile loading/city scale](../doc/design/reference/world/observations/2026-09-10_world_tile_loading_and_city_scale.md)
  distinguish observations, published rules and gaps. The source unlicensed
  sale was rejected; successful local licensed resale is not presented as a
  newly observed successful Neverlands sale.
- **Server authority:** Shop transactions lock and revalidate ownership,
  location, offer, license, price/item state, capacity, stock and funds.
  Database constraints and retained receipts protect financial invariants.
  Browser coordinates, artwork geometry and quoted form data are not authority.
- **Local adaptations:** adaptive sizing, original imagery, technical offer
  TTLs and bounded starter content are explicit implementation choices. No
  periodic restock, automatic economic reset or unobserved license right is
  implied. Rails/domain owners remain documented in the handbooks.

## Rollout and recovery

Apply the three added migrations through `bin/rails db:migrate`: Shop accounts
and stocks, character licenses, then currency/receipt hardening. PostgreSQL
triggers and generated references require [db/structure.sql](../db/structure.sql)
instead of a Ruby schema dump. Use compatible PostgreSQL tooling; load a schema
only into an empty/disposable database. Migration preflight rejects invalid
financial/history data rather than silently rewriting it.

Fresh bootstrap retains the explicit dependency order in
[db/seeds.rb](../db/seeds.rb). Existing installations use the targeted
[Shop content rollout](../doc/features/shop_economy.md#content-rollout):

```bash
SHOP_CATALOG_ONLY=1 bin/rails runner 'load Rails.root.join("db/seeds/shop_inventory.rb"); load Rails.root.join("db/seeds/shop_accounts.rb")'
```

Catalog-only application grants no demonstration items/licenses. Repeated
account seeding preserves traded stock and balances; template corrections
preserve owned-item durability. An unconfigured shop cannot borrow Forpost's
economy. Gate repair is exact-target and transactional, preserves managed
content and unrelated player/economic state, and aborts conflicts; follow the
[bounded gate-repair procedure](../doc/guides/managing_game_content.md#bounded-forpost-gate-repair).
Do not reset/replant an existing game to apply these changes.

Deploy matching artwork/config together and reload the process-cached catalog
after configuration changes. Retained receipts restrict deletion of referenced
financial records; no administrative reversal UI is supplied. Recovery needs
an explicit reconciled procedure, not deletion of ledger history. This final
changelog-only follow-up performs no migrations, reseeding or gameplay mutation.

## Verification

### Previously recorded local automated results

Final pre-merge `bin/verify full` on `c24f6abe` passed: **2,602 non-system and
293 system examples, zero failures; 562 Ruby files lint clean; Brakeman zero
warnings; Bundler and Importmap audits clean; 11 feature handbooks and 83
architecture documents passed**. These results are preserved in
[Shell acceptance](../doc/features/game_shell.md#september-11-final-local-browser-acceptance)
and were cross-checked against the retained local full-run log for this record.
Rack status-name deprecation warnings occurred; they were not test failures.
Runtime/security suites were not rerun for this documentation-only follow-up.

### Independently observed CI

[Run 362](https://github.com/lukin-io/mmorpg/actions/runs/34577148411)
on `98b53fe4` failed one non-system SQL-budget example and one short-movement
system example. Thread-scoped SQL capture and deterministic transient-state
assertions corrected those failures.
[Run 363](https://github.com/lukin-io/mmorpg/actions/runs/34578157128)
on `c24f6abe` passed all five jobs: lint, test, system-test, documentation and
security. This is pre-merge-head CI evidence, not an inferred run on squash
commit `bf19f52` or this subsequent changelog commit.

### Previously recorded local browser acceptance

After the applicable automated checks, actual Chrome controls were exercised
on local development data, separately from Neverlands observation:

- [Shop acceptance](../doc/features/shop_economy.md#september-11-pre-merge-manual-shop-acceptance),
  September 11, 1041×799 CSS px at DPR 2: cancel purchase preserved balance,
  mass and stock; confirm bought one 7-NV Penknife with stock 199→198 and
  mass 0→5. Inventory → Wear → profile/reload retained 10/10 durability;
  removal returned one carried item. Confirmed 1.4-NV resale restored stock
  to 199 and mass to zero; empty inventory survived reload/login. All six
  licenses rendered, duplicate Trading purchase was blocked and the tested
  level-16 player saw the beginner restriction. Native Chrome buttons handled
  confirmation dialogs when the browser connector stalled.
- [World acceptance](../doc/features/world.md#1511-pre-merge-offer-and-browser-acceptance-2026-09-11):
  390×844 phone-sized viewport, immediate Enter after resizing, Law Quarter
  exit back to `[11,9]`, then restored desktop navigation through Residential,
  Central Square and Shop. Earlier
  [raster/walker acceptance](../doc/features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10)
  inspected joined detailed cells, actual cardinal/diagonal motion and all
  eight animation directions. Phone-sized pointer use is not physical-touch
  or comprehensive zoom acceptance.
- [Final Shell acceptance](../doc/features/game_shell.md#september-11-final-local-browser-acceptance):
  expired-form resubmission recovered to a fresh sign-in form, explicit
  credentials restored Shop, and a new logout/login succeeded on its first
  credential submission. Inventory, balance and stock remained persisted.
  Earlier exploratory passes and the earlier blocked Shop confirmation were
  superseded by these successful affected-flow checks.

### New checks for this consolidated record

- `bin/verify docs` — passed: 11 feature handbooks and 83 architecture
  documents. Four existing Partially Implemented status warnings remain
  intentional; they are not audit failures.
- `python3 tmp/validate_city_session_links.py` — passed: all 44 relative links
  resolved, including 15 heading anchors; all eight required sections present,
  no template placeholders. This temporary read-only validator explicitly
  covers this changelog, which is outside the canonical audit inventory.
- `git diff --cached --check` and `git diff --check` — passed. Final status
  and staged-file review contain only this new changelog; process documents,
  runtime files and the earlier World record are unchanged.

The documentation and link checks were repeated on the finalized record.
No new browser pass applies: this follow-up changes only historical
documentation. No unrelated work was staged or changed.

## Documentation

The session synchronized the canonical runtime owners:
[Shop/Economy](../doc/features/shop_economy.md),
[Inventory](../doc/features/player_inventory.md),
[City](../doc/features/city.md), [World](../doc/features/world.md),
[Shell](../doc/features/game_shell.md),
[Character Progression](../doc/features/character_progression.md) and
[Quests](../doc/features/quests.md), including related handoffs and gap owners.
Evidence indexes, domain navigation, normalized economy/inventory/city/world
design and the [MVP plan](../doc/design/launch_mvp_plan.md) track their respective
truth layers.

[ARTWORK.md](../doc/ARTWORK.md),
[map generation record](../doc/artwork/forpost-panel-map-generation.md) and
[walker repair record](../doc/artwork/traveller-walk-repair-generation.md)
preserve prompts, sources, technical packaging and unsuccessful corrections.
[Shared scene standards](../doc/ARTWORK.md#shared-scene-image-standard) and
[adaptive UI acceptance](../doc/design/areas/game_client_layout.md#adaptive-ui-acceptance)
own dimensions/composition and responsive/manual-check requirements. Engineering,
UI and content-management guidance was updated during implementation.

This final follow-up adds only this consolidated record. The current
[AGENTS.md](../AGENTS.md) and
[changelog template](CHANGELOG_TEMPLATE.md) were reread; the user's explicit
whole-session instruction governs this record. Process files and the earlier
World changelog are preserved, per the final narrowed request.

## Follow-up

Owners below identify the responsible feature/domain, not an unassigned
individual. An unscheduled item has no promised delivery date or inferred
post-MVP exemption.

| Gap | Owner | Delivery stage / disposition |
|---|---|---|
| `[IMPL]` Full assortment, additional item art and other shops' authored funds/supply; `[EVIDENCE]` replenishment, successful source sale/license feedback, renewal/activation/expiry and eligible novice variants | [Shop §6.4](../doc/features/shop_economy.md#64-deferred-behavior-boundary), Economy evidence | Full Shop parity Not Done in MVP; remaining slices Not scheduled. |
| `[IMPL]` Merchant garment reward/dialogue presentation and Doctor qualification/treatment; unresolved exact source dialogue/variants remain `[EVIDENCE]` | [Shop §6.4](../doc/features/shop_economy.md#64-deferred-behavior-boundary), [Character Progression](../doc/features/character_progression.md), [Professions](../doc/features/professions.md) | Bounded profession follow-up; Not scheduled, not automatically Stage 2. |
| `[IMPL]` Consensual player-sale settlement and `[EVIDENCE]` missing offer/acceptance variants | [Inventory](../doc/features/player_inventory.md), [inventory design](../doc/design/features/items_inventory_equipment.md) | Not scheduled; unilateral settlement remains disabled. |
| `[IMPL]` Remaining quarter service interiors and source-backed operations | [City](../doc/features/city.md), [MVP plan](../doc/design/launch_mvp_plan.md) | Separate city-building task requested by user; City-interior parity Not Done, no date agreed. |
| `[IMPL]` Named coarse-pointer alternatives for small building/exit hotspots and remaining touch/zoom acceptance | [adaptive UI requirements](../doc/design/areas/game_client_layout.md#adaptive-ui-requirements), City (`UI-ADAPT-005`) | Open adaptive acceptance requirement; Not scheduled. |
| `[IMPL]` Perfect diagonal opposite-foot walking anatomy | [World §15.10](../doc/features/world.md#1510-city-raster-detail-and-walking-frame-stability-2026-09-10), artwork repair record | Visual polish Not scheduled; current four-phase loops retain this limitation. |
| `[IMPL]` Full-zone population/art; further populated zones and walking crossings | [World §19](../doc/features/world.md#19-open-world-parity-audit-updated-2026-09-09), [movement design](../doc/design/features/movement.md) | Full-zone content/art: Stage 2. Additional populated zones/crossings: after the one-zone MVP. |
| `[IMPL]` Mine/profession and exchange operations; missing complete source workflows are `[EVIDENCE]` | [Shop §6.5](../doc/features/shop_economy.md#65-mine-shop-and-resource-exchange-gap-ownership), [Professions](../doc/features/professions.md) | Separate unfinished workflows, Not scheduled; reachable lobbies do not implement operations. |

The `[DOC]` gap for a discoverable consolidated city/shop/artwork session
record is closed by this file; no runtime-parity gap is closed by documentation
alone.

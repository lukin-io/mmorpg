# UI/UX Alignment Plan (English-only player loop)

This document is a handoff plan for continuing the Neverlands-based UI/UX
alignment work. It is written so another agent can pick up execution without
re-deriving context.

## Goal

Align the player-facing UI/UX of the Rails game with the Neverlands captures in
`doc/design/`, focusing on the **person loop**: game shell (top bar), player
profile, inventory, and the stats/skills allocation surfaces.

## Hard decisions already made (do not relitigate)

1. **Player-facing language is English-only.** This is the launch principle in
   `doc/design/launch_mvp_plan.md` and `doc/design/areas/game_client_layout.md`,
   and the maintainer explicitly confirmed: the *current game* is English-only;
   Neverlands (the reference) is Russian, but our build is not. Convert every
   player-facing Russian string to English. Keep the original Russian only as
   non-rendered source/traceability metadata (see `source_name` in the skill
   registry) or in capture docs under `doc/design/reference/`.
2. **No live-site scraping.** Do not attempt to log into `neverlands.ru`. The
   capture discipline in `doc/design/reference/neverlands_live_player.md` warns
   that repeated logins lock the account for 30 minutes. The captures already in
   `doc/design/reference/` (including the 2026-05-25 `max_kerby` game-shell
   capture) are the authoritative reference.
3. **Reference, not literal clone.** No iframes/frameset. One persistent Rails
   game layout, replaceable `main_content` Turbo frame, persistent chat/presence,
   server-authored actions. Reuse the existing `nl-*` CSS token surface; do not
   add Tailwind.

## Environment / how to run tests

The repo uses an RVM gemset. The default shell Ruby (3.4.4) is wrong and Bundler
will refuse to run. Activate the project Ruby first in every shell:

```bash
source ~/.rvm/scripts/rvm; rvm use ruby-4.0.3@mmorpg --create
bundle exec rspec <files>
```

System specs are `js: true` (Capybara + browser driver) and are slower; run the
request/view/model specs first for fast feedback.

## Phase 1 — person loop (DONE)

Converted the shell, profile, inventory, and stats/skills allocation to English
and aligned them with the captures. Files changed:

App (data/labels):
- `app/lib/game/skills/passive_skill_registry.rb`: skill `name:` + category
  names now English; added `source_name:` (original Russian) for traceability;
  `description` is English.
- `app/models/character.rb`: `STAT_LABELS` and `ALIGNMENT_LABELS` now English;
  `alignment_label` fallback `"None"`.

App (shell):
- `app/views/layouts/game.html.erb`: top nav (`Character`/`Inventory`/`Skills`/
  `Return`/`Exit`), chat `Say` button, players panel (`refresh`/`Unknown`/
  `Total`), exit confirm text — all English.
- `app/views/shared/_player_context_buttons.html.erb`: English; aligned to the
  captured strip (`Your character` / `Inventory` / `Skills` / `Stats` /
  `Return`).

App (profile):
- `app/views/players/show.html.erb`: English; added owner-gated **Primary
  stats** panel (value + equipment delta), **Combat profile** panel (attack,
  defense, crit, AP, attack cost, armor class, dodge, accuracy, crushing,
  fortitude, armor pierce), and embedded the stat-allocation panel for the
  owner when stat points are available (profile owns the allocation loop). Money
  + detailed stats are gated to the owner so the public `/player/:name` page
  stays a paper-doll + basic info (per "formula/detail stats are not part of the
  public player page").
- `app/controllers/players_controller.rb`: sets `@own_profile`, `@stats_data`,
  `@allocatable_stats` for the owner; added `build_stats_data`.
- `app/helpers/player_profile_helper.rb`: added `profile_primary_stats` and
  `profile_combat_stats`.
- `app/views/shared/_player_equipment_summary.html.erb`: uses the shared
  paper-doll; money row gated behind `show_money` local.

App (shared paper-doll — unifies profile + inventory dolls):
- NEW `app/views/shared/_equipment_paperdoll.html.erb` and
  `app/views/shared/_equipment_paperdoll_slot.html.erb`. Read-only for the
  profile (`interactive: false`, source `slots_pla`); interactive remove for
  inventory (`interactive: true`, source `slots_inv`) via an accessible
  per-slot remove button. Interactive filled slots keep the
  `equipment-slot--<slot>` + `filled` classes for styling/specs.
- DELETED `app/views/inventories/_equipment_slot.html.erb` (superseded).

App (inventory):
- `app/views/inventories/show.html.erb`: `Inventory`, `Mass`, `Sort by type`/
  `Sort by name`.
- `app/views/inventories/_equipment.html.erb`: renders the shared interactive
  paper-doll.
- `app/views/inventories/_grid.html.erb`: `Wear`/`Use` actions (were Russian).
- `app/views/inventories/_stats.html.erb`: English parameter labels.
- `app/helpers/inventories_helper.rb`: `Mass`/`Description` labels.

App (allocation pages + flashes):
- `app/views/characters/stats.html.erb`, `skills.html.erb`,
  `_stat_allocation.html.erb`, `_skill_allocation.html.erb`: English.
- `app/controllers/characters_controller.rb`: all stat/skill flash + auth
  messages English.
- `app/services/game/inventory/manager.rb`: use-item messages English
  (`Restored N HP/MP`, `No usable effect`).
- `app/services/players/progression/stat_allocation_service.rb`: English error.

App (CSS):
- `app/assets/stylesheets/application.css`: added `.nl-slot-unequip`,
  `.nl-profile-slot-durability`, `.nl-profile-slot-value--empty`,
  `.nl-stat-equip-delta`, and `.nl-profile-slot { position: relative }`.

Specs updated to English assertions:
- `spec/views/layouts/game_spec.rb`
- `spec/requests/characters_spec.rb`
- `spec/models/character_spec.rb`
- `spec/system/skill_allocation_spec.rb`
- `spec/system/inventory_progression_spec.rb` (also: unequip now clicks the
  per-slot `Remove Weapon` button instead of clicking the slot div)

Note: the arena fighter card (`app/views/arena_matches/_fighter_card.html.erb`)
hardcodes Russian `Сила:`/`Ловкость:` literally (not via `STAT_LABELS`), so the
Phase 1 label change does not affect `spec/system/arena_match_ui_layout_spec.rb`.
That card is Phase 2 (arena) work.

### Phase 1 verification status

- [x] Run and green via full suite: `spec/requests/characters_spec.rb`,
  `spec/requests/players_spec.rb`, `spec/requests/inventories_spec.rb`,
  `spec/views/layouts/game_spec.rb`, `spec/models/character_spec.rb`.
- [x] Run and green via full suite (js): `spec/system/skill_allocation_spec.rb`,
  `spec/system/inventory_progression_spec.rb`.
- [x] Browser smoke covered the active game shell pages after the English pass.

## Phase 2 — English conversion across the rest of the game (DONE)

Player-facing Russian strings outside the person loop have been converted to
English, with matching spec assertions updated. Source scan status: `rg
'[А-Яа-яЁё]' app config db spec` now only reports non-rendered passive-skill
`source_name` metadata.

Areas and where the strings live (app → spec):

1. **World / movement / city** — DONE. `app/controllers/world_controller.rb`,
   `app/services/game/world/*` (`tile_building_service.rb`,
   `city_hotspot_service.rb`, `tile_npc_service.rb`), `app/views/world/*`.
   Specs: `spec/requests/world_spec.rb`, `spec/system/world_map_spec.rb`,
   `spec/system/world_interactions_spec.rb`, `spec/system/onboarding_spec.rb`,
   `spec/views/world/*`, `spec/services/game/world/city_hotspot_service_spec.rb`,
   `spec/models/city_hotspot_spec.rb`. Note: zone/NPC/building *names* (e.g.
   "Форпост", "Чумная крыса") are seed/content data — decide with the maintainer
   whether to localize content names or only UI chrome. Recommendation: localize
   UI chrome and action labels (`Войти`→`Enter`, `Напасть`→`Attack`, building
   error messages); treat proper nouns as content to localize via seeds later.
2. **Shop (`Лавка`)** — DONE. `app/services/game/shop/*` (`catalog.rb`, `sale.rb`,
   `purchase.rb`), `app/controllers/shop_controller.rb`, `app/views/shop/*`.
   Specs: `spec/requests/shop_spec.rb`. Tabs/categories/messages →
   English (`Купить`→`Buy`, `Лицензии`→`Licenses`, `Продать`→`Sell`,
   `Новичкам`→`Novice`, `Недостаточно NV`→`Not enough NV`, etc.).
3. **Arena + combat** — DONE. `app/views/arena*/**`, `app/views/arena_matches/*`
   (incl. `_fighter_card.html.erb` hardcoded `Сила:`/`Ловкость:`),
   `app/helpers/arena_helper.rb`, combat action labels in
   `Game::Combat::ActionCatalog` / combat services (`Простой удар`,
   `Прицельный удар`, `Блок ...`, `Сделать ход`, `Бой начался`, `Идет`,
   `Завершен`, `Победа`/`Поражение`, `Принять`, `Подать заявку`, room names).
   Specs: `spec/system/arena_match_ui_layout_spec.rb`,
   `spec/system/arena_npc_combat_spec.rb`,
   `spec/system/arena_match_notification_spec.rb`, arena request/service specs,
   `spec/services/arena/combat_processor_spec.rb` (`Недостаточно ОД`).
4. **Chat / presence** — DONE. `app/views/shared/_online_players*.html.erb`,
   `_nl_players_list.html.erb`, chat partials (`Приватно`, `Инфо`,
   `Нет игроков`). Specs: `spec/views/shared/_online_players_compact_spec.rb`,
   `spec/views/shared/_nl_players_list_spec.rb`.
5. **Devise/auth pages** — DONE. Login/registration pages now use English
   headings and controls.

### Phase 2 verification status

- [x] Full suite: `bundle exec rspec` — 1405 examples, 0 failures, 4 expected
  pending specs.
- [x] Browser smoke: `/world`, `/arena`, and `/shop` render without Cyrillic
  body text when records are recreated from the updated English seeds/config.
- [x] Persisted seed/content names are defined in English in `db/seeds.rb` and
  gameplay config; recreate the records to replace old Russian zone, hotspot,
  room, NPC, and item names.

## Phase 3 — remaining UI/UX fidelity items (not language)

These are open alignment items from the gap analysis; pick up after language is
consistent. Cross-check each against the cited capture before building.

- **Inventory categories**: `InventoriesHelper::INVENTORY_CATEGORIES` only has
  All/Things/Elixirs/Materials. The capture
  (`neverlands_live_player.md` → "Inventory Categories") lists 8 top-level
  families + equipment subcategories. Expand only with backing item_type
  mapping in `InventoriesController#inventory_category_item_types`; do not add
  filter tabs that match nothing.
- **Slot rules**: two-handed weapons (occupy both hand slots), layered armor,
  ring/belt/pocket-content slots, relic — see
  `doc/design/features/items_inventory_equipment.md` "Remaining design detail".
- **Item seeds**: recreate the captured live inventory items + exact
  requirements/effects (capture: "Captured Inventory Contents").
- **Durability/repair UX**: breakage messages, repair flow.
- **`Навыки` boolean perks**: not implemented after the generic-perk cleanup;
  rebuild only from captured perk IDs/point pool/exclusions if the MVP loop
  needs them (`launch_mvp_plan.md`).
- **Quests modal, `Лавка` shop building, wild NPC handoff**: documented but not
  implemented; out of UI/UX-pass scope but tracked in `launch_mvp_plan.md`.

## Working rules for the next agent

- After editing a string, immediately grep specs for the old Russian token and
  update assertions in the same change (`rg '<token>' spec`).
- Keep edits area-scoped and run that area's specs green before moving on.
- Preserve `data-*`/Stimulus hooks and CSS class names; only change visible text
  unless a layout/markup change is explicitly part of the task.
- When a capture and the code disagree, the capture wins; update the code, and
  if the design rule itself changes, update the relevant `doc/design/` file too
  (do not silently diverge).

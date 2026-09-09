# NPCs And Quests

Domain navigation: `doc/domains/npcs_quests.md`.

## Purpose

NPCs make locations readable and useful. Source-backed quest behavior still
needs a dedicated Neverlands capture before Rails implementation.

## Source Material

Inputs:

- live arena mannequin and outdoor hostile-NPC captures;
- observed NPC drop/result behavior;
- supplied mixed chat/game-event timeline observation in
  `doc/design/reference/social/observations/2026-08-23_chat_game_event_timeline.md`;
- official NPC group-size guidance and unresolved equations preserved in
  `doc/design/reference/social/observations/2026-09-07_cell_chat_and_presence_boundaries.md`;
- documented movement, tile-action, and shop captures.
- the bounded starter atlas and explicit user-reported encounter cadence in
  `doc/design/reference/world/observations/2026-09-09_starter_encounter_authoring.md`.
- unresolved NPC inputs and their existing evidence in
  `doc/design/reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md`.

## Player Experience

The player encounters NPCs as source-backed combatants: outdoor hostile NPCs
on world tiles and arena training opponents inside the arena flow.

Building services are not NPC dialogue yet. `Лавка` is a documented shop
building, not a generic town vendor NPC. Any future building NPC, service NPC,
or quest NPC must be captured from Neverlands before adding tables, routes, or
UI.

Quest interaction is intentionally not implemented right now. It should be
documented from Neverlands before adding tables, routes, or UI.

## NPC Roles

Core:

- hostile monster;
- arena training opponent;
- loot-bearing combatant.

Deferred until capture:

- building/service NPCs;
- quest NPCs;
- dialogue/action entry points;
- training, storage, banking, transport, or other town services.

## NPC Rules

- NPC availability is tied to location.
- NPC role defines default actions.
- Hostile NPCs can start PvE combat.
- Outdoor hostile NPCs can interrupt normal tile actions and hand the player
  into combat from the current coordinate.
- Arena training NPCs can appear as normal arena application participants and
  resolve through the same combat rules as player and team fights after the
  player accepts the open side.
- No town service role may create an action until its Neverlands behavior is
  documented.

## NPC Loot And Drops

NPC drops are part of NPC design, even when the NPC appears inside the arena.
Arena training opponents, wilderness monsters, dungeon blockers, and bosses can
all own loot rules.

Design rules:

- an NPC can define a loot table with item entries, drop chances, quantity, and
  optional conditions; typed entries currently support items and NV;
- every authored loot entry declares its chance explicitly as either a `0..1`
  fraction or `0..100` percent; an omitted chance is invalid rather than a
  silent guaranteed award;
- loot is rolled after combat victory and before or during the result-finish
  step;
- the canonical combat log/result should show whether the NPC was searched and
  whether anything was found;
- dropped items enter the same inventory/capacity rules as loot and shop
  purchases;
- a successful carried-item award also creates a recipient-only item-found row
  in the persistent chat timeline; a failed capacity or validation outcome
  must not claim that an item was awarded;
- a successful NV outcome credits the player's persisted wallet and immutable
  transaction ledger before creating a recipient-only money-found row;
- one persisted per-NPC-participation resolution marker makes item/NV award
  processing retry safe independently of the presentation event;
- capacity, protected-item rules, and binding rules must be enforced before the
  item becomes carried inventory;
- arena rewards and NPC drops are separate concepts: a mannequin dropping wood
  chips is an NPC loot-table result, not a generic arena payout;
- NPC templates can share a loot table, but individual spawned NPCs can also
  override it when a source-backed capture proves that behavior.
- an NPC template can provide an explicit XP reward independently from its
  loot table;
- a solo winning player receives the sum of configured defeated-enemy NPC XP,
  capped by the current level's source table; multi-player distribution is not
  implemented until the Neverlands group formula is captured;
- Observation is known to affect drop probability, but its nonlinear formula
  is not captured, so explicit loot-table rolls currently remain unchanged.

The mannequin/wood-chips case belongs here: `Манекен` is an arena training NPC,
and wood chips are a low-value material drop from that NPC role. The May 19
starter capture won three mannequin fights and each result log included a bot
search result of `Вещь «Щепки»`; inventory then showed `Щепки` as carried item
rows. The drop should flow through combat result -> loot check -> validated
inventory item/material -> personal timeline fact, then feed shop economy
rules. The inventory row remains the item authority; the timeline row is
feedback only.

The outdoor rat-tail case belongs here as well. The May 20 capture near
`Окрестность Форпоста` entered two bot-ambush fights against paired
`Чумная крыса` NPCs. In that capture, each defeated rat passed its random
bot-specific loot roll and produced a separate search result line of
`Вещь «Крысиный хвост»`. In the first fight, the first rat was searched before
the second rat was defeated, proving that per-NPC loot checks can happen during
a multi-NPC fight and not only after the fight-level victory line.

The capture proves that Plague Rats can drop Rat Tails but does not establish
their exact probability. The local production entry therefore retains the
pre-existing no-drop behavior through an explicit `0.0` evidence hold. That
value is not a Neverlands balance claim; replace it only after the probability
is observed, then cover and document the source-backed value.

## Outdoor Hostile NPCs

Outdoor hostile NPCs are hidden tile-local combatants. The outdoor map does not
present their marker, identity, stats, or a manual Attack control; the captured
source behavior reveals them by interrupting a normal outdoor action.

Design rules:

- NPC availability and hostile attack eligibility are resolved from current
  tile state;
- NPC identity and placement remain server-only until combat begins;
- a hostile check can run before a mutating outdoor action completes;
- a bot attack creates a normal fight with side/team membership, not a special
  wild-combat shortcut;
- a fight can include multiple NPCs on one side, up to the official article's
  stated ten-member maximum; this is capacity, not an uncaptured roster;
- when one NPC in a multi-NPC fight loses, the fight can continue against the
  remaining NPCs;
- each defeated loot-bearing NPC can run its own bot-specific random loot-table
  check.

Implemented MVP boundary:

- the captured Plague Rat cell is represented by one persistent `TileNpc` encounter anchor with explicit `encounter_count: 2` source metadata;
- starting the encounter creates two separate `ArenaParticipation` rows on the NPC side, even though both use the same `NpcTemplate`;
- each living NPC acts and each defeated NPC is searched/logged separately;
  the fixed paired-rat anchor is marked defeated only after its entire side
  falls;
- the mapped variable encounter cell selects one complete captured roster,
  preserving member order, identity, level/HP, XP, and injury-risk metadata;
  after victory and Finish it can schedule another sample at the same cell;
- fixed counts and complete samples accept `1..10` members; the model and
  fight-start checks reject eleven without a partial fight, and the config
  loader rejects oversized samples. Existing seeded groups are not expanded
  to fill the capacity;
- solo victory awards configured NPC experience through the shared idempotent
  fight-finalization path and respects the level-specific per-fight cap;
- offered movement, entrance, local observation, Character, and Inventory wilderness actions use one hostile-interruption query before their intended transition completes;
- no outdoor NPC action offer, marker, name, or manual attack endpoint is
  rendered;
- targetless passive checks use a persisted exact-cell deadline, captured
  delay windows on original captured anchors, the user-reported 300–360-second
  window on new starter profiles, and the existing explicit local fallback
  otherwise; neither a broad wiki cadence nor user approximation replaces
  measured live windows on the original independent capture;
- duplicate starts reuse the character's active match, and the result finish returns through a saved allowlisted logical context.

This is authored encounter composition, not a generic random-encounter table.
Only complete captured samples are replayed. Additional group sizes, members,
levels, and mixed templates require their own Neverlands evidence; the complete
eligible pool, selection weights, population/strength equations, probabilities,
and timing distribution remain unresolved.

### Bounded starter profile reuse

The user authorized populating starter encounter cells with source-backed
groups. Named profiles reuse complete captures only where every member's type
and exact level fits the destination cell's public atlas annotation. They do
not interpolate HP for the other levels in a range or invent a strength ring
around Forpost. The current projection supports 40 additional Bandit cells;
the existing `[7,7]` cell is the only surveyed match for the captured rat pair.
Atlas-inactive cells, entrances, the explicitly bot-free pond, and occupied
managed cells are excluded from initial bootstrap.

New sampled placements use the user's approximate five-to-six-minute interval
as explicit configurable data, with uniform integer sampling inside
`300..360` seconds as a local calibration. Uniformity is not a measured source
rule. Placements can select another complete eligible sample
after victory and Finish. Their target atlas provenance and original roster
capture are separate. Fixed source anchors retain their existing lifecycle.
Bootstrap writes the same editable cell records as Manage; later management
edits, moves and deactivation survive reseeding. A deleted bootstrap record
can be recreated by a later seed, so deactivation is the durable removal path.
The content guide owns that operator workflow.

### Remaining NPC content and formula work

The [NPC-owned gap record](../reference/npcs_quests/observations/evidence_needed_world_npc_content_and_formulas.md)
is the detailed follow-up list for this feature. It distinguishes:

- **Missing combat content:** broader NPC identities and exact-level HP/stats,
  especially rats at levels 0–3. Level-zero authoring, selection and display
  already work; the missing part is supported content, not integer handling.
- **Incomplete encounter pools:** every eligible whole composition, group size
  and member combination for the target cells. The 40 added starter placements
  reuse existing profiles; they are not 40 newly captured groups.
- **Unresolved probability rules:** group weights, action/passive attack
  probabilities, cooldowns, timing distributions and player-state modifiers.
  Equal default sample weights and uniform local delays are explicit calibration,
  not exact Neverlands formulas.
- **Weak starter-area content:** use captured weak profiles only where atlas
  eligibility supports them. More varied low-level encounters require more
  content evidence; do not derive strength from distance to Forpost or assume
  a painted road is free of NPCs.
- **NPC reward inputs:** per-NPC drop/NV chances and reward modifiers remain
  bounded by the NPC Loot section and the existing combat/progression owners.

These are evidence/content follow-ups within the declared one-zone scope;
additional zones do not have to exist before supported starter content can
be added. Unknown general formulas do not justify fabricating missing stats.
`doc/features/world.md` remains the current-runtime and verification owner,
and the MVP plan owns scheduling rather than this evidence-gap list.

## Quest Behavior Status

Quest behavior is required for the final Neverlands-based design, but the old
generic quest/story implementation was removed. Do not rebuild quest chains,
daily tasks, repeatable tasks, cutscenes, branching story steps, quest boards,
or quest-giver roles until a Neverlands capture documents the exact behavior.

Required future capture:

- where quest entry points appear in the UI;
- how NPC dialogue or action links start a quest;
- how active tasks/journal state is displayed;
- how progress is updated through movement, combat, shop, or NPC actions;
- how completion, turn-in, reward, cancel, failure, and repeatability behave;
- whether quest items exist and how they are protected from sale/discard.

The 2026-05-25 shell/UI pass captured only the generic quest modal shape:
`Квесты` can appear in the top shell, open a modal overlay through keyed AJAX,
paginate dialogue text, and expose final get/finish actions. This is enough to
design an accessible modal shell later, but not enough to rebuild quest rules.

## State Concepts

- NPC template;
- NPC instance/location;
- hostile encounter rule;
- spawned tile NPC;
- loot table;
- drop result;
- future captured quest/action state.

## Interactions

- `areas/world_map.md`: outdoor NPCs and tile-local actions.
- `areas/cities_and_buildings.md`: building entry points.
- `areas/arena.md`: arena training fights.
- `features/combat.md`: hostile and training combat.
- `features/progression_stats_skills.md`: owns the level table, per-fight XP
  cap, grants, and deliberate group-XP evidence boundary.
- `features/social_chat_presence.md`: owns the personal item-found projection
  and money-found projection after Combat confirms the authoritative award.
- `features/economy_trading_shops.md`: owns the NV wallet and transaction
  ledger used by a configured NPC currency outcome.
- `features/professions.md`: owns future profession-gated NPC/resource activity,
  not hostile combat templates.

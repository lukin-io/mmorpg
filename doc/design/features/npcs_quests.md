# NPCs And Quests

Domain navigation: [NPCs and Quests](../../domains/npcs_quests.md).

[NPC](../../NPC.md) catalogs authored creatures, groups and drops;
[WORLD](../../WORLD.md#4-npc-habitats-and-resources) owns habitat context and
[ITEMS](../../ITEMS.md#4-acquisition-and-item-lifecycle) distinguishes loot from
decorative equipment. [Arena Combat](../../features/arena_combat.md) describes
current NPC fights; [Quests](../../features/quests.md) retains the separate
unimplemented quest boundary.

## September12 authorized calibration

The user authorized the best evidence-grounded approximation after22 controlled
fights. [Calibration v1](combat_calibration.md) owns the fitted combat, mastery,
fatigue, magic, XP/drop, injury/recovery and remote-placement rules. It
supersedes earlier implementation holds for hidden coefficients; historical
source observations and uncertainty remain unchanged. Medical Care supplies
the bounded healer/patient transaction and Hospital bag purchase handoff.


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

General NPC quest interaction remains unimplemented. The official Trader wiki
now establishes a bounded Shop-owned license prerequisite: Market acceptance,
1,000-NV Shop receipt payment, then Market completion. The local implementation
persists that unlock path; original dialogue and its temporary garment reward
remain incomplete. See `features/economy_trading_shops.md` and the September 9
economy observation; this does not establish a generic quest system.

## NPC Roles

The final [Ogre cycle](../reference/combat/observations/2026-09-11_ogre_combat_cycle.md)
adds complete groups[16,16,17] and[16,16,16,18], with independent per-level
HP, displayed attributes and ten occupied equipment slots. Do not interpolate
the user's reported19–24 range. The single launch zone already has compatible
atlas habitats at local [20,6]/[20,7], remote from both Forpost gates. They use
one continuous darker woodland illustration under `doc/ARTWORK.md` and the
same editable TileNpc/encounter pipeline. These two placements are active with the September12 user-authorized
calibrated damage and fallback reward model.
The existing40 Bandit bootstrap placements remain unchanged.

Reusable starter profiles may now reference a template with complete captured
rosters without inventing a standalone source-coordinate anchor. Reseeding
preserves disabled/moved placements and operator-selected cell artwork.

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
- an eligible newly defeated NPC is searched after its committed exchange,
  including during an ongoing fight or one the player ultimately loses;
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
- a solo victory uses one configured NPC reward or an explicit encounter total;
  an uncaptured multi-NPC total uses the authorized calibration rather than claiming a source-verified sum.
  An explicit positive integer `encounter_defeat_experience_reward` supports
  the captured `57` XP loss only for a sole player with a defeated enemy NPC
  and an NPC winning side. It does not reuse victory XP or grant a victory
  counter. Both paths apply the recipient's level/entitlement cap; multi-player distribution and general XP now use [calibration v1](combat_calibration.md#experience-and-loot);
- Observation modifies drop probability through the documented fitted saturating curve; its exact Neverlands equation remains unexposed.

Search eligibility uses the actual participant level and the recipient's
active trusted combat entitlement: total windows are standard/Worker ±2,
Premium ±2, Gold ±4 and VIP ±6. Corresponding maximum fight-XP multipliers are
×1.0, ×1.5, ×2.0 and ×2.5; they change the cap, not earned XP or drop chance.
Authored limits only narrow these windows, and `search_enabled: false` always
disables search. The [Arena handbook](../../features/arena_combat.md#63-turn-combat-and-completion)
owns server metadata, expiry, mutation guards and reward persistence. The
[stronger-NPC observation](../reference/combat/observations/2026-09-11_stronger_npc_loot_combat_cycle.md)
owns the direct loss/loot/premium evidence. No purchase flow is implemented by
these combat benefits.

Higher-level NPCs and larger NPC groups should yield more XP per fight. This
is a normalized content direction: observed rewards depend strongly on roster
composition and level, with combat contribution and the recipient's cap also
relevant. Keep actual captured XP and source player level with each encounter;
do not invent an additive or scaling formula. The completed ten-fight stronger
cycle includes Robber 14 solo awards of 494 and 493 XP despite the same 815
credited HP and one defeated opponent.

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
their exact probability. The September12 user-authorized local entry uses provisional 3%. This is
calibration, not a measured Neverlands probability; typed pools and Observation
also use explicitly documented fitted values.

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
  stated ten-member content maximum, additionally bounded by the player's
  [progression ceiling](../../FORMULAS.md#prog-02--current-level-table). Select
  complete eligible samples, never truncate a captured group or its rewards;
- when one NPC in a multi-NPC fight loses, the fight can continue against the
  remaining NPCs;
- each defeated loot-bearing NPC can run its own bot-specific random loot-table
  check.

Implemented MVP boundary:

- the captured Plague Rat cell is represented by one persistent `TileNpc` encounter anchor with explicit `encounter_count: 2` source metadata;
- starting the encounter creates two separate `ArenaParticipation` rows on the NPC side, even though both use the same `NpcTemplate`;
- in solo PvE, only the selected NPC returns its committed package; each
  defeated NPC is logged and independently considered for eligible search;
  the fixed paired-rat anchor is marked defeated only after its entire side
  falls;
- the mapped variable encounter cell selects one complete captured roster,
  preserving member order, identity, level/HP, XP, and injury-risk metadata;
  after victory and Finish it can schedule another sample at the same cell;
- fixed counts and complete samples accept `1..10` members; the model and
  fight-start checks reject eleven without a partial fight, and the config
  loader rejects oversized samples. Existing seeded groups are not expanded
  to fill the capacity;
- solo victory or explicitly configured defeat XP uses the shared idempotent
  finalization path and recipient level/entitlement cap; positive solo-NPC
  completion chat is published once on Finish, not by rerunning the award;
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

### Per-level combat and equipment sets

`NpcTemplate` metadata separates engine `stats`, visible `display_stats`, mana,
`combat_profile`, response inputs, avatar and equipment. Template defaults,
exact `level_profiles` and per-participation overrides are snapshotted at fight
start. Equipment is a complete slot map: the highest-priority authored map
replaces the lower map, including when empty or smaller. It is not merged slot
by slot. Omitted visible stats stay unknown rather than borrowing attack/HP
or a portrait's props.

The stronger cycle independently records Bandit and Robber level 13–15 sets,
including Robber 14 in fight 5 and Bandit 13 in fight 8. Store each new loadout in
its exact level profile. Do not put high-level gear at the template root where
unknown low levels would inherit it, or infer further levels from the player's
stat-grant table. Preserve an existing root set only where its shared scope is
itself evidenced. New spawned fights read updated content; started fights keep
their captured snapshots. Repeated NPCs retain separate identities and state.

Named filled slots and empty slots are content, independent of original
portrait/equipment art registered in [ARTWORK.md](../../ARTWORK.md). Descriptive
NPC equipment creates neither player inventory nor additional loot outcomes.
Per-level management must keep all slots and the independently observed numeric
profile together; changing an item name or image must not invent numeric stats.
The source origin of the stronger capture remains unknown. September12
authorizes provisional local remote habitats at [19,9]/[19,10], using all ten
complete `encounter_presets`. Exact roster profiles and explicit rewards retain
their evidence; local placement and delay bands are marked as calibration.

Mixed player/NPC commitment examples do not verify independent NPC-versus-NPC
AI, target selection or progression. Stage2 source capture is complete; the [Combat Completion Matrix](../launch_mvp_plan.md#combat-completion-matrix) links the current calibration and final local acceptance separately from that historical source evidence.

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

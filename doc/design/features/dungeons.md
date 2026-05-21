# Dungeons

## Purpose

Dungeons are a post-MVP Neverlands-based feature. They are not part of the
launch MVP in `doc/design/launch_mvp_plan.md`.

The dungeon feature exists around two source-defined goals:

- team goal: descend as deep as possible;
- individual goal: claim the current floor's prize.

## Source Of Truth

Only these Neverlands sources define dungeon design for now:

- Neverlands wiki dungeon page:
  `http://wiki.neverlands.ru/wiki/%D0%9F%D0%BE%D0%B4%D0%B7%D0%B5%D0%BC%D0%B5%D0%BB%D1%8C%D1%8F`
- Neverlands forum dungeon launch post:
  `http://forum.neverlands.ru/12/1/882967/10/`

Do not add dungeon mechanics from generic MMO assumptions, the current legacy
code scaffold, or old local docs. If this file disagrees with those source
pages, the source pages win. When the wiki and forum differ, prefer the current
wiki page; the forum post is the original launch explanation.

## Player Experience

The player reaches a dungeon entrance on the world map, enters or joins a run,
then explores room-by-room floors with a party or alone. The run is constrained
by lamp oil, floor timer, hostile room NPCs, floor-local keys, seals, and portal
state.

The dungeon loop is:

```text
enter dungeon
-> move between generated rooms by spending lamp oil
-> clear blocking NPCs
-> activate floor seals
-> optionally find the hidden-room key
-> optionally open the hidden room for a boss or chest
-> gather the party at the activated portal
-> descend to the next floor
-> repeat until exit, timeout, death/blocking state, or floor cap
```

## Entry And Applications

- Starting a dungeon run as leader requires a special dungeon key or equivalent
  unlock described by the source.
- The source describes key acquisition through crafting and through
  source-backed random-event rewards.
- A character without the starter key can join another player's application.
- Join eligibility is tied to the leader: party members can differ from the
  leader by no more than two levels.
- Dungeons have level and equipment-quality restrictions.
- Party size has a maximum, but there is no minimum; solo runs are allowed.
- The source limits the number of simultaneous active dungeon runs.
- Some source dungeon types have visit cooldowns or event availability windows.
- The leader can remove a party member during a run in the current source
  updates.
- If the leader leaves, the source launch post states that the whole party
  leaves with the leader.

## Dungeon Types And Restrictions

Source examples define dungeon access by level band, equipment quality, and
location. Treat those as design patterns rather than mandatory copied content.

Patterns to preserve:

- each dungeon type has a fixed entrance location;
- each dungeon type has level requirements;
- each dungeon type can allow or forbid equipment quality classes;
- temporary event dungeons can have different level and equipment restrictions;
- high-level dungeons can tie NPC strength to another world-system outcome;
- source updates currently cap dungeon depth at a finite floor count.

## Floor And Room Structure

- A dungeon contains multiple floors.
- Each deeper floor is harder, primarily through stronger NPCs.
- Dungeon maps are generated automatically; static player-made maps are not
  useful because layouts do not repeat.
- Each floor has ordinary rooms, one hidden room, floor-local seals, and a
  portal to the next floor.
- Each floor has a timer. If the party stays on a floor too long, the run is
  ejected from the dungeon entrance location.
- The floor timer resets after descending to the next floor.
- Current source updates define a finite bottom floor.

## Lamp Oil Movement

- Dungeon movement requires lamp oil.
- Each movement to another room spends one oil from the moving character.
- Oil is personal: it is spent even if another player has already lit or
  visited the room.
- A character with no oil cannot move.
- The source grants some oil at dungeon start.
- More oil can come from normal NPC drops, boss drops, or chest rewards.
- Oil scarcity is a dungeon pacing mechanic. The design should make oil
  spending visible and meaningful.

## Room Blockers And NPC Combat

- Hostile NPCs in the current room fully block the affected character.
- A blocked character cannot move, use interactive objects, or pick up keys
  until the NPCs are defeated.
- NPCs are attacked by selecting/clicking them.
- Party members can intervene in NPC fights to help allies.
- NPC strength increases with floor depth.
- Normal NPCs can drop oil.
- Bosses live in hidden rooms and can drop oil and dungeon currency.
- Boss archetypes from the source include lich-style bosses that require magic
  damage and paladin-style bosses with heavy resistance or shield behavior.
- Source updates add special boss/NPC behavior such as summoned plague zombies
  and single-target HP/MP explosion effects.
- Open PvE fights in source updates have a fixed timeout.

## Death And Recovery

- A character killed by dungeon NPCs receives combat injury in the source.
- A dead character cannot move or interact.
- The party cannot descend while a required party member is dead.
- Source recovery options are:
  - the dead player leaves the dungeon and party;
  - another party member resurrects them with a resurrection scroll;

## Seals And Portal Descent

- Each floor contains a portal.
- The portal starts inactive.
- The portal activates after the party activates five floor seals.
- Seal progress is shared by the whole party; it does not matter which
  character activates each seal.
- The current wiki rule requires all active party members to be in the portal
  room before descent.
- Portal descent is blocked if any required party member is dead, blocked by
  NPCs, in combat, or away from the portal room.
- Once descent succeeds, the party moves to the start room of the next floor.
- Floor-local keys disappear on descent.

## Hidden Room

- Each floor has one hidden room.
- The hidden room requires a floor-local key.
- The key is somewhere on the same floor.
- Only one character can pick up and use that key.
- After the keyed player opens the hidden-room door, any party member can enter.
- The hidden room resolves into a 50 percent chance of a boss or a 50 percent
  chance of a bonus chest.
- A chest can be claimed by only one character.
- Boss loot is available through boss combat participation rules.
- Lower floors increase boss strength and chest reward quality.

## Interactive Objects

Source interactive objects are:

- seals;
- portal;
- hidden-room door;
- hidden-room key;
- chest.

Source launch rules make object interactions one-time: after one character uses
an object, other characters cannot repeat that same interaction.

## Dungeon Inventory

- The normal inventory is unavailable inside the dungeon.
- Characters cannot change equipment inside the dungeon.
- A special dungeon inventory exposes only allowed consumables.
- Source consumables include HP restoration, MP restoration, combined HP/MP
  restoration, combat modifier buffs, primary-stat buffs, HP/MP maximum buffs,
  armor/physical damage buffs, elemental magic buffs, AP buffs, and
  resurrection.

## Dungeon Effects

- Characters receive a claustrophobia-style dungeon effect while inside.
- That effect significantly reduces HP and MP recovery speed.
- The source describes periodic magical disturbances inside dungeons.
- Disturbances apply temporary modifiers and expire when their duration ends or
  when the character leaves the dungeon.
- Disturbance patterns include:
  - one elemental magic school strengthened while the opposed school weakens;
  - all magic weakened while physical damage strengthens;
  - all magic strengthened while physical damage weakens;
  - physical damage strengthened while armor weakens;
  - physical damage weakened while armor strengthens;
  - AP strengthened while armor weakens;
  - AP weakened while armor strengthens;
  - one combat modifier strengthened while another weakens.

## Rewards, Ratings, And Specialist Shop

- Floor depth affects rating rewards.
- The source defines a permanent deepest-floor rating.
- The source defines a weekly rating based on total floors completed during the
  week.
- Hidden chests and bosses are the main floor prize hooks.
- Bosses can drop dungeon currency.
- Dungeon currency is spent in the source specialist shop.
- Source updates require contribution and survival for some boss currency drops.

## Non-MVP Build Sequence

When the launch MVP is complete, implement only the source-backed path:

1. Entrance and application flow with source-style key, level, equipment, party,
   and active-run restrictions.
2. Generated floor rooms, oil movement, floor timer, party state, and exit.
3. Room NPC blockers and source-style dungeon combat handoff.
4. Seal activation and portal descent with current wiki party-at-portal rules.
5. Hidden-room key, hidden-room door, boss/chest branch, and one-time object
   interactions.
6. Dungeon inventory, claustrophobia, magical disturbances, ratings, dungeon
   currency, and specialist shop.

## Legacy Until Proven By Source

Any dungeon scaffold is legacy for design purposes if it cannot be mapped back
to the wiki or forum sources. Generic difficulty modes, encounter checkpoints,
attempt counts, abstract raid-like instance flow, or reward rules not present
in those sources should not be treated as canonical dungeon design.

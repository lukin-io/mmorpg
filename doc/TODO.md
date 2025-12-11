# Elselands MMORPG – Design TODOs

High-level MMORPG design ideas to extend existing systems, grouped by
domain. These are *above and beyond* the current feature set and can be
broken into individual feature specs under `doc/features/` and
`doc/flow/` later.

---

## Items, Inventory, Crafting

- **Item Ecosystems & Set Synergies**
  - Design multi-piece item sets and smaller "micro-sets" (e.g.,
    2-piece bonuses) that interact with specific class builds,
    professions, or alignments.
  - Emphasize buildcrafting (synergies, conditional bonuses) over raw
    stat stacking so gearing decisions are more interesting.

- **Attunement & Item Growth**
  - Introduce items that level or "attune" to the user over time based
    on usage (kill count, specific quest completions, faction deeds).
  - Provide mutually exclusive upgrade branches so two players can own
    the same base item but evolve it in different directions.

- **Salvaging, Reforging & Rerolls**
  - Add a deterministic salvage system that breaks items into
    essences/components feeding other recipes.
  - Introduce reforging/rerolling stations where specific stat lines can
    be rerolled at predictable cost, providing a sink for unwanted
    drops and crafting mats.

- **Cosmetic Transmogrification & Dyes**
  - Allow players to imprint the appearance of one item onto another of
    the same slot (transmog), decoupling looks from stats.
  - Add dye/inscription systems tied to professions so crafters can
    create visual customization (colors, patterns, cosmetic glows)
    without affecting power.

- **Multi-Stage Legendary Crafting Quests**
  - Create epic, profession-heavy questlines where multiple crafts are
    required (blacksmith, enchanter, alchemist, doctor, etc.).
  - Legendary items become the culmination of coordinated effort rather
    than random drops, giving professions strong social value.

- **Collaborative Workshop Projects**
  - Add guild/clan workshops in cities or strongholds where members
    contribute materials/work orders into long-term projects.
  - Example outputs: siege engines, town statues, clan banners, special
    crafting stations, or buff-granting structures.

- **Specialized Crafting Minigames (Server-Authoritative)**
  - Design simple, step-based or timing-based crafting flows (e.g.,
    choose heat/hammer/cool steps) that influence quality within a
    deterministic server-authoritative model.
  - Reward knowledge and decision-making rather than reflexes; keep the
    math deterministic and testable.

- **Logistics & Storage Gameplay**
  - Extend inventory into logistics: crates, shipments, pack animals,
    carts, and clan warehouses.
  - Design trade-offs between shipping options (cheap but slow, risky
    but fast, instant but expensive) to link crafting with economy and
    regional trade.

---

## Economy & Trading

- **Player Shops & Stall Leasing**
  - Beyond kiosks and the auction house, allow players to rent stalls
    in cities or set up shops tied to housing plots.
  - Let players curate shop inventory, set pricing, signage, and
    opening hours, turning social hubs into real marketplaces.

- **Regional Markets & Trade Routes**
  - Make vendor prices and stock vary by region and biome so some
    materials are abundant in one area but scarce in another.
  - Encourage "merchant" playstyles that move goods along profitable
    routes, potentially linking with caravan systems.

- **Caravan & Escort Systems**
  - Introduce caravans (player, guild, or clan-managed) that move goods
    between cities with real risk: bandit NPCs, opt-in PvP zones,
    ambush events.
  - Provide strong rewards (profits, reputation, unique titles) for
    successfully completed routes.

- **Crafting Commissions & Contracts Board**
  - Add a commissions board where players post crafting orders with
    budget, materials provided/required, deadlines, and desired
    qualities.
  - Crafters accept contracts and receive escrow-backed payments upon
    completion, making professions a social service.

- **Service & Boost Contracts**
  - Extend contracts to services: dungeon carries, escorting caravans,
    boss kills, gathering runs.
  - Use in-game escrow that releases payment automatically when tracked
    conditions are met (boss defeated, caravan arrived, resource quota
    gathered).

- **Dynamic Vendor Pricing & Demand Signals**
  - Use existing analytics (`MarketDemandSignal`, price history) to let
    NPC vendors adjust buy/sell prices over time.
  - Dumping large quantities lowers vendor buy prices; shortages raise
    them, making the world feel economically reactive.

- **Reputation-Based Economic Perks**
  - Tie vendor discounts, auction tax reductions, extra kiosk slots, or
    better commission visibility to specific reputations/titles
    (e.g. "Renowned Trader", "Honest Smith").
  - Reward long-term fair trading and participation rather than raw
    currency totals.

- **Seasonal Economic Events**
  - Design time-limited events ("Iron Festival", "Harvest Week",
    "Alchemy Fair") where certain recipes are cheaper, vendor demand
    spikes, or specific resource nodes spawn more frequently.
  - Use these to periodically shake up the economic meta without
    permanent balance changes.

---

## Quests, Story & Events

- **Class & Profession Epic Storylines**
  - Create long, class-specific and profession-specific questlines
    (e.g., "Epic Hunter Trials", "Master Blacksmith Forge Saga").
  - Focus rewards on unique titles, cosmetics, utility abilities, and
    profession perks rather than just raw stats.

- **Branching Faction Campaigns with World States**
  - Extend alignment/faction systems into multi-chapter campaigns where
    server-wide outcomes influence world state (which faction controls
    a city, temporary taxes, NPC presence).
  - Use these arcs to temporarily change available quests, vendors, and
    travel options in affected zones.

- **Player-Influenced World Events**
  - Aggregate player actions (monsters killed in a region, quests
    completed, resources gathered) to trigger events like sieges,
    plagues, invasions, or festivals.
  - Unlock special quests, temporary rewards, and world reskins when
    thresholds are reached, making the world feel reactive.

- **Long-Form Mystery & Puzzle Arcs**
  - Introduce multi-step riddle, lore, and exploration chains with
    intentionally sparse guidance.
  - Emphasize server-wide collaboration (hidden runes, obscure NPC
    hints, map overlays) and reward cosmetic relics, titles, and
    achievements.

- **Dynamic Micro-Events & Local Stories**
  - Add recurring micro-events (caravans under attack, NPC duels,
    traveling merchants, weather-based quests) that spawn in specific
    tiles or zones.
  - Announce them via chat/map pings and keep them short and frequent
    so explorers always have "side hooks" while roaming.

- **Fail-Forward Quest Design**
  - Lean more on the existing failure-consequence framework: failing or
    abandoning certain quests should branch the story, not just block
    it.
  - Examples: rivals gain power, alternate zones/paths unlock, NPCs
    remember failures and adjust dialogue/rewards.

- **Cooperative Story Instances**
  - Design small story instances for 2–5 players where choices are
    voted on (dialogue options, branching paths).
  - Make outcomes affect all party members (branching rewards, future
    quest availability), reinforcing social storytelling.

- **Seasonal Story "Chapters"**
  - Run narrative seasons (e.g., 6–8 weeks) with a clear arc: opening
    quests, escalating events, and a finale.
  - After a season ends, keep key content accessible as dungeons/side
    quests while new seasons advance the overarching storyline.


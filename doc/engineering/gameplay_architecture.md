# Gameplay Architecture Guide

This is the active architecture guide for gameplay implementation.

The design source of truth is `doc/design/gdd.md`. This file explains how to
translate that Neverlands-inspired design into maintainable Rails code.

## Core Rule

Build gameplay as server-authoritative Rails workflows backed by explicit DB
state. The browser can display, animate, and submit choices, but it must not
invent available movement, NPC, resource, shop, combat, or building actions.

## Architecture Principles

- GDD first: when code or older docs disagree with `doc/design/gdd.md`, update
  the derived material.
- Rails for I/O: controllers, models, jobs, views, and channels handle web app
  concerns.
- POROs for rules: services and small `app/lib/game/` objects own gameplay
  rules that need isolated tests.
- DB-backed commands for player actions: action offers, movement commands,
  combat turns, gathering attempts, and shop actions should have durable server
  state when reload/persistence matters.
- Deterministic tests: inject time and RNG when a rule depends on either.
- KISS: add abstractions only when they remove real duplication or isolate a
  rule that is changing.

## Current Gameplay Layers

```text
Controllers
  validate request shape, authorize, call services, render HTML/Turbo/redirects

ActiveRecord models
  persist state, associations, validations, DB-backed state machines

app/services/game/*
  gameplay commands, orchestration, action acceptance/completion

app/lib/game/*
  formulas, stat helpers, map helpers, deterministic calculations

Views and Stimulus
  compact browser-game UI, timers, forms, local interaction feedback
```

## Neverlands-Inspired Action Model

For world/city gameplay, prefer this loop:

1. Server resolves current character state from DB.
2. Server builds short-lived action offers for the current location.
3. UI renders only those offers.
4. Player submits one offer/action key.
5. Server validates that the offer is still valid.
6. Server writes accepted/in-progress/completed state.
7. Reload resumes from DB state.
8. Completion rebuilds the next location and next offers.

This applies to:

- wilderness movement;
- city movement and gates;
- NPC interactions;
- resource gathering;
- dungeon/castle/building entry;
- shops and economy actions;
- combat entry points.

## Movement Architecture

Current Neverlands-style movement is centered on durable commands and
server-authored destinations:

- `Game::Movement::MapState` resolves current position and offered moves.
- `Game::Movement::AcceptMove` validates and accepts one offered move.
- `Game::Movement::CompleteMove` finalizes expired in-progress movement.
- `Game::Movement::TravelTime` calculates travel duration.
- `MovementCommand` stores offered, accepted, in-progress, completed, failed,
  and cancelled movement state.
- `WorldActionOffer` stores tile-local non-movement actions.

Older helpers such as pathfinding or generic movement validators may still
exist where non-current systems use them. Do not make them the player-facing
movement source of truth unless the GDD and movement feature doc are updated
first.

## Combat Architecture

Combat should remain deterministic enough to test without UI:

- formulas belong in `app/lib/game/formulas/` or similarly small pure objects;
- turn orchestration belongs in services;
- combat logs should be persisted or broadcast from accepted server results;
- player choices should be validated against current combat state;
- RNG should be injectable in specs.

Combat design details belong in `doc/design/features/combat.md` and
`doc/design/areas/arena.md`.

## Items, Economy, And Shops

Inventory, shop, and trading flows should be reachable through location/action
offers when player context matters. Global routes may exist for admin or
development, but the normal player loop should move through the world/city UI.

Use DB constraints for ownership, quantities, inventory entries, and currency
ledger integrity. Keep price/loot/profession calculations isolated in services
or formula objects.

## NPCs, Quests, And Resources

NPCs, quests, gathering nodes, and buildings should be represented as
server-resolved offers at the current tile/city node:

- action availability is calculated server-side;
- accepted actions persist enough state to survive reload where needed;
- cooldowns and timers are based on server time;
- specs should prove unavailable/stale action keys are rejected.

## Tests

Gameplay specs should focus on contracts:

- offered actions are generated from current DB state;
- stale or wrong-location action keys are rejected;
- accepted actions persist the expected state;
- reload/resume behavior is covered for timers and in-progress actions;
- completion produces the next location/state/actions.

Use service specs for rule logic, request specs for controller contracts, and
system specs for the player-facing browser loop.

## Feature Workflow

1. Read `doc/design/gdd.md`.
2. Read the relevant `doc/design/features/*` and `doc/design/areas/*` docs.
3. Check `doc/design/neverlands_parity_matrix.md` for known parity gaps.
4. Implement the smallest Rails-way change that satisfies the current feature.
5. Add focused specs.
6. Update the relevant feature/area doc's `Related Implementation Files` if
   files moved or new implementation files were added.
7. Delete obsolete planning notes, or fold valid Neverlands-aligned content into
   the relevant GDD, feature, area, or engineering doc.

# Stat & Skill Allocation System

## Version History
- **v1.0** (2025-12-11): Initial implementation - +/- allocation UI
- **v2.0** (2025-12-28): Enhanced skill system with tiered progression and dual pools

## Overview

A client-side allocation system for character stats and passive skills. Players use +/- buttons to distribute stat points and skill points, with real-time UI updates before saving to the server.

## GDD Reference
- Section: `doc/gdd.md` (Character Progression)
- Feature spec: `doc/features/neverlands_inspired.md` (Stat/Skill Allocation)
- Related flow: `doc/flow/16_passive_skills.md`

## Implementation Notes

### Design Decisions
1. **Client-side allocation first**: Changes are tracked in JavaScript before server submission
2. **Familiar +/- button interface**: Visual feedback with pending change indicators
3. **Separate pages for stats and skills**: Keeps UI focused and maintainable
4. **Turbo Stream responses**: Real-time updates without full page reloads
5. **Dual skill pools**: Combat and peace skill points are tracked separately

### Stat Allocation
- **Stats**: Strength, Dexterity, Intelligence, Constitution, Agility, Luck
- Points come from `stat_points_available` on Character
- Allocated values stored in `allocated_stats` JSONB column
- Total = base (from class) + allocated

### Passive Skill Allocation
- Skills defined in `Game::Skills::PassiveSkillRegistry`
- Each skill can be leveled 0-100
- **Dual pools**: `combat_skill_points` and `peace_skill_points`
- Levels stored in `passive_skills` JSONB column
- **Tiered progression**: Higher levels require more spends per point
- Effects calculated by `Game::Skills::PassiveSkillCalculator`

### Skill Categories and Pools

| Category | Skills | Pool |
|----------|--------|------|
| Combat | Melee Combat, Ranged Combat, Unarmed Combat, Critical Strikes, Evasion, Block Mastery | Combat |
| Magic | Elemental Magic, Healing Arts, Arcane Power, Spell Mastery | Combat |
| Resistance | Fire/Cold/Lightning Resistance, Physical Fortitude | Combat |
| Survival | Wanderer, Endurance, Perception, Luck | Combat |
| Peace | Herbalism, Mining, Fishing, Blacksmithing, Alchemy, Cooking, First Aid, Trading, Animal Handling | Peace |

### Tiered Progression

Skills use tiered progression where points per spend decrease at higher levels:

| Tier | Levels | Example Rate |
|------|--------|--------------|
| 0 | 0-24 | +10 per spend |
| 1 | 25-49 | +8 per spend |
| 2 | 50-74 | +6 per spend |
| 3 | 75-99 | +4 per spend |

### UI Features
- Real-time point counter updates
- Visual feedback for pending changes (+X indicator)
- Points-per-spend preview based on current tier
- Effect preview (e.g., "Movement: 9.3s (-7%)")
- Reset button to undo pending changes
- Save button disabled until changes made
- Shake animation for invalid actions

## Hotwire Integration

### Turbo Frames
- `stat-allocation`: Wraps the stat allocation form
- `skill-allocation`: Wraps the skill allocation form

### Turbo Streams
- On save: Replace allocation panel + update flash message

### Stimulus Controllers
- `stat_allocation_controller.js`: Handles stat +/- buttons
- `skill_allocation_controller.js`: Handles skill +/- buttons with tiered progression

## Game Engine Classes
- `Game::Formulas::SkillProgressionFormula` - Tiered progression calculation
- `Game::Skills::PassiveSkillRegistry` - Skill definitions and metadata
- `Game::Skills::PassiveSkillCalculator` - Effect calculations

## Routes

```ruby
resources :characters, only: [] do
  member do
    get :stats
    patch :stats, action: :update_stats
    get :skills
    patch :skills, action: :update_skills
  end
end
```

## Responsible for Implementation Files

### Controllers
- `app/controllers/characters_controller.rb` - Stat/skill allocation actions

### Views
- `app/views/characters/stats.html.erb` - Stats page
- `app/views/characters/_stat_allocation.html.erb` - Stats form partial
- `app/views/characters/skills.html.erb` - Skills page
- `app/views/characters/_skill_allocation.html.erb` - Skills form partial

### JavaScript
- `app/javascript/controllers/stat_allocation_controller.js`
- `app/javascript/controllers/skill_allocation_controller.js`

### Game Engine
- `app/lib/game/formulas/skill_progression_formula.rb`
- `app/lib/game/skills/passive_skill_registry.rb`
- `app/lib/game/skills/passive_skill_calculator.rb`

### Styles
- `app/assets/stylesheets/application.css` (nl-allocation-* classes)

### Specs
- `spec/requests/characters_spec.rb` - Request specs for allocation actions
- `spec/system/skill_allocation_spec.rb` - System specs for UI behavior
- `spec/lib/game/formulas/skill_progression_formula_spec.rb`
- `spec/lib/game/skills/passive_skill_registry_spec.rb`

## Usage Examples

### Accessing Stats Page
```
GET /characters/:id/stats
```

### Allocating Stats
```ruby
# Via form submission
PATCH /characters/:id/stats
params: {
  allocated_stats: {
    strength: 3,
    dexterity: 2
  }
}
```

### Accessing Skills Page
```
GET /characters/:id/skills
```

### Allocating Skills (with tiered progression)
```ruby
# Via form submission
# Note: allocated_skills values represent "spends", not final levels
PATCH /characters/:id/skills
params: {
  allocated_skills: {
    wanderer: 1,      # 1 spend = +10 at tier 0
    melee_combat: 2   # 2 spends = +10, +10 = 20 total
  }
}
```

## JavaScript Controller Usage

### Stat Allocation Controller

```html
<div data-controller="stat-allocation"
     data-stat-allocation-free-value="10"
     data-stat-allocation-stats-value='{"strength":15,"dexterity":12}'
     data-stat-allocation-added-value="{}">

  <button data-action="click->stat-allocation#addStat"
          data-stat-allocation-stat-param="strength">+</button>

  <button data-action="click->stat-allocation#removeStat"
          data-stat-allocation-stat-param="strength">−</button>
</div>
```

### Skill Allocation Controller

```html
<div data-controller="skill-allocation"
     data-skill-allocation-combat-free-value="10"
     data-skill-allocation-peace-free-value="5"
     data-skill-allocation-skills-value='{"wanderer":50}'
     data-skill-allocation-rates-value='{"wanderer":"10:8:6:4"}'
     data-skill-allocation-pools-value='{"wanderer":"combat"}'
     data-skill-allocation-spends-value="{}">

  <button data-action="click->skill-allocation#addSkill"
          data-skill-allocation-skill-param="wanderer"
          data-skill-allocation-pool-param="combat"
          data-skill-allocation-rate-param="10:8:6:4">+</button>

  <button data-action="click->skill-allocation#removeSkill"
          data-skill-allocation-skill-param="wanderer"
          data-skill-allocation-pool-param="combat"
          data-skill-allocation-rate-param="10:8:6:4">−</button>
</div>
```

## Skill Effects in Combat

Combat skills directly affect battle mechanics:

| Skill | Effect |
|-------|--------|
| Melee Combat | +0.5% damage per level |
| Critical Strikes | +0.15% crit chance per level |
| Evasion | +0.2% dodge per level |
| Block Mastery | +0.4% block per level |
| Fire/Cold/Lightning Resistance | +0.4% resist per level |
| Physical Fortitude | +0.25% phys resist per level |
| Endurance | +0.5% max HP per level |

## Skill Effects in Non-Combat

Peace skills affect non-combat activities:

| Skill | Effect |
|-------|--------|
| Wanderer | -0.7% movement cooldown per level |
| Herbalism/Mining/Fishing | +1% yield per level |
| Trading | +0.2% better prices per level |
| Alchemy | +0.5% potion effectiveness per level |
| Cooking | +1% buff duration per level |

---

*Last updated: December 2025 (v2.0 - Tiered progression and dual pools)*

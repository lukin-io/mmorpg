# Stat & Skill Allocation System

## Version History
- **v1.0** (2025-12-11): Initial implementation - Neverlands-inspired +/- allocation UI

## Overview

A client-side allocation system for character stats and passive skills, inspired by Neverlands MMORPG. Players use +/- buttons to distribute stat points and skill points, with real-time UI updates before saving to the server.

## GDD Reference
- Section: `doc/gdd.md` (Character Progression)
- Feature spec: `doc/features/neverlands_inspired.md` (Stat/Skill Allocation)

## Implementation Notes

### Design Decisions
1. **Client-side allocation first**: Changes are tracked in JavaScript before server submission
2. **Neverlands-style UI**: Familiar +/- button interface with visual feedback
3. **Separate pages for stats and skills**: Keeps UI focused and maintainable
4. **Turbo Stream responses**: Real-time updates without full page reloads

### Stat Allocation
- Stats: Strength, Dexterity, Intelligence, Constitution, Agility, Luck
- Points come from `stat_points_available` on Character
- Allocated values stored in `allocated_stats` JSONB column
- Total = base (from class) + allocated

### Passive Skill Allocation
- Skills defined in `Game::Skills::PassiveSkillRegistry`
- Each skill can be leveled 0-100
- Points come from `skill_points_available` on Character
- Levels stored in `passive_skills` JSONB column
- Effects calculated by `Game::Skills::PassiveSkillCalculator`

### UI Features
- Real-time point counter updates
- Visual feedback for pending changes (+X in green)
- Reset button to undo pending changes
- Save button disabled until changes made
- Shake animation for invalid actions

## Hotwire Integration

### Turbo Frames
- `stat-allocation`: Wraps the stat allocation form
- `skill-allocation`: Wraps the skill allocation form

### Turbo Streams
- On save: Replace allocation panel + update flash

### Stimulus Controllers
- `stat_allocation_controller.js`: Handles stat +/- buttons
- `skill_allocation_controller.js`: Handles skill +/- buttons

## Game Engine Classes
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

### Styles
- `app/assets/stylesheets/application.css` (nl-allocation-* classes)

### Specs
- `spec/requests/characters_spec.rb`

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

### Allocating Skills
```ruby
# Via form submission
PATCH /characters/:id/skills
params: {
  allocated_skills: {
    wanderer: 10
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
     data-skill-allocation-free-value="5"
     data-skill-allocation-skills-value='{"wanderer":50}'
     data-skill-allocation-added-value="{}">

  <button data-action="click->skill-allocation#addSkill"
          data-skill-allocation-skill-param="wanderer">+</button>

  <button data-action="click->skill-allocation#removeSkill"
          data-skill-allocation-skill-param="wanderer">−</button>
</div>
```


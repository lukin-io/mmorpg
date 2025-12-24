# Onboarding Loop (Devise → World Entry)

## Overview
The onboarding loop is the shortest path from account creation/sign-in to entering `/world`.

- Devise handles sign-up and sign-in.
- `/world` bootstraps an active character context.
- If the active character has no `CharacterPosition`, `/world` auto-creates a starter position.

## Current Behavior
1. Player signs up (`/users/sign_up`) or signs in (`/users/sign_in`).
2. On success, the app redirects to `/world` (also the app `root`).
3. `WorldController` selects the first character (`current_user.characters.order(:created_at).first`).
4. If `character.position` is missing, `WorldController#ensure_character_position!` creates a starter `CharacterPosition` in the first available city zone (fallback: first `Zone`) using the zone’s default spawn point.

## Routes
- Devise: `/users/sign_in`, `/users/sign_up`
- World entry: `GET /world` (and `root "world#show"`)
- Dashboard fallback: `GET /dashboard` (used when onboarding cannot place the player into a zone)

## Success / Failure / Edge / Auth Cases
### Success cases
- Valid credentials sign in and render the world UI.
- A character with no position is booted by creating a starter position.

### Failure cases
- Invalid credentials show Devise validation errors.
- Unconfirmed users are blocked by Devise Confirmable.

### Null/edge cases
- No zones exist: `/world` redirects to `/dashboard` with an alert.
- User has no characters: `/world` raises a Pundit authorization error and redirects via `ApplicationController#user_not_authorized`.

### Authorization cases
- Unauthenticated users visiting `/world` are redirected to `/users/sign_in`.

## Responsible for Implementation Files
- `app/controllers/application_controller.rb`
- `app/controllers/concerns/current_character_context.rb`
- `app/controllers/world_controller.rb`
- `app/models/user.rb` (character selection helper)
- `app/models/character_position.rb`, `app/models/zone.rb`, `app/models/spawn_point.rb`
- `config/routes.rb`

## Testing
- System spec: `spec/system/onboarding_spec.rb`

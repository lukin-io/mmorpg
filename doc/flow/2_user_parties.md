# 2. Social Systems — Parties Flow

## Overview
Parties are lightweight, Hotwire-first groups used for short session loops (dungeon prep, arena queues, coordinated world play).

- Leaders create parties with a name/purpose/max size.
- Leaders invite other players; invitees accept from the parties index.
- Leaders can start a ready check; members respond with **Ready / Not Ready**.
- Each party provisions a `ChatChannel` of type `party` for coordination (membership is enforced via `ChatChannelMembership`).

## Implementation Status

| Component | Status | Details |
|-----------|--------|---------|
| Party lifecycle (create/show/leave/disband) | ✅ Implemented | `app/controllers/parties_controller.rb`, `app/models/party.rb` |
| Invitations (send/accept/decline) | ✅ Implemented | `app/controllers/party_invitations_controller.rb`, `app/models/party_invitation.rb` |
| Membership management (kick/promote/ready state) | ✅ Implemented | `app/controllers/party_memberships_controller.rb`, `app/models/party_membership.rb` |
| Ready check orchestration | ✅ Implemented | `app/services/parties/ready_check.rb` |
| Party chat channel provisioning | ✅ Implemented | `Party#ensure_chat_channel!` creates `ChatChannel(channel_type: :party)` and ensures leader membership |

## Core Data Model

### `Party`
- `leader_id` (User)
- `status` enum (forming/queued/in_instance/completed/disbanded)
- `ready_check_state` enum (idle/running/resolved)
- `max_size` (2–10)
- `chat_channel_id` (optional)

### `PartyMembership`
- `user_id`, `party_id`
- `role` enum (member/leader/tank/healer/damage)
- `status` enum (active/benched/left)
- `ready_state` enum (`unknown`/`ready`/`not_ready`)

### `PartyInvitation`
- `sender_id`, `recipient_id`, `party_id`
- `status` enum (pending/accepted/declined/expired)
- `token`, `expires_at`

## UI & Routes

### Party Finder / Party Detail
- `GET /parties` → `PartiesController#index`
- `POST /parties` → `PartiesController#create`
- `GET /parties/:id` → `PartiesController#show`
- `POST /parties/:id/leave` → `PartiesController#leave`
- `POST /parties/:id/promote` → `PartiesController#promote` (leader-only)
- `POST /parties/:id/disband` → `PartiesController#disband` (leader-only)

### Invitations
- `POST /parties/:party_id/party_invitations` → `PartyInvitationsController#create` (leader-only)
- `PATCH /party_invitations/:id?decision=accept|decline` → `PartyInvitationsController#update`

### Membership + Ready States
- `PATCH /parties/:party_id/party_memberships/:id?ready_state=ready|not_ready` → `PartyMembershipsController#update`
- `DELETE /parties/:party_id/party_memberships/:id` → `PartyMembershipsController#destroy` (leader-only kick)

## Ready Check Flow

### Start Ready Check (Leader)
1. Leader clicks **Start Ready Check** on the party page.
2. `POST /parties/:id/ready_check` → `PartiesController#ready_check`
3. `Parties::ReadyCheck#start!`:
   - sets `party.ready_check_state = :running`
   - resets all active `party_memberships.ready_state` to `:unknown`
4. UI shows the ready-check panel and per-member status indicators.

### Respond to Ready Check (Member)
1. Member clicks **I'm Ready!** or **Not Ready** while their `ready_state` is `unknown`.
2. `PATCH /parties/:party_id/party_memberships/:id?ready_state=ready|not_ready` → `PartyMembershipsController#update`
3. `Parties::ReadyCheck#mark_ready!` updates the membership state and calls `resolve_if_complete!`.

### Resolve Ready Check (Automatic)
- `Parties::ReadyCheck#resolve_if_complete!` marks the party `ready_check_state = :resolved` once no active membership remains `:unknown`.
- The UI hides the ready-check panel after resolution.

## Authorization Rules (Pundit + Controller Guards)
- `PartiesController#ready_check/#promote/#disband`: leader-only.
- `PartyMembershipsController#update`: the membership owner can update their own ready state; the leader can also update any membership.
- Invitations: only leaders can send invitations; only the recipient can accept/decline.

## Testing
- System coverage: `spec/system/economy_group_loops_spec.rb` exercises party create → invite → accept → ready check.

## Responsible for Implementation Files
- **Models:** `app/models/party.rb`, `app/models/party_membership.rb`, `app/models/party_invitation.rb`
- **Services:** `app/services/parties/ready_check.rb`
- **Controllers:** `app/controllers/parties_controller.rb`, `app/controllers/party_invitations_controller.rb`, `app/controllers/party_memberships_controller.rb`
- **Views:** `app/views/parties/index.html.erb`, `app/views/parties/show.html.erb`, `app/views/parties/_member.html.erb`
- **Routes:** `config/routes.rb` (party resources + ready_check/leave/promote/disband)


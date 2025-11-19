# 5. Moderation, Safety, and Live Ops

## Goals & Principles
- Preserve nostalgic community vibe while protecting players from abuse, spam, and exploits.
- Empower GMs/moderators with Hotwire-admin tools to act quickly without full redeploys.
- Provide transparent player-facing processes for reports, penalties, and appeals.

## Reporting & Ticket Flow
- In-game report UI accessible from chat, player profiles, combat logs, and NPC magistrates (per GDD).
- Categories: chat abuse, botting, griefing, exploit/cheating, inappropriate names, payment disputes.
- Reports generate tickets stored in Postgres with evidence (log excerpts, screenshots, combat replay IDs).
- Action Cable updates notify moderators of new tickets; status changes reflected in player inbox.

## Enforcement Toolkit
- Role-based admin panel (Pundit policies) letting moderators issue warnings, temp/perma bans, mutes, trade locks.
- Trauma/healing exploits flagged automatically by detectors; suspicious accounts queued for review.
- Premium refunds and quest adjustments logged for audit, surfaced in account history (ties into `1_auth.md`).

## Live Ops & Events Oversight
- GM commands to spawn NPCs, trigger seasonal events, seed rewards, or pause arenas when exploits detected.
- Scheduled jobs monitor arena tournaments, clan wars; ability to rollback standings if cheating confirmed.

## Transparency & Player Communication
- Penalty notifications delivered via in-game mail and email, including reason and duration.
- Appeal workflow with SLA targets; moderators can re-open tickets and attach follow-up notes.
- Public-facing policy docs linked from `/doc/features/5_moderation.md` summary for future knowledge base export.

## Instrumentation & Alerting
- Structured logs for moderation actions shipped to ELK/Datadog; anomaly alerts for surge in reports per zone.
- Dashboard widgets for report volume, resolution time, repeat offenders.
- Integrate with Discord/Telegram webhooks for urgent escalations (e.g., dupe exploit outbreak).

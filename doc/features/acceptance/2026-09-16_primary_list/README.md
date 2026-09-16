# September 16 primary-list local acceptance

Owners: [Character Progression](../../character_progression.md),
[Arena Combat](../../arena_combat.md), [Inventory](../../player_inventory.md).
[Source observations](../../../design/reference/character/observations/2026-09-16_primary_list_audit.md)
are distinct from these local checks.

## Automated verification

- Focused request/model/combat/scroll regression run:160 examples,0 failures.
- Skills/Perks system run:30 examples,0 failures.
- Corrected existing request contracts:36 examples,0 failures. The first full
  attempt had4 stale expectations: legacy-fight Inventory access and three
  combined-skill-display assertions. They now assert the intended behavior.
- `bin/verify full`:3,118 non-system and303 system examples,0 failures;
  627 Ruby files,0 offenses; Brakeman0 warnings; dependency/importmap and both
  documentation audits passed.
- Final public-profile form change and the three previously failing CI paths:
  14 request/system examples,0 failures;5 changed Ruby/spec files lint-clean.
  These checks ran after the full profile and before final manual acceptance.
- Final evidence/document updates: documentation audits and `git diff --check`
  passed. Existing Rack status-name deprecation warnings remain warnings.

## Agent-performed browser acceptance

Browser: active Chrome, localhost development, isolated `Artwork0916` and
`PrimaryOpponent0916` fixtures. Desktop1150×819, actual narrow390×844, and native
Chrome200% zoom (confirmed by Chrome UI; CSS viewport517×426). Temporary
viewport overrides and zoom were reset afterward. A preliminary1366-width
emulation had a cropped capture; the retained desktop captures use1150.
No production or source-account data was modified by local acceptance.

1. **Skills:** Inventory → Wear the fixture Penknife → Your character → Skills.
   Learned Knife98 and red+30 were separate; Doctor displayed0601 and+10.
   Keyboard Enter on Add Knife previewed100; Reset restored98. A second add and
   Save spent exactly one combat point. Reload → reopen Skills retained100,
   +30, one free point and MAX. Fifteen profession rows remained read-only.
2. **Perks:** all42 rows/six categories appeared;38 were Unavailable. Keyboard
   add/reset/add/Save acquired More Strength. Reload → reopen Perks retained
   bold Yes. At390px, keyboard focus reached controls without page overflow.
   Later saving Careful Fighter exhausted the pool:42 rows remained and no
   perk-allocation buttons were present.
3. **Narrow Skills:** at390px, keyboard Add Self-Healing previewed002; Reset
   cleared it. The page scroll width was390. Scrolling reached both categories
   and controls; no page-level horizontal overflow was observed.
4. **Equipment:** Remove Penknife → Skills removed red+30/+10 while learned
   Knife100/Doctor601 remained. Inventory Wear restored the bonuses. These
   were UI mutations, not database substitutions for the tested actions.
5. **Fight reservation/waiting:** a bounded two-player development match64 was
   prepared as fixture state (not a test of Arena admission). Clicking Inventory
   entered the reserved fight. Head Simple32 plus Head Block35 submitted one
   67-AP package through Turn. The waiting view survived reload at390px and
   retained living names, timer and Surrender. Native200% zoom kept the waiting
   text, log and keyboard-reachable controls accessible after scrolling.
6. **Expiry:** the fixture knife had a45-second server deadline. After expiry,
   public profile AP preview changed32→45 and Armor Pierce1→0; the owned item
   remained visible. Read-only server inspection confirmed `expired=true`,
   `equipped=true`, HP100 unchanged, saved fight seed32/AP100 and pending67AP
   unchanged. This is local expiry proof, not live Neverlands expiry evidence.
7. **Profile/navigation:** clicking the header name during the fight opened
   its readable profile and in-combat log link, without a stat form despite
   available points. Clicking Skills returned the reserved fight. Public log
   → Statistics showed both participants and zone totals.
8. **Aftermath:** Surrender and its native confirmation completed the match;
   no resolved damage meant0XP. Finish Fight returned to Trial Hall. The
   character's stat form was available again. Inventory Remove retained the
   expired item with “Item has expired” and no Wear action. No healing or item
   deletion was attributed to expiry; ordinary post-fight regeneration was
   visible separately after surrender.

Artifacts: [desktop Skills](skills-desktop.png),
[desktop Perks](perks-desktop.png), [narrow Skills](skills-mobile.png),
[narrow Perks](perks-mobile.png), [narrow waiting](waiting-mobile.png),
[200% waiting](waiting-zoom200.png).

The synthetic opponent did not submit a turn; this pass proves waiting,
reservation, expiry, surrender/Finish and navigation, not another source PvP
fight or live Group assembly. Wider automated team coverage remains in the
303-example system suite. Unsupported skills/perks and Workshop/Doctor-growth
flows are not promoted by these checks.

## Checkpoint CI history

Checkpoint `9a1672d` was pushed before this follow-up. Its
[CI run35113678768](https://github.com/lukin-io/mmorpg/actions/runs/35113678768)
passed lint, security, non-system and documentation jobs, but failed3 of303
system examples: profile→fight-log navigation, Shop category→scroll row and
World village movement. This failure remains historical evidence. The follow-up
adds bounded navigation waits/category readiness and waits for World viewport
negotiation before movement. Original end-state assertions remain. The focused
recheck passed; fresh pushed-commit CI is a separate publication check.

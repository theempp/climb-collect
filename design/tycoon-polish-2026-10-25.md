# Tycoon testing and polish — October 25, 2026

Scope: continue approved Q1–Q11 on `codex/tycoon-redesign`, starting clean at `0751c9b`. No merge, push, publication, live DataStore access, original-world edits, or other checkout source edits.

## Changes and decisions

Habitat corner posts and back rails give the active modules a visible frame. Storage tracks show empty/partial/full inventory; full adds an amber bar and FULL text. Processor/sorter/collector arches show installed progression. A bank plinth and deposit slot clarify the destination. All parts remain anchored/noncolliding; the empty dressed plot is 101 parts within the approved 110x120 footprint. This is a restrained readability pass using existing materials and kingdom palette colors, not a claim of final premium art acceptance.

Plot clear now hides storage indicators, resets conveyor automation/ownership, and hides installed machine details before a replacement owner arrives. Upgrade cards explain next-level benefits and have room for prerequisites. Onboarding calls out both starter habitats and full-storage pauses. No economy values, profile schemas, assets, combat rules, outer plots or six kingdoms changed.

Ruling: retain provisional costs/rates. Production-rule simulation provides an initial baseline, not player acceptance. Two matched starter Commons generate 132 eggs/hour before tenth-egg value. With immediate collection/banking and no purchases, saving 20 coins takes 9.10 minutes, 25 takes 10.92, 40 takes 17.28, 50 takes 20.92, and 100 takes 41.83. These are separate save targets, not sequential purchases. Mountain rewards, training spending, travel/input time and creature acquisition are excluded.

Eight-hour earnings with both starters and repeated bag-emptying at each visit: 5/15-minute visits 1,160 coins; 30-minute visits 1,056; hourly visits 528. Initial 30-egg habitat storage fills in about 27.3 minutes at 66 eggs/hour. Storage therefore matters during expeditions. One level-zero matched producer with continuous banking earns Common69 / Uncommon82 / Rare206 / Epic248 / Mythic453 / Legendary716 coins in one hour. Eight max-upgraded mixed-kingdom Legendary producers earn 12,819/hour in the fixture. The late-game ratio and first-upgrade wait need human pacing feedback; no blanket balance approval.

## Fresh verification

- 1,310 CLI checks pass: previous 1,181 plus four upgrade-benefit checks and 125 economy/stress checks. Upgrade helper test failed before implementation and passes afterward.
- All 89 mountain Luau files compile; Rojo 7.6.1 builds the source package.
- Eight independent pure-rule profiles run 28,800 sequential ticks in approximately 0.24 seconds on this host. Foreign-creature assignment, replayed timestamp, full storage, offline no-autobank, and next-day stored-egg retention pass. This is neither eight clients nor network/rendering throughput.
- Fresh saved Review04 opened in Studio (PlaceId0); 50 isolated memory persistence/combat checks pass. Studio uses memory profiles. No hosted persistence claim.
- Studio visual fixture: 213 checks pass for empty/half/full gauges, FULL text, installed machines, clearing, replacement owner, noncollision and footprint bounds. Fixture models are destroyed afterward; it never uses real profile sessions. Evidence includes runnable `world-fixture.luau` and raw result. Initial fixture failure was strict floating-point equality: engine stored .9 as .899999976; changed assertion tolerance only.
- iPhone7 landscape 666x374: all six tabs have zero checked overflowing description labels or buttons smaller than44x44. Screenshots inspected for upgrade layout and habitat frames. Runtime-created desktop pool remains24 when switching devices after startup; a phone-start check is recorded separately.
- Independent code reviewer found no important regressions. Suggested asserting stress setup transitions and testing visual clear/reassignment; both incorporated. No extra reviewer pass required.
- Review04 package: 30 runtime sources match disk; all protected service-tree hashes (including Workspace/terrain and ServerStorage) match the baked integration baseline. SHA256 `280e55bc8fd355ec20354a4a88f5ed432e886bddde5d80e199ddcf6a09d9b971`.

Playable artifact: `C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/outputs/ClimbCollect.Tycoon.Review04.rbxlx`.

Evidence: `evidence/tycoon_2026-10-25/`. Commands: all `mountain/tests/*.luau`, `python mountain/tests/run_ui_server.py`, `luau-compile --null` over mountain sources; `mountain/tools/package_hud.py` with Review06 baseline and new output. Source package is not a standalone playable world.

## Remaining acceptance and graph scope

Eight simultaneous real clients, actual leave/rejoin with hosted saves, cross-server/budget failure behavior, low-end physical mobile performance, human progression timing and premium visual approval remain open. The connector exposes solo Play start/stop; this run did not establish an eight-client session. Review04 is an unpublished PlaceId0 memory build; no live production-data test was attempted. Existing abrupt-crash unsaved-window and respawn-during-save-outage limitations remain.

Desktop graph was CURRENT at entry; it excludes this isolated feature source. Query results referenced historical economy and integration notes; current source and approved tycoon contract were used instead. QUALITY_REPORT flagged a historical status heading, not a tycoon code finding. The new vault pointer records this scope; final refresh status is recorded with handoff evidence. No retrieval implementation changed, so benchmark rerun is unnecessary.

Final runtime checks: eight isolated memory profiles passed80 save/release/rejoin/offline/contended-session checks; these are sequential fixtures, not actual players or hosted DataStore. A fresh iPhone7 landscape Play start had TouchEnabled=true and12 pooled visual eggs; all six tabs again passed checked text/button bounds. Natural client assignments produced2 eggs, collected and banked for2 coins; earlier empty-bag attempts were correctly rejected. A repeated banking request returned its cached acknowledgement (the recorded result is not an independent final balance audit). Console contained only the normal startup message. Play stopped and device simulation restored to default. Raw results: natural-loop.json, phone-start.json, persistence-fixture-result.json.

Final graph refresh: CURRENT, zero project/vault input drift;3,418 merged nodes/6,058 edges. Refresh made verified backup C:/Users/HOME!/Documents/vault-backup-graphify-2026-10-25-002158.zip and versioned export2026-10-25-002158. Its automatic retrieval benchmark remained recall@8=1.0, MRR=.75. Coverage still excludes isolated feature source. Pre-append copies of the two handwritten notes are in Documents/ClimbCollect-Recovery/tycoon-vault-2026-10-25. No DRS Rush notes edited.

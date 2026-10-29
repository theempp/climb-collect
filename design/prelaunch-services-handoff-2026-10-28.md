# Prelaunch services handoff (2026-10-28)

Branch `codex/prelaunch-services` from `codex/homebase-c` 04b444a (merged home base + Glassbloom P7). New standalone modules only; no existing file edited, nothing requires them yet, no Studio/place change.

- `mountain/shared/Analytics.luau`: AnalyticsService wrapper; enum-only events/fields (unknown text -> `other`), verified signatures, pcall, 80% of 120+20xCCU/min budget, counter aggregation + flush.
- `mountain/shared/LiveConfig.luau`: flags/tunables schema, whole-config validation (type, range, preset banner keys), versioned, last-good on failure, change listeners, client-safe view. Fetch is injected (DataStore key + MessagingService nudge wiring still to do).
- `mountain/shared/Sfx.luau`: cue tokens (all ids 0 until sourced), groups, cooldowns, 24/12(LOW) concurrency caps, haptics gated by phone + toggle + Reduce effects, rare/ladder sting pickers.
- Test: `mountain/tests/prelaunch_services.luau` (87 checks). Full run 44/44 suites.

Next (needs owner approval, touches files other chats own): server bootstrap that builds LiveConfig from a DataStore key + 60 s poll; hook Analytics into Bank/Inventory/Progression/Shop; SoundGroups + Settings toggles; Open Cloud owner script.

## Server hooks (owner-approved 2026-10-28)
- `mountain/server/LiveOps.luau`: singleton. LiveConfig from DataStore `CC_LiveConfig`/`config` (`{version, values}`), refresh on start, every 60 s and on MessagingService topic `CC_LiveConfig`; PlaceId 0 uses code defaults and never touches DataStores. Public flags mirrored to `ReplicatedStorage.LiveFlags` attributes. Analytics flushed each poll.
- `Main.server.luau`: session_start (after safe load), session_end, area_enter (sanctuary, arrivals, summit), egg_banked (securing), egg_lost (died/fall, only while carrying), fall, summit coins as economy source. Fall-site hooks are `if LiveOps then` guarded because test harnesses splice that block.
- `UIRequests.luau`: hatch (rarity context), production bank coins as economy source. Loaded only when `typeof(script)=='Instance'`.
- Bank/Inventory/Progression from the old `src/core` are not in the live mountain build; the equivalents above were hooked instead.
- Not yet: flags do not gate anything (kill switches need Shop/UIRequests decisions); egg_lost from bats/Guardians; onboarding funnel steps; Open Cloud owner script; Studio play check (`AnalyticsService` calls, `LiveFlags` folder). Unverified in Studio.

## Owner script (2026-10-28)
`tools/liveconfig.py` (show / set / unset / revert / log). Env `ROBLOX_API_KEY` (DataStore read+write; MessagingService publish only for `--nudge`) and `ROBLOX_UNIVERSE_ID`, never printed. Schema parsed from `LiveConfig.luau`, so refusals match the game. Writes need `--yes` (dry run otherwise); each write appends `liveops/config-log.jsonl` (version, time, user, note, old, new); revert re-applies a logged version as a new, higher version. The log is local: commit it after writes, or reverts only work on this machine. Offline test `mountain/tests/run_liveconfig_tool.py` (19 checks). Never run against Roblox yet.

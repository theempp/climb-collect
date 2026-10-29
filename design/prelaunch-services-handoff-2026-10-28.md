# Prelaunch services handoff (2026-10-28)

Branch `codex/prelaunch-services` from `codex/homebase-c` 04b444a (merged home base + Glassbloom P7). New standalone modules only; no existing file edited, nothing requires them yet, no Studio/place change.

- `mountain/shared/Analytics.luau`: AnalyticsService wrapper; enum-only events/fields (unknown text -> `other`), verified signatures, pcall, 80% of 120+20xCCU/min budget, counter aggregation + flush.
- `mountain/shared/LiveConfig.luau`: flags/tunables schema, whole-config validation (type, range, preset banner keys), versioned, last-good on failure, change listeners, client-safe view. Fetch is injected (DataStore key + MessagingService nudge wiring still to do).
- `mountain/shared/Sfx.luau`: cue tokens (all ids 0 until sourced), groups, cooldowns, 24/12(LOW) concurrency caps, haptics gated by phone + toggle + Reduce effects, rare/ladder sting pickers.
- Test: `mountain/tests/prelaunch_services.luau` (87 checks). Full run 44/44 suites.

Next (needs owner approval, touches files other chats own): server bootstrap that builds LiveConfig from a DataStore key + 60 s poll; hook Analytics into Bank/Inventory/Progression/Shop; SoundGroups + Settings toggles; Open Cloud owner script.

# Impossible Mountain implementation plan — 2026-10-24
User authority: REQUEST.txt. Native implementation, isolated place; preserve all Phase 1 work.
Baseline: e126557, original branch codex/expedition-fairground, dirty source retained in original checkout. Dedicated branch feature/six-kingdom-mountain-first-draft.

1. Define six kingdoms, 36 species, six Guardians and pure progression/egg/combat rules. Verify capacity, timestamp incubation, sequential gates, one capture, ownership, level thresholds with Luau CLI tests.
2. Generate one continuous 850-stud mountain, six routes, twelve branches, eighteen landmarks, arenas/checkpoints, ladders/ropes/moving platforms, secrets and biome decoration. Build in a new place only. Geometry and natural-avatar verification in Studio.
3. Add isolated server profile sessions using the existing Store adapter, inventory, hatching, equipment/evolution, exploration, economy and cooperative boss encounters. Validate all requests, positions and ownership; never load legacy data. Live Studio tests + pure rules tests.
4. Add responsive PC/touch HUD, team collection/incubator/travel/sanctuary panels, special/dodge controls and companion art. Check client startup and screenshots.
5. Add snapshot competition against server-generated defenses, independent from online defender presence, plus stored defense registration. Verify deterministic rewards/replay bounds. Document online matchmaking limitations.
6. Package, open, run, audit, save checkpoint, compare protected hashes, review source, record evidence and refresh project/vault.

Provisional choices: local expedition refuge stands in for the sanctuary integration; no final Phase 1 gateway coordinates assigned. New schema/data namespace. Caeloryn remaining abilities provisionally Gravity Choir, Constellation Accord, Celestial Dominion (request truncates after Astral Lance). New modular procedural art is draft art, not premium mesh completion. All timing/production readiness require playtesting; never mark acceptance on compilation alone.

Review focus: failed/contended saves cannot reset accounts; duplicates/replays cannot mint captures or eggs; client teleports cannot unlock kingdoms; teammates joining/leaving battle cannot inherit unearned rewards; malformed remote payloads cannot crash game loops.

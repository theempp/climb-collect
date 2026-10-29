# Home-base schema and rules (P2) — 2026-10-29

Code: `mountain/shared/HomeTiers.luau` (data), `mountain/shared/HomeRules.luau` (pure rules), wired in `Profiles.luau`, `Tycoon.luau`, `ExplorerRules.luau`, `UIProtocol.luau`, `UIRequests.luau`, `Main.server.luau`. Commit `88eb572`. Every number below is **PROPOSED** until STOP 3.

## `p.home` (v1)
```
p.home = { v = 1, tier = 1..4,
  decor = { ['1'..'14'] = { kind = 'creature' | 'prop', id = string<=80 } },   -- string keys (DataStore-safe sparse map)
  stock = { [propId] = 0..4 } }                                                 -- bought props not on a stand
```
- **Valid (strict, fails closed):** exactly these four keys; `v` 1..1 (a newer `v` refuses the load); tier integer 1..4; slot keys `'1'..'14'` only; decor entries exactly `{kind,id}`; stock ids <= 32 chars, counts integer 0..4. A malformed home **refuses the whole profile load and leaves the store untouched** (same rule as `tycoon`).
- **Structural only:** an unknown prop id or a stale creature id still loads. Meaning is fixed by `normalize` on load, so retuning numbers can never lock a player out.
- Absent `home` (every existing profile) is seeded: tier 1, empty decor/stock.
- Rollback: a pre-P2 build ignores `home` (its `valid` checks listed keys only). Tycoon stays version 1 with 8 entries. `trophies`/`competitionAt` stay inert.

## Tiers (owner Q1: rank level AND coins)
| Tier | Name | Rank | Fee (coins) | Habitat comfort cap | Usable decor slots | Props unlocked |
|---|---|---|---|---|---|---|
| 1 | Dry-stone Yard | 1 | 0 | 1 | 4 | boulder, bed |
| 2 | Cedar Cloister | 5 (480 XP) | 1,000 | 2 | 7 | + hedge, lantern |
| 3 | Brass & Lantern | 15 (4,480 XP) | 5,000 | 3 | 10 | + sapling |
| 4 | Azure Terrace | 30 (17,980 XP) | 15,000 | 4 | 14 | + basin |
- One tier per raise; tiers never drop. Rank = `ExplorerRules.summary(p).level` (server XP); the client sends only `{op='tier'}`.
- Comfort cap: `Tycoon.quote('habitat')` returns `ready=false`, "Raise your plot to <tier>". Comfort levels bought before P2 are kept (no strip).
- Role names per tier (`HomeTiers.roles`) are intel A1 token names; atlas confirms them in P3. No colour values here.

## Prop catalog (owner Q6: creatures AND coin props)
| id | Name | Price | Min tier | Form source |
|---|---|---|---|---|
| boulder | Weathered boulder | 150 | 1 | `HomeProtos.Boulder` |
| bed | Alpine planting bed | 300 | 1 | `HomeProtos.PlantingBed` |
| hedge | Hedge planter | 500 | 2 | `HomeProtos.Divider_01` (trimmed) |
| lantern | Cedar lantern | 800 | 2 | `HomeProtos.Lantern` |
| sapling | Pine sapling | 1,200 | 3 | `HomeProtos.Tree` (scaled to a 3x3 stand) |
| basin | Azure basin | 2,500 | 4 | channel water (Azure `CAT:4`); form needs atlas (P3/P4) |
- Coins only; no Robux, no products. Placing a prop uses one from `stock`, else buys it at its price (tier + coins checked before any debit).
- Clear: a prop returns to `stock` (never sold, never lost; at most 4 per kind, a full stock keeps it placed). A creature simply leaves the stand.

## Decor rules
- Slot 1..14, must be <= usable for the tier, must be empty (clear first: replay-safe).
- Creature: owned, not in a habitat, shown once. `Tycoon.assign` refuses a displayed creature (one creature, one place).
- Robux-origin creatures may be displayed (looks only, earn nothing).

## Secure XP by rarity (replaces `10 x section`)
Common 6 · Uncommon 12 · Rare 30 · Epic 70 · Mythic 150 · Legendary 0 (never an egg; Trials keep their derived 150k). Unchanged: first carrier only (stolen = 0), 20 secures/day, +50 new ledger species, Robux origin 0. Daily max 20 x 150 = 3,000 XP (all Mythic; the plan's "1,400" assumed Epic). Stored `explorer.repeatXp` shape unchanged: no XP migration.

## Habitats capped at 6 (owner Q10) — load migration table
`TycoonConfig.habitats.costs` = {50,120,250,450} (modules 7-8 at 750/1,200 removed). Stored array stays 8 entries; `T.snapshot` shows 6.

| Saved state | On load (same write) |
|---|---|
| no `home` | seeded tier 1 |
| slots <= 6 | unchanged |
| slots 7 | +750 module, + comfort coins spent on habitat 7, + its stored egg value (no banking bonus); creature unassigned (kept); entry reset (attunement kept); slots = 6 |
| slots 8 | as 7, plus +1,200 and habitat 8's comfort + eggs (max: 1,950 + 2 x 800 + egg value) |
| decor creature not owned / in a habitat / duplicate | slot cleared (lowest slot keeps a duplicate) |
| unknown prop id in decor/stock | kept, inert |
| malformed or newer `home` | **load refused, store untouched** |
Idempotent: a replayed UpdateAsync or a later load pays nothing more. Coins clamp at 2^53-1. **Open:** the player is not told about the refund yet (one-time notice belongs in P6).

## Wire actions
| Action | Payload (strict: no extra fields) | Server gates | Reply |
|---|---|---|---|
| `Home` | `{op='tier'}` | safe, own plot, nothing saving, no run; rank AND coins | durable before reply (`P.transact`), then `publish` (`ui.home`) |
| `Home` | `{op='place',slot=1..14,kind='creature'\|'prop',id}` | as above + slot/ownership/tier/coins | `{home=snapshot}` |
| `Home` | `{op='clear',slot=1..14}` | as above | `{home=snapshot}` |
| `Inspect` | `{plot=1..8,kind='habitat'(1..6)\|'decor'(1..14),index}` | in sanctuary, 0.5 s per player | `{inspect={kind,species,name,rarity,level,owner}}` or prop `{kind,name}`; never ids, coins or inventory |
Refusals return a message and change nothing. `s.ui.home` = `{tier,name,habitatCap,usable,slots,decor[1..14]|false,stock,next={tier,name,rank,fee,level,ready,reason}}`.

## Tests (all pass, 42/42 suites)
New: `home_rules` 91, `home_profile` 15. Extended: `explorer_rules` 115 (was 111), `egg_raids` 36, `tycoon` 71, `tycoon_economy` 109, `ui_protocol` 126 (95), `ui_server` 87 (66), `run_persistence` 73 (61). Mutation check `tools/mutate_home.py`: 30/30 gates killed (`evidence/homebase_2026-10-29/p2/mutation.json`).

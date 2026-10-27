# Phone candidate prep — October 26, 2026 (Stage 4)

Nothing published, uploaded, granted or spent. Stop point: owner approval in chat before any upload or publish.

## File

`outputs/ClimbCollect.PhoneCandidate01.rbxl`, SHA256 `a59a1d1d0ee617f950bba482df9ff703eba748220c68ece6826cb97d6283e470`. Built from the Review06 session: Studio Save As (`PhoneCandidate01.StudioSave.rbxl`), then Terrain `SmoothGrid` + `Materials` restored from Review02 with `mountain/tools/restore_terrain_payloads.py` (70/70 terrain properties exact; 1,796 other chunks untouched).

Differences from Review06:
- New `MountainShared.BuildFlags.studioAids()` = Studio **and** `ReplicatedStorage.StudioAids ~= false`. It gates the forced Mossbun nest (`raid:1:1`) and the `UIProbe`. The candidate saves `StudioAids=false`, so Studio Play behaves like a live server.
- `ServerScriptService.MountainServer.StudioTests` removed.
- `OffspringAssets.mossbun.clips` holds per-clip Animation asset ids (all `0` now). `OffspringPresentation` uses an id when it is non-zero, else Studio's local KeyframeSequence; a live server with `0` plays no clip (static pose), no error.

## Verified

- `evidence/phone_candidate_2026-10-26/phonecandidate01-file-integrity.json`: 93/93 runtime sources match the repo, terrain identical to Review02, no QA objects, 13,707 instances.
- CLI: 34 suites pass (combat_raids / run_persistence fail standalone exactly as before; their `.py` wrappers pass); 94/94 files compile.
- Cold Play (session just before save): one `MountainHUD`, no `UIProbe`, `StudioAids=false`, console only the ready line + default control-script note.

## Not re-run (same code as Review06 for these paths)

- 26-tab HUD audit on 4 emulator sizes: needs the UIProbe. To rerun, set `ReplicatedStorage.StudioAids=true` in Edit, audit, set it back to `false`, never save in between.
- Two-client bat theft: bat code is unchanged since Review05's pass.
- The forced-nest-off path was checked by flag, not by striking `raid:1:1`.

## Publishing blockers

| # | Blocker | State | Next step |
|---|---|---|---|
| 1 | 7 Mossbun clips (Idle, Move, Run, Turn, Reveal, Carried, Happy) | Code ready for ids | Owner OK → upload each `Rig|<clip>` KeyframeSequence from `ReplicatedStorage.MountainAssets.Offspring.blossom-rabbit-creature` as an Animation asset owned by the **same creator as the place** (else it won't play), paste ids into `OffspringAssets.mossbun.clips`, re-package |
| 2 | Studio-only aids | Done | Forced nest, UIProbe, StudioTests gated/removed. Inert old generator modules remain in ServerStorage (never replicated) |
| 3 | Real DataStore | Code path exists | `Profiles`/`Competition` use DataStore whenever not in Studio (`MountainEmpire_FirstDraft_v1`, `MountainEmpire_Defenses_v1`). Studio stays memory-only even when published. Only a hosted test proves it — see checklist |
| 4 | MaxPlayers | File says 12; 8 homes | Read-only from scripts. Set **8** in Game Settings › Places at publish (owner) |
| 5 | Phone performance | Unmeasured on hardware | Budget below. `StreamingEnabled` is **off** — fine for an 8-player private test at 2.7 MB, revisit before public |
| 6 | Other | Open | 35 species placeholder art; guardians catch carriers ~6 s after pickup (short theft window); party/daily/rankings/paid shop absent by design |

## Phone performance budget (PROPOSED)

| Metric | Target on iPhone 16 Pro / 18 Pro Max |
|---|---|
| Join → playable | ≤ 15 s on Wi-Fi |
| Frame rate at home, gate, mid-mountain, nest fight | 60 FPS median, no stall > 100 ms |
| Client memory (Ctrl+F7 / Shift+F5 not on phone: use Developer Console › Memory) | ≤ 1.5 GB |
| Ping (Dev Console › Network) | ≤ 150 ms |
| Battery/heat after 20 min | Playable, no throttling feel |

## Owner checklist — private test place

Do these yourself in Studio; ask me before step 3 if you want me to drive any of it.

1. **Animations (optional before first test):** approve the 7-clip upload in chat. Without it Mossbun shows but doesn't animate.
2. Open `outputs/ClimbCollect.PhoneCandidate01.rbxl` in Studio.
3. **Publish to a NEW private experience** (File › Publish to Roblox As › *Create new game*), name e.g. "Climb & Collect – Phone Candidate". Don't overwrite the October 22 playtest place `134979185642785` unless you prefer that — it holds older data. Use a fresh DataStore universe so saves start clean.
4. Game Settings: Permissions → **Private**; Collaborators/access: you + your girlfriend's account only (friend her account, then add her with Play access). Places → Max Players **8**. Security → **Enable Studio Access to API Services: OFF** (not needed; Studio stays on memory saves). Monetization: nothing.
5. **Device test**, both phones (iPhone 16 Pro, iPhone 18 Pro Max), Roblox app, signed in to each account:
   - a. Join. Time from tap to control. Spawn at a home facing the gate.
   - b. Open Menu → each of the 8 hubs; close; walk + sprint. Note any text cut off or buttons under the notch/thumbstick.
   - c. Habitats: assign, wait, collect, bank.
   - d. Go through the gate, climb, strike a nest egg, carry the creature home, secure it.
   - e. Together: one carries, the other taps **Bat** to knock the creature loose; grab it; secure it.
   - f. Open Developer Console (chat `/console`): note FPS, memory, ping at home and on the mountain.
6. **Save/rejoin test:** note coins + creature count → leave → wait 1 min → rejoin → same values? Then: leave mid-carry → rejoin (unsecured creature should be gone, secured kept). Then: both leave, new server, rejoin.
7. **Record** per phone: model, iOS, join time, FPS/memory/ping at 4 spots, any UI overlap (screenshot), every bug with what you did just before, save/rejoin results, how long the theft window felt.

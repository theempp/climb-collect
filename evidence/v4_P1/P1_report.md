# v4 P1 — Cliff Ledge Line, first section (2026-10-20/21)

All numbers: Roblox Studio on this desktop (i9-12900K / RTX 5060), **not a phone**. Labels: `BOT` = scripted input through the same controller a player uses (perfect input, not human time) · `PlaySolo` · `emulation` = Studio Device Simulator (iPhone XR, screen/touch only, desktop CPU/GPU) · `ESTIMATE` · `UNVERIFIED`.

## What was built
- **Terrain:** the Ledge route's old stamped trail is no longer stamped for s 40–640 (`WorldConfig` `stampSkip`); that box was re-written from the generator (`MountainGen.writeBox`), so the natural 55–70° cliff is back and there is no stamped bypass. From the Ledge gate the line crosses open foothills to the trailhead on the lower bench.
- **`src/world/LedgeP1.luau`** (`B.ledgeP1()`, 285 instances): trailhead (flag, sign, checkpoint) → **Face B** (59-stud marked strata face with a fixed rope) → **Ledge L1** (226 studs along the cliff contour, y 160→168: sandstone ledge, slate back wall, orange handline on pitons) with a **knife-ridge spur** (decks on a rock fin 16 studs off the flank, open both sides, no handline), a **rest ledge** (RestLedge, checkpoint), a **rockfall chute** (8-stud gap, marked traverse panel, carved chute lined with a 63° scree plate, rock every 8 s with a 3 s tell) → **final pillar** (steel ladder 168→190, marked face →211) → joins the old ledge at s≈645. 9 glowing guide flags on cairns. Static atmosphere: 3 soft mist particle volumes (cloud layer below L1), 3 light shafts.
- **`src/runtime/CC_ClimbClient.client.luau`** (new): climb state on `Climbable` parts — auto-grab when pushing into marked rock, stick into the wall = up, sideways = sideways, Jump = lunge (8 studs, 12 stamina), X / "Let go" = release; stamina 100 (≈30 s climbing; refill 8 s on ground, 4 s on rest ledges); slip (stamina out / hazard hit) = slide with a 1.75 s catch window (push in or Jump, once per slip chain), missed = free fall judged by the existing fall rule; mantle at tops; camera auto-frame (CameraOffset + FOV 80); Guide button / G = mote pulse to the next flag; jumps that start on ground steeper than ~49° give no lift. Numbers in `CoreConfig.CLIMB` (PROPOSED).
- Runtime hooks: hazards make a climber slip instead of knocking them back (`CC_AscentClient`); `Straight` rockfall lanes; players pass through each other (collision group `CC_Players`, `CC_CheckpointService`).

## Acceptance (v4-climb-concept §7)
| # | Criterion | Result | Label |
|---|---|---|---|
| 1 | Controller on keyboard and touch emulation; no stuck states in 20 scripted runs | Keyboard (real key presses): W grabs + climbs Face B, Space lunges, X lets go. Touch (Device Simulator iPhone XR, real clicks on the virtual thumbstick/buttons): thumbstick grabs + climbs, Jump button lunges (+8.5 studs), Let go releases. **20/20 runs clean on the final build** (and 20/20 on the build before the last fixes): trailhead → exit 39.0–44.6 s, 0 stuck, 0 falls, 0 slips. | BOT · emulation |
| 2 | Section in 60–90 s | **Ledge gate → exit 80.5 s** (incl. 6.8 s waiting out the rockfall; 34.9 s of it is the walk over the foothills), trailhead → exit 39–45 s. | BOT |
| 3 | Forced slip, catch, missed catch, respawn; fall cost logged | Slip at y 132 → caught after 0.62 s (8.6 studs lost). Second slip in the same chain (catch used) → slid 22 studs to the bench and stood up. Slip on the chute panel, no catch → 1.75 s slide → miss → fell down the chute → server-accepted fall → respawn at the rest-ledge checkpoint **7.25 s after the slip** (cost ≈ 12–15 s with the walk back to the chute, BOT ESTIMATE; unbanked cargo follows the locked fall-loss rule via the existing pipeline). | BOT |
| 4 | No free bypass (±36-stud profiles) | Terrain profiles every ~24 studs along L1: 69–85 % of cells within ±36 studs are steeper than 45°, **0 walkable cells within 10 studs of ledge height** (table below). Physical walk/jump tests with climbing disabled (grounded jumps only, as a player): bench → L1 max +27 studs (L1 is +61), foothills → rest ledge max +4, chute near → far not crossed, L1 end → exit not reached. | BOT |
| 5 | Two-client pass-through | Single client + server-side clone avatars: a clone in `CC_Players` was walked through in 0.9 s; a control clone in the Default group blocked 2 studs short. `CollisionGroupsAreCollidable(CC_Players, CC_Players) = false`. **A real two-client test is UNVERIFIED** (the MCP starts Play Solo only). | PlaySolo |
| 6 | 3 hero shots at avatar scale + phone aspect | `P1_01` knife-ridge over the cloud layer, `P1_02` Face B climb with auto-framed camera and the drop to the Foothold, `P1_03` chute crossing during the rockfall tell; each `_desktop` + `_phone_aspect` (19.5:9 centre crop of the same frame = same vertical FOV; HUD scale is the desktop's). `P1_04` = real Device Simulator frame (touch UI). Rejected: `90`–`93`. | — |
| 7 | Mobile-emulation FPS + instances | Rest ledge, iPhone XR emulation: **60 FPS static and orbiting, worst 19.7 ms, 0 frames > 33 ms**, render CPU 3.7–4.1 ms, draw calls 148–169 (max 442). World streamed there 4,198, of which P1 = 278 (+7 % over the ~3,920 without it, ESTIMATE); +11 % vs the Stage 4 average baseline (3,785) — inside the +15 % cap. Phone GPU/CPU: **UNVERIFIED**. | emulation |

### ±36-stud terrain profiles across L1 (offsets −36 … +36 step 6; negative = downhill)
| Sample | Ledge y | Terrain heights | > 45° | walkable within 10 of ledge y |
|---|---|---|---|---|
| Ledge x−492 | 159 | 99 99 100 111 125 138 156 169 176 183 189 196 204 | 69 % | 0 |
| Ledge x−516 | 160 | 98 98 100 113 125 140 155 169 177 183 190 197 204 | 85 % | 0 |
| Fin x−537 | 161 | 95 96 96 98 112 124 137 156 168 177 183 189 197 | 77 % | 0 |
| Fin x−561 | 162 | 95 96 96 106 117 130 145 164 174 181 188 194 202 | 69 % | 0 |
| Ledge x−585 | 162 | 95 96 102 114 126 141 159 172 180 187 193 200 207 | 85 % | 0 |
| Ledge x−608 | 163 | 96 96 101 115 126 140 160 173 182 188 195 201 208 | 85 % | 0 |
| Ledge x−632 | 164 | 97 97 101 116 128 143 161 174 182 189 195 202 209 | 85 % | 0 |
| Ledge x−663 | 165 | 98 99 101 119 130 149 162 175 184 190 196 203 210 | 77 % | 0 |
| Ledge x−687 | 166 | 99 99 101 121 132 145 161 177 184 190 197 203 211 | 69 % | 0 |
(Measured before the knife-ridge spur moved 16 studs out; the terrain there did not change.)

## Defects found and fixed during P1 (kept for honesty)
- 2-stud gap between Face B's top and L1 (bot fell through) → L1 starts inside the top platform.
- Marked chute panel coplanar with the back wall → face rays hit plain rock → climber dropped off; panel now 0.4 proud.
- 5-stud gap between L1's last slab and the pillar floor; pillar later re-anchored so its top meets the old ledge's walkable start (bot slid off the pillar's side once).
- False mantle: at a slab seam the top check started inside the rock → teleport into the face. Now: seam-tolerant face rays, mantle only with nothing in front of the head.
- Slides "landed" on a marked stratum's top edge; a missed catch could be re-grabbed instantly mid-air → landing ignores marked rock, 1.5 s no-grab after a miss.
- A terrain foothold 6 studs under the chute gap (could stand there, maybe cross) → chute carved and lined with a 63° scree plate.
- The chute panel's top was 6 studs above the ledge (jumpable, skips the crossing) → panel as tall as the back wall.
- Guide target never reset (counted "reached" upward only) → target = the flag after the nearest one.
- Bot artifact (not a game bug): `ChangeState(Jumping)` from a script works mid-air, so an early bypass test "flew" to y 342; tests now jump only when grounded, like real input. The steep-ground jump rule still cancelled 79 hop attempts in that test.

## Self-review against master.md §3 and references-intel (honest)
- **Works:** a narrow line on a cliff with a visible drop (img1 / §3 exposure), orange fixed ropes and steel ladder (img4, old_a f10), glowing route flags, mist below the ledge (old_c/old_e cloud sea, static), light shafts (img1), strata in the Broken-Cliffs words (sandstone amber + charcoal slate), the Foothold visible from the face ("how far you've come").
- **Weak / first draft:** buttresses read as stacked striped boxes; the flank around the line is the foothill red-earth terrain, so the section reads as "rock structures on an earth cliff" more than one rock cliff (fix attempted in P2: rock material on the flank); the rockfall tell strip reads as a dark glass pane; knife-ridge is short (~24 studs at full stand-off); no audio; human feel of the controller (speeds, catch window, lunge) **UNMEASURED** — your playtest decides.

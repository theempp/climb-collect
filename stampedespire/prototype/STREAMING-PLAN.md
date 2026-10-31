# Stampede Spire: streaming plan for the 10-section mountain (draft, 2026-10-29)

Scope: the 17,960-stud, ~4,875-stud-rise path in `SECTIONS-PLAN.md` (P5 "streaming change"). Read-only research; nothing in Studio, `src/` or Blender was changed. **All budgets are provisional until the M7 real-phone numbers.** No visual values are set here; fog/light come only from `art/LOOKDEV.md`.

Geometry used below (from `SS_Path`: start at the origin, climbing along -Z): summit at about z -17,250, y +4,875, x up to +340, so about **17,930 studs from the origin**.

## 1. What breaks at 18k studs today, and why
| # | Problem | Why | Evidence |
|---|---|---|---|
| B1 | `SS_Mountain` as one Persistent model cannot scale | Today: 278k tris for 4,000 studs (~70 tris/stud). At that density 17,960 studs is ~1.25M tris, all kept in client memory. Persistent models "never stream out" and "overuse may hurt performance". | PERF-BUDGET; [streaming docs](https://create.roblox.com/docs/workspace/streaming) |
| B2 | Far view goes empty once the mountain streams | Streamed-out parts are removed. The far stand-in, SLIM, needs a **published place with Team Create**; local .rbxl tests produce nothing. Legacy `StreamingMesh` imposters have no textures, physics or raycasts. | [SLIM](https://create.roblox.com/docs/workspace/streaming/slim), [StreamingMesh (DevForum)](https://devforum.roblox.com/t/improvements-to-model-level-of-detail-lod/2204938) |
| B3 | The server may not see where the rider is | While riding, the client anchors the HRP (`SS_Ride` 360, 369, 465) and moves it by CFrame. Community reports conflict on whether a client-anchored HRP replicates. If it doesn't, the streaming focus (the character's PrimaryPart) stays at the last unanchored spot, so nothing streams in ahead. P1's section-10 fail check stood on the slabs at d≈15,240 with streaming on (devserver.log: `STREAM enabled=true`), which suggests it works in Play Solo. A live server is unproven. | [DevForum 3136271](https://devforum.roblox.com/t/how-do-i-replicate-local-humanoid-root-part-cframe-changes-when-it-is-anchored/3136271), [1153526](https://devforum.roblox.com/t/my-character-cframe-dont-show-in-server-while-is-anchored/1153526) |
| B4 | Long jumps arrive before the ground does | Summit reset (18k back to d -30), BOT teleports and P3 checkpoint restores move the rider instantly, with no prefetch. The `free` state then unanchors onto slabs that may not be streamed yet, so the rider falls or the game pauses. Client physics runs only in streamed areas, client-made parts included. | [streaming docs](https://create.roblox.com/docs/workspace/streaming), [fall-through report](https://devforum.roblox.com/t/players-fall-through-terrain-when-teleported-with-streaming-enabled/4762912) |
| B5 | Client FX and herd float over missing ground | `SS_Env` builds every marker FX for the whole mountain at load, and the herd is placed analytically up to `Pool.Ahead` 700 studs ahead. Both are client-made, so they never stream out, even where the ground has. | `SS_Env` 13-15/131+, `SS_Ride` 944-1025 |
| B6 | Float precision past 16,384 studs | The per-axis float32 step is 0.00098 studs from 8,192 to 16,384 and 0.00195 from 16,384 to 32,768. The last ~900 studs of section 10 sit past \|z\| 16,384, so the **0.001 placement tolerance** (postimport, P5 BOT) cannot hold there. Jitter of small or skinned objects is reported from ~8-10k studs. | [DevForum 202782](https://devforum.roblox.com/t/loss-of-precision-causes-game-breaking-issues-at-distances-far-from-origin/202782), [2879723](https://devforum.roblox.com/t/floating-point-reaching-very-early-under-10k-studs/2879723) |
| B7 | Fog does not change with altitude | Atmosphere density ignores camera height, so Y 4,900 fogs exactly like Y 0. Nothing breaks: per-section LOOKDEV values apply unchanged, but "thin air" up high is not automatic. Roblox `Clouds` sit at a fixed height, which matters for S9 Cloud Sea Ridge. | [Atmosphere](https://create.roblox.com/docs/environment/atmosphere), [height fog request](https://devforum.roblox.com/t/atmospheric-fog-should-take-height-into-account/1667515), [cloud height](https://devforum.roblox.com/t/is-it-possible-for-roblox-clouds-to-appear-below-the-player-is-it-possible-to-adjust-cloud-height/1863308) |
| B8 | Far LOD on huge parts | `Automatic` RenderFidelity uses camera distance: highest detail under 250 studs, medium at 250-500, lowest from 500. Parts up to 1,829 studs long sit near the camera and far from it at once (unclear which distance counts; verify). Beams cull at ~2,048 studs from the camera (TEST-LOG M3). | [meshes](https://create.roblox.com/docs/parts/meshes) |
| B9 | Frame spikes on jumps | P1 PERF: 53 fps, worst frame 89 ms, 3,152 parts (2,760 of them collision slabs). Stream-in bursts on jumps add to that. | TEST-LOG P1 |

## 2. Recommended setup
### Workspace (set in Studio by the owning session; provisional)
| Property | Value | Why |
|---|---|---|
| `StreamingEnabled` | true (already) | |
| `ModelStreamingBehavior` | Improved | a model streams with its parts, no empty shells |
| `StreamingMinRadius` | 128 | about 1.6 s at 78 st/s. Content inside it never streams out. Raise it only if S2 fails. |
| `StreamingTargetRadius` | 1024 (default) | covers `Pool.Ahead` 700 + camera. The M7 phone memory decides any raise. |
| `StreamOutBehavior` | Opportunistic | docs recommend it for memory; sections behind are dropped |
| `StreamingIntegrityMode` | PauseOutsideLoadedArea (docs' pick) | Prefetch (below) should mean it never fires. BOT counts pauses. |
| `Player.ReplicationFocus` | a server-owned anchored focus part at `P.surf(d)` (server only) | Streaming follows the ride even if B3 is real. |

### Model layout
| Group | Streaming mode | Contents | Limits |
|---|---|---|---|
| `SS_Far` | **Persistent** (the only one) | 1-2 far-shell meshes per section (silhouette for the clear-air sections), the 38 backdrop peaks, the summit crown silhouette | `Performance` fidelity, `CollisionFidelity Box`, CanCollide/CanQuery/CanTouch off. ≤ ~70k tris total (§4). |
| `SS_Sec01..10` (Model, Nonatomic container) → `SS_SecNN_Tmm` tiles | **Atomic** per tile | ground mesh + skirts + props for ≤ 512 path studs (≤ 2,048 per axis: width ±950 fits) | Ground and props arrive together, so no floating props. Tiles stay flat, with no Persistent inside an Atomic (docs). |
| `SS_Track` (server collision) | Nonatomic (current Folder) | slabs, walls, summit pad | Fine as is. The rider just needs them streamed before unanchoring (§3). |
| Client-only (never streamed) | n/a | `SS_Herd`, `SS_FX`, weather, aurora (camera-locked), title cards, timeline viewport, Lighting/Sky/Atmosphere | They must **check that their tile is present** (B5). |
| Terrain | n/a | none today (Workspace = Camera, SS_Mountain, Terrain, which is empty) | If S9 uses Terrain or water, it streams by region. Re-check then. |

Prefetch: a new server script `SS_Stream` (server-side, needs the owning session):
- The client reports the rider's d at 4 Hz on a RemoteEvent. P3 needs the same feed for distance validation.
- The server moves the focus part, and every 1.5 s calls `RequestStreamAroundAsync(P.surf(d + 6 s × speed))`.
- A RemoteFunction `prepare(d)` calls `RequestStreamAroundAsync(pos, 5)` before any jump and returns when done. The docs show it server-side, before `PivotTo`. ([techniques](https://create.roblox.com/docs/workspace/streaming/techniques))

## 3. Code impact (current `src/`, read 2026-10-29)
| File:line | What | Under streaming | Fix |
|---|---|---|---|
| SS_Ride 360-361, 369-370, 465-466 | `hrp.Anchored = true` (mount, jump, leap) | B3: the server may lose the rider | Server focus part from the reported d (§2), or replace anchoring with an unanchored HRP held by AlignPosition/AlignOrientation |
| SS_Ride 1127 | `sendToFoothills`: `hrp.CFrame = onFoot(-30, 0)` from the summit | 18k jump with no prefetch | `prepare(-30)` during the 4 s `SummitHold`, so the jump waits for it |
| SS_Ride 1279 | summit `onFoot(P.Total + 20)` | fine if streaming kept up | covered by S2 |
| SS_Ride 1342-1345 | fall → `free`: unanchor onto the slabs | falls through if no slab is streamed | Before unanchoring, raycast down (Include `SS_Track`). On a miss, stay anchored and call `prepare(d)`. |
| SS_Ride 1391-1409 | `onCharacter` → `foothillsDue` | spawn is at d -30, the default focus, so OK | none |
| SS_Ride 944-1025 | pool `place` / `bandsFor` / `poolStep` spawn up to `Pool.Ahead` | B5: herd over void under memory pressure | Spawn only where tile `SS_SecNN_Tmm` exists (`FindFirstChild`). Otherwise keep the creature parked. |
| SS_Ride 1455-1460 | debug `teleport` (moves `mount.d`) | jump with no prefetch | Debug action calls `prepare(arg)` first |
| SS_Ride 617-623 | `pickCreature` raycast (herd only) | unaffected | none |
| SS_Env 13-15, 131+ | marker FX built for the whole mountain | B5 + needless cost | Create/enable per tile when its tile streams in (`ChildAdded` on the section models) |
| SS_Env 380, 385 | aurora root and weather box follow the camera | unaffected | none |
| SS_Track 43-58, 76 | slabs every `CollisionStep` 20 over the whole path | fine (Nonatomic) | none. Optionally group into one Atomic model per 200 studs so walls and slabs arrive together. |
| SS_Bot 143, 160, 165, 189, 197, 248, 354, 372, 401, 437 | `F:Invoke("teleport", …)` | ground not ready after the jump | `waitStreamed(d)`: `prepare` + slab-under-rider raycast, 5 s timeout |
| SS_Bot 220-243 | fail → standing height on the slabs | flaky right after a teleport | runs after `waitStreamed` |
| SS_Bot 468-475 | PERF counts `workspace` parts | now counts only streamed parts | Label the line "streamed". Add a per-section count (S9). |
| art/tools/studio/check, dedupe, assetids, patchprep, postimport | `workspace.SS_Mountain` | Edit mode sees everything, so OK. A Play-mode run would not. | Retarget to `SS_Far` + `SS_Sec*`. Keep them Edit-only. |
| SS_Timeline 188-192 | mount icon ViewportFrame | unaffected | none |

## 4. Per-section budget (PROVISIONAL, replace after M7)
In memory at once: target radius 1,024, so ~2,048 path studs ≈ **≤ 5 tiles**. Mountain ≈ 5 × 40k + `SS_Far` 70k ≈ **270k tris**, about today's 278k (59 fps desktop; phone unknown). Herd: ≤ 50 live (P2 cap) × ≤ 3k tris, animating only the ≤ 25 within 250 studs (PERF-BUDGET).

"Far-view need" reads each biome's LOOKDEV fog note: light fog means the far shells carry the view; heavy fog hides the streaming edge.

| # | Biome | Length | Tiles (≤512) | Near tris / tile | Parts / tile | Far shell | LOOKDEV fog | Far-view need |
|---|---|---|---|---|---|---|---|---|
| 1 | Frozen Taiga | 880 | 2 | ≤ 40k (≤ 10k / part) | ≤ 150 | ≤ 3k | light (Z1) | high |
| 2 | Rime Fog Forest | 1,010 | 2 | ≤ 40k | ≤ 150 | ≤ 2k | heavy, densest (S2) | low |
| 3 | Crevasse Ice Canyons | 1,170 | 3 | ≤ 40k | ≤ 150 | ≤ 3k | strong cyan haze (Z2) | low |
| 4 | Ice Cave Labyrinth | 1,340 | 3 | ≤ 40k | ≤ 150 | ≤ 3k | medium-strong (S4), enclosed | low |
| 5 | Hot Spring Terraces | 1,540 | 4 | ≤ 40k | ≤ 150 | ≤ 4k | medium, far range readable (S5) | medium |
| 6 | Geothermal Obsidian | 1,780 | 4 | ≤ 40k | ≤ 150 | ≤ 4k | heavy warm haze (Z3) | low |
| 7 | Storm Peaks | 2,050 | 5 | ≤ 40k | ≤ 150 | ≤ 5k | medium (S7) | medium |
| 8 | Wind-Carved Spires | 2,360 | 5 | ≤ 40k | ≤ 150 | ≤ 6k | light (S8) | high |
| 9 | Cloud Sea Ridge | 2,710 | 6 | ≤ 40k | ≤ 150 | ≤ 6k | medium at horizon, cloud below (S9) | medium |
| 10 | Aurora Crown | 3,120 | 7 | ≤ 40k | ≤ 150 | ≤ 7k | clear air (Z4) | high (summit view) |
| | **Total** | 17,960 | 41 | | | ≤ 43k + backdrop 12.8k + crown ≈ ≤ 70k | | |

- **Draw distance** is not a property. It is target radius + Atmosphere + the device quality level. Measure the effective range per section in M7. Density values come only from LOOKDEV.
- **Far LOD:** tile meshes `Automatic`; `SS_Far` and backdrop `Performance`; nothing `Precise`. SLIM only if the owner allows a publish (Q1).
- **Delivery rate:** at 78 st/s a 512 tile passes every 6.6 s. A 6 s prefetch lead ≈ 470 studs.

## 5. Origin, precision, fog and camera at 4,900 rise
| Option | Max distance from origin | Float step | Cost | Verdict |
|---|---|---|---|---|
| Keep as is (start at 0, 0, 0) | ~17,930 | 0.00195 | none | fails the 0.001 tolerance in the last ~900 studs; jitter risk |
| **Shift along Z/X only (path midpoint at z 0)** | ~9,900 (z ±8,630, y 0..4,875) | 0.00098 | one constant `Origin` in SS_Path + sspath.py; free at the P5 rebuild (every mesh is re-exported anyway) | **Recommended** |
| Also centre Y (start at y -2,440) | ~9,000 | 0.00098 | `FallenPartsDestroyHeight` (default -500) would delete the lower half; must be lowered | no: same precision bit, extra risk |
| Floating origin / per-section re-centre | < 2,000 | tiny | moves the whole world at runtime; fights streaming, server physics, BOT and the markers | no |

**Keep one continuous mountain** with a Z/X origin shift. Fog and camera:
- Atmosphere is not height-based, so the per-section LOOKDEV blend in `SS_Env` keeps working at any Y.
- The skybox and ClockTime don't depend on altitude. The "black after sunset" gotcha still applies.
- The camera never leaves the character by more than the summit orbit (230 studs), so camera-side streaming is not needed.
- For S9, decide Roblox `Clouds` (fixed height) vs a cloud mesh layer (Q7).

## 6. New BOT checks
| ID | Check | Pass |
|---|---|---|
| S1 | server sees the rider: server focus/HRP vs client d at 6 points, incl. section 10 and right after the summit reset | ≤ 50 studs |
| S2 | ground streamed: every frame of an unattended ride 0 → summit, the tile under the rider and at d + `Pool.Ahead` exists, and a slab raycast hits under the rider | 0 misses |
| S3 | jump readiness: summit reset, each `teleport`, each P3 restore: slab present before unanchor; time to ready | 0 falls; report seconds |
| S4 | persistent set: `SS_Far` present after `PersistentLoaded`; parts and tris within §4 | ≤ 70k tris |
| S5 | no herd over void: live creatures over a missing tile | 0 |
| S6 | no floating FX: enabled marker FX over a missing tile | 0 |
| S7 | precision: max \|x\|, \|y\|, \|z\| of any tile/far part ≤ 16,384 (Edit); placement vs manifest | ≤ 0.001 everywhere |
| S8 | pauses: gameplay-paused events during the full ride (if readable; the property may be locked) | 0 |
| S9 | memory per section: streamed parts, meshparts, tris, MEM tags, logged per section (M7 input) | logged |
| S10 | stream-out: after reaching section 10, section 1-2 tiles have left the client (Opportunistic) | > 0 removed |
| S11 | never below the track: the rider ≥ -2 studs vs `P.surf` every frame of the full ride | 0 |

## 7. Open questions for the owner
**Answered 2026-10-29 (SECTIONS-PLAN S11):** every recommendation below was taken (Q1 one private unlisted publish, owner clicks; Q3 before M7).
**Q3 built (P4, 2026-10-30):** `SS_Stream` (server) + the 4 Hz `Rider` feed, `Prepare(d)` before the summit reset and debug teleports, respawn re-focus; BOT S1 (focus within 25 studs of the client, limit 50) and S3 (slab under the rider after every jump, prepare <= 0.07 s in Play Solo) pass. **§2 Workspace properties set 2026-10-30** (Improved, Min 128, Target 1024, Opportunistic, PauseOutsideLoadedArea) via the Properties panel; Studio 0.745 does not expose them to the command bar (only `StreamingEnabled`). Full BOT 41/41 on them.
| # | Question | Recommendation |
|---|---|---|
| Q1 | SLIM far LOD needs a **published place + Team Create**. M7 also needs a private publish. Allow one private, unlisted publish? | Yes, once, for M7 + a SLIM trial. Without it the far view is hand-built `SS_Far` shells only. |
| Q2 | Shift the origin along Z at the P5 rebuild (§5)? | Yes |
| Q3 | Add the server rider feed (RemoteEvent 4 Hz + focus part + `prepare`) now? P3 needs it for distance validation anyway. | Yes, in P3 |
| Q4 | Pause behaviour if streaming falls behind: the Roblox modal, a custom "loading" card, or no pause? | Custom card, rare by design |
| Q5 | Tile size 512 studs (41 Atomic tiles), or one Atomic model per section? | 512 tiles; whole sections are up to 3,120 studs and exceed 2,048/axis |
| Q6 | Does the signed-off Greybox place stay Persistent (4 zones) while only the Sections place streams? | Yes, until P5 replaces it |
| Q7 | S9 cloud sea: Roblox `Clouds` (fixed height) or a mesh layer? Look comes from the S9 sheet / LOOKDEV. | Decide at S9 art time |
| Q8 | Raise `StreamingTargetRadius` for the clear-air sections (1, 8, 10)? It is one value for the whole place. | Only if M7 memory allows; else rely on `SS_Far` |

Sources: [Streaming](https://create.roblox.com/docs/workspace/streaming) · [Techniques](https://create.roblox.com/docs/workspace/streaming/techniques) · [SLIM](https://create.roblox.com/docs/workspace/streaming/slim) · [ModelLevelOfDetail](https://create.roblox.com/docs/reference/engine/enums/ModelLevelOfDetail) · [Meshes / RenderFidelity](https://create.roblox.com/docs/parts/meshes) · [Player API](https://create.roblox.com/docs/reference/engine/classes/Player) · [Atmosphere](https://create.roblox.com/docs/environment/atmosphere) · [Multiple replication foci](https://devforum.roblox.com/t/new-instance-streaming-feature-multiple-replication-foci/3848736) · DevForum threads linked inline (community reports, not official).

# Stage 3 — Performance diagnosis (2026-10-20, measure only; nothing in the place or `src/` changed)

**Machine:** i9-12900K, RTX 5060, 32 GB RAM, Windows 11. **This PC is not a phone.** Every frame number below is from Roblox Studio on this desktop.
**Labels:** `PlaySolo` = Studio Play Solo (a server DataModel and a client DataModel in one process, real replication and streaming over local loopback, no network latency) · `QL<n>` = Studio rendering quality forced to level n on the desktop GPU (closest available stand-in for a weak device's auto-quality, still NOT a device) · `emulation` = Device Simulator (screen size/DPI only, desktop CPU/GPU) · `ESTIMATE` = not measured · `UNVERIFIED` = could not be tested here.
**Not done:** no real phone, no published server (PlaceId 0), no multi-process "Clients and Servers" test (Play Solo already includes server→client replication; network latency/bandwidth is not modelled). Tools: `tools/perf_probe.luau` (frame sampler), `tools/rbxl_audit.py` (file audit), Stats service, MicroProfiler (`P1_01/02`), quality sweep (`P1_03/04`).

## 1. Measured

### Time to playable (join → character can move → HUD + tutorial step 1 visible)
| Measure | Value | Label |
|---|---|---|
| Play pressed → character on the ground + step "(1/9)" visible | **19.9 s** (upper bound; includes ~1.4 s MCP call overhead → ~18.5 s) | PlaySolo |
| …of which Studio work before the server DataModel starts running | **~17.7 s** | PlaySolo (server `time()` = 8.89 s at a known tick) |
| Client DataModel start → playable (character + HUD step 1) | **≤ 0.8 s** | PlaySolo (client `time()` 0.79 s when all three were already true) |
| Real phone join over a network | UNVERIFIED | — |

### Memory and file (the dominant cost)
| Item | Value | Label |
|---|---|---|
| Place file | **79.2 MB**, of which **69.5 MB (88%) = 15 `TerrainRegion` checkpoint snapshots** in `ServerStorage.CC_Checkpoints`; live terrain 5.6 MB; everything else < 4 MB | file audit (`rbxl_audit.py`) |
| Instances | ServerStorage **245,795** (checkpoints 245,561) vs Workspace 6,308 vs ReplicatedStorage 14 | Edit |
| Studio process, Edit | **8.3 GB** (TerrainVoxels 3.4 GB) | Stats, Edit |
| Studio process, playing | **13.3 GB** (TerrainVoxels 6.8 GB; server instance count 298,707); OS: 13.9 GB private, **4.0 GB of 32 GB free** | Stats + OS, PlaySolo |

Play Solo copies the whole edit DataModel (checkpoints included) into the server DataModel, so every Play press copies ~252k instances and 15 whole-map voxel snapshots, and memory roughly doubles.

### Frame cost per location (10 s static + 10 s orbiting camera at avatar scale; vsync caps at 60)
| Where | FPS | p95 / worst frame | render CPU med (p95) | GPU med (p95) | draw calls med (max) | triangles med (max) | World streamed | Label |
|---|---|---|---|---|---|---|---|---|
| Spawn | 60.4 / 60.1 | 17.9 / 19.6 ms | 5.2 (6.3) ms | 1.2 (2.3) ms | 216–296 (414) | 195–228k (315k) | 2,853 | PlaySolo |
| Foothold plaza | 60.2 / 60.3 | 17.8 / 21.2 ms | 5.5 (6.3) ms | 2.9–3.5 (4.4) ms | 353–405 (419) | 273–369k | 2,881 | PlaySolo |
| Shepherd's Road s≈2500 | 60.6 / 60.7 | 17.6 / 18.7 ms | 5.1–5.3 (6.3) ms | 3.5 (4.5) ms | 232–295 (625) | 185–282k (611k) | 3,548 | PlaySolo |
| Hollow nest | 60.6 / 60.3 | 17.8 / 25.3 ms | 4.9 (5.6) ms | 2.9–3.2 (3.9) ms | 333–391 (467) | 301–338k (418k) | 3,559 | PlaySolo |
| Lip nest (guardian active) | 60.2 / 60.2 | 17.7 / 18.9 ms | 4.5–4.9 (5.5) ms | 2.4–2.6 (3.3) ms | 120–322 (360) | 101–425k | 3,891 | PlaySolo |
| Edit viewport (spawn → summit view) | 59.8 | worst 33.2 ms | 4.4 ms | — | 389 | — | whole map (no streaming in Edit) | Edit |
| Spawn, iPhone XR | 60 | worst 19.0 ms | — | — | — | — | — | emulation (Run 1, `B_test_log.md` §7) |

0 frames over 33 ms in every playtest window. **Slow frames were not reproduced on this PC** in the play client (it idles most of each 16.7 ms frame; MicroProfiler `P1_01/02`: RenderViewUpdate ≈ 5 ms per frame, rest waiting for vsync). Server: Heartbeat script time 0.036 ms avg / 0.11 ms worst with 1 player + 1 guardian, send 1.6 kbps.

### Quality sweep at spawn (desktop GPU)
| Quality | draw calls | triangles | render CPU | Label |
|---|---|---|---|---|
| Automatic (≈ high here) | 201 | 183k | 4.2 ms | QL auto |
| Level 7 | 172 | 174k | 4.1 ms | QL7 |
| Level 4 | 132 | 127k | 3.9 ms | QL4 |
| Level 1 | 105 | 94k | 3.7 ms | QL1 |
**At QL1 the whole mountain, the valley walls and the summit disappear from the spawn view** (`P1_03` vs `P1_04`): terrain beyond the short low-quality view distance is not drawn. Weak phones pick low quality automatically, so on those devices the summit focal point and route silhouettes are gone (navigation, not frame rate).

### Post effects / shadows (plaza view, 521 draw calls, desktop)
All on: GPU 3.0 ms · no DoF 3.5 · no DoF/SunRays/Bloom 3.3 · + no GlobalShadows 3.0 ms — **within noise on this GPU**; their phone cost is UNVERIFIED.

### Settings read from the file (the MCP cannot read them)
Lighting.Technology = **ShadowMap**, GlobalShadows on, post: Atmosphere, Bloom, DepthOfField, SunRays, ColorCorrection. Workspace: StreamingEnabled, **StreamingMinRadius 64, StreamingTargetRadius 1024**, StreamingIntegrityMode **PauseOutsideLoadedArea**, StreamOutBehavior Opportunistic, 1 Persistent model (lip nest).

## 2. Causes ranked by cost, with fixes
| # | Cause | Evidence | Fix | Expected gain (ESTIMATE) | Risk to look/gameplay |
|---|---|---|---|---|---|
| 1 | **15 whole-map checkpoints live inside the place** (69.5 MB TerrainRegions + 245.6k instances in ServerStorage) | file audit; 17.7 s before the server runs; memory 8.3 → 13.3 GB on Play; 4 GB RAM free | Keep only the newest checkpoint(s) in the place; the full set stays in a verified file copy (`ClimbAndCollect.C_2026-10-20_Stage1_01.rbxl` is byte-identical to the current place and holds all 15). Change `tools/checkpoint.luau` workflow: archive older ones after each new one. | Play start ~18 s → **~3–6 s**; Studio memory −4 to −6 GB in play; file 79 → ~20 MB (faster open/save/publish, faster published-server boot) | None in game. Restoring an old checkpoint means opening the archive file. |
| 2 | **Low-quality view distance hides the mountain** | `P1_03` | Option A: a cheap distant "skyline" stand-in (few large low-poly parts) shown only when quality is low. Option B: accept and rely on HUD arrow. Needs your call (look/identity). | navigation on weak phones; frame cost +ESTIMATE <1% | A: visible stand-in quality; must not show at high quality |
| 3 | Streaming: target 1024 + PauseOutsideLoadedArea | settings | On a slow phone the player is frozen until the area around them streams; 1024 radius pulls a lot of terrain. Candidate: MinimumRadiusPause; keep 1024 (summit/vista). Not changeable from the MCP (Properties panel only) and unmeasurable without a device. | phone join time: UNVERIFIED | lower radius would drop distant views |
| 4 | Draw calls / triangles at the Foothold (up to 521 / 434k at auto quality) | per-location table | Art-pass items: merge small Foothold props, MeshParts for repeated union trees, fewer lit lanterns (75 PointLights). | phone GPU: UNVERIFIED | look; art pass, not now |
| 5 | Post effects (DoF, SunRays, Bloom) + ShadowMap shadows | sweep | Keep on desktop; quality-tier them later with the weather tiers (LOCKED dynamic-weather tiers). | phone GPU: UNVERIFIED | look |
| 6 | Startup scripts / per-frame scripts | Server Heartbeat 0.036 ms; client 1 Hz visibility sweep over ~319 core instances; RenderStepped marker/wisp; guardian 20 Hz (1.6 kbps) | none needed now | negligible | — |
| 7 | Codex's `Workspace.CC_CreatureStage1` (181 instances, y = 6000) | tree | Not mine (Codex track); streamed only near y 6000 | negligible | — |

**Honest read:** the "takes far too long to load" problem on this machine is cause #1 (Studio copying 15 whole-map checkpoints on every Play, and the 79 MB file). The slow frames could not be reproduced on this PC; the likeliest local explanation is Studio memory pressure (13.9 GB, 4 GB free), which #1 also reduces. Phone frame cost and phone join time stay UNVERIFIED until you test on a device.

## 3. Incidents during measurement (logged)
- An empty "Open 3D File" dialog from the 3D importer (left by the Codex creature session) blocked Play; I cancelled it (nothing selected, nothing lost).
- A playtest stopped once when I clicked in the viewport while it was starting; re-run, no data affected.
- A Codex session ("Plan creature Phase C next steps") was open on this machine and had used this Studio. Two agents driving one Studio is a risk; flagged to you.

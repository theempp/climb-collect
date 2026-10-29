# Stage 4 — Performance after the fix (2026-10-20)

Same machine and labels as `perf_report.md` (i9-12900K / RTX 5060, Studio on this desktop, **not a phone**). `PlaySolo` = Studio Play Solo; frame numbers via `tools/perf_probe.luau` (10 s static + 10 s orbiting camera at avatar scale, vsync caps at 60).

## Fix applied
Cause #1 only: 14 of 16 whole-map checkpoints moved out of the working place into `ClimbAndCollect.CheckpointArchive_2026-10-20.rbxl` (byte-identical to `ClimbAndCollect.S4_PrePerf.rbxl`, verified by `tools/rbxl_audit.py`). Kept in place: `C_2026-10-20_Stage1_01` (Codex) and `S4_PrePerf_2026-10-20`. No game content changed.

## Before / after
| Measure | Before (Stage 3) | After (Stage 4) | Label |
|---|---|---|---|
| Place file | 79.2–84.8 MB | **18.0 MB** (17.96 MB after B-polish, 22:57 save) | file |
| Play pressed → character on ground + tutorial step visible | 19.9 s (≈18.5 s without MCP overhead) | **6.5 s / 6.1 s** (two runs, incl. ~1.4 s MCP overhead) | PlaySolo |
| Studio process memory while playing | 13.3 GB | **9.8 GB** | Stats, PlaySolo (all datamodels in one process; not a device number) |
| Instances in ServerStorage | 245,795 | **12,602** (2 checkpoints × 6,183) | Edit |

## Frame cost per location after the fix and B-polish (22:50 run, Studio window focused)
| Where | FPS static / orbit | p95 / worst frame | frames > 33 ms | render CPU med (p95) | GPU med (p95) | draw calls med (max) | tris med (max) | World streamed | Label |
|---|---|---|---|---|---|---|---|---|---|
| Spawn | 60.1 / 60.6 | 17.7 / 23.2 ms | 0 | 6.5 (10.4) ms | 3.8–4.0 (5.7) ms | 335–338 (537) | 316–357k (519k) | 3,854 | PlaySolo |
| Foothold plaza (campfire) | 60.3 / 60.5 | 17.9 / 27.9 ms | 0 | 5.0–6.7 (12.7) ms | 3.0–3.2 (5.0) ms | 326–349 (387) | 275–358k (400k) | 3,854 | PlaySolo |
| Hollow nest | 60.6 / 60.4 | 17.9 / 20.2 ms | 0 | 4.4–4.6 (6.3) ms | 1.3–2.3 (3.2) ms | 109–218 (334) | 122–210k (301k) | 3,714 | PlaySolo |
| Shepherd's Road s≈2500 | 60.3 / 60.2 | 17.8 / 19.5 ms | 0 | 3.8–4.2 (7.7) ms | 2.7–3.0 (4.3) ms | 203–244 (377) | 173–196k (348k) | 3,580 | PlaySolo |
| Lip nest (30 studs off, guardian active) | 60.2 / 60.2 | 17.7 / 18.3 ms | 0 | 2.6–3.1 (3.6) ms | 0.9–1.3 (1.7) ms | 35–100 (187) | 65–124k (164k) | 3,923 | PlaySolo |
Client InstanceCount 52.7–53.0k; Studio memory (Stats) 3.9–4.0 GB in this session.

**Read:** frame times were already vsync-bound on this PC before the fix and stay so (0 frames over 33 ms everywhere). Draw calls/triangles at spawn/plaza read higher than Stage 3's table because the probe's camera faced the Foothold buildings this time (views are not identical); frame times did not change. **No perf regression found.** Phone frame rate, phone join time and a real network join stay **UNVERIFIED**.

## Measurement artifacts (not game cost, kept for honesty)
- First spawn sample and the first hollow/lip orbit samples read **15 FPS with exactly 66.7 ms frames and GPU 0 ms**: Studio throttles rendering when its window is not focused. Re-measured after focusing the Studio window; only focused numbers are in the table.
- The first lip spot (13 studs from the nest) got the character knocked off the lip by the guardian (a real fall, respawn); re-measured 30 studs off.

## Still not fixed (listed for the user, unchanged from `perf_report.md` §2)
QL1 view distance hides the mountain (#2, look decision) · streaming radius/integrity (#3, unmeasurable without a device) · Foothold draw calls (#4, art pass) · post effects tiers (#5, with the weather tiers).

# v4 P2 — P1 fix + Shepherd's Road "gentle but alive" section (2026-10-21)

Labels as in `../v4_P1/P1_report.md` (Studio desktop, not a phone; BOT = scripted input through the same controller).

## 1. Fix from the P1 evidence (no user feedback yet; self-review vs master.md §3 + references-intel)
- **Problem:** the flank around the Ledge line was foothill red earth, so P1 read as "rock structures on an earth cliff" (`P2_00`), not the dark rock cliff of img1 / §3 "fractured cliff rock".
- **Fix:** `LedgeP1` now repaints terrain Mud/Salt → Rock (lichen-rock token) above the bench in 8-stud bands with ragged ends (no straight seam). The cliff band now reads as one grey rock band between the red earth base and the green top (`P2_01`). No instance cost.
- Other P1 weak points left as listed in `P1_report.md` (striped buttresses, tell strip, short knife-ridge) — art-pass items.

## 2. Shepherd's Road section (`src/world/ShepherdP2.luau`, `B.shepherdP2()`, 49 instances)
Shepherd s≈1390–1500 (past everything the tutorial uses: the tutorial bot walks s 0–822; beats 4–5 and the Rare nook at s≈840 unmoved).
- **Railed ledge** (s 1392–1428): a strata rock band squeezes the road to ~5.5 studs along the drop; the road's existing drop-side fence is the rail (`P2_04`).
- **Rope scramble** (s 1440): an old rockfall closes the road; its near face is marked rock with a fixed rope (14 studs) (`P2_02`).
- **View-down moment:** a railed slate lookout juts out from the rockfall top over a 53-stud drop, with a lantern (`P2_03`).
- **Stairs** back down to the road (3.9 studs over 19).

| Check | Result | Label |
|---|---|---|
| Walk-through s 1370 → 1495 incl. scramble + lookout detour | **12.8–12.9 s, 5/5 runs reached, 0 stuck** (scramble 2.3 s ≈ 18 % hands-on in this stretch) | BOT |
| Bypass around the rockfall without climbing (grounded jumps only) | not reached: max y 148 (rockfall top 153), bot ended down the drop | BOT |
| Tutorial beats 4–5 / Rare nook | untouched; tutorial timing below | BOT |

## 3. Regression on the P2 build
| Test | Result | Label |
|---|---|---|
| Tutorial bot (WalkSpeed 12) | done **6:07.6**, Rare **2:06.5**, 0 stuck, 0 hits, step 12, L2 / 220 XP (Stage 4: 6:08.6 / 2:06.4) | BOT |
| B scripted checks | **12/12 PASS** (pack recovered with 15 s left) | PlaySolo |
| A1 persistence suite | **12/12 PASS** (in-memory mock; real DataStore UNVERIFIED) | PlaySolo |
| Ledge P1 batch on the final controller | 20/20 clean, gate → exit 80.5 s | BOT |

### Perf pass (desktop, Studio focused; 10 s static + 10 s orbit each)
| Where | FPS static / orbit | worst frame | > 33 ms | draw calls med (max) | World streamed (Stage 4) | Label |
|---|---|---|---|---|---|---|
| Spawn | 60.2 / 60.5 | 18.9 ms | 0 | 333–370 (520) | 4,170 (3,854) | PlaySolo |
| Foothold plaza | 60.1 / 60.1 | 20.1 ms | 0 | 334–363 (395) | 4,170 (3,854) | PlaySolo |
| Hollow nest | 60.5 / 60.4 | 21.3 ms | 0 | 253–309 (529) | 4,073 (3,714) | PlaySolo |
| Shepherd s≈2500 | 60.6 / 60.1 | 19.9 ms | 0 | 202–244 (383) | 3,931 (3,580) | PlaySolo |
| Lip nest (30 off) | 60.0 / 60.6 | 18.9 ms | 0 | 62–119 (209) | 4,266 (3,923) | PlaySolo |
| P1 rest ledge | 60.4 / 60.7 | 19.6 ms | 0 | 187–204 (371) | 4,041 | PlaySolo |
| P2 lookout | 60.1 / 60.7 | 18.9 ms | 0 | 188–218 (346) | 2,987 | PlaySolo |
Streamed World is +8–10 % vs Stage 4 at the old spots (P1 + P2 + core-loop growth; ESTIMATE split), inside the +15 % cap. Phone numbers **UNVERIFIED**.

## 4. Honest limits
Shepherd section is one stretch, first draft: boxy rock band, no audio, the lookout view is a sunny sand floor (drama comes from height only). Human feel and a phone run are still needed. The rest of Shepherd's Road is unchanged (P3 rework not started, per the stop rule).

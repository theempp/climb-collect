# Stampede Spire: P2 herd-pool model (2026-10-29)

> **Status (2026-10-29 night):** fixes from section 5 are now in `src/`: yield, stragglers tire to **0.15x** (0.3 at P2b; lowered at P4 start, see TEST-LOG "10d s4 native swing"), RecycleClear 60, FrontBand 400, per-section Herd 8..4, swap-target clamp, start at d 5-30. BOT 10d runs the continuous ride. Results in `TEST-LOG.md` (P2b). Unchanged: ViewDist / RecycleAhead (fog not measured), Zones[k].Rare. Rare flyers' Weight 0.12 -> 0.05 (owner, P4 start).

> **P4 (2026-10-30):** src now uses per-section `Pool.ViewDist` / `RecycleAhead` 350, `Pool.Readable` (fog re-measure), `Pool.FarFade` 2 s for respawns and fade-outs ahead, `Pool.Ahead` 500 with no FrontBand, the on-foot quota fix (stragglers past their biome don't fill its quota while the rider is on foot: casual policy went from 4/8 runs stuck 60 s to 0), and Herd 8,7,6,6,6,6,6,6,5,5. `python sim/herdsim.py ten-d` (defaults = src) runs the BOT's 10d window per run, not pooled: 0/32 fail. `--p2` gives the old pool (11/16 fail). The sim still does not model the swap-target clamp (a 0.7-stud gap mid-leap in one seed is that, not a Studio bug).

> **This is a model, not a playtest.** It is a 1D-per-lane kinematic sim of the P2 pool written in Python. No Studio, no physics, no rendering, no human. Use it to pick starting values and BOT thresholds. Feel and visibility still need Studio and a phone.

- Code: `prototype/sim/herdsim.py` (Python 3, stdlib only, seeded and deterministic).
- Full tables: `prototype/sim/results.md`, rebuilt with `python sim/herdsim.py report --seeds 4 --out sim/results.md` (about 4 min).
- One config: `python sim/herdsim.py run --policy greedy --per-lane 5 --ahead 700 --seeds 4 [--yield --straggler-drop 0.7 --recycle-clear 60 --per-lane-sec 8,7,6,6,5,5,5,5,4,4 --ahead-secs 9 --view-dist 450 --recycle-ahead 450 --rare 2 --rare-zones 6 10]`.

## 1. What is modelled (sources)
The sim copies the **P2 pool that is already in `src/`**, not just the plan text. I read it, did not run it.

| Piece | Source | In the sim |
|---|---|---|
| 10 sections, Length / LaneWidth / Speed | SS_Config:18-27 | as is: 17,960 studs, 22 to 78 st/s |
| `speedAt` ramp, lane width ramp, laneX | SS_Path:63-78, 201-209; SS_Config:29-30, 146 | as is |
| Species: Speed tier, Size, Fly, Rare, Weight, Score | SS_Config:56-142 | as is; jitter ±10% per creature, drawn once (SS_Config:147, SS_Ride:97) |
| Pool build: PerLane×5 commons + ExtraEach of every extra; Weight × zone `Rare` | SS_Ride:164-195; SS_Config:160 | as is. No zone has `Rare` set yet, so it is 1 |
| Quota, bands (far / front / rear), candidates, park / fade / unpark, SpawnPerFrame, Tries | SS_Ride:884-1105; SS_Config:160-163 | as is: Behind 150, Ahead 700, FrontBand 250, ViewDist 300, RecycleAhead 250, RecycleClear 120 |
| Lane solver: LaneGap 14, ridden creature pushes the chain, overtake if >1.05× the leader, PassRetry 0.6, PassEase 2.5 | SS_Ride:1158-1227; SS_Config:163-164 | as is |
| Swap: SwapRange 40 body-to-body, stance 0.6, press at 0.933 s into the ring | SS_Config:191-198; SS_Ride:374-386 | 3D distance with lane x, xo and Fly height |
| Leap: T = 1.1 + 0.5·power game s; world eases to 0.3× (EaseIn 0.15, EaseOut 0.12, MaxSlow 1.4) | SS_Config:205-214; SS_Ride:533-545 | same time-scale curve. Auto-target means it always lands on the picked target |
| Fail: drop back FallDistance 30, faceplant 1.4 s, grace 0.4 s, remount by a same-lane ground creature within 9 | SS_Config:225-228; SS_Ride:388-400, 667-673, 1350-1360 | as is. Wait = faceplant start to pickup (same as `lastRemountWait`) |
| Camera: Back 24, Lag 7 | SS_Config:250 | camera at d − 24 − v/7, looking up the slope |
| Start: re-lay at −30, jump onto the lowest middle-lane creature | SS_Ride:1113-1131 | as is |
| BOT limits: cap PerLane×5+10, ≤2 biomes, ≥4 creatures in the 300 ahead, native ≥50% at +250, gap ≥13.5, remount wait ≤30 s | SS_Bot:433-456, 424, 240 | measured the same way, but on a **continuous** ride (the BOT teleports) |

**Rider policies** (one decision every 0.75 s, swap only to something better):
- `slow`, `normal`, `fast`: hold tier 0.8 / 1.0 / 1.4.
- `flyer`: prefer flyers.
- `greedy`: highest Score × tier.
- `casual`: 50% chance to swap to a random reachable creature.

A swap fails at ring timing with p = 0.15. The remount stress test uses p = 0.5. Results are 4 seeds per config, at 30 fps.

**Simplifications:** no physics, collision or terrain; bends ignored (d is along the path). The rider on foot stands still in the mount's lane. "On screen" = between the camera and camera + distance, with every lane counted inside the frustum. No fog model: **BOT view** = `Pool.ViewDist` 300 (the BOT's own test, SS_Ride:893), and **strict view** = a guessed true visibility of 450 studs. The real fog distance per biome is unknown, which is the biggest gap in this model. Zone-1 meshes use the config `Size` boxes. Opportunities/min = creatures newly entering SwapRange per riding minute.

## 2. Results with today's `src/` (pool 25, Ahead 700)

### Per section, policy `normal` (`greedy` in brackets)
| Sec | Speed | swap opps/min | no target: share of ride, mean / p95 s | live max (BOT cap 35) | biomes live | native share avg / at +250 | min gap | ahead min |
|---|---|---|---|---|---|---|---|---|
| 1 | 22.0 | 14 (28) | 31%, 5.9 / 12.2 (22%) | 27 | 2 | 100% / 100% | 14.0 | 1 |
| 2 | 25.3 | 14 (14) | 9%, 7.1 / 9.7 (0%) | 35 | 3 | 54% / 48% | 14.0 | 1 |
| 3 | 29.1 | 14 (18) | 0% | 40 | 4 | 38% / 31% | 14.0 | 4 |
| 4 | 33.5 | 13 (33) | 3% | 46 | 5 | 38% / 25% | 14.0 | 5 |
| 5 | 38.6 | 20 (43) | 0% | 46 | 6 | 44% / 32% | 14.0 | 7 |
| 6 | 44.4 | 31 (46) | 0% | 43 | 6 | 52% / 36% | 14.0 | 5 |
| 7 | 51.2 | 28 (51) | 0% (6%) | 51 | 7 | 47% / 19% | 14.0 | 5 |
| 8 | 58.9 | 27 (50) | 0% (5%) | 48 | 8 | 42% / 21% | 13.5 | 7 |
| 9 | 67.8 | 29 (51) | 0% (7%) | 49 | 9 | 46% / 13% | 14.0 | 7 |
| 10 | 78.0 | 44 (75) | 0% (9%) | 46 | 9 | 40% / 25% | 14.0 | 9 |

- **In view (BOT view): 0 in every config tried.** The nearest respawn ahead is r+300, which is 324+ studs from the camera, and respawns behind sit behind the camera. **Strict view (450): ~100 respawns per run** are inside 450 studs. Soft fade-outs (1 s) inside 450 studs: ~500 per run.
- **Remount** (stress test, p_fail 0.5): mean 2.8–4.9 s, p95 3.6–10.5 s, max 10.5 s (section 1). Pool 15 gives max 13.2 s and pool 35 gives 15.3 s. Nobody was stuck past 60 s in any config. TEST-LOG P1 measured 2.0 / 11.5 s, so the model agrees.

### Section time vs the 40 s target
| Policy (avg tier) | Sections 2–10 | Section 1 | Total (400 target) |
|---|---|---|---|
| slow (0.80) | 50.2–51.3 s (+26%) | 39.5 | 494 s |
| normal (1.02) | 38.6–42.5 s (within 10%) | 32.8 | 388 s |
| fast (1.44) | 27.3–29.7 s (−30%) | 27.1 | 281 s |
| flyer (1.55) | 25.2–26.9 s (−35%) | 26.1 | 261 s |
| greedy (1.43) | 27.5–29.3 s | 27.6 | 283 s |
| casual (1.08) | 47–52 s (slow-motion leaps + slow picks) | 42.4 | 495 s |

The plan's risk note says "slow +33%, flyers −40%". The model gives +26% / −35%, because the species actually available average 0.80 (slow) and 1.55 (flyer).

**Section 1 runs up to ~10 s short:** the summit-reset start (SS_Ride:1113-1131) picks the lowest middle-lane creature of a uniform re-lay over 0..670, which is often 100–250 studs up the slope.

### Encounters per run (`greedy` / `normal`)
- **Rares** (big runners plus rare flyers): 4.2 / 7.5 seen; 3.5 / 7.5 within SwapRange; `greedy` rides 2.5.
- **Rare flyers** (dragons, Weight 0.12): about 2 seen and 1.75 reachable per run, and no seed ever saw 0. That is not "hard to get".
- **Common flyers:** 4.2 / 13 seen.
- **Sections 2, 4, 5, 7, 8 and 9 have no extras at all** (no flyer, no big rare in SS_Config:68-129), so their `Rare` multiplier would do nothing.
- `Rare` ×2 on every section gives 6.8 rares seen; ×4 gives 9.2. On sections 6 and 10 only, ×4 gives 8.0.

## 3. Problems the model finds in today's P2 code
1. **Convoys around the rider.** The ridden creature pushes slower creatures ahead of it forever (SS_Ride:1203-1213). A creature less than 5% faster than the mount never pulls out from behind it (`c.spd > lead.spd * 1.05`, SS_Ride:1219), so trains form in the rider's lane. Both stay in the seen band, so they never recycle.
2. **Stragglers from earlier biomes stay with the rider.** Any unridden creature inside r−120..r+250 is never parked (SS_Ride:1044-1045), and every creature runs at the speed of the ground it is on. So a creature near the rider's tier rides along through several sections.
   - Live count reaches **51 against the BOT cap of 35**, with up to **9 biomes** at once.
   - **Native share 250 studs past a border is 13–36%** (BOT needs ≥50%). The rider's own biome sits mostly in the far band.
   - The BOT pool check (SS_Bot:433-456) only passes because it teleports to each border first, and the teleport re-lays the window.
3. **Respawns ahead are hard to reach.** A slow creature respawned at r+450..700 closes on a tier-1 rider at only 5–30% of herd speed. At 22 st/s that takes 30–90 s, while a section lasts 40 s. That is why sections 1–2 have long no-target stretches.
4. **Swap target overlap.** During stance/ring both the mount and the target are `fixed` (SS_Ride:1200-1201). A faster target directly behind the mount in the same lane drives into it: the min gap reached 6.6 studs (`greedy`), below the BOT's 13.5.
5. **Fades in view.** Today the ahead edge of the seen band is RecycleAhead 250, so quota trims and border crossings fade creatures out between 274 and 450 studs from the camera, about 1 per second. They are invisible only if the fog hides 274 studs.

## 4. Fixes tested (not in `src/`; sim flags)
`yield`: a pushed creature steps into a free lane, and anything faster pulls out from behind the ridden creature. `drop 0.7`: past its own biome an unridden creature eases to 0.7× its tier, then recycles behind the camera. `clear 60`: RecycleClear 120 → 60 (the camera sits at r−24). `fb`: FrontBand = Ahead − 300, so respawns ahead spread over r+300..Ahead.

| Variant (pool 25, Ahead 700) | Policy | Live max | Biomes | Native avg / at +250 | Opps/min | No-target share / p95 |
|---|---|---|---|---|---|---|
| today | normal | 51 | 9 | 45% / 28% | 23.7 | 4% / 12.2 s |
| today | greedy | 51 | 8 | 50% / 20% | 40.7 | 4% / 4.1 s |
| all 4 fixes | normal | 46 | 6 | 61% / 35% | 32.4 | 5% / 10.4 s |
| all 4 fixes | greedy | 37 | 4 | 84% / 66% | 53.5 | 17% / 5.3 s |

**Per-section density** (all 4 fixes, policy `normal`):

| Variant | Opps/min s1 / s2 / s3 / s10 | No-target share s1 / s2 | Run no-target p95 | Live max | Strict-view respawns |
|---|---|---|---|---|---|
| uniform PerLane 5 | 16 / 16 / 23 / 56 | 32% / 13% | 10.4 s | 46 | 200 |
| PerLane 8,7,6,6,5,5,5,5,4,4 | 19 / 26 / 26 / 43 | 12% / 0% | 16.4 s | 54 | 183 |
| + Ahead = Speed × 9 s (min 450) | 28 / 34 / 37 / 40 | 0% / 0% | 5.8 s | 59 | 405 |

**Respawn distance** (policy `normal`, strict view 450):

| Setting | Respawns in view | Fades in view per run | Live max | No-target p95 |
|---|---|---|---|---|
| ViewDist 300 (today) | 111 | 514 | 51 | 12.2 s |
| ViewDist 450 | 0 | 411 | 52 | 36.4 s |
| ViewDist 450 + RecycleAhead 450 | 0 | 0 | 70 | 12.8 s |
| the same + all 4 fixes | 0 | 0 | 50 | 37.8 s |

The long p95 values come from rare long gaps in section 1. With policy `fast`: ViewDist 500 gives 0 strict-view respawns and costs only 33.9 → 31.7 opps/min.

**Pool × window sweep** (today's code, `normal`):
- Opps/min: pool 15 gives 12–20, 25 gives 20–38, 35 gives 25–46.
- Ahead 500 is denser than 700 or 900, because the quota divides the same count by `Behind + Ahead`. A larger window makes the herd sparser.
- Pool 15 leaves the worst section (1 or 2) with no target 21–33% of the time, and up to 60% in the worst section with the fixes and the `greedy` policy.
- Pool 35 cuts the worst section to 0–11% but live reaches 59–78.

## 5. Recommendations for P2 tunables
| Tunable | Today | Recommend | Why |
|---|---|---|---|
| Lane solver | push + 1.05 rule | **add `yield`** (pushed creature sidesteps; any faster follower of the ridden one pulls out) | breaks the convoys; biomes 9 → 6 |
| Stragglers | ride along while in the seen band | **past its biome, ease to 0.7× tier** (never the mount or target) | native share 45 → 61% (`normal`), 50 → 84% (`greedy`) |
| `RecycleClear` | 120 | **60** | the camera sits at r−24, so r−60 is already behind it |
| `Pool.FrontBand` | 250 | **Ahead − ViewDist** (respawns spread over the whole out-of-view band) | the rider meets its own biome sooner |
| `Pool.PerLane` | 5 everywhere | **per section 8,7,6,6,5,5,5,5,4,4** (quota 40…20), as a new `Zones[k].Herd` | low sections need density: opps/min ∝ density × speed. Section 1 no-target 32% → 12% |
| `Pool.Ahead` | 700 | **keep 700**; try `Speed × 9 s, min 450` only if fog hides r+300 | the time-based window removes all no-target in s1–s3 but doubles strict-view respawns |
| `Pool.ViewDist` / `RecycleAhead` | 300 / 250 | **set both to the measured fog distance per biome**, likely 400–450 | at 450/450 no respawn or fade lands inside 450 studs; live rises to ~50 with the fixes |
| Swap target | `fixed` | clamp a same-lane target behind the mount during stance, or don't mark it fixed | the 6.6-stud overlap |
| Start | lowest middle-lane creature of a uniform re-lay | re-lay with the first slot at d 0–30 | section 1 is up to ~10 s short today |
| `Zones[k].Rare` | unset (1) | **leave at 1**; lower the dragons' Weight 0.12 → **0.04–0.06** if they must be rare. Give sections 2, 4, 5, 7, 8 and 9 one flyer and one big rare each, or Rare means nothing there | ~2 dragons reachable per run today. Rare also scales the common flyers |

## 6. BOT thresholds the model suggests
- **Run the pool check on a continuous ride** across at least 2 borders, without teleporting. The teleport re-lay hides problems 1–2.
- **Live cap:**
  - Today's `PerLane×5+10` (35) fails a continuous ride even with the fixes (37–46).
  - Use **max quota of the two live biomes + 15** (pool 25 → 40; with the per-section table → 55).
  - Better: also require **stragglers (outside their biome) ≤ 25% of live**.
- **Biomes ≤ 2:** keep it for creatures outside the seen band. Allow **≤ 4 overall** (the fixes reach 4 with `greedy`, 6 with `normal`).
- **Native share:** ≥ 50% **averaged over the section**. At +250 use ≥ 30%. The fixes give 35–66% at +250 and today gives 13–36%.
- **In view (BOT view):** keep 0. Add a strict check at the measured fog distance that counts respawns and **fade-outs**.
- **Min gap:** keep ≥ 13.5, after the swap-target fix. Until then, exclude the mount–target pair during stance.
- **Remount:** fail above **15 s**, warn above 10 s. Model max 15.3 s, p95 ≤ 10.5 s; the BOT allows 30 s today.
- **Ahead ≥ 4 in 300:** the model's minimum is 1 in sections 1, 2 and 9. Use **min ≥ 2 and mean ≥ 5**.
- **New check, no-target share:** time on a mount with nothing in SwapRange ≤ **15% per section**, longest gap ≤ **12 s**.
- **Section time:** tier-1 within ±10% of 40 s holds in sections 2–10 (38.6–42.5 s). Section 1 needs the start fix first.

## 7. Not verified
- Real fog / visible distance per biome, which decides ViewDist, RecycleAhead and Ahead.
- Mesh sizes (zone 1) vs config boxes.
- Lateral frustum edges and the bends.
- A rider walking while on foot.
- Human swap cadence and fail rate (0.15 / 0.5 are guesses).
- Performance of 50–60 live creatures on a phone.
- None of the fixes exist in `src/`. They are sim flags only.

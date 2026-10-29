# V4 Climb concept — rethink of routes and climbing (interview 2026-10-20; AWAITING APPROVAL, nothing built)

**Status:** concept only. No code, terrain or `master.md` edits made. Sources: six reference clips (reviewed as contact sheets, no audio), the 5-round interview, `master.md` §0.5/§0.6/§1/§3/§4/§6, `design/v3-ascent-plan.md`, `design/v3-morning-report.md`.
**Legend:** **LOCKED** = chosen by you in this interview · **PROPOSED** = my detail, not approved · **OPEN** = still undecided · **ESTIMATE** = not measured.

## 1. Why V3 routes failed
V3 routes are wide stamped trails across open ground. Nothing is in the way, there is no exposure and no skill, so the climb is running. The clips show the opposite: a narrow line on a face (planks, ropes, ladders, ridge) with a visible drop beside it.

## 2. Reference breakdown (short)
**OBSERVED**
- *(Fall 2 evidence removed 2026-10-20 per the approved plan: that clip is not in `references/` — see `design/references-intel.md` §8. Plank walkways / hanging bridges stay optional set pieces only.)* Clips 2-6: K2-style per captions/cards (`references-intel.md` §8.2).
- K2: slope-walking beside fixed ropes (red/orange/blue), a ladder over a crevasse, a ridge above a cloud sea, tumbling and sliding falls in snow and scree, whiteout, blizzard, a night headlamp climb, floating camp labels, a dense HUD panel, a hotbar, a gear shop with helmets/goggles/harness/backpack.
- Third-person camera behind and above; on steep slopes it looks down along the slope. Not observed: touch controls, audio.

**INTERPRETATION**
Tension comes from a narrow visible line plus a big visible void, helped by fog depth and a few set pieces, not from enemies. K2's long stretches of plain rope-walking are the thing to beat with denser set pieces. Neither reference has our colour variety, which stays a differentiator.

## 3. Decisions

### LOCKED by you
| # | Decision |
|---|---|
| 1 | **Mechanic:** custom climb state on **marked climbable faces**, with stamina. Walk up to the slope limit; designated faces (cracks, ledge strata, ropes) are climbable. |
| 2 | **Mobile controls:** stick + **auto-grab** when pushed into a climbable face + **Jump = lunge** to the next ledge. No extra buttons beyond an optional release. |
| 3 | **Wayfinding:** the route follows the rock's natural lines. Cues are objects in the world (fixed ropes, pitons, cairns, lanterns). No built trail on hard faces. |
| 4 | **Guidance, 3 layers:** (a) glowing flags/cairns at every turn, always on; (b) a Guide button that pulses a mote trail to the next marker; (c) HUD objective arrow to the next camp. No continuous glowing line by default. |
| 5 | **Slip / stamina out:** you slide with a **catch window** (re-grab if you act in time). Miss it and you drop to the **last checkpoint** (decision 8 unchanged). No HP damage; unbanked cargo follows the locked loss rule. Out of stamina = lose grip and slide. |
| 6 | **Easy route:** "gentle but alive": a trail linking rope scrambles, railed ledges and one real view-down moment, ~25% hands-on. |
| 7 | **Hard routes:** Cliff Ledge Line and Spire Ridge are **~75%** on faces, ledges and ropes. |
| 8 | **Suspense tools:** exposure and depth; weather and visibility; the already-locked hazards stay (falling trees, rockfall, gusts, avalanche chutes, scaled by route). |
| 9 | **Camera:** auto-frames the drop while climbing; the player can override. |
| 10 | **Stamina:** rest ledges refill fast. Improving stamina is a **Training Yard** minigame as a **new annex outside the frozen Foothold**, added later. |
| 11 | **Oxygen:** an optional **canister consumable, no oxygen meter** (V2 "no oxygen meter" approval holds). |
| 12 | **Equipment:** a small earned kit **plus a K2-style gear shop** (cosmetic helmets, outfits, goggles). |
| 13 | **Weather:** **dynamic day/night + weather** with mobile quality tiers; the prototype measures mobile cost first. |
| 14 | **Co-op:** shared fixed ropes plus a rescue assist. No tether between players in v1. |
| 15 | **Collision:** players pass through each other on climbing faces and marked ledges. |
| 16 | **Route time:** keep **25–30 min skilled** (~60 min first-time on the easy route). |
| 17 | **Keep:** Foothold and the 4 route gates stay as built. Everything else on the mountain may be improved in look, quality and feel. |
| 18 | **First prototype:** one short **Cliff Ledge Line first section**, at hero quality, for your review. |
| 19 | **Polish scope:** improve look, quality and feel across the whole mountain (a touch-up everywhere, not only the routes). Details are mine, derived only from the clips, your answers and the docs. |

### PROPOSED by me
- **Climb controller:** faces are authored rock-face assemblies tagged for climbing (parts/CSG, collision-safe) in front of terrain, re-sculpting flanks only where hard routes need real cliff. Move along the face plane from the stick, auto-attach within ~2 studs, Jump lunges ~6–10 studs for a stamina cost, a release drops you. Bots must drive the same controller to produce times.
- **Stamina (tuning targets, not final):** ~25–35 s of continuous climbing per full bar; rest ledges every ~20–40 s on hard faces and 60 s or more on the easy route; full refill in ~5–8 s on a ledge. The easy route never makes stamina the limiter.
- **Slip/slide:** catch window ~1.5–2 s, re-grab by pushing into the face with stamina above zero. A drop under ~15 studs onto a ledge is a stagger only. A real fall respawns at the last checkpoint. Check the existing fall threshold in `CC_CheckpointService`.
- **Share of hands-on time:** Shepherd ~25%, Waterfall Stair ~50% (inferred), Ledge and Spire ~75%.
- **Camera:** auto-frame with `Humanoid.CameraOffset` and an FOV tween, not by replacing the camera module (mobile-safe).
- **Equipment kit:** ice axe, crampons (ice faces), headlamp (night climbs), oxygen canister (lower stamina drain in the high zones). Earned through progression and the Forge, visible on the avatar, changing route choices rather than raw stats. The shop is a UI on the existing Market/Forge, so the Foothold is not changed.
- **Training Yard:** capped, diminishing gains so it cannot be ground forever (§9 "no endless grind"). Not in the prototype.
- **Night:** needs the headlamp on hard routes; markers still glow so nobody is lost.

## 4. Conflicts and how they were resolved
| Item | Resolution |
|---|---|
| Timed hazards (LOCKED #9) not picked in a suspense list | You chose to keep them as locked. |
| Stamina not picked as suspense but the mechanic uses it | Stamina is a mechanic, not a suspense tool; out of stamina = slide. |
| Catch ledge vs LOCKED decision 8 (last checkpoint) | You chose last checkpoint only. Decision 8 stands unchanged. |
| Oxygen vs approved "no oxygen meter" | Canister consumable, no meter. |
| Dynamic day/night + weather vs LOCKED mobile-first (30 FPS floor) | Dynamic with quality tiers; the prototype measures the cost before commit. |
| Training Yard vs frozen Foothold | A new annex outside the footprint, built later. |
| Gear shop vs §9 economy | Cosmetics are approved; currency and prices are OPEN. |

**No LOCKED item is reversed.** Proposed `master.md` edits (not made until you approve this file): scope §3 "every major trail has shoulders and signs" to the easy route and camps; rewrite Shepherd's Road character; mark "stamina vs no stamina" decided (stamina, yes); add the climb state, guidance layers, canister, kit, shop, Training Yard annex and dynamic weather; supersede the V3 "wide stamped trails" route form.

## 5. What stays, what is rebuilt
- **Stays:** Foothold + 4 gates; Ring Mountain identity, 5 regions, 4 route names and intensity ladder; 4 camps; checkpoint/hazard runtime (`CC_CheckpointService`, `CC_AscentClient`), reused and extended.
- **Rebuilt:** the physical form of all 4 routes; hard-route trails; flank terrain where cliff faces are needed. Shepherd's open trail becomes "gentle but alive".
- **Improved everywhere (late):** look, lighting, materials, dressing, per decision 19.

## 6. OPEN
- Gear shop currency, prices and what is earned vs bought; Training Yard exact gain curve and cap.
- Real stamina numbers (set in the prototype, measured).
- How the first-Rare nook on the easy route moves with the rebuilt route.
- Whether avalanche chutes fit as a face hazard or a crossing; descending/two-way rules on the Ledge route.
- Mobile device targets (Studio emulation is not a phone).
- Whether `generate_mesh` is good enough for hero rock faces; unverified, to be tested in the prototype, never assumed.

## 7. Phased build outline
Every phase: checkpoint first, checksum src vs Studio, playtest, screenshots in `evidence/v4_P<n>/` (rejected kept with `9x_`), then **STOP**.

**P0 Safety (small):** checkpoint `PreV4_<date>` in `ServerStorage.CC_Checkpoints` and a file copy; baseline instance/FPS numbers from V3.

**P1 Prototype: Cliff Ledge Line, first section (~60–90 s, hero quality)**
- Contents: authored rock face with strata ledges; a 3–4 stud ledge; a fixed rope; one plank gap; one lunge gap; one rest ledge; one rockfall lane with a tell; flags/cairns with glow and the Guide pulse; the climb controller (auto-grab, lunge, release); stamina; slide + catch window; fall to checkpoint; auto-framing camera; exposure via fog depth and a cloud layer below; one dynamic weather condition to measure cost.
- Not in the prototype: equipment, shop, oxygen, Training Yard, other routes.
- **Accept (each measured):**
  1. Controller works on keyboard and Studio touch emulation, with no stuck states in 20 scripted runs.
  2. Bot completes the section in 60–90 s, labeled as a BOT time.
  3. A forced slip, a successful catch, a missed catch and a respawn all work, and the cost of a fall is logged.
  4. No free bypass (terrain profile ±36 studs).
  5. Two-client pass-through collision verified.
  6. 3 hero screenshots at avatar scale and at phone aspect, self-reviewed against `master.md` §3 and the clips' exposure read.
  7. Studio mobile-emulation FPS and instance counts, stated honestly as emulation.
- **STOP for your review.**

**P2 Tune, then easy-route variant:** adjust from your feedback; then one Shepherd "gentle but alive" section on the same controller. **STOP.**

**P3 Routes, one at a time:** Cliff Ledge Line full → Spire Ridge → Waterfall Stair → Shepherd rework. Per route: bot run, 25–30 min skilled ESTIMATE, checkpoint spacing, hazards, two-way ledges. **STOP after each.**

**P4 Systems:** equipment kit and shop UI, oxygen canister, rescue assist and party ropes, Training Yard annex, full dynamic day/night + weather with mobile tiers.

**P5 Whole-mountain polish and mobile pass:** touch-up of every region, lighting and materials, measured mobile budgets.

**P6 Verification and report:** re-measure all routes, update `CLAUDE.md` and `master.md`, list gaps. **STOP.**

## 8. Honest limits
- The clips show results, not input; the climb controller is my design, and its feel must be tested in the prototype.
- Bot times are perfect-input times; skilled and first-time human times need your runs.
- Studio emulation is not a phone; real device numbers stay UNVERIFIED until you test.
- A dynamic weather system on mobile is the biggest performance risk in this concept.

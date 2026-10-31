# Stampede Spire: finish plan (locked 2026-10-29)

Goal: take the mountain from "3c" (BOT 13/13, 99 meshes, 264,690 tris, place SHA 5c96ad64…) to done and polished, including final creatures, rarity, mythics, weather and wind.
Background: `MORNING-REPORT.md`, `TEST-LOG.md`, `art/LOOKDEV.md`.

## Owner rules (unchanged)
- Never touch Climb & Collect (its repos, or Studio PID 16472).
- No publishing, no Robux.
- Every visual value traces to an approved sheet via `art/LOOKDEV.md`; there is no house style. Anything that can't be traced gets deleted.
- Each MeshPart is ≤10k tris and ≤2048 studs per axis.
- `src/` == Studio, byte for byte. Tunables go in `SS_Config`.
- Concise replies. Decisions go through AskUserQuestion with the recommendation first.
- After each milestone, update the Obsidian note (`Inbox/Stampede Spire concept (2026-10-29).md`).

## Locked decisions (owner, 2026-10-29)
| # | Decision |
|---|---|
| D1 | **Uploads: blanket OK** for private assets (mesh re-imports, zone-4 skybox texture, creature meshes, Animation assets). Every upload is listed in the milestone report. Never publish. |
| D2 | **Scope includes all 20 final creature species** from the r2 sheets, plus fixes for pop-back and lane overlap. |
| D3 | **Gentle plan-view bends: yes, done first**, before the visual polish. |
| D4 | **Old uploads are kept.** At the end, list the asset IDs no longer used, so the owner can clean up in Creator Hub. |
| D5 | **The values chosen overnight** (light brightness, fog, bloom, particle rates, Neon, the Gotham font) **are reviewed at each zone's sign-off**: show the zone next to its r2 sheet; the owner approves or vetoes. |
| D6 | **In scope:** wind gusts at the peak, rarity tiers (Common / Rare frost coat / Epic ice armour / Legendary aurora), weather mythics (Aurora Stag, Fogwraith Elk, Stormhorn Ibex, Prism Ram) and their weather events. **Out of scope:** multiplayer herd sync. |
| D7 | **Run mode: autonomous.** Stop only for zone sign-offs, sheet approvals, the real-phone test, or a missing product decision. |
| D8 | **Rarity and mythic visuals come from new r3 sheets** in the r2 style, approved before any build. Round-1 sheets (01–05) stay unused. Confirm with the owner before spending image-generation credits. |
| D9 | **Creatures are Blender skinned meshes** with uploaded private Animation clips (gallop, idle, swap/jump, faceplant reaction). |

## Milestones (in order)

### M4: Phone UI + ride camera (S, src only)
- Debug readout off by default (`SS_Ride.client.luau:538`), behind an `SS_Config` flag.
- The title card and HUD never overlap on phone. Swap hint resized and moved off the lanes.
- Name-tag decluttering: limit how many show, stack offset, fade.
- Ride-camera occlusion: never inside a creature or wall; next-lane creatures fade or are pushed back.
- Done when the Device Simulator (phone landscape) screenshots for each zone are clean and BOT is 13/13.

### M5: Gentle plan-view bends (L)
- `SS_Path` gains a plan-view curve; `sspath.py` mirrors it. Lanes, projection, herd, collision slabs and walls all follow it.
- **Check-in:** show a Blender top view and ride-camera preview of the bend amount before the full rebuild and re-import.
- Rebuild every mesh, re-import, and re-verify placement (max error 0.001).
- New BOT checks: lane-centre error on the curve, and herd stays in lanes. Keep the 3c guarantees: no border steps, props grounded within ±1 stud, skirts on every edge.

### M6: Visual polish, per zone, ending in a zone sign-off (M each)
- Z4: navy skybox from Z4 tokens (upload), taller aurora curtains, upper sky no longer black.
- Summit view: no black zone-3 slabs or tan flank behind the crown (evidence/36).
- Skirts: break up the plain bands and vertical texture streaks (evidence/44).
- Basalt columns no longer read as posts. Zone-2 light shafts no longer look like slabs at the camera.
- Z3 sun bloom washout fixed (evidence/38). Far zone-1 rock less blocky.
- **Sign-off per zone:** a side-by-side with its r2 header, plus a review of the D5 values.

### M7: Real-phone performance (M; needs the owner's phone)
- The owner runs the place on their phone; record sustained FPS and memory per zone.
- Set an LOD and draw-distance budget from those numbers (far pines, RenderFidelity, streaming mode), and set a per-creature tri/bone budget for M8.

### M8: Final creatures (L; one zone at a time, a sign-off after each)
- 20 species from the r2 sheets. Add creature tokens to LOOKDEV.
- Skinned mesh plus Animation clips (D9).
- Fix pop-back (unridden creatures recycle off-screen) and same-lane overlap (keep a gap).

### M9: r3 sheets, then rarity tiers and mythics (L)
- Generate the r3 sheets, get owner approval, and add LOOKDEV tokens.
- Build the 4 rarity variants per species, plus spawn odds in `SS_Config`.
- Build the 4 mythics and their weather events (fog, lightning, aurora/rainbow storm, re-themed to the sheets), with triggers in `SS_Config`.

### M10: Wind gusts at the peak (M)
- Zone-4 gusts push lanes or affect timing, with blowing-snow FX. Tunables go in `SS_Config`, with a BOT check.

### M11: Final pass
- Run the definition-of-done checklist below.
- List the unused asset IDs (D4).
- Final report, save the place with its SHA, Obsidian milestone.

## Definition of done
- [ ] The ride camera, summit orbit and vista cameras show no seams, steps, floating props, texture streaks or black geometry in any zone.
- [ ] Each zone's sky, light and fog match its r2 sheet side by side; the zone-4 sky is not black; every zone is signed off (D5).
- [ ] Every value traces to LOOKDEV.
- [ ] Real phone: sustained FPS and memory within the budget set in M7.
- [ ] Phone UI: nothing overlaps, tags are readable, debug readout off. The camera is never inside a creature or wall.
- [ ] All 20 species, the rarity tiers, the mythics, weather and wind are in and signed off.
- [ ] BOT fully passing (extended suite), no console errors, `src/` == Studio, place saved, every upload reported.

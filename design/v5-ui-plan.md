# v5 UI plan (interview 2026-10-21) — AWAITING APPROVAL, nothing built

Sources: user interview (this doc), code inventory of `src/runtime/*` + `src/core/*` (OBSERVED from code), `design/references-ui-index.md` + `design/ui-intel.md` (Atlas, from `references/ui/`), `design/references-intel.md` (K2 clips), `design/v5-trails-and-mountain-plan.md`. No world file, `.rbxl` or `src/` touched. Legend: LOCKED = user answer · PROPOSED = my detail · OPEN = needs a decision. Tags: OBSERVED / INFERRED. Pin ids as in the index (`f1v3_NN`, `rbx2_NN`, `rbx1_NN`, `mg_NN`).

**Reference source:** user-supplied Pinterest boards, user-confirmed (read-only; boards f1v3, RobloxF1 v2, RobloxF1, MINI G; New track skipped as scenery; 76 files saved, 65 unique, 3 of 93 pins did not render). 30 used, 19 style-only, 16 skipped; 30 unique pins BRANDED (style qualities only, never assets/logos/names). **The boards contain no in-world HUD, prompts, compass or touch layout** (OBSERVED).

## 1. Ledger
**LOCKED (user answers 2026-10-21)**
1. Boards drive popups, reveals, banners, cards, badges, summit screen. HUD **layout** from K2 clips in `references/` (img2 altitude track, new_v2/new_v3 bars+hotbar) minus oxygen/chat/leaderboard; HUD **skin** from the boards' panel anatomy (layered borders, chips, rails).
2. Rarity tier = **ornament + glow + star count** (rbx2_23, rbx1_01, f1v3_17); colour is an accent only, no colour order set.
3. Reveals are **tiered**: overlay for checkpoint, camp, level-up, Common/Uncommon claim; dim + takeover only for Rare/Epic/Mythic, hatch, summit.
4. Design **landscape phone-first** (~19.5:9, emulator 801x413), then widen to desktop.
5. Loading = live spawn view + title line + progress rail + one tip. Camera intro = 4-5 s skippable crown reveal, first join only.
6. Always-on HUD = **stamina, altitude track (KEEP), pack count, level + slim XP**; coins/found/Heartstone timers move to a tap-open status card.
7. Route Board tile = rope colour edge + glyph + difficulty ticks + time + one ENTER.
8. Banners tiered: camp arrival = tilted band (name + altitude, ~2.5 s); mini-checkpoint/cairn = small chip; rest at tent/pavilion shows a stamina-refill chip.
9. Fall-loss = compact calm centre card (lost items, drop-pack timer chip, "banked finds are safe", one button); slide/catch = "Grab!" prompt + stamina bar + edge vignette.
10. Hatch = Heartstone as card-back (shake/glow, crack, creature card with rarity chip). Collection (Hall of Wonders) = portrait card grid + "x/y collected".
11. Hazards: edge chevron + glyph chip, no text, >= 2 s before impact; whiteout/night get no UI.
12. Menus: one tabbed **Expedition panel** (Backpack, Collection, Routes/Map progress, Settings; pause inside), opened by one round top-right button.
13. Summit: small overlay, then summit card (route, time, falls) with Photo (HUD hidden, free camera) and Continue. No external share (no Roblox share API).
14. Sound: **cue slots only**; nothing chosen or sourced until references exist.
15. Round 3 exclusions still stand (no chat, leaderboard, name tags, oxygen toggle, Points shop, quest NPC, avatar gear/outfits, Spanish, handles/branding); references-only colour supersedes master §1.

**User overrode my recommendation (once flagged): "Keep and restyle" the Gear Forge/Provisions Market (Head/Eyes/Outfit), Summit Points and O2 canister button.** Recorded as **OPEN risk R1**: this contradicts Round 3 exclusions 24 (no Points shop, no avatar gear/outfits, no oxygen toggle) and master §1 monetisation (cosmetics only). Shop pins on the boards are EXCLUDED-LOCKED, so their form is style-only. Needs one explicit word: keep exclusions or amend them.

**PROPOSED (my micro-decisions)**
- System banners (store-down, reconnect, busy profile): small top band on a persistent chip row, not a takeover; copy from `CC_CoreService` MESSAGES (English only).
- Tutorial caption: ribbon chip under the top edge with step pips `n/11`; wisp and marker unchanged; Skip stays.
- Interaction prompts: replace default ProximityPrompt look with a custom `PromptUI` (icon + verb + hold ring); hold time shown by ring fill.
- Level-up: overlay burst (f1v3_26 form), emblem takeover only at milestone levels (f1v3_23 form).
- Checkpoint/summit/level text: headline max 2 words + 1 sub-line (reveal screens carry 2-4 text elements, OBSERVED f1v3_05).
- Rarity chip text + pips on every claim reveal; Common/Uncommon use a plain burst, Rare+ add rays/sparkles, Epic adds wings/spikes + strong glow, Mythic adds crown + prismatic halo + beacon call-out.
- One pooled reveal frame reused for all reveals (instance budget; no per-reveal creation).
- Minimum tap target 48 px on every button (existing Climb buttons are 46 px, raise them); `ScreenInsets` set on every ScreenGui; `UIScale` driven by viewport short side.

**OPEN**
1. R1 above (shop/gear/Points/O2 UI vs exclusions).
2. **Typeface**: FredokaOne is provisional. Boards show heavy italic outlined gradient headlines (f1v3_07, 01, 26) plus clean heavy geometric titles (f1v3_05). Roblox font catalogue is limited; headlines may need uploaded image text. Needs a decision before build.
3. Colour: Atlas hexes are eyeballed. The boards are saturated violet/gold/cyan; the K2 references are desaturated alpine. The "references-only" lock does not say which wins per screen. Needs Atlas pass on the final reference set + your call (ledger item 15 covers only the rule, not the mix).
4. Rarity **colour accent** per tier (colour order conflicts across pins) and Mythic tint (already OPEN-3 in the v5 plan).
5. Route colour per route: rope colours red/blue/black per route is INFERRED from old_e, not confirmed; locked cue colour is orange rope + coloured flags.
6. NO REFERENCE yet: hatch egg object, backpack-full / bank confirm, fall-loss tone, checkpoint banner (partial), in-world HUD pins, touch controls layout, loading/title look, audio.
7. Currency: only "Cairn Coins" (and Summit Points) exist in code; which is shown in the status card depends on R1.
8. Real phone numbers still emulation only.

## 2. Existing UI (OBSERVED from code)
HUD text-stack panel (zone, pack, level, coins, pts, found; `CC_CoreClient`), ripening timers, save banner, toasts (3 max), objective marker + edge arrow, tutorial companion line + Skip + wisp, loss card, locker card, resume button, shop card, O2 button, stamina bar, "Grab the rock!", thin-air note, Guide/Let go/Rope buttons (`CC_ClimbClient`), checkpoint toast (`CC_AscentClient`), world tags/tell/watch billboards, 8 default-style ProximityPrompts, kit signs. FredokaOne everywhere, no sound, no `UIScale`; only `CC_CoreUI` sets `ScreenInsets`. 9 `CoreFx` kinds have no client handler (welcome, ripened, recovered, packGone, locker, shop, resume, trainStart, guardian). Climb UI and checkpoint toast overlap the companion line zone (y 8 vs 56). Missing: loading, intro, Route Board, menus, collection, rarity reveal, level-up, XP bar, summit screen, photo mode, touch layout.

## 3. Per-stage screen inventory
| # | Stage | Exists | Build (LOCKED/PROPOSED) | Reference | Motion / sound cue slot |
|---|---|---|---|---|---|
| 1 | Join | save banner only | Loading: spawn view + rail + tip; intro: 4-5 s crown reveal, skip | rbx2_09, mg_03, f1v3_03 (forms); img1 (sightline) | rail fill; intro tilt, "wind"/"swell" cue slot |
| 2 | Tutorial | caption line, wisp, marker, Skip | Ribbon chip + step pips; prompts via `PromptUI` | f1v3_15 (ribbon), chips rbx2_22 | caption slide-in 0.25 s; step tick cue |
| 3 | HUD | text stack, stamina bar | Stamina + altitude track + pack + level/XP; status card on tap | img2 (track), new_v2/v3 (bars), panel anatomy f1v3_03/32 | stamina low pulse; low-stamina cue |
| 4 | Route Board | none | 4 tiles, rope-colour edge, glyph, ticks, time, ENTER | rbx2_19, f1v3_06, rbx2_09 | tile press; gate-open cue |
| 5 | Banners / camp | checkpoint toast | Band (camps) / chip (mini); rest + refill chip; Locker restyle; bank prompt | f1v3_11, f1v3_26, f1v3_15 | band slide 0.3 s, dwell 2.5 s; camp cue |
| 6 | Climb moments | stamina bar, Grab!, loss card, Guide/Let go/Rope | edge vignette, Grab! prompt, compact loss card, drop-pack chip | f1v3_11 (nearest only) | slip cue, catch cue, fall cue |
| 7 | Creature loop | toasts, burst, tags | tiered reveal, rarity ladder, hatch, collection grid, backpack-full/bank confirm (NO REF) | f1v3_17/33/24/25/16, rbx2_23, rbx1_01, rbx2_01, mg_04 | per-tier burst; rarity escalation cue; jackpot server-wide band |
| 8 | Hazards | world-space tells | edge chevron + glyph chip | none (INFERRED form) | tell cue per type, >= 2 s lead |
| 9 | System | save banner, toasts | persistent chip row + top band | f1v3_11 (form) | soft error cue |
| 10 | Menus | none | Expedition tabbed panel | rbx2_22, rbx2_14, f1v3_32 | open/close, tab cue |
| 11 | Summit | Summit Points toast | overlay, summit card, Photo, Continue | old_c, f1v3_05/23, rbx2_11 | summit fanfare slot, photo shutter |
| 12 | Mobile | partial | see section 5 | - | - |

## 4. Style rules traced to pins (OBSERVED unless marked)
- Panel anatomy: 2-3 border layers (dark outer, bright mid, light inner), header ribbon straddling the top edge, close button overlapping the top-right corner, hard bottom lip + soft shadow, glossy top highlight (f1v3_03, 24, 32).
- Buttons: primary saturated pill/parallelogram with chunky lip, secondary dark slate (f1v3_03, 05, 11).
- Reveal screen: dim + hero centre (30-45 % height) + headline above + one reward row + one CTA, 2-4 text elements, "tap to continue" idle (f1v3_01, 05, 23, rbx1_12).
- Tier ladder: ornament complexity + glow + stars escalate, same base shape (rbx2_23, rbx1_01, f1v3_17); table in `ui-intel.md` §(b) (INFERRED mapping).
- Lettering qualities (heavy, outlined, gradient headline; clean heavy title) from `ui-intel.md` §(d); no face named (OPEN-2).
- Colours: only from `ui-intel.md` §(a) hex estimates (eyeballed) and `references-intel.md` §4; nothing invented; per-screen colour mix is OPEN-3.

## 5. Mobile notes (PROPOSED)
- Design 801x413 landscape first; every ScreenGui `ScreenInsets = DeviceSafeInsets`; `UIScale` from `min(viewport.X/1280, viewport.Y/720)` clamped; min tap 48 px; bottom-right thumb cluster (Guide/Let go/Rope/Expedition) clear of the stamina bar and companion line; top-left altitude track + level; top-centre banners; no persistent element within the bottom-centre jump/move zone.
- Keep one pooled reveal frame, no per-reveal ScreenGui creation; particles via UI sprites, no 3D burst in the UI path; tier-down on mobile (rays/confetti count) with the +15 % instance cap and 30 FPS floor from the v5 plan.
- Existing overlap (Climb UI, checkpoint toast, companion line) resolved by a single `UILayout` slot map.

## 6. Components (PROPOSED list)
`UILayout` (slots + safe area + scale) · `Panel` · `Ribbon` · `Chip` · `PillButton` · `Rail` (progress/altitude) · `PromptUI` · `Toast/Banner` (tiered) · `RarityFrame` (5 tiers) · `RevealCard` (pooled) · `LevelUp` · `CardGrid` (collection) · `ExpeditionPanel` (tabs) · `RouteTile` · `SummitCard` · `PhotoMode` · `EdgeCue` (hazards/objective) · `LossCard` · `SystemChip`. All client-only (`src/runtime/*.client.luau` + a new `src/ui/` module tree), no world files.

## 7. Proposed phase slot in the v5 plan
UI is client-only and can run **beside** the world rebuild as long as it does not touch world files and sequencing with the other chat avoids `CC_CoreClient` edit collisions.
- **U0 (before P1, after your approval):** foundation: tokens from Atlas, `UILayout`, component kit, remove/relocate overlapping elements, typeface decision. Checkpoint + file copy.
- **U1 (with P2 Shepherd):** HUD, prompts, tutorial caption, banners, loss card, Route Board, Expedition panel, system chips. Playtest on bots + emulator.
- **U2 (with P7 fog/cloud sea + P8 jackpot):** rarity ladder, reveals, hatch, collection grid, summit card + photo mode, hazard cues (needs P4 hazards).
- **U3 (inside P9 mobile pass):** phone measurement, tiering, audio cue wiring if references exist.
Each phase: evidence `evidence/v5_U<n>/`, then STOP.

## 8. Acceptance (PROPOSED)
Every screen at 801x413 and 1920x1080 with no clipped/overlapping element; 48 px targets; reveal pooled (0 new ScreenGuis per reveal); tutorial bot + B checks 12/12 + A1 12/12 still pass; no UI element traces to an excluded feature unless R1 is amended; every colour/lettering choice traces to a pin id.

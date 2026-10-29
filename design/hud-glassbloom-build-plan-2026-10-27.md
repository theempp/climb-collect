# Glassbloom HUD build plan, 2026-10-27

Architect plan. No code in this doc. Target: the owner-approved board `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` (artifact AnNnRCZqNRybd77HdoMbzE) plus the decisions in memory `hud-revision-decisions`, `overhaul-plan-decisions` and `egg-loop-decisions`. Do not reopen settled decisions: core buttons stay clear, the chase dock is 3 buttons at 25 %, the carry portrait sits right of the dock, and the shop is approved as drawn.

## 0. Ground rules
- **Branch:** `codex/hud-glassbloom`, cut from `codex/hud-v2` at `f6da03b`. Commit at each stop point.
- **Place:** `outputs/ClimbCollect.Glassbloom.Review01.rbxl` is a byte copy of `outputs/ClimbCollect.HUDv2.Review01.rbxl`. Copy it only after its SHA256 matches `2a3bff90935f2930418cc3f164f0a1d7e9915a11c0c4eb09083a4c7527bc6343`. Never save over the base, PhoneCandidate02 or any published place.
- **Studio window:** the window that published "HUD v2 Review" is now linked to PlaceId `112921656767061`, so Ctrl+S there writes to Roblox. Open the new copy in a fresh window with File › Open from File. Assert `game.PlaceId==0` before any save.
- **Pipeline:** P0 setup (inline) → atlas → component-builder → motion → design-reviewer. Each specialist gets one task at a time. No backend specialist is installed, so the small server edits in P2 are done inline by the main session, one task at a time.
- **No products:** no product creation, no live prices, no Robux. Every Robux button has product id 0 and stays disabled with a "Coming soon" state. Prices on the board are proposals.
- **Design values:** only from the board and `design/vfx-ui-intel-2026-10-27.md`, transcribed by atlas. Builders never invent tokens. If atlas hasn't covered a piece, the builder stops and asks.

## 1. Code facts that change the brief
| Brief assumes | Code reality (file) | Consequence |
|---|---|---|
| Level/XP ring for the player | There is **no player level or XP**. Only per-creature XP exists (`Rules.addXP`, team XP on section entry and landmarks in `Main.server.luau`) | Owner decision D1 |
| Carry start / stolen / re-grab signals | The client gets the full profile in `state`: `run.phase` (`breaking`/`revealed`/`carried`) and `run.stolenFrom`, set by `RunRules.receive`. Knock, loss and safe outcomes arrive only as free-text toasts (`CarryVisuals.show`, `Bats.lua` notify). An expiry auto-return calls `adopt` for the original carrier | Carry start and re-grab can be derived on the client (re-grab = `stolenFrom` equals my previous run id). Knocked vs lost vs safe needs a structured event |
| Guardian awake | `Encounters.Guardian_k` carries `GuardianState` (`approaching`/`pursuing`/`resting`/`defending`) and `TargetUserId` (`Guardians.luau`). The server also toasts "X heard your strike!" | Readable on the client. A structured event is still recommended (timing, name, section) |
| Distance to the safe gate | `SanctuaryExits` parts exist in the world (1–3 of them, transparent). There are no exit positions in `context` | The client can measure them because streaming is off (`Arrival.client` asserts `not StreamingEnabled`). Adding them to `context` is recommended so this survives streaming |
| Section, checkpoint, altitude | Client: root Y + `GuardianBounds` give the section (`Controller.luau`). `p.checkpoint` and `ui.nearCheckpoint` come in `context`. There are **6 sections and 18 checkpoints**; the board draws 5 nodes | Rail node count goes to D10 |
| Sanctuary vs mountain | `ui.inSanctuary` and `ui.atHome` arrive in `context` | Enough as is |
| One message system | The server sends untyped strings: `send(player,'toast',text)`, about 40 call sites | Needs a tier classifier on the client plus typed events for the key moments |
| HUD = coin, gear, rail, dock, orbs | The current HUD also has **team slots 1–3 (combat specials), Context action, Dodge, Ability, boss battle bar, hint card, journey card, quest tracker, timer and Menu sidebar**. Guardian and wild battles exist (`Combat.luau`) | The board has no battle state (D3), no context action (D4) and no route to 4 of the 8 hubs (D2) |
| Jump orb on the board | Jump is Roblox's native `TouchGui.JumpButton`. Sprint is a separate ScreenGui `MountainSprint` with Shift hold or touch toggle | D5 |
| Settings rows on the board | Prefs today: `reducedMotion, largeText, highContrast, simplifiedVFX, musicVolume, sfxVolume, hints`. `UIProtocol.settings` only accepts bool values or numbers in 0–1. Camera shake does **not exist** in the game. Graphics quality and camera speed are probably not writable by game scripts (check in P0) | New prefs must be bool or 0/.5/1 enums. D11 |
| Shop | Today: Bats (real coin upgrades and equips), Cosmetics and Convenience. Convenience shows the promise tiles **"No paid odds / No capture edge"**, which the board's Robux eggs and Egg Luck contradict | D8. The real bat upgrade flow must survive (the board's note says bat levels are earned with coins) |
| Fonts | Board CSS renders `.btn` and prices in Luckiest Guy. Bangers appears only in board chrome. Roblox has FredokaOne only (no 500/600 weights) | D12. Weight contrast comes from size and opacity |
| Tooling | `sync_hud.py` asserts each target module already exists, so it cannot create new ones | Extend it in P0 to create missing ModuleScripts |

## 2. Roblox limits → chosen approach
| Board feature | Approach (recommended) | Upload? |
|---|---|---|
| Frosted glass (`backdrop-filter`) | Frame at about 0.4 transparency + 2-stop violet UIGradient + UIStroke rim + 2 px top highlight frame + offset dark "lip" frame. No blur | no |
| Glow (`box-shadow`) | One soft radial-glow ImageLabel behind orbs, CTAs and rarity cards, tinted per use | yes (1) |
| Menu backdrop blur | Tint frames only (board `mtint`). Lighting BlurEffect is a world blur with mobile cost, so none | no |
| Conic rings (XP, distance, boost timer, ladder) | **Two half-clip frames.** Each holds a circular Frame with a UIStroke ring; a UIGradient under the stroke uses a hard 0/1 transparency step; tween its Rotation 0–180° per half. One `W.ring(value)` helper. Spike it in P3; fallback is a ring PNG | no (fallback 1) |
| Rotating rays (shop panel, hero) | Rays PNG + Rotation tween | yes (1) |
| Starburst bonus | 3 squares rotated 0/30/60° give a 12-point star, matching the board's polygon | no |
| Shield pass card / round-top boost card / ticket notches / ribbon tails | 9-slice ImageLabels (`SliceCenter`) rendered from the board CSS so every shape traces to the board | yes (4) |
| Sparkle flare (`.fl`) | 2 thin rotated frames with a centre-bright UIGradient | no |
| Pink edge vignette (radial) | 4 edge frames with linear transparency gradients | no |
| Gradient text (RUN!) + text stroke | UIGradient on the TextLabel + UIStroke (Contextual). Offset drop-shadow label for display titles only (≤6 on screen) | no |
| Holographic hero border | UIGradient Offset tween on the hero frame | no |
| Sticky hero | Hero sits **above** the ScrollingFrame. When `CanvasPosition.Y>8` it switches to the one-line state and the ScrollingFrame top shrinks | no |
| Scroll bottom fade | Overlay frame at the bottom of the scroll viewport, gradient to the panel tint, hidden at the end of the content (no masks in Roblox) | no |
| Visible scrollbar | `ScrollBarThickness` 6, solid pink thumb (no gradient thumb) | no |
| `clip-path` egg | Existing `egg` icon id + "?" label + ellipse plinth frame | no |
| Safe-gate beacon | BillboardGui (AlwaysOnTop, distance-scaled) on the nearest `SanctuaryExit`. Screen-edge arrow when the gate is off screen (`WorldToViewportPoint`, 10 Hz) | no |

**Upload set (D9):** about 7 PNGs: radial glow, rays, shield card, round-top card, ticket, ribbon tails, plus a fallback ring. Atlas renders them from the board CSS. Owner approval is needed, then they go through Studio Asset Manager on the owner account (no Robux). The 17 existing icon ids stay.

## 3. Structure (fewest files)
- **Edit:** `client/UI/Theme.luau` (Glassbloom tokens, legacy keys kept as aliases), `Widgets.luau` (Glassbloom kit), `Controller.luau` (wiring only, HUD body moves out), `Screens.luau` (panel frame + reskin, shop body moves out), `Feedback.luau` (becomes the 3-tier message host; name kept for stability), `client/Sprint.client.luau` (orb look, hold/toggle pref), `shared/UIPresentation.luau` (`P.hudLayout` rewrite), `shared/UIProtocol.luau` (new prefs), `tools/hud_overflow_audit.client.luau`, `tools/hud_state_audit.client.luau`, `tools/rmcp/sync_hud.py`.
- **New:**
  - `client/UI/Hud.luau`: HUD states rest/carry/chase/sanctuary/battle, plus dock, rail, carry portrait, edge arrow and beacon.
  - `client/UI/Shop.luau`: Shop hub body.
  - `client/UI/Motion.luau`: **the one motion-tokens module**. It holds named durations and easings and the `Motion.play(instance, token)` API. Only motion edits it.
  - `shared/HudState.luau`: pure functions. Profile + context + observations → HUD state, carry/re-grab detection, message tier map.
  - `tests/hud_state.luau`.
- **Server (P2, additive):** `Main.server.luau` (`hud` event payloads, exit positions in `context`), `CarryVisuals.luau` and `Bats.luau` (typed events next to the existing toasts), `Guardians.luau` (alert event). No rule changes.
- **Animation hook rule:** builders set the attribute `Motion="<token>"` and build the static end state. Motion wires the tweens. Builders write no tweens.
- **Drift flags:** delete the quick tiles, Menu sidebar, journey card, quest tracker, timer and centred team strip outright (no dead code). `hud_layout.luau` has 8 references to them that must be rewritten. Mountain tools do not reference them (grep is clean).

## 4. Phases

### P0 · Setup and baseline (inline, main session)
- **Work:** create the branch. Verify the base hash, make the byte copy and open it in a fresh Studio window (`PlaceId==0`). Extend `sync_hud.py` to create missing ModuleScripts and to include the new files.
- **Baseline captures:**
  - All tests pass (hud_layout 288, ui_presentation 46, ui_client_state 50, ui_protocol 42, ui_server).
  - Overflow audit shows 0 errors on the copy.
  - HUD `#gui:GetDescendants()` per state.
  - 10 s frame sample at the iPhone 16 Pro emulator size.
- **Checks:** whether `UserGameSettings` quality and sensitivity can be written by scripts; whether a UIGradient under a UIStroke rotates correctly.
- **Done:** copy hash recorded, baseline JSON in `evidence/hud_glassbloom_2026-10-27/p0/`, check results noted in the handoff.

### P1 · Atlas: Glassbloom intel
- **Output:** `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md`, containing:
  1. Theme token table (colours, transparencies, radii, stroke widths, font roles, text sizes at S/M/L, rarity 4-colour map onto the 6 tiers), each value cited to a board selector.
  2. Component map: each board builder (`B.tr/rail/dock/orbs/cp/edge/beacon/toast/bnr/moment/cpop/run/pcard`, `panel/tabs/card/buy/cpk/pass/bst/egg/skin/row/sl/tog/seg`, hero, ladder, ticket, wallet, reveal strip) → Roblox primitives per §2.
  3. Containment rules (§5) as numbers.
  4. Message tier map (event → tier, slot, duration).
  5. Upload sheet (PNG specs, 9-slice centres).
  6. A motion token list (names and durations only). Motion owns the values' implementation.
- **Done:** every value traces to a board line. Open gaps are listed, not filled.
- **STOP 1 (owner):** approve tokens, upload set (D9) and decisions D1–D12.

### P2 · Data and signals (inline, after STOP 1)
- **Work:**
  - `HudState.luau` + `tests/hud_state.luau`: carry start, re-grab via `stolenFrom`, chase on/off, section change, checkpoint touch, XP gain diff, sanctuary flag, tier classification of legacy toasts.
  - Server `hud` event kinds on the existing RemoteEvent (no new remote): `carry`, `regrab`, `knocked`, `lost`, `safe`, `alert{guardian,section}`, `calm`.
  - `context.exits` positions.
  - Player-level source per D1.
  - New prefs in `UIProtocol` (bool or 0/.5/1): `cameraShake`, `hudScale`, `altitudeRail`, `sprintMode`, `effectsTier`.
- **Done:** ui_protocol, ui_server and hud_state tests pass. Existing toasts still fire (backward compatible). No change to raid, theft or save rules.

### P3 · Component-builder: kit
- **Work:**
  - Theme rewritten to atlas tokens.
  - Widgets: `glass`, `orb`, `ring`, `cta` (pink→violet), `buy` (mint = Robux, gold = coins; disabled for id 0), `tab`, `sectionHeader`, `scrollArea` (scrollbar + bottom fade), `chip`, `rarityCard`, `glow`, `burst`.
  - Uploaded image ids go in `Theme.images`.
- **Done:**
  - Existing hubs render through the new kit (reskin) with overflow audit at 0 errors.
  - Ring spike verified in Studio.
  - No tweens in builder code (grep for `TweenService` outside Motion returns 0).
  - Button names unchanged.

### P4 · Component-builder: HUD states
- **Work:**
  - `Hud.luau`: topbar-right coin pill + gear (in `TopbarInset`, 44 px, flush right).
  - Altitude rail: left edge below the core zone, ends above the thumbstick zone, 30 % idle state, checkpoint label state, hidden in the sanctuary or when the pref is off.
  - Dock: 5 buttons. Creatures carries the XP ring and level badge. 3-button chase variant. XP line slot above the dock.
  - Sprint and bat orbs. No bat in the sanctuary.
  - Carry: pop-up (static frames for "CARRYING" and "GOT IT BACK", rarity tint), 52 px carry portrait right of the dock with a distance ring and label, edge arrow, BillboardGui beacon.
  - Chase vignette.
  - Battle state per D3. Context action per D4. Player card per D2.
  - `Feedback` becomes the tier host: tier 1 under the coin pill, tier 2 in the top band, tier 3 in the centre. Nothing blocks input on the mountain. The sanctuary tier 3 waits for Collect.
  - `P.hudLayout` rewritten. `hud_layout.luau` extended (§5).
  - UIProbe QA action `hudState(name)` renders fixtures (rest/carry/chase/sanctuary/battle, regrab) when `StudioAids` is on.
- **Done:**
  - hud_layout passes at 6 sizes × touch on/off × topbar on/off × large text × HUD scale S/M/L.
  - `hud_state_audit` shows 0 errors for 5 states × 3 phone sizes.
  - Chase permanent coverage at 844×390 is ≤ 12 % (board 11.0 %).
  - Rest coverage is ≤ the board's rest value + 1 pt.
- **STOP 2 (owner):** static captures, 5 states × 3 sizes, plus battle.

### P5 · Component-builder: hubs and shop
- **Work:**
  - `Screens` panel frame: gold or glass panel, ribbon title + red X straddling the edge (tagged `Overhang`), fixed side tabs, ScrollingFrame content, section headers, visible scrollbar, bottom fade.
  - Section-jump tabs whose highlight follows the scroll position.
  - Rebuild from the board: Creatures › Collection (cards with ???/Locked), Settings (board rows + kept accessibility rows per D11), Shop (`Shop.luau`):
    - wallet straddling the edge, + jumps to Coins
    - sticky Starter Pack (full and mini states)
    - free-gift ladder and daily-deal ticket per D6
    - coin stacks with bonus bursts and BEST VALUE ribbon
    - FOREVER shield passes
    - round-top boosts with timer ring
    - egg pedestals with odds bars from the **real roll table** (D8)
    - bat skins with trail preview
    - the real bat upgrade and equip section kept
  - Sanctuary hatch reveal strip.
  - The other 22 tabs get the kit reskin only (layout logic unchanged).
- **Done:** overflow audit 0 errors at 749×330, 844×390, 932×430, 1024×700, 1180×780 and 1600×860, all tabs. No horizontal scroll. Every Robux button is disabled with id 0. Gamepad can reach every tab and button.
- **STOP 3 (owner):** hub sheet captures plus shop scroll states.

### P6 · Motion
- **Work:** `Motion.luau` tokens and wiring:
  - carry pop-up 2.5 s, then shrink into the portrait
  - toast 1.5 s
  - banner 2.5 s (danger 1.5 s)
  - moment 2.5 s
  - RUN! slam (1.5 s guardian alert) with the vignette pulse
  - chase dock fade to 25 %; a tap restores 5 buttons for 3 s; full restore when safe
  - rail idle-to-bright pulse at checkpoints
  - XP line flash 1.5 s, ring tweens
  - shop rays, holo, buy-button shine (staggered), bob and wobble
  - hero mini transition, tab scroll-to-section tween, panel open and close
- **Settings gates:** Reduce effects stops every loop, and transitions become ≤ 0.15 s fades or instant. The camera-shake pref gates any shake motion adds (none exists today).
- **Done:**
  - Loop budget (§6) measured.
  - Frame sample equal to the P0 baseline or within 1 ms.
  - Reduce effects verified on all states.
  - No style edits to components (diff touches only Motion and `Motion=` attribute reads).

### P7 · Design-reviewer (read-only) → evidence → docs
- **Review:** the build against the board, state by state and size by size. Findings go back to the owning specialist, one task each.
- **Evidence:** `evidence/hud_glassbloom_2026-10-27/final/`. Captures for each state × 3 sizes plus each hub tab, audit JSON (overflow + state), test counts, perf JSON, emulator reduce-effects captures, gamepad focus capture.
- **Close-out:**
  - Save the copy (`StudioAids` false, `PlaceId==0`), record the hash, commit.
  - Docs: new `design/hud-glassbloom-handoff-2026-10-27.md` (workflow and gotchas), a top note in `climb&collect\CLAUDE.md`, and Obsidian `Climb & Collect/` Milestones + Decisions. Memory `hud-revision-decisions` updated with the settled D-items (process only).
- **STOP 4 (owner):** final sign-off. Publishing is **not** in scope.

## 5. Containment spec (port of `checkHud` / `checkMenu`)
- **Zones** use full-screen coordinates via the `MountainHUDScreenProbe` (ScreenInsets None):
  - Screen S.
  - Core zone C = `x < max(116, TopbarInset.Min.X)`, `y < max(56, TopbarInset.Max.Y)`.
  - Thumbstick T = left 30 % × bottom 48%.
  - Keep-clear M = x 28–72 %, y 24–70 %.
  - Native TouchGui jump/thumbstick rects also count as obstacles.
- **Permanent HUD:** inside S, no overlap with C, T, M or each other.
- **Transients** (toast, banner, moment, pop-up, XP line, rail label, RUN!): inside S, not touching C, may cross T and M, never take input on the mountain.
- **Menus:** panel inside S and clear of C. Every element sits inside the panel, except `Overhang` parts (ribbon, X, wallet), which must stay inside S and clear of C. ScrollingFrame children must fit its width; no horizontal canvas. `Decor` is exempt (rays, sparkles).
- **Text:** fits (`TextFits` or no overflow); touch targets ≥ 44 px.
- **Sizes:** 749×330, 844×390, 932×430 (board) + 1024×700, 1180×780, 1600×860 (existing).
- **Coverage metric:** area union of permanent HUD at 844×390 for rest and chase, the same 2 px grid as the board's `area()`.

## 6. Phone performance budget (PROPOSED, measured in P0/P6)
- **HUD at rest:** ≤ 3 looping tweens; carry distance and edge arrow updated at 10 Hz, no per-frame UI work; descendant count ≤ P0 baseline + 15 %.
- **Chase:** + vignette pulse only. RUN! is a one-shot.
- **Open menu:** ≤ 12 concurrent loops (Shop: panel rays 1, hero rays 1, holo 1, shine on ≤ 3 visible buttons staggered, bob/wobble ≤ 6). Menus are built on open and destroyed on close.
- **No ParticleEmitters in UI.** Sparkles are ≤ 6 frames. No BlurEffect.
- **Gates:** in the iPhone 16 Pro emulator, opening the Shop never produces a frame > 33 ms. Owner phones (iPhone 16 Pro and 18 Pro Max) are the real check. Low-end Android stays **unproven**; the `effectsTier` LOW setting (= reduce effects + no rays) is the safety valve.

## 7. Stability (must not break)
- **Names kept:** `MountainHUD`, `SafeRoot`, `MountainSprint/SprintToggle`, `Swing`, `Dodge`, `Ability`, `Slot1-3`, `Context` (if D4 keeps it), `HubShade.Hub.Tabs.Tab<name>`, `UIProbe` actions `open/close/tab/detail` (+ new `hudState`).
- **Also kept:** remotes and request actions, keyboard M/Tab/Esc/1-3/Q/F, gamepad ButtonSelect/B/X/Y, and `MountainReducedMotion`/`MountainSimplifiedVFX` player attributes.
- **Large text:** `T.size` + `BaseTextSize` stays the scaling path. HUD scale uses one UIScale on the HUD root, never on menus.
- **Gamepad:** dock, tabs and scroll content are selectable. Focusing the faded chase dock restores all 5 buttons, like a tap.

## 8. Risks
1. **Faded chase dock mis-taps** (owner chose it). The 25 % dock still takes input; test on the owner's phone and log it.
2. **The ring technique may not render** correctly on the UIStroke gradient. The P3 spike decides; the fallback is a ring PNG (included in D9).
3. **Copy and odds compliance:** paid eggs need true odds before purchase. The board's odds are placeholders. The "No paid odds" copy contradicts the shop.
4. **Glass layering multiplies instances** (about 5 per panel). Watch the descendant budget on the 27 tabs.
5. **Streaming:** client reads of guardians and exits rely on streaming being off. The P2 `context.exits` + `hud` events remove that dependency.
6. **Free-text toasts** may land in the wrong tier. The classifier defaults unknown text to tier 1.
7. **Accidental publish** from the window linked to the published place (§0).
8. **Scope creep in "reskin only" tabs.** The reviewer flags redesign beyond the kit.

## 9. Owner decisions needed (recommendation first)
- **D1 Level source:** no player level exists.
  - **Recommended:** a client-derived "Explorer level" from total creature XP already saved (no save change).
  - Alternatives: a new server player-XP system, or show the team lead's level.
- **D2 Hub access and ring tap:** the dock has Creatures, Map, Shop, Daily and Quests, so Discovery, Sanctuary, Social and Profile have no entry, and "Daily" has no system.
  - **Recommended:** tapping the ring opens the player card, which works as a mini launcher (Creatures, Profile, Social, Discovery, Sanctuary). Map → Mountain›Map. Quests → Mountain›Quests. Daily → Shop›Free gifts if D6 = real, otherwise hide it.
- **D3 Battle HUD:** not on the board.
  - **Recommended:** the dock hides; 3 special orbs take the dock slot; Dodge takes the bat-orb slot; Ability becomes a chip; a glass boss bar sits in the tier-2 band.
- **D4 Context action** (Strike, Pick up, Escape, Manage sanctuary).
  - **Recommended:** remove it on the mountain, since eggs already have prompts. Show a contextual orb above the bat orb only for "Pick up". In the sanctuary the dock covers it.
- **D5 Jump.**
  - **Recommended:** keep Roblox's native jump button; restyle only the sprint and bat orbs.
  - Alternative: hide the native jump and build a custom one (input risk).
- **D6 Free gifts and daily deal.**
  - **Recommended:** visual placeholders now.
  - Alternative: real server timers and rewards (new save fields).
- **D7 Coin-priced shop items** (eggs, skins).
  - **Recommended:** disabled placeholders now.
  - Alternative: build coin purchases.
- **D8 Paid eggs:** may creatures from Robux eggs join battle teams ("no paid power in raids")? May the "No paid odds / No capture edge" copy be replaced?
  - **Recommended:** paid eggs stay placeholders with odds from the real roll table; remove the contradicting copy only with your OK.
- **D9 Image uploads:** about 7 PNGs, rendered from the board, Asset Manager, owner account, no Robux.
  - **Recommended:** approve.
- **D10 Rail and units:** 6 sections + summit vs 5 drawn nodes; "m" vs studs.
  - **Recommended:** 6 section nodes + gold summit node, and display studs 1:1 as "m".
- **D11 Settings rows.**
  - **Recommended:** Graphics = the game's own effects tier (LOW/MED/HIGH). Drop "Camera speed" unless P0 shows it is writable. Keep High contrast + Hints under HUD. "Reduce effects" sets both `reducedMotion` and `simplifiedVFX`.
- **D12 CTA font:** board CSS uses Luckiest Guy for buttons and prices; the brief says Bangers CTA.
  - **Recommended:** follow the board CSS.

## 10. Handoff
- **Next specialist: atlas (P1).** Read `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` (CSS lines 44–300, builders 593–647, checks 676–707), `design/vfx-ui-intel-2026-10-27.md` and this plan §2/§5. Write `design/hud-glassbloom-intel.md` with the 6 sections listed in P1. No code, no Studio.
- **First component-builder task (after STOP 1 and P2):** rewrite `mountain/client/UI/Theme.luau` to the atlas token table (legacy keys aliased) and add `W.glass` + `W.ring` to `Widgets.luau`, verifying the ring spike in the Glassbloom copy. Done = existing hubs render and the overflow audit is at 0 errors.

## 11. Owner answers (popups, 2026-10-27) — these override §9 recommendations
- **D1 Level:** build a **new server player-XP system** (new save fields, migration, validation, tests). Adds server work to P2; define XP sources and curve in P2 and stop for owner review of the numbers.
- **D2:** player card is the launcher (Creatures, Profile, Social, Discovery, Sanctuary). Map → Mountain›Map, Quests → Mountain›Quests, Daily → Shop›Free gifts.
- **D3:** battle = specials replace the dock, Dodge in the bat slot, Ability chip, glass boss bar in the tier-2 band.
- **D4:** context action removed on the mountain except a "Pick up" orb above the bat orb.
- **D5:** keep Roblox's native jump; restyle sprint + bat orbs only.
- **D6:** free gifts + daily deal = visual placeholders.
- **D7:** **coin purchases work for real** (Meadow Egg, Candy Swirl skin): server purchase validation, coin debit, inventory/cosmetic grant, egg roll from the real odds table (odds shown = odds used), idempotent, tested. Robux items stay disabled (product id 0).
- **D8:** **replace the "No paid odds / No capture edge" copy.** Rule: creatures from Robux eggs are cosmetic/tycoon-only and never join battle teams or raids; enforce server-side and say so in the shop.
- **D9:** ~7 shape PNG uploads approved (Asset Manager, owner account, no Robux).
- **D10:** 6 section nodes + gold summit node; studs shown 1:1 as "m".
- **D11/D12:** settings rows as recommended; CTA labels and prices in Luckiest Guy (board CSS).
- **Execution:** run in a new chat from `design/hud-glassbloom-new-chat-prompt-2026-10-27.md`.

## 12. STOP 1 answers (popup, 2026-10-28)
- Atlas intel (`climb&collect/design/hud-glassbloom-intel.md`) approved as written.
- D9 widened: **11 PNG uploads** (fallback ring held), one 20-ray image.
- Touch targets: drawn sizes kept, invisible hit areas ≥ 44 px trimmed at neighbour midpoints; audits check hit areas.
- Timing conflicts: board text wins (XP line 1.5 s, pop-up in at 0.35 s, rail hold 3 s); CSS = easing shape only.

## 13. P2 owner answers (popups, 2026-10-28)
All Q1–Q8 recommendations in `design/hud-glassbloom-p2-proposal-2026-10-28.md` §1 approved (see the answer note at its top). P2 implementation is unblocked.

## 14. P3 owner answers (popups, 2026-10-28)
- G15: Robux = Roblox native purchase prompt (handles insufficient Robux top-up); product id 0 → disabled "Coming soon" (ghost). Coins = two-tap confirm (3 s); short → scroll to Coins, label "Need N".
- Save of the copy: computer use granted on retry at the save step.

## 15. P4 gap answers (popups, 2026-10-28)
- G6 battle: kit sizes. 3 special orbs = sprint-orb 54 in the dock slot (dock glass r30, gap 6); Dodge = bat-orb 52 in the bat slot; Ability = glass chip h27 above the dock; boss bar = banner glass r24 in the tier-2 slot (top 62) with a 10 px `gradAction` bar.
- G7 launcher: one row of 5 dock buttons (42, white T.9, icons 28, gap 6) under the player-card XP bar; card widens to fit (~262). Hit areas 44.
- G8 pick-up orb = bat-orb recipe 52, 10 px above the bat orb (bottom −158). G19: edge arrow only while the safe gate is off screen.
- G2 HUD scale S 0.85 / L 1.15 (one UIScale on the HUD root).
- G9 rail: nodes 12 / summit 15; rail < 110 px tall → 10 / 13. Checkpoints are not nodes; label "Checkpoint n/18 · h m".
- G5: knocked = tier-1 toast "Knocked loose!"; lost = tier-2 banner "LOST IT / <name> went home"; safe = tier-2 banner "SECURED / <name>" + dock restores; calm = vignette off + dock restores, no message.

## 16. STOP 2 (owner popup, 2026-10-28)
- HUD states approved as captured (`evidence/hud_glassbloom_2026-10-27/p4/stop2/`); next phase P5.
- HUD scale S: drawn buttons shrink but the dock/launcher on-screen pitch stays ≥ 48 (virtual gap max(6, 48/s − 42)), so hit areas stay 44; the carry portrait follows the dock's right edge (+9).

## 17. P5 owner answers (popup, 2026-10-28)
- G14: hub panels follow the board insets (24 sides, 66 top, 10 bottom) up to 850×660, then stay that size, centred.
- Real bat upgrade/equip cards: a "Bats" section right after Bat skins, reached by the Skins tab (5 side tabs kept).
- Collection: missing species from sections the player has entered = "???"; from sections never entered = Locked (padlock).
- Free gifts + Daily deal: board look (2 claimed, 1 ready, 1 timer; Ember trail ticket), inert buttons, "coming soon" in the section headers.

## 18. P5 result (2026-10-28) — STOP 3 approved
P5 built in 6 component-builder tasks (A frame, B Collection, C Settings, D Shop, E reveal strip, F reskin caveats), commits `ea8ccf1`…`f2395fd`. All §4 P5 done-checks pass (handoff "Final P5 checks"). Copy saved after P5 (SHA256 e1d1afde…17b0). STOP 3 approved (popup): hubs/shop as captured; reveal title "RARE PULL!" only for Rare and up, else "NEW COMPANION!". Next: P6 motion.

## 19. P6 gap answers (popup, 2026-10-28)
- G19 panel: open = fade + scale .96 → 1, 0.2 s ease-out; close = 0.15 s fade, then destroy. Only on a real open/close (not on refresh or tab re-render).
- G19 scroll/hero: tab tap tweens the scroll 0.3 s ease-out (a touch cancels it); Shop hero full ↔ mini 0.2 s ease-out, scroll top follows.
- G23 player card: **as rendered** — from (−115, +40) with fade, 0.2 s ease-out.
- Reveal spin title **by tier**: board "SOMETHING RARE IS COMING..." for Rare and up, "SOMETHING IS COMING..." for Common/Uncommon.

## 20. P6 result (2026-10-28) — STOP 4 approved
P6 built by the motion specialist in tasks A (Motion.luau + HUD), B (menus/shop), C (reveal) + perf/budget fixes, commits `91d8b02`, `67a7fee`, `392b8d0`. All §4 P6 done-checks pass (handoff "P6 results"); Shop open +1.0 ms vs no motion. STOP 4 approved (popup): motion as captured; first tap on the faded chase dock only restores it. Copy saved after P6 (SHA256 249a2786…705a). Next: P7 design-reviewer (new chat).

## 21. P7 design review answers (popups, 2026-10-28)
Review `evidence/hud_glassbloom_2026-10-27/final/design_review.md` (R1–R10). Owner picked every recommendation:
- R3 egg card: plinth glow only (no glow box on the egg icon).
- R4 chase vignette: board strength (CSS corner α .55 → edge `vignette.T` .45), still pulses, off under Reduce effects.
- R6 Map: undiscovered chips show "?" like Collection, at a readable size.
- R7 Dodge orb: Luckiest Guy text "DODGE" (no new upload).
- R8 coin packs: board height steps (+0/+10/+20/+38) on top of the content minimum, so packs rise left to right.
- R10 Settings › Account storage note: Studio only.
- R10 "Tycoon" renders "Ty coon" (FredokaOne spacing at ~11 px): 7 Shop strings now say "sanctuary" (kept, popup).
- R5 coin buttons outside the Shop: gold buy look, "Need N" when short, a short tap opens Shop › Coins (kept, popup).

## 22. Owner requests during P7 (2026-10-28)
- "Consistent look; settings button + coins widget cut out towards the bottom; smooth, full icons": the kit lip was a flat clipped strip, which reads as a slab on round shapes. Every lip is now the true `box-shadow 0 Y 0` crescent (opaque: a same-shape frame behind; translucent glass: a CanvasGroup rounded clip + outer-stroke ring). Widgets `lip()`.
- "Pop-ups (RUN! and more) tucked to the top as close as possible; middle clear at all times": overrides intel §4 slots and plan §5 "transients may cross M". Every mountain transient sits in the top strip (coin-pill row top when it fits between zone C and the coin pill, else just below it), scaled by one factor so it ends above M (x .28–.72W, y .24–.70H); the tests and state audit now flag transients that enter M. Sanctuary Collect sits below M (no room above it on phones).
- Popup: RUN! word and the "<GUARDIAN> IS AWAKE" pill side by side in one row (stacked would shrink the pill text to ~6–7 px). Carry pop-up shrinks/fades in place at the top while the portrait pops in (no flight through the centre).
- Custom emulator devices GB_844x411 / GB_932x430 reserve a top safe inset that clips the coin row (ClipToDeviceSafeArea); real device profiles (iPhone 16 Pro / Pro Max) don't. Final phone evidence uses the real profiles.

## 23. P7 result (2026-10-28) — STOP 4-final approved
Design review R1–R10 fixed (R9 left: world sign); owner requests (smooth crescent lips everywhere, pop-ups in the top band with the centre clear) built by component-builder tasks A–F and motion task G, verified in Studio. All checks green (handoff "P7 results"); copy saved (SHA256 9d37d9b4…688b). Publishing not in scope.

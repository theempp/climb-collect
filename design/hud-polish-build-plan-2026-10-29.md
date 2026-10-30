# HUD polish build plan — 2026-10-29

Architect plan for `design/hud-polish-plan-2026-10-29.md` (approved decisions + tasks 1–7). No code in this doc.
- **Repo:** `game/homebase-c`, branch `codex/homebase-c`.
- **Studio (owner choice, 2026-10-29):** work in `outputs/ClimbCollect.HomeBase.PhonePublish01.rbxl`, freshly opened in its own process (PID 8444, MCP id `1e40dbe0…`, PlaceId 0, Http off). The older publish window (PID 4000, MCP id `640121ed…`, PlaceId 134979185642785) is linked to the live place: never sync, Play or save there. Save the copy at the end (owner OK); no publish.
- **Evidence:** before = `evidence/hud_polish_2026-10-29/before/` (Studio i16p states, 30 hub captures, 52 phone frames). After = `evidence/hud_polish_2026-10-29/after/`.
- **Rules:** no publish without the owner's OK. Every design value comes from Theme/Motion or is an atlas gap.

## 0. Findings (what the code says)
| Item | Finding |
|---|---|
| **"Health bar / SAFE RETURN"** | The green bar (f_001, f_007; absent in f_009 at full HP) is **Roblox's native CoreGui health bar**. No HUD code draws a bar, and nothing calls `SetCoreGuiEnabled` anywhere in the repo. It shows whenever Health < MaxHealth: `Main.server.luau:137` spawns at 140/140, then `:84` raises MaxHealth from the team. The "SAFE RETURN" text is **not in any HUD source**. The only repo hits are world BillboardGuis (`world/FreeClimb.luau:53`, `world/MountainEntrances.luau:78`, `Art.luau:15` MaxDistance 115). P0 confirms it. **Nothing depends on the bar:** HudState, Feedback, tests and audits are all clean (grep). |
| **Empty gear / coin "0"** | Not a code or layout gap. `Hud.luau:102` (coin, 40 px Overhang) and `:107` (gear, 26 px) call `W.icon` → `Theme.icons.coin/gear` (non-zero ids). They render in Studio (`before/states/i16p_sanctuary.png`). On the phone **every** `rbxassetid` image is blank (f_001, f_009): tab icons, title chest, coin, gear, dock and launcher icons. Assets are AssetTypeId 1, same creator as the place, so delivery fails on device (moderation or permission). That is outside code. "0" is the real balance of a fresh profile in the Private Playtest universe. |
| **Vector fallback** | `Widgets.luau:455-501`: `W.icon` draws vector art **only when the id is 0 at build time**, not when a load fails. Fallback art exists only for some kinds: Creatures, Discovery, Mountain, Sanctuary, Shop, Profile, Social, Settings (cog), Menu, Coin, Interact. The HUD's `'Gear'`, `'Map'`, `'Chest'`, `'Calendar'`, `'Scroll'`, `'Creature'`, `'Bat'` etc. have **none**. Product question Q5. |
| **"Inventory bar"** | The Glassbloom **dock** (`Hud.luau:128-146`). It is a glass bar 250×58 at `H-10-58` with 5 circles: Creatures (XP ring + level badge), Map, Shop, Daily (dot), Quests. On device the icons are blank, so it reads as a hotbar. The game has no Roblox Tools or Backpack. |
| **Five circle slots** | The **PlayerCard launcher row** (`Hud.luau:220-224`): `LaunchCreatures/Profile/Social/Discovery/Sanctuary`, five `dockButton` 42 px circles, gap = `l.dockGap` (D2/G7). Each opens a hub and sets `cardOpen=false`. |
| **Cash / second** | **No such field exists.** The client gets the raw `profile.tycoon` through `state`, plus `production` (`Main.server.luau:434-447`, every 2 s when changed; `ClientState.luau:51-54`). The only production rate is **eggs per hour**: `Tycoon.rate(p,i)` (`shared/Tycoon.luau:41-55`) returns eggs/h and coins per egg; `Tycoon.snapshot(p).rate` (`:177`) sums eggs/h (shown as "Eggs / hour", `TycoonHub.luau:132`). Coins arrive only on collect + bank (`T.bank`, +2.5 %/banking level). Coins/s can be derived on the client: Σ(rate·value)/3600 over unlocked, assigned slots (Robux creatures already give 0). That is a **pure shared helper, with no server change**. Range: two starter Commons ≈ 0.03/s; late game ≈ 2/s (`TycoonConfig.luau:4`). Q2. |
| **Title "not centred"** | The box **is** centred on the panel: `Screens.luau:228` and `Shop.luau:103` use AnchorPoint (.5,0) at (.5,0,0,−21). On the phone, f_001 panel centre = 655 and plate centre = 656. The visible offset comes from Shop's asymmetric label inset (padL 44 for the chest, padR 20): the text sits about 12 px right of the axis, and the chest is blank on device. The plate is also oversize (h42, padX 20, `Widgets.luau:757-767`). |
| **Side tabs** | `W.tab` (`Widgets.luau:844-858`): h34, r11, label **left-aligned** (`:852`) at x 10.5. Tabs with icons reserve 22+7 px (blank on device, so the text looks shifted). Column 128 (`Screens.luau:273`), gap 5 (`:279`), hits trimmed to 39 px pitch (`:286`, STOP 1 G1). **"Accessibility" and "Convenience" are not in this build.** Longest real labels: "Achievements", "Recognition", "Leaderboard", "Field guide"; with an icon: "Collection", "Evolution". |
| **Card today** | `Hud.luau:204-224`: glass 262×124, ring 48 + creature icon, meta "Name · Lv N" FO14, XP bar h10, sub "N creatures" FO11, launcher. It is placed by `P.hudLayout` `card=rect(W/2-125, H-78-124, …)` (`UIPresentation.luau:222`), 10 px above the dock. It is class `transient`, open by default in the sanctuary (`Hud.luau:377`), and toggled by the dock Creatures ring (`Controller.luau:49`). It is **exempt from M** (tests `hud_layout.luau:171`, audit `hud_state_audit:83`). |
| **M conflict** | At 844×390 the card spans x 297–559, y 188–312, and the keep-clear M spans x 236–608, y 94–273. Any always-on card above the dock on the **mountain** breaks the owner's centre-clear rule (plan §22) at every phone size. Q1. |

## 1. Code map per task
1. **Title position:** `Screens.luau:224-230` `S:titlePlate`, called at `:267` for every hub and creature detail. `Shop.luau:100-110` `Shop.titlePlate`: gold, chest decor at (−12,−8) rot −10, U6 tails, padL 44. Other popups: `Feedback.luau:494-505` `F:confirm` (title = left-aligned W.text at 16,14 inside the dialog) and `:506-524` `F:reveal` (centred gold text). Hatch reveal title `Feedback.luau:380-386` and band moments are approved board pieces, not popups: out of scope.
2. **Pill component:** `W.ctaPlate` and `W.plateWidth` (`Widgets.luau:757-767`) sit on `ctaCore` (`:732-756`). Current geometry: h42, stroke 3, gloss, glowCta, lip 6, LG `t.menuTitle` 23, padX 20.
3. **Tabs:** `W.tab` `Widgets.luau:844-858`; `Screens.luau:272-287` (column, gap, glow margin `T.glowTabOn.b`, hit trim). `W.tabButton` (`:780-796`) is unused.
4. **Top-right:** `Hud.luau:98-110` (TopRight list: coin glass h34 r18 + gear glass 44, gap 8). Layout `UIPresentation.luau:155-164` puts it in Roblox's topbar row, flush right.
5. **Profile widget:** card build `Hud.luau:204-224`; render `:434-445`; `toggleCard` `:284`; sanctuary auto-open `:376-378`; `clearTransients` `:323-326`; `apply` `:269`; view model `Controller.luau:208-234` (name, level, xp, creatures; add cash/s); fixtures `:236-257`; card layout `UIPresentation.luau:220-222`.
6. **Expand:** Motion `pcard.open` (`Motion.luau:81`). Candidate reuse: `hero.mini` (tween .2 s out, `:92`) and `hero.fade` (.2 s, `:93`).
7. **Verify:** `Controller.luau:100-143` (topbar, native jump/stick obstacles), `P.hubPanel` (`UIPresentation.luau:284-288`), QA `tools/rmcp/qa/p7_insets`, `p7_centre`, `capture_states.py`, `cap_on_device.sh`.

## 2. Phases (one specialist task at a time)

### P0 · Inline (main session) — confirm before building
- **Health bar:** in Play on the i16p profile, damage the character. Record that the native health bar appears in the topbar row and where it sits relative to `TopRight`. List every visible ScreenGui/BillboardGui on screen to pin down the "SAFE RETURN" text. If it is the world sign, it stays (world, out of scope).
- **Assets:** check the moderation and permission state of all 17 `Theme.icons` and the 11 `Theme.images` in the Creator Dashboard. This is the separate track for risk R1; no code.
- **Baseline:** suites, overflow, state audit, coverage, descendants and perf from the current checks. Before captures already exist.

### P1 · Atlas — token confirmations (gaps: atlas picks from intel/Theme, no new values)
| Gap | Question | Existing candidates |
|---|---|---|
| A1 | Title pill height | now 42 (`.ttl` L180); 36 (`.side .btn` L186), 34 (tab) |
| A2 | Title pill padX | now 20; 12 (buy padX), 10 (chip/beacon pill), 9 (tab) |
| A3 | Title text role | keep `t.menuTitle` 23, or `t.ticketTitle` 18 / `t.btnSide` 16 if the pill drops below ~36 |
| A4 | Pill straddle | top = −h/2 (centre on the panel edge); lip 6, stroke 3, gloss, glow unchanged? |
| A5 | Shop gold pill | same geometry, symmetric text padding; chest and tails as Decor overhangs that never move the text |
| A6 | Side tab | height (34 → 30 ghost / 27 chip?), column width (128 → text-fit of the longest label + 2×padX?), gap 5, icon+label as one centred group, FO 13 |
| A7 | Compact card | from pcard L170-174: border 2 + padding 10/12, meta FO14 line 17, gap 4, XP bar h10, gap 3, sub FO11 T.15 line 13 → h ≈ 71. Width: keep 262 (launcher width, no width jump) or fit the content (2+12+176+12+2 = 204)? Cash/s on the sub line or as a right-aligned label (same role)? |
| A8 | Expanded card | compact + gap 10 + launcher 42 + 10 → ≈ 123; ring and creature icon dropped (per Q3) |
| A9 | Motion | confirm `pcard.expand` = `hero.mini` values (.2 s, out) for height, `hero.fade` (.2 s) for the launcher row; Reduce effects = instant |
| A10 | Number format | cash/s copy and decimals (depends on Q2); `P.comma` exists |
- **Done:** a short addendum in the Glassbloom intel (or the atlas doc it names) with every value cited. Gaps that stay open go to the owner.

### P2 · Component-builder (tasks A–E, in order; Studio check inline after each)
- **A · Shared title pill**
  - New `W.titlePill(panel, text, style?)` in `Widgets.luau`, on `ctaCore` plate mode.
  - Width = text + 2·padX (A2) + 2 strokes; AnchorPoint (.5,.5) at (.5,0,0,0), so it is centred on the panel's own top edge.
  - Tags: `Overhang`, Name `TitleRibbon` (kept for audits).
  - `style='gold'` = Shop recipe with symmetric padding; the chest and tails are `Decor`.
  - Replace the bodies of `S:titlePlate` and `Shop.titlePlate` with it; delete the `padL` path if nothing else uses it.
  - Per Q4: `F:confirm` and `F:reveal` get the pill on the Dialog's top edge, and the body rows move up.
- **B · Side tabs**
  - `W.tab`: label `TextXAlignment.Center`. Icon + label are laid out as one group centred in the body (icon width counted only when present); vertical centre stays.
  - A6 height and width; `Screens.luau:273/279/286` follow (column = `side`, hit trim = new pitch).
  - Active state unchanged unless the reviewer flags it.
  - Overflow audit must pass on "Achievements", "Recognition", "Leaderboard", "Field guide" and the icon tabs.
- **C · Top-right**
  - Controller: `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health,false)` once at start (pcall + short retry, the usual CoreGui race). Touch only the Health type.
  - The coin pill and gear stay as built: icons already wired, no layout change.
  - Comment the R1 dependency at `Hud.luau:98`.
- **D · Data:** a pure helper, recommended `Tycoon.coinRate(p)` in `shared/Tycoon.luau` next to `snapshot`. It is additive and the server never calls it. It returns coins/s per Q2. `Controller.liveView` adds `cash`; fixtures add a value.
- **E · Profile widget (static end states only, no tweens)**
  - `P.hudLayout` returns `cardCompact` and `card` (expanded) with the **same bottom** (H−78), so expanding raises the top and never reaches the dock.
  - Hud card: remove the ring and creature icon (Q3). The info block shows only name · Lv, XP bar, "N creatures", cash/s. The `Launcher` row hides when compact.
  - Info-block toggle `Hit` ≥ 44, gamepad-selectable, kept below the launcher buttons in Z.
  - State: `self.expanded` replaces `cardOpen`.
  - Visibility follows Q1. Recommended: compact by default where today's card shows by default (sanctuary); on the mountain the Creatures ring still opens it.
  - **Collapse rules:**
    - Tap the info block again.
    - **Tap outside:** `UIS.InputBegan` Touch or MouseButton1 outside the card's absolute rect. Read the input, never sink it: a dock or jump tap still fires its action.
    - `v.hubOpen` true, modal or reveal: collapse, and stay collapsed after the hub closes. This fixes today's reopen bug: `cardOpen` survives non-launcher opens.
    - Chase, battle or `blocked`: hidden as today.
  - Pieces carry `Motion='pcard.expand'` (frame) and `Motion='pcard.launcher'` (row).
  - Class stays `transient` (M-exempt, player-opened). The compact card in the sanctuary keeps the current exemption.
  - UIProbe: `motionDemo 'card'` = expanded; add `card 'compact'|'expanded'`.

### P3 · Motion (one task)
- **Expand / collapse:**
  - Tokens `pcard.expand` (height tween, bottom-anchored, values per A9) and `pcard.launcher` (row fade in on expand, out on collapse).
  - The first show keeps `pcard.open`. Reduce effects / LOW: instant.
  - Perf: tween the inner content or a clip, not the glass root's size every frame (the glass lip refits on AbsoluteSize; the HUD lip is a CanvasGroup). Measure both on the i16p profile.
- **Title / tab:** no new motion. Panel open/scale and `tab.scroll` already cover them. Confirm the new pill straddles correctly under `panel.scale`.
- **Done:** the loop count is unchanged at rest; worst frame within 1 ms of P0; TweenService only in `Motion.luau`.

### P4 · Design-reviewer (read-only)
Check on the i16p and i16pm profiles plus 844×390, before vs after:
- **Pills:** every pill on its panel's axis and top edge, in all 8 hubs, creature detail, and the confirm/reward dialogs (per Q4). The pill hugs its text; Shop's text is centred while the chest overhangs.
- **Tabs:** text centred both ways, equal height and gap, the longest labels fit, the active state reads at a glance, icons are not mis-centred when blank.
- **Top-right:** no native health bar, even after damage; coin pill + gear in the topbar row, clear of Roblox's buttons.
- **Card:**
  - compact shows only the 5 items, with readable numbers;
  - expanded launcher reveal;
  - never overlaps the dock;
  - collapses on tap again, tap outside and hub open;
  - does not reopen after a hub closes.
- **Mobile:** jump, sprint and bat clear; safe-area insets; Reduce-effects frames.

### P5 · Inline close-out
- Suites; overflow 174 screens × 6 sizes; state audit + coverage; `p7_insets`, `p7_centre`, tab sync; perf.
- Captures to `after/`; handoff section; Obsidian Milestones/Decisions; save Review01 (PlaceId 0, StudioAids off).
- Phone re-check needs an owner-approved republish to Private Playtest; it is blocked visually by R1.

## 3. Tests and audits to update
- **`tests/hud_layout.luau`**
  - `:196`: board card → `cardCompact` and `card` (expanded) at A7/A8 sizes.
  - `:103/:108`: launcher rects from the expanded card.
  - New, at every size × scale × topbar case: same bottom for both; card bottom ≤ dock top − 10 (never covers the dock); both inside S and clear of C and `tr`; the compact toggle hit ≥ 44 does not trim the dock buttons.
  - M exemption `:171` stays for `card`. If Q1 = also on the mountain, add an M check and expect failures (which is why Q1 is asked).
- **`tools/hud_state_audit.client.luau`:** sanctuary = compact visible, launcher hidden; new fixture `sanctuaryOpen` (expanded); `CENTRED` already lists `card`. Expect no change in coverage at rest/chase (card not permanent).
- **`tools/hud_overflow_audit.client.luau`:** add a check that `TitleRibbon` centre X = Hub centre ±1 and top = −h/2 ±1 for every hub/tab; tab labels `TextFits` with TextXAlignment Center; equal tab heights per hub.
- **New / extended suite:** `tests/tycoon.luau` (or `ui_presentation.luau` if the helper goes there):
  - empty or locked slots give 0;
  - a Robux creature gives 0;
  - the sum matches Σ rate·value/3600;
  - no mutation of the profile.
- **Unchanged:** `tests/hud_state.luau`, `HudState.luau`, `UIProtocol`, server code (except the additive helper if placed in `Tycoon.luau`).
- **Greps:** a single `SetCoreGuiEnabled` (Health only); TweenService only in `Motion.luau` (+ OffspringPresentation).

## 4. Risks
- **R1 (blocks the visual goal on device):** every image asset is blank on the phone, so the gear, coin, chest, dock and launcher icons stay empty whatever the layout. Resolution is outside code: dashboard moderation or permission, possibly a re-upload. Vector fallback only exists for id 0 and only for some kinds (Q5).
- **R2:** removing the native health bar leaves **no HP readout** while hazards and guardians still deal damage (`RaidConfig` hazardDamage).
- **R3:** an always-on card on the mountain conflicts with M on every phone (Q1).
- **R4:** cash/s values are tiny early on (≈ 0.03/s), so "per second" may read as 0.0 (Q2).
- **R5:** a tap-outside listener must never sink input or fight the thumbstick or camera drag. It reads input only and ignores the touch that started on the card.
- **R6:** tighter tabs lower the pitch below the already-trimmed 39 px; hits trim further at neighbour midpoints. Confirm against STOP 1 G1 (owner-approved trimming).
- **R7:** animating the glass size per frame refits the CanvasGroup lip, which costs frames on mobile; motion measures this (P3).
- **R8:** the task names "Accessibility" and "Convenience" do not exist in this build, so a stale reference may be in play. Fit tests use real labels and add those two as stress strings only.

## 5. Open product questions (popup; recommendation first)
- **Q1 Where does the compact widget show?** (Recommended) Sanctuary by default, as today's card does; on the mountain it stays hidden and the Creatures ring opens it. Alternative: always visible on the mountain too, which breaks the centre-clear rule unless the dock or card moves.
- **Q2 Cash per second:** no field exists, only eggs/hour. (Recommended) Derive coins/s = Σ eggs/h × coins-per-egg ÷ 3600, shown with 2 decimals. Alternatives: per minute, or per hour (early values ≈ 0.03/s), and whether to include the bank bonus and the every-10th bonus egg.
- **Q3 Drop the card's XP ring and creature icon** so compact shows only the 5 locked items, and expanded = the same + the launcher? (Recommended) yes.
- **Q4 Confirm and reward dialogs** (Abandon creature, Guardian captured): give them the shared title pill too? (Recommended) yes.
- **Q5 Blank images on device:** (Recommended) fix the asset delivery first (dashboard check / re-upload, no code). Alternative: detect failed loads (PreloadAsync status or `IsLoaded`) and show the existing vector art; that needs new fallback art for Gear, Map, Chest and others, which is a design task.
- **Q6 (confirm assumption)** "Inventory bar" = the 5-button dock, and "five circle slots" = the card's launcher row. (Recommended) yes.

### Owner answers (2026-10-29)
- **Q1:** sanctuary only (compact by default there); on the mountain hidden, opened from the dock Creatures ring.
- **Q2:** coins per second, computed on the client (Σ eggs/h × coins/egg ÷ 3600), 2 decimals. Bank bonus and bonus egg excluded (base rate).
- **Q5:** owner checks the Creator Dashboard; build keeps the existing ids; device icons flagged unverified. No fallback art.
- **Q3, Q4, Q6:** taken from the brief ("ONLY" the five items; "plus any other labels over popups"; "five circle slots underneath" the card): yes, yes, yes.
- **P0 result:** native CoreGui health bar confirmed (health 198.95/198.95 at spawn, bar shows only when damaged; `coreHealth` enabled). "SAFE RETURN" = world BillboardGui `ImpossibleMountain.ExitLantern.Label` (MaxDistance 115), projects on screen from spawn; world, out of scope. Evidence `evidence/hud_polish_2026-10-29/p0/`.

## 6. Handoff
- **Next:** P0 inline, then atlas P1 (gaps A1–A10, after Q1–Q4 are answered).
- **First component-builder task (after atlas):** Task A. Add `W.titlePill` to `mountain/client/UI/Widgets.luau` per A1–A5, and route `S:titlePlate` (`Screens.luau:224-230`) and `Shop.titlePlate` (`Shop.luau:100-110`) through it.
- **Done for Task A:** in every hub and the creature detail, the title centre = Hub centre ±1 and pill top = −h/2; Shop text centred with the chest as Decor; overflow audit 0 errors at 6 sizes; no TweenService outside Motion.

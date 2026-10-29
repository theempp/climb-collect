# Glassbloom HUD — P7 design review (2026-10-28)

Scope: 18 state captures (6 states × 844 / 932 / i16p), 32 hub captures, 15 Shop captures + reveal, P6 contact sheets. Sources: board `design/hud-board-v3/index.html` (L###), intel `climb&collect/design/hud-glassbloom-intel.md`, plan §11–§20, handoff. Settled items in the handoff (Robux "Coming soon", no hero timer, inert gifts/deal, chase-dock first tap, native jump, reveal title by tier, HUD hidden under hubs) were not re-raised.

Capture note: `review_input/shop/reveal.png` is a mid-spin frame ("SOMETHING RARE IS COMING...", band not dimmed, no result card), not the landed state. I judged the landed state from `p6/stop4/sheet_reveal.jpg`.

## Findings (most severe first)

### R1 — blocker — Menus and the reveal are inset twice from the top
- **Where:** every `hubs/*.png` (01–32) and `shop/*.png`, and `shop/reveal.png` / `sheet_reveal.jpg`. It was already present in `p5/stop3/hubs/01_Creatures_Collection.png`, so it went through STOP 3 unnoticed.
- **What:**
  - **Cause.** `Screens.luau:230-235` sizes the panel from `self.root.AbsoluteSize`, and that root is `SafeRoot` under `ScreenInsets.CoreUISafeInsets` (`Controller.luau:15-17`). The root already starts ≈78 px below the screen top, and the code then adds the board's 66 px top inset on top of that.
  - **Panel.** At 844 the panel top sits at ≈144 instead of 66 (intel §2 `panel()`, L177–179, plan §17). Its height is ≈257 instead of ≈335, about 23 % less. The Collection grid shows 1⅓ card rows where the board (`board_menus.png`) shows 2. Settings › Controls can't scroll far enough for its own tab to light up (`30_Settings_Controls.png` highlights Account).
  - **Tint.** The `mtint` shade only covers the root, so the top ≈78 px of the world stays untinted with a hard horizontal seam. The board tints the whole frame.
  - **Reveal.** The backdrop stops at the same line, so the world and the HUD coin pill + gear show above it. The board reveal is full-bleed (`board_reveal.png`). Its UIScale `min(1, W/844, H/390)` then shrinks the strip to ≈0.85.
- **Owner:** component-builder (Screens panel frame, Feedback reveal host).
- **Fix:**
  - **Panel.** Place it in screen space, the way the HUD already does with `screenRect()`: top = 66 − rootTop (in root coordinates), height = min(660, screenH − 76), still clear of zone C (§3).
  - **Shade and reveal backdrop.** Size both to the screen rect, not the root (offset Y = −rootTop, height += rootTop).
  - **Reveal scale.** Compute the UIScale from the screen height.
  - **HUD.** Hide `tr` while the reveal is open, since the board reveal draws no coin pill.
  - **Audit.** Re-run the overflow audit with the real SafeRoot offset. Today's audit resizes the root to the full screen, so it can't see this.

### R2 — major — The Shop side tab lights the wrong section when the Shop opens on a tab
- **Where:**
  - `hubs/23_Shop_Coins.png`: Coins section showing, **Eggs** lit.
  - `hubs/24_Shop_Passes.png`: Passes showing, **Eggs** lit.
  - `hubs/25_Shop_Eggs.png`: Eggs showing, **Skins** lit.
  - Correct when reached by section jump: `shop/shop_03_coins.png`, `shop_04_passes.png`, `shop_06_eggs.png`.
- **What:** This breaks the board tab-sync rule (L660, intel §2 per-menu "Tab sync"). The probable cause is `S:syncTab` (`Screens.luau:178-190`) running while later sections are still being built over several frames. A section frame that hasn't been laid out yet reports an offset ≤ the scroll position and wins. The open-with-tab path (UIProbe, and possibly the Daily dock → Free gifts and wallet "+" → Coins) lands without the highlight being held.
- **Owner:** inline (wiring).
- **Fix:**
  - **On open.** Highlight the requested tab when opening with a tab or section.
  - **Sync timing.** Skip `syncTab` while `self.sectionsPending` is set, or while the target's `sectionOffset` is nil or not yet laid out. Re-run it once after `complete`.
  - **Check.** Confirm by opening the Shop from the Daily dock button and from the wallet "+".

### R3 — major — The egg card's rarity glow shows as a rectangular box behind the egg
- **Where:** `shop/shop_06_eggs.png`, `hubs/25_Shop_Eggs.png` (blue halo on Meadow, gold on Golden, each with square corners around the 62×78 icon).
- **What:** On the board, `glow.rarity` 20 (L290) follows the egg's CSS shape. In the build, the hollow U1 is wrapped around the icon's rectangle, so a dark rounded box with a coloured rim sits behind each egg and the pedestal reads as unfinished. Intel G12 already notes that how the egg shows rarity on the icon is undefined.
- **Owner:** component-builder.
- **Fix:** Needs an owner decision (G12). Interim option that stays inside the tokens: drop the U1 glow on the egg icon and keep only the two-layer U11 plinth (L292, intel §2 `egg()`), which already carries the glow.

### R4 — minor — The chase vignette is much weaker than the board
- **Where:** `states/844_chase.png`, `932_chase.png`, `i16p_chase.png`. It is barely visible over the pale world. In `sheet_run.jpg` it only shows at the pulse peak.
- **What:** The build follows intel §2 (α .23 at the edge midpoints, ≈.41 where the frames overlap, then pulsing to .45). The board's chase frames (`board_chase.png` "After", `board_states.png`) read clearly pink, with corners at α .55 (L139). After RUN! fades, the edge glow is the only remaining chase cue ("then only the edge glow", board text), so a weak vignette loses that state.
- **Owner:** atlas → motion/component-builder.
- **Fix:** Needs an owner decision. Option A: take the edge value from the CSS corner α .55 (T .45 = `vignette.T`, intel 1c), not the derived midpoint .23. Option B: keep the current values and accept the softer look.

### R5 — minor — Unaffordable coin prices look different in the Shop and in the hubs
- **Where:**
  - Shop: `shop_06b_eggs_low.png` ("Need 2,500") and `shop_07b_batskins_low.png` ("Need 5,000") use the gold `coinBuy` look.
  - Hubs: `shop_08_bats.png` / `08b` ("120 COINS"), `hubs/08_Sanctuary_Habitats.png` ("25 COINS") and `09_Sanctuary_Upgrades.png` ("50 / 40 COINS") use a dark ghost.
- **What:** The same state (not enough coins) gets two different looks. The board (Shop caption, L242–246) says "gold buttons spend coins", and plan §14 sets the short-on-coins rule to the label "Need N".
- **Owner:** component-builder (reskin consistency).
- **Fix:** Use the `buy()` coin recipe (`coinBuy`, `glow.buyCoin`, lip `gold.lip`, LG 16) for every coin-priced action. When short, label it "Need N" as in the Shop. Keep the ghost (`W.ghostOff`) only for actions that are truly unavailable.

### R6 — minor — Map: "UNDISCOVERED" is unreadable and row titles change size
- **Where:** `hubs/13_Mountain_Map.png`.
- **What:**
  - **Chips.** 18 "UNDISCOVERED" chips are word-fit down to ≈7 px, below the smallest board text role (`t.micro` 10.5 / `t.small` 11, intel 1i).
  - **Titles.** Sibling section titles render at different sizes (Blossom Gardens ≈13, Azure Falls ≈18, Sunstone Desert ≈15) because each row fits on its own. The rhythm is uneven.
- **Owner:** component-builder.
- **Fix:**
  - **Titles.** Fit all sibling row titles once and apply the smallest result to every row.
  - **Chips.** They can't hold the word at ≥ 10.5 in their width. Needs an owner decision: a shorter label, or the padlock / "?" treatment Collection already uses (L205, plan §17).

### R7 — minor — Battle: the Dodge orb looks like a second jump button
- **Where:** `states/844_battle.png`, `932_battle.png`, `i16p_battle.png`.
- **What:**
  - **Dodge.** It uses the kit Jump icon (green up arrow, `Hud.luau:149` GAP) right next to Roblox's native jump arrow, so the two read as the same control. Nothing on the board covers this (G6).
  - **Special-orb badges.** They show "CC" / "3s" / "3", which reads like debug text.
  - **Boss kicker.** It reads "Phase 2 · 1 climber(s)".
- **Owner:** inline (icon/copy); owner decision for the icon.
- **Fix:**
  - **Dodge icon.** Needs an owner decision: an icon that isn't an up arrow (none of the 17 board icons is a dodge).
  - **Badges.** Show only the slot number (1–3), or the cooldown seconds with "s" consistently.
  - **Kicker.** Pluralise it ("1 climber" / "2 climbers").

### R8 — minor — Coin packs no longer read as "rising stacks"
- **Where:** `shop/shop_03_coins.png`, `hubs/23_Shop_Coins.png`.
- **What:**
  - **Heights.** The board offer table promises "Rising stacks", with heights 112/122/132/150 (L615, intel §2 `cpk()`). The build uses them as minimum heights under ≈141 px of content (handoff D), so the first three cards are the same height and only BEST VALUE is taller.
  - **Bursts.** The bonus burst also covers the second coin of each pile.
- **Owner:** component-builder.
- **Fix:** Needs an owner decision. Option: keep the board steps on top of the content minimum (+0 / +10 / +20 / +38 px), so the cards still rise left to right.

### R9 — polish — The rail label collides with a world sign
- **Where:** `states/844_rest.png`, `932_rest.png`, `i16p_rest.png`.
- **What:** The "Checkpoint 5/18 · 320 m" pill and the rail nodes sit directly on the world BillboardGui "Assign a creature / 0/30 production eggs", and the two texts overlap. It depends on camera position, but a player standing at the sanctuary edge will notice it.
- **Owner:** inline (world sign, not the HUD).
- **Fix:** Leave the HUD alone. Lower the sign's billboard priority (e.g. `MaxDistance`, or hide it while the rail label is showing), or move its anchor.

### R10 — polish — Copy and finish details
- **"Ty coon" gap.** FredokaOne renders "Tycoon" with a visible gap in pass/boost descriptions and section notes (`shop_04*`, `shop_05*`). The source string is correct (`Shop.luau:325,358,533`), so this is an engine kerning issue. Check whether another casing or wording avoids it.
- **Ellipsis.** The Challenges input placeholder ends in an ellipsis ("Player UserId (0 =…", `hubs/17`). Intel §3 says text must fit, with no ellipsis.
- **Level format.** The player card reads "Zoplaysroblox · Lv12" but the board meta reads "Player · Lv 48" (L173). Add the space.
- **Dev text.** Settings › Account shows a developer storage note ("Studio memory • resets when Play stops"; live builds would show "Live DataStore") as player-facing text (`hubs/31`, `Profiles.luau:12`). Hide it outside Studio.
- **Cosmetics.** The "Selected" pill sits on the APPLIED button with no gap (`hubs/11`). Separate them using the row's gap (6–8, as in `row()` controls).
- **Owner:** inline / component-builder.

## Checked and fine
- **HUD anchors.** Stable across all 6 states and 3 sizes. The coin pill, gear, dock, sprint and bat follow intel §2 positions. The bat is hidden in the sanctuary and the rail is hidden in the sanctuary (L432, L628).
- **Dock.** The 5-button glass with the XP ring, lv badge and Daily dot matches L110–115. The chase dock shows 3 buttons at T .75.
- **Carry and regrab.** The pop-up layout (kicker / LG name / hint, rarity-tinted, portrait) matches L155–160. It shrinks into the carry portrait as in the board (`sheet_carry.jpg`). The distance pill and edge arrow match L128–129.
- **RUN!** Gradient, stroke, awake pill, shock ring and slam timing match L162–168 (`sheet_run.jpg`).
- **Player card launcher and battle layout.** Both follow the plan §15 kit sizes.
- **Hub frame.** The hub frame kit is consistent across all 8 hubs: title plate, X, side tabs with the on-gradient and glow, scrollbar, section headers.
- **Settings.** Rows, sliders, seg, toggles and Reset match `board_menus.png` and L311–323 closely.
- **Shop frame.** Gold panel, rays, ribbon title with chest and tails, wallet straddling the top edge.
- **Shop sections.** Hero full and mini (L632, L659), free-gift ladder, ticket, pass shields, boost round-tops, odds bars and legend, and skin trail previews all match the board shapes.
- **Robux.** Robux buttons uniformly read "Coming soon".
- **Reveal (landed, from the P6 sheet).** Selector, dim, card-in, EPIC slam, name/chance and Collect at ≈5.7 s match L326–356. The title by tier follows plan §19.
- **Reduce-effects sheets.** Static, no loops, instant transitions.

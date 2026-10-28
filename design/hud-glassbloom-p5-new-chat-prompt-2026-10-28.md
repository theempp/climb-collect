You are continuing the approved Glassbloom HUD for Climb & Collect in Roblox. Work in `C:\Users\HOME!\Desktop\climb-collect-integration`, branch `codex/hud-glassbloom` (HEAD `a70659d` or later). P0–P4 are done and approved (STOP 2 approved 2026-10-28). Your job is **P5: hubs and shop**, start to finish, then STOP 3. Work continuously: don't pause between steps or wait for confirmation on implementation micro-decisions (make the best choice, record it in the handoff, keep going).

READ FIRST
- Handoff: `design/hud-glassbloom-handoff-2026-10-27.md` (state, Studio notes, P3/P4 results, gotchas).
- Plan: `design/hud-glassbloom-build-plan-2026-10-27.md` §0–§3, §4 P5, §5 containment, §6 perf, §7 stability. Owner answers §11–§16 override §9.
- Intel (the only token source): `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md`. Menu builders in §2: panel, tabs, per-menu content, scroll area, chips, card, hero, buy, pbtn, note, ladder, ticket, cpk, pass, bst, egg, skin, row, sl, seg, tog, wallet, shop panel, reveal strip. Also §3 containment, §5 uploads, §6 motion token names, §7 gaps.
- Board: `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` (published at https://claude.ai/artifact/AnNnRCZqNRybd77HdoMbzE).
- Code: `mountain/client/UI/{Theme,Widgets,Screens,Hud,Controller,Feedback}.luau`. The kit sits at the top of Widgets; read its header comments. On kit controls, use `fn`/`W.bind`, not `.Activated`.
- Server shop rules (P2): `mountain/shared/{ShopRules,EggOdds}.luau` and `Main.server.luau`.
- Memory: hud-revision-decisions, overhaul-plan-decisions, egg-loop-decisions.

STUDIO SETUP (first)
- Glassbloom copy: `outputs/ClimbCollect.Glassbloom.Review01.rbxl`. On disk it is the P3 save, SHA256 `f67f0edfe328741724f8bb1ccb28720b967e33a021d0b5751af97280402e6f0a`. Check it.
- Run `python tools/rmcp/rmcp.py call list_roblox_studios {}`. The last id was `6ca0e676-3401-41ad-a8ac-fc402096a2e5`; ids change per launch. If the window is gone, launch `RobloxStudioBeta.exe <path>` (never the taskbar). Assert `game.PlaceId==0`, then update the id in `tools/rmcp/x.sh`.
- Sync the branch in Edit mode: `python tools/rmcp/sync_hud.py <id> --changed f6da03b`.
- Never Ctrl+S in these windows:
  - the window linked to PlaceId 112921656767061;
  - the PhoneCandidate02 window;
  - the base place.
- QA tools:
  - `tools/run_all_tests.sh`: all 40 suites; must print `SUITES pass=N fail=0`.
  - `tools/rmcp/p3_checks.sh <id> <outdir>`: StudioAids on, then sync, play, overflow audit at 6 sizes, state audit, perf/counts, console, stop, StudioAids off.
  - `tools/rmcp/capture_hubs.py <id> <dir>`: every hub tab.
  - The device simulator is scriptable through `StudioDeviceSimulatorService` in the Edit DM. The `GB_844x411` custom device at `ActualResolution` gives 844-wide captures. Restore iPhone 16 Pro and `ScaleToPhysicalSize` afterwards.

DO NOW: P5 (plan §4), then STOP 3
Pipeline: orchestrator → component-builder, one task at a time. You run the Studio verification yourself. Builders never invent a value. If the intel lacks one (gaps G1–G23, e.g. G12 hexagon/shards, G13 filters, G14 large-screen panel max width, G16 letter-spacing, G22 Robux glyph), stop and ask me in the popup with your recommendation first. Motion is P6: builders only set `Motion="<intel §6 token>"` and build static end states. No TweenService in any touched file.

1. **Panel frame** (`Screens`):
   - Glass panel (gold rim for the shop).
   - Ribbon title and X close straddle the edge, tagged `Overhang`.
   - Fixed side tabs (128 px column).
   - ScrollingFrame content with section headers, a visible 6 px pink scrollbar with its track, and a bottom fade.
   - Section-jump tabs whose highlight follows the scroll position (intel per-menu "Tab sync" and "Jump" offsets; the tween belongs to motion, so jump instantly now).
2. **Creatures › Collection:** `W.rarityCard` grid (intel `card()` column formula), ??? and Locked cards, chips All / Owned / Missing / Rarity. Fix the Screens:281 grey gradient multiply.
3. **Settings:** board rows (`row`, `sl`, `seg`, `tog`, `pbtn`), keeping the accessibility rows per D11. Prefs come from P2 (`cameraShake`, `hudScale` S/M/L, `altitudeRail`, `sprintMode`, `effectsTier`). "Reduce effects" sets both `reducedMotion` and `simplifiedVFX`.
4. **Shop** (new `mountain/client/UI/Shop.luau`), per intel:
   - wallet straddling the edge; its + jumps to Coins;
   - sticky Starter Pack hero, full and mini states (mini when CanvasPosition.Y > 8);
   - free-gift ladder and daily-deal ticket as visual placeholders (D6);
   - coin packs with bursts and the BEST VALUE ribbon;
   - FOREVER shield passes;
   - round-top boosts with the timer ring;
   - egg pedestals with odds bars from the **real roll table** (`EggOdds`; odds shown = odds used);
   - bat skins with the trail preview;
   - the real bat upgrade and equip section kept;
   - the FAIR PLAY and TRUE ODDS note.
   Buy rules (owner G15):
   - Robux uses `MarketplaceService:PromptProductPurchase`. Every product id is 0, so these buttons are disabled "Coming soon".
   - Coin buys (Meadow Egg 2,500, Candy Swirl 5,000) are real (P2 server). Two taps: CONFIRM for 3 s. When short on coins, the shop scrolls to Coins and the label reads "Need N".
   - The Daily dock button goes to Shop › Free gifts.
5. **Sanctuary hatch reveal strip:** static end state of the landed reveal, plus a UIProbe QA fixture.
6. **The other tabs:** kit reskin only, layout logic unchanged (plan risk 8). Fix the P3 caveats:
   - mid-word breaks in small buttons ("UNDISCOVERE D" on Mountain › Map);
   - chip semantic colours;
   - the active-tab glow clipped by the Tabs frame.
7. **P5 done-checks:**
   - All suites green.
   - Overflow audit at 0 errors at 749×330, 844×390, 932×430, 1024×700, 1180×780 and 1600×860, all tabs.
   - No horizontal scroll.
   - Every Robux button disabled with id 0.
   - Gamepad reaches every tab and button.
   - State audit still at 0 errors.
   - HUD rest ≤ 726 descendants.
   - Shop-open 10 s sample with no frame > 33 ms. Menus are built on open and destroyed on close.
   - Console clean. TweenService 0 in touched files.
8. **Save the copy:** request computer use for Roblox Studio (plus File Explorer, click-only, to focus the title bar). Check that the title reads `…ClimbCollect.Glassbloom.Review01.rbxl - Roblox Studio`, assert PlaceId==0 and StudioAids==false, then Ctrl+S. Record the SHA256 and commit.
9. **STOP 3:** show me the hub sheet captures and the shop scroll states (top, mini hero, coins, passes, eggs, skins, bats) at 844×390 for approval in the popup.

HARD RULES
- No publishing, no product creation, no live prices, no Robux spending.
- Never save over the base place, PhoneCandidate02 or any published place. Never save with `StudioAids` true.
- No new uploads without my OK. The 11 shape ids in `Theme.images` and the 17 icons are already uploaded.
- Containment must pass at all 6 sizes with the board's rules (plan §5).
- Ask every decision in the popup widget, recommendation first.
- After each milestone, keep these current:
  - the plan;
  - the handoff note;
  - `C:\Users\HOME!\Desktop\climb&collect\CLAUDE.md` (Glassbloom note under the title);
  - the Obsidian vault (`Climb & Collect/Milestones.md` and `Decisions.md`, `#milestone` / `#decision` lines).
- P2 release order still holds: a build with T0 (`f92575b`) must be live before any build that writes the new pref keys.

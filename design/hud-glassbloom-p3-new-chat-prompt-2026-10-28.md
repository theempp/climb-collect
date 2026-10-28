You are continuing the approved Glassbloom HUD for Climb & Collect in Roblox. Work in `C:\Users\HOME!\Desktop\climb-collect-integration`, branch `codex/hud-glassbloom`. P0, P1 (atlas intel, approved) and P2 (data and signals, approved and built) are done. Your job is P3, the kit.

READ FIRST
- Handoff: `design/hud-glassbloom-handoff-2026-10-27.md`. It has the current state, the Studio notes and the P2 results.
- Plan: `design/hud-glassbloom-build-plan-2026-10-27.md`. Read §0–§3, §4 P3/P4, §5 containment, §6 perf budget and §7 stability. My answers in §11–§13 override §9.
- Intel (the only token source): `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md`.
  - §1 tokens and the legacy alias table (1j).
  - §2 component map.
  - §3 containment.
  - §5 upload sheet.
  - §6 motion tokens.
  - §7 open gaps.
- Board: `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` (published at https://claude.ai/artifact/AnNnRCZqNRybd77HdoMbzE).
- `design/hud-v2-handoff-2026-10-27.md`: the `tools/rmcp/` tools, how the 17 icons went through Asset Manager, the save routine and gotchas.
- Memory: hud-revision-decisions, overhaul-plan-decisions, egg-loop-decisions.

STUDIO SETUP (do this first)
- Glassbloom copy: `outputs/ClimbCollect.Glassbloom.Review01.rbxl`.
  - It has never been saved since the copy, so on disk it is still HUD v2 Review01 (SHA256 `2a3bff90…6343`). Check that hash.
  - Re-enumerate Studio. The last window was MCP id `6ca0e676-3401-41ad-a8ac-fc402096a2e5`, but ids change per launch.
  - If that window is gone, open the copy in a fresh window: launch `RobloxStudioBeta.exe <path>`. Never use the taskbar.
  - Assert `game.PlaceId==0`, then update the id in `tools/rmcp/x.sh`.
- Sync the branch into the copy (Edit mode only): `python tools/rmcp/sync_hud.py <id> --changed f6da03b`. It creates missing modules, skips StudioTests and refuses to run unless PlaceId is 0.
- Never Ctrl+S in these windows:
  - the window linked to PlaceId 112921656767061 (it published "HUD v2 Review");
  - the PhoneCandidate02 window;
  - the base place.

DO NOW: P3, then P4, then STOP
Pipeline: orchestrator → component-builder, one task at a time. Motion comes in P6 and owns `mountain/client/UI/Motion.luau`, which does not exist yet. Until then builders only set the attribute `Motion="<token>"` (token names from intel §6) and build the static end state; they write no tweens. Builders never invent a value. If the intel lacks one (gaps G1–G23), stop and ask me in the popup, with your recommendation first.

1. **Theme** (component-builder):
   - Rewrite `mountain/client/UI/Theme.luau` to the intel §1 tokens:
     - flat camelCase keys;
     - `grad*`/`glow*` prefixes;
     - `r`/`s`/`t` sub-tables;
     - `fontDisplay` (Luckiest Guy) and `fontBody` (FredokaOne).
   - Alias every legacy key per §1j.
   - Add `Theme.images` with U-ids set to 0 until the uploads land.
   - Keep the 17 icon ids.
2. **Ring spike** (component-builder):
   - Build `W.ring(value)` as two half-clip frames: a UIStroke ring with a hard-step UIGradient under it, rotated 0–180° per half.
   - P0 showed the gradient rotates with a hard step. The half-clip angle math is still unfixed.
   - Verify it in Studio at 0/25/50/75/100 % on the XP (42), carry (52), card (48) and boost (62) sizes, with captures.
   - If it fails, ask me before using the held U7 fallback ring.
3. **The 11 uploads:**
   - Render U1–U6, U8, U9, U9b, U10 and U11 (U7 stays held) as white PNG masters exactly to intel §5: size, shape and SliceCenter. Use one 20-ray image.
   - Commit the masters and the render script.
   - Import them through Studio Asset Manager › Import on my account, the same way as the 17 icons (`upload_image` only takes http URLs). No Robux.
   - Verify each id by name, type (Image) and creator, then put the ids in `Theme.images`.
4. **Widgets kit** (component-builder, `mountain/client/UI/Widgets.luau`):
   - Widgets: `glass`, `orb`, `ring`, `cta` (pink→violet), `buy`, `tab`, `sectionHeader`, `scrollArea` (6 px pink scrollbar + bottom fade), `chip`, `rarityCard`, `glow`, `burst`.
   - `buy`: mint for Robux, gold for coins. It is disabled with "Coming soon" when the product id is 0. The confirm and insufficient-funds states are gap G15: ask me.
   - Hidden hit areas ≥ 44 px, trimmed at neighbour midpoints (STOP 1).
   - Translucent lips go in clip holders (intel conversions table).
5. **Reskin** the existing hubs through the kit:
   - Reskin only, no redesign (plan risk 8).
   - Button names, remotes, UIProbe and gamepad focus stay unchanged (plan §7).
6. **P3 done-checks:**
   - All 40 Luau/py suites green. Runner: `C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe mountain/tests/<name>.luau`, plus `python mountain/tests/run_*.py`.
   - Overflow audit at 0 errors at 749×330, 844×390, 932×430, 1024×700, 1180×780 and 1600×860. Prepend `SIZES={...}` to `mountain/tools/hud_overflow_audit.client.luau`, and set `StudioAids` true only while it runs, then false again.
   - Ring spike verified.
   - `TweenService` count 0 in every file a builder touched. Today it only appears in `UI/Feedback.luau`, which becomes the message host in P4, and in `OffspringPresentation.client.luau`, which is not HUD.
   - HUD descendants at rest ≤ 726.
   - Shop-open perf sample has no frame over 33 ms.
   - Console clean.
7. **Save the copy** (end of P3):
   - Ctrl+S on the Glassbloom window only, after asserting PlaceId==0 and StudioAids==false.
   - Record the SHA256. Commit.
8. **P4 HUD states** per plan §4, then STOP and show me the states (captures at 844×390 for rest, carry, chase, sanctuary and battle) for approval in the popup.

HARD RULES
- No publishing, no product creation, no live prices, no Robux spending.
- Never save over the base place, PhoneCandidate02 or any published place. Never save with `StudioAids` true.
- The 11 shape uploads are approved (Asset Manager, my account, no Robux). Any other upload needs my OK.
- Containment must pass at all 6 sizes with the board's rules (plan §5).
- Ask every decision in the popup widget, with your recommendation first.
- After each milestone, keep these current:
  - the plan;
  - the handoff note;
  - `C:\Users\HOME!\Desktop\climb&collect\CLAUDE.md` (Glassbloom note under the title);
  - the Obsidian vault (Climb & Collect Milestones and Decisions).
- P2 release order still holds: a build with T0 (`f92575b`) must be live before any build that writes the new pref keys.

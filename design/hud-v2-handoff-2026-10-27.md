# HUD v2 handoff — 2026-10-27

Branch `codex/hud-v2` (from `codex/integration-review01`). Latest commit: `cf0ad4f` (Review02).

## State
- Design sources: `C:\Users\HOME!\Desktop\climb&collect\design\hud-v2-intel.md` (tokens, recipe, owner decisions), mocks in `...\design\hud-v2-mocks\`, approved icons in `...\design\hud-v2-icons\`, Pinterest refs in that project's `references/ui/pinterest-2026-10-27/` (the only allowed style source).
- Code: `mountain/client/UI/{Theme,Widgets,Controller,Screens,Feedback}.luau`, `mountain/client/Sprint.client.luau`, `mountain/shared/UIPresentation.luau` (`hudLayout`, mock-1 geometry), `mountain/tests/hud_layout.luau` (144 checks; old "crowded" assertion replaced by top-strip non-overlap).
- Kit: `W.candy` (outline, lip = the TextButton background, `Face` gradient, `Rim`, `Shine`, `Gloss`, Bangers `Label` mirroring `b.Text`), `W.dot`, `W.tile`, `W.progress` (pill bar), rarity `W.portrait`, panel ribbon + red close-X in `Screens:render`, purple reward modal in `Feedback:reveal`.
- Owner decisions this session: icons upload approved; rarity = keep 6 tiers mapped to 4 colours (Common/Uncommon blue, Rare gold, Epic purple, Mythic/Legendary prismatic); "match mocks closer" done in Review02.
- Tests: hud_layout 144, ui_presentation 46, ui_client_state 50, ui_protocol 42 — all pass. Phone audit (iPhone 13, 27 screens) 0 errors twice; console clean.
- Evidence: `evidence/hud_v2_2026-10-27/` (Review01) and `.../review02/` (captures, hubs sheet, mock comparison, audit JSON).

## Studio
- Place copy: `outputs/ClimbCollect.HUDv2.Review01.rbxl` (byte copy of PhoneCandidate02, SHA256 482deef4…e017 verified before copy). **Not saved since opening**; the open Studio window holds the synced Review02 source. PlaceId 0 (unlinked).
- **Do not touch** the other Studio window: it is the published Phone Candidate place (PlaceId 139426549461023).
- Studio MCP is registered only for the `climb&collect` folder, so it is not loaded in sessions started here. `tools/rmcp/` holds a stdio client for the same bridge: `rmcp.py list|call <tool> <json>`, `x.sh <file.luau>` (execute_luau in the copy; `DM=Client` during Play), `mksync.py out.luau UI/Screens.luau ...` (writes Source into the copy), `probe.luau` (UIProbe open/close/tab). Studio ids change per launch: run `python tools/rmcp/rmcp.py call list_roblox_studios {}` and update the id in `x.sh`/`mksync` calls.
- Icon preview: icons are copied to `%LOCALAPPDATA%\Roblox\Versions\version-7062aec9dbe74b14\content\textures\hudv2\` and the copy's `Theme.icons` was patched in Studio to `rbxasset://textures/hudv2/<name>.png` (**PREVIEW ONLY**). Repo `Theme.icons` stays 0 (vector fallback). `upload_image` only accepts http(s) URLs, so the real upload must go through Studio's Asset Manager › Bulk Import (owner approved the upload; owner account, no Robux), then put the ids in `Theme.icons`.
- `ReplicatedStorage` attribute `StudioAids` was set true for the UIProbe and reset to **false**. Never save with it true.
- Device sim: iPhone 13 landscape (844×390, safe root 749×330).

## Owner feedback on Review02 (verbatim intent)
Not approved yet. Refine everything: every card/widget must fit inside its popup/page (some cards spill over panel edges); neat, nothing overflowing. Redo the Shop page and the other popup hubs: currently overwhelming; focus on visuals — more art and spotlight, more creative and unique, less basic and sloppy. Re-read the Pinterest board references repeatedly.

## Known gaps
- Many hub tabs are text rows (`W.row`) — the "overwhelming" part. Shop › Bats/Cosmetics/Convenience are plain rows.
- No `???`/LOCKED cards in Creatures; no hearts (no HP system); no gem currency in the game.
- "Assign a creature 0/30 production eggs" label at the screen's left is another GUI (not MountainHUD), visible since tiles moved.
- Reward modal (purple) not captured yet.
- Not done: icon upload, saving the copy, docs/vault record (`master.md`/`CLAUDE.md`, `Obsidian Vault\Climb & Collect\Milestones.md`).

## Review03 — approved and saved (2026-10-27, later)
- **Owner-approved.** Saved in `outputs/ClimbCollect.HUDv2.Review01.rbxl` (Ctrl+S on the copy only; SHA256 `2a3bff90935f2930418cc3f164f0a1d7e9915a11c0c4eb09083a4c7527bc6343`; same 89 classes / 13,707 instances as PhoneCandidate02, uncompressed data 7.00 → 7.04 MB; smaller file only because Studio now compresses two chunks the old file stored raw). `StudioAids` false. Nothing published; PhoneCandidate02 and the published place untouched.
- **HUD (owner requests):** the top row sits in Roblox's topbar row (`GuiService.TopbarInset`, 44 px, 12 px from the top like the core buttons): Menu / Creatures / Mountain just right of the core buttons, coin pill + gear flush right; journey card moved up to the first HUD row; team slots + Manage Sanctuary centred on screen (they may sit over the dynamic-joystick gesture zone, never the visible stick or jump). `P.hudLayout(..., topbar)`, `Controller` probe ScreenGui `MountainHUDScreenProbe`.
- **Hubs:** all 27 tabs rebuilt from the pins: spotlight banners (rays + big icon, LuckiestGuy title; on short phones a full-height hero column beside the cards), offer cards (`W.card`, navy header strip, chips, pills), stat cells, milestone tracks, team/defense slot strips, ON/OFF candy toggles. Kit in `Widgets.luau` (`fit/label/card/chip/pill/stat/spotlight/spotlightColumn/track/slot`); candy labels now shrink instead of spilling. Button names, remotes, attributes, UIProbe and gamepad focus unchanged (UIProbe gained a QA-only `detail` action).
- **Icons:** 17 PNGs imported through Asset Manager › Import to the owner account (no Robux); ids verified by name, type (Image) and creator, set in `Theme.icons`; all ids fetch in play.
- **Checks:** hud_layout 288 (new rules: centred team/context, topbar row), ui_presentation 46, ui_client_state 50, ui_protocol 42. New `mountain/tools/hud_overflow_audit.client.luau` (parent containment, scroll width, text fit, touch size, text overlap) at 749×330 / 1024×700 / 1180×780 / 1600×860: 108 screens, 0 errors. Phone audit (iPhone 16 Pro emulator, safe root 750×343): 27 screens, 0 errors; console clean. The last phone-audit run had touch controls hidden by the emulator; the bottom layout passed the joystick/jump check in earlier runs.
- **Evidence:** `evidence/hud_v2_2026-10-27/review03/` (28 captures, sheets a–d, mock and Review02 comparisons, audit JSON, `00_hud_uploaded_ids.png`).
- **Tools:** `tools/rmcp/sync_hud.py <id> [--preview-icons]` (all HUD sources), `cycle.sh <id>` (stop/sync/play), `capture_hubs.py <id> <dir>` (every tab + creature detail in one MCP session).
- **Not verified:** real phone, Studio device sizes other than the iPhone 16 Pro emulator (other sizes by the root-resize audit only), reward modal capture. Repo work is uncommitted on `codex/hud-v2`.

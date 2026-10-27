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

You are building the approved Glassbloom HUD for Climb & Collect in Roblox. Work in `C:\Users\HOME!\Desktop\climb-collect-integration`.

READ FIRST
- The plan: `design/hud-glassbloom-build-plan-2026-10-27.md`. Section 11 lists my answers; they override the §9 recommendations.
- The approved board: `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` (published at https://claude.ai/artifact/AnNnRCZqNRybd77HdoMbzE).
- `design/hud-v2-handoff-2026-10-27.md`: Studio workflow, the `tools/rmcp/` tools, gotchas.
- Memory: hud-revision-decisions, overhaul-plan-decisions, egg-loop-decisions.

DO NOW: P0, then P1, then STOP
- P0 (inline):
  - Create branch `codex/hud-glassbloom` from `codex/hud-v2` (HEAD f6da03b).
  - Verify the SHA256 of `outputs/ClimbCollect.HUDv2.Review01.rbxl` (2a3bff90…6343), then byte-copy it to `outputs/ClimbCollect.Glassbloom.Review01.rbxl`.
  - Open the copy in a FRESH Studio window and confirm PlaceId == 0 before any save. The window that published "HUD v2 Review" is linked to PlaceId 112921656767061: never Ctrl+S there.
  - Record baselines: Luau tests, the overflow audit, perf.
  - Run the P0 Studio checks in the plan (graphics-quality and camera-speed writability).
  - Extend `sync_hud.py` so it can create new modules.
- P1: run the atlas agent to write `design/hud-glassbloom-intel.md` exactly as P1 specifies. Tokens come only from the board and this project's intel, never from defaults.
- Then STOP and show me the atlas tokens for approval (popup). No component building before that.

LATER PHASES (only after my approval at each stop)
- Order: P2 data and signals → P3 kit → P4 HUD states (stop) → P5 hubs and shop (stop) → P6 motion → P7 design-reviewer, evidence and docs (stop).
- The pipeline is architect → atlas → component-builder → motion → design-reviewer, one task at a time, through the orchestrator. Motion owns all animation in `mountain/client/UI/Motion.luau`.
- P2 grows because of my answers:
  - a real server player-XP system (stop for my review of XP sources and curve);
  - real coin purchases for the Meadow Egg and the Candy Swirl skin (server-validated, idempotent, odds shown = odds used);
  - a server rule that Robux-egg creatures never join battle teams or raids.
  - Robux items stay disabled with product id 0.

HARD RULES
- No publishing, no product creation, no live prices, no Robux spending.
- Never save over the base place, PhoneCandidate02, or any published place.
- Never save with `StudioAids` true.
- Shape image uploads (~7) are approved: Asset Manager, my account, no Robux.
- Containment must pass at 749×330, 844×390 and 932×430 plus the existing audit sizes, using the board's rules (plan §5).
- Ask every decision in the popup widget, with your recommendation first.
- Keep the plan, the handoff note, CLAUDE.md and the Obsidian vault (Climb & Collect Milestones/Decisions) current after each milestone.

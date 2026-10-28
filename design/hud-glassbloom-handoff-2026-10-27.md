# Glassbloom HUD handoff — 2026-10-27

Plan: `design/hud-glassbloom-build-plan-2026-10-27.md` (§11 owner answers override §9). Branch `codex/hud-glassbloom` from `codex/hud-v2` `f6da03b`.

## Studio
- Copy: `outputs/ClimbCollect.Glassbloom.Review01.rbxl`, byte copy of HUDv2 Review01 (SHA256 `2a3bff90…6343` verified before and after copy). **Not saved since copy.**
- Opened in a fresh Studio window by launching `RobloxStudioBeta.exe <path>` (no taskbar). MCP id this launch: `6ca0e676-3401-41ad-a8ac-fc402096a2e5` (`x.sh` updated). PlaceId 0, GameId 0. The window remembered the iPhone 16 Pro emulator (safe root 750×343).
- Never Ctrl+S in the window linked to PlaceId `112921656767061` or the PhoneCandidate place. Assert `game.PlaceId==0` and `StudioAids==false` before any save.

## P0 results (`evidence/hud_glassbloom_2026-10-27/p0/baseline.json`)
- Tests: hud_layout 288, ui_presentation 46, ui_client_state 50, ui_protocol 42, ui_server 25 (+ py 25), rules 121, bat_rules 27, egg_raids 21 — all pass. Runner: `C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe mountain/tests/<name>.luau`.
- Overflow audit, 6 sizes (749×330, 844×390, 932×430, 1024×700, 1180×780, 1600×860): 162 screens, 1 error (844×390 Shop/Convenience "No paid odds" tile title — removed by D8). Prepend `SIZES={...}` to the audit to set sizes.
- State audit (rest): 3 pre-existing errors (AddCoins < 44 px; Slot1 and Context over the dynamic-thumbstick zone).
- HUD descendants: rest 631 (budget +15 % = 726), Shop open 1034. Perf (emulator view, desktop GPU, 10 s): rest avg 16.6 / worst 20.0 ms, Shop open avg 16.6 / worst 18.9 ms, 0 frames > 33 ms.
- `UserGameSettings` quality and mouse sensitivity are not writable (RobloxScript capability) → Graphics = own effects tier, no Camera speed row.
- UIGradient under UIStroke rotates with a hard step → ring technique viable; half-clip angles still to tune in P3.
- `sync_hud.py` now creates missing modules (ModuleScript, LocalScript for `*.client.luau`) and skips repo files not written yet.

## P1 results (atlas)
- Intel: `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md` (623 lines, 8 sections). Every value is cited to a board line; the board's estimated token table (L566–575) loses to the CSS (same rule as D12).
- Independent audit (7 agents, about 1,290 values): 81 issues (`evidence/hud_glassbloom_2026-10-27/p1_intel_verification.json`); atlas re-checked and fixed all 81, 0 rejected (doc §8).
- Board self-check run in a browser at 844×390: 21/21 PASS, both controls fail. Permanent HUD coverage: rest 10.6 %, carrying 11.6 %, chase 11.1 % (the plan's 11.0 % is superseded), sanctuary 9.0 %, old chase 24.7 %.
- Open for STOP 1: upload set 11 vs the approved ~7; drawn controls under 44 px (proposal: invisible 44 px hit areas); timing conflicts between the board text and the CSS (XP line, carry pop-up entry, rail hold); gaps G1–G23.
- **STOP 1 approved (2026-10-28):** tokens as written; 11 uploads; hidden 44 px hit areas; board-text timings. See plan §12.
- **P2 decisions approved (2026-10-28):** player XP (40L+20, cap 50, daily caps), stolen secure 0 XP, Robux creatures earn 0 coins, Competition 5 coin wins/day, Meadow Egg 2,500 (section-1 table), Candy Swirl 5,000 (board look), TRUE ODDS / FAIR PLAY tiles, Robux odds 'TBD'. Spec: `design/hud-glassbloom-p2-proposal-2026-10-28.md`.

You are the lead owner for CLIMB & COLLECT (Roblox) in a NEW session. Today we align on everything locked for the next improved rebuild, verify the environment, and agree a plan to a publishable playtest version. This session is AUDIT + PLAN first. Build nothing and change no world file until I approve at Gate A.

HARD RULES
- Replies concise. Honesty over agreement: flag problems, don't rubber-stamp. If I pick against your recommendation, say so once, record it as an OPEN risk, don't override me.
- Every decision via the AskUserQuestion popup (max 4 per popup, recommendation first, labelled "(Recommended)"). Never ask as a prose list.
- Design values come ONLY from `references/` (incl. `references/ui/`). No house style, no invented palette/typeface. Tag claims OBSERVED / INFERRED; ledger LOCKED / PROPOSED / OPEN.
- Do not trust docs over reality: verify. Do not touch `creatures/`, `ServerStorage.CC_Creatures`, `Workspace.CC_CreatureStage1` (Codex owns them).
- Never click a Roblox icon on the Windows taskbar (it closes Studio). Save only with the Studio window visible: title bar click, Ctrl+S, check file mtime.

STEP 1: READ (in this order)
`CLAUDE.md` (all gotchas), `master.md` (§0.6-0.9, §1, §3), `design/publish-plan.md` (the checklist we start following today), `design/v5-trails-and-mountain-plan.md`, `design/v5-ui-plan.md`, `design/ui-intel.md`, `design/references-intel.md`, `design/v4-run2-log.md`, `evidence/v4_P3_report.md`, `design/decision-log.md`. Also the Obsidian vault: `C:\Users\HOME!\Documents\Obsidian Vault` -> `Home.md`, `Climb & Collect/*`.

STEP 2: LOCKED SUMMARY (tell me back in <= 15 lines what you understand is locked; I correct)
Cover: core loop (claim/bank/Heartstone, tents/lockers, drop packs, fall-loss, no HP damage); 4 routes + signatures; 25-30 min skilled, ~60 min first-time; tight natural spline trails (v5, NOT yet built); fog/cloud sea; jackpot tiers (Mythic rename); Round 3 exclusions; mobile budget (+15 % instances, 30 FPS floor); UI decisions (boards drive popups/reveals, K2 layout for HUD, ornament-led rarity, tiered reveals, landscape phone-first, lean HUD, tabbed Expedition panel, summit card + photo mode, cue slots only for sound); OPEN risks (R1 shop/gear/Points/O2 UI, typeface, colour mix).

STEP 3: ENVIRONMENT + STATE AUDIT (read-only; report as a table, OBSERVED only)
1. Studio MCP connected, correct place open, Edit mode, `HttpEnabled` off, one Studio instance, no blocking dialogs.
2. `src/**` vs Studio checksum parity (method in CLAUDE.md); list drift.
3. The latest recorded state is "Run 2 stopped at the instance cap after v4 P3 (+31-76 % streamed instances; P4 code untested)". I say the rebuild continuation is now done: find out what is really done (logs, evidence, git, file mtimes, Studio contents) and list claims vs reality.
4. Regression: A1 12/12, B checks 12/12, tutorial bot (~6 min BOT, Rare ~2:06), 0 stuck. Perf at the 6 Stage-4 spots vs baseline.
5. Repo hygiene: git has 2 commits and many untracked `.rbxl` copies and new folders; propose a commit + `.gitignore` + archive plan (don't delete anything without my yes). Checkpoints in the place <= 2.
6. Live-server safety: dev tools (DevBridge/DevRequest/bots) inert for players, no leftover HTTP.
Report problems found, ranked. Do not fix yet.

STEP 4: INTERVIEW (popups)
Settle first: (a) which 2 routes ship (recommend Shepherd + Waterfall; the other 2 get a rope/fence + "Coming soon" sign); (b) route form: build the 2 shipped routes directly on the v5 spline kit (recommended, avoids polishing v4 routes that v5 would replace) vs ship polished v4 routes and rebuild later; (c) private place + tester count; (d) anything in `design/publish-plan.md` you'd change. Then ask only consequential gaps.

STEP 5: PLAN
Update `design/publish-plan.md` with the agreed scope, order, gates and owners (use the agent pipeline: architect -> atlas -> component-builder -> motion -> design-reviewer where relevant; orchestrator routes). Add a pointer in `CLAUDE.md` (current milestone) and `master.md`, and one decision line + open questions in the Obsidian vault. Then STOP and wait for my approval at Gate A. Finish with a 5-line summary and the OPEN list.

Scope reminder (LOCKED by me): first publishable version = 2 routes to the summit, fully complete and polished; the other 2 trails visibly blocked with a "Coming soon" sign; shop/gear/Points/O2 UI hidden in the test build; publish path first, the rest of v5 after.

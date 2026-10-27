# Integrated review — October 26, 2026

## Latest: Review05 — bats and creature theft (stage 3, part 1)

`C:/Users/HOME!/Desktop/climb-collect-integration/outputs/ClimbCollect.Integrated.Review05.rbxl`, SHA256 `d9184c14c4c6e78e23e14ca502bdad428bd6dbdf0ee03b87ee0fefb6d834cb76`. Same world as Review02 (terrain bytes identical, 88/88 sources match, no QA objects). Branch HEAD `731aa1e`.

What's new (owner rules from 2026-10-26):
- Every player holds a bat. Press **F** or tap **Bat** (the button appears outside the sanctuary and outside battles). A hit sends the target flying.
- A hit on someone carrying an unsecured creature drops it for **3 s**. Anyone can grab it, the original carrier included. If nobody grabs it, it returns to the carrier. Once secured at the gate, a creature is safe for good.
- Limits: no hits in the sanctuary or within 20 studs of rest points; no hits on a player who is securing; a carrier can't swing (both arms are busy); 1.5 s swing cooldown; 8 s before you can hit the same victim again; Trial-reward creatures can't be stolen.
- **Shop → Bats**: the Trail Bat (starter) plus one bat per section. Completing a section's 6-creature index set unlocks its bat. Coins upgrade the equipped bat up to level 10 (cost 120 × level²), adding knockback and reach. Each bat takes its section's catalog colour, material and trail. All numbers are provisional.

Verified: 34 CLI suites (new: 27 bat rule checks) and 88/88 compiles. A real two-client Studio session covered hit and grab, the thief securing the stolen creature at the gate (3 → 4), and hit with no grab (the creature returns to the carrier). It found and fixed two bugs: the swing cooldown order and a carry pose that stuck after a drop. Evidence: `evidence/integrated_2026-10-26/bat-theft-two-client.json`.

Not yet done in stage 3: one fully finished sample creature (idle/walk/run/turn/reaction) and the egg break/hatch polish. Touch Swing hasn't been tried on a real phone. Bat swing art is simple (a two-part bat, an arm pose and a trail).

## Review02 (stages 1–2)

## Open this file

`C:/Users/HOME!/Desktop/climb-collect-integration/outputs/ClimbCollect.Integrated.Review02.rbxl`
SHA256 `ba4e2a769376099011b4a9019ef60cdc09228ccaae1e852f8468d4cfabb38648`. Branch `codex/integration-review01` (worktree of `Desktop/climb-collect-mountain-quality`), HEAD `4c0710e`. Review01 (`e1d9f500…`) is the pre-fix checkpoint. Nothing published, pushed or merged.

## What it combines

| Piece | Source | How |
|---|---|---|
| Compact mountain Review02 + home promenade Review01 | `codex/homebase-promenade` `bd00e3a` | Base branch; its baked `HomePromenade.Review01.rbxl` (`e7e5cb7c…`) is the world |
| E+B HUD (Review05) | `codex/hud-eb-redesign` `f093e3b`/`90a6963` (`.codex/worktrees/hud-eb-redesign`) | `git merge`, clean, common base `b97ddc0` |
| Tycoon habitat label clearance | `codex/tycoon-redesign` `904ff3b` | Already in the promenade lineage (identical `TycoonWorld.luau`); no change needed |
| Short-phone nav fix | new, `4c0710e` | See below |

Packaging: `mountain/tools/package_free_climb.py` patches only script `Source` into the promenade binary. **1,712 non-Source chunks byte-identical** (terrain, world, sanctuary, lighting). 85 runtime sources match the repo. Changed vs the promenade file: the 7 E+B UI sources (Sprint, Feedback, Theme, Widgets, Screens, Controller, UIPresentation). No terrain regenerated; no files moved or deleted.

## Fix found during HUD wiring

On the Galaxy S25 Ultra emulator (safe root 685×280) the thumbstick gesture region starts at y≈93, inside the Menu / Creatures / Mountain row (54–102). New rule in `UIPresentation.hudLayout`: when a left native control reaches the nav row, Menu moves into the top bar beside status, the two shortcut tiles hide (Menu reaches every hub) and the expanded strip uses the top row. Other sizes unchanged. Evidence: `evidence/integrated_2026-10-26/review01-…before-fix.jpg` → `review02-galaxy-s25-ultra-hud.jpg`.

## Verified

- **CLI:** 28 Luau suites + 5 Python-run suites pass (incl. 105 home layout, 128 E+B layout, 98,981 surface geometry, 125 tycoon economy, 121 rules); 85/85 runtime files compile.
- **Cold open, Edit:** promenade scene check 403/403 on both Review01 and Review02 (mountain 5,362 parts / 978 colliders, single gate exit, 8 homes, lanes, gate opening).
- **Cold Play:** spawn at home 1; one `MountainHUD`; console shows only the ready line.
- **HUD, 8 hubs / 26 tabs, Device Emulator:** Galaxy S25 Ultra, iPhone 16 Pro Max, iPad Air, iPhone 13 (Review02) and iPhone 17 Pro / iPhone 16 (Review01): zero text-fit, touch-target, native-control or HUD-panel overlap errors; no GUI focus left after closing; keyboard W walked 19 studs after hub close. `device-audit.json`.

## Not verified here

Large Text / High Contrast not re-run (E+B Review05 passed them; the fix only moves nav buttons). No fresh full raid/guardian run, multi-client natural spawns at homes 2–8, hosted saves, real phones or low-graphics culling recheck. Party/daily/ranking/badge/paid services remain absent as before.

## Owner checklist

1. Open Review02, Play. Spawn at home 1 facing the gate; new E+B HUD with three creature slots.
2. Menu → all eight hubs; close and walk/sprint.
3. Sanctuary → Habitats: assign, wait, collect, bank.
4. Walk through the grand gate, climb, strike an egg, carry it back through the gate.
5. Device Emulator: try a short phone (Galaxy S25 Ultra) — Menu sits in the top bar.

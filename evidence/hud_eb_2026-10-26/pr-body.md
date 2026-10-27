The playable mountain HUD previously used small portraits and a text-heavy action stack. This applies the approved E+B direction across the gameplay HUD and all eight existing hubs: colorful creature slots and illustrated navigation, compact status/corner progress, consistent navy/cyan/gold panels, and native-control-safe touch layouts.

All existing authoritative profile/team/egg/training/evolution/tycoon/checkpoint/Guardian/settings request paths are retained. Missing party, daily-reward, ranking, badge/title, live-raid and paid-commerce services remain explicitly unavailable. No mock currencies, purchases or rewards were introduced.

### Integration and playable review

- Base `codex/hud-eb-base` freezes verified MountainQuality Review06 `b97ddc0`, which includes the tycoon/HUD-completion/free-climb/sprint lineage. This keeps the UI review scoped; integration into main remains a separate owner decision. PR #1 and both requested feature branches were inspected.
- The active uncommitted compact-mountain prototype and separate offspring production work were preserved. They are not silently represented as integrated.
- Open `outputs/ClimbCollect.HUD.EB.Review05.rbxl` in Studio and press Play. Local identical delivery: `C:/Users/HOME!/Desktop/ClimbCollect-HUD-EB-Review-2026-10-26/ClimbCollect.HUD.EB.Review05.rbxl`.
- SHA256 `72118419291110636f04db796c471bf146f2b00c64b9de3a2975ff8f4eee1e8e`. All1,697 non-Source chunks of the baked Review06 are preserved; all79 current runtime sources match. The additional Rojo SourcePackage is for editable source, not the preserved-world playtest.

### Validation

- 27 inherited CLI suites /105,322 checks plus110 layout cases and navigation-policy assertions pass;79 runtime Luau compiles; Rojo7.6.1 source build; diff check.
- Fresh cold Review05 Play: sanctuary spawn, six sections/18 checkpoints, exactly three slots,26tabs across desktop/short phone/notched phone/tablet with large text/high contrast, plus first24second tablet hint/navigation regression. Zero reported audit errors.
- Real mouse input: settings save, habitat assignment, natural production collection and banking for one coin; actual W movement after hub close. No grants or time acceleration.
- Forty hub cycles retain429 descendants; respawn retains one ready HUD. Clean final runtime console. Independent review's cooldown layering/navigation/hint findings repaired and regression-checked.
- Actual screenshots and device JSON: `evidence/hud_eb_2026-10-26/`; gallery `gallery.html`. Full service status, ancestry, walkthrough and limitations: `design/hud-eb-redesign-report-2026-10-26.md`.

### Acceptance limits

Physical hardware/controller/low-end performance, hosted save/network behavior, a fresh eight-client/full natural Guardian run, owner aesthetics and later compact/new-asset integration remain open. Static compilation is not Roblox-aware type-analysis certification. Studio uses memory profiles that reset on Stop.

Leave this PR unmerged. No Roblox publication occurred. Start owner review with the three creature slots/navigation, then Sanctuary→Habitats and natural collect/bank.

# Glassbloom P5 builder brief (shared by every P5 component-builder task)

Repo: `C:\Users\HOME!\Desktop\climb-collect-integration`, branch `codex/hud-glassbloom`. Roblox Luau. You write code only; the main session syncs to Studio and verifies. Do not commit.

## Sources (the only design source)
- Intel: `C:\Users\HOME!\Desktop\climb&collect\design\hud-glassbloom-intel.md` — §1 tokens, §2 "Menu builders" table, §3 containment, §6 motion token names. Every value you use must be a Theme token or an intel §2 number. Never invent a colour, size, radius or duration. If a value is missing, use the closest kit fallback and write a `-- GAP:` comment naming it (that is how P3/P4 builders recorded gaps), and list it in your report.
- Board (for structure/copy only): `C:\Users\HOME!\Desktop\climb&collect\design\hud-board-v3\index.html` CSS L176–323, builders L606–647.
- Owner answers: `design/hud-glassbloom-build-plan-2026-10-27.md` §11–§17 (§17 = P5 answers).
- Kit: `mountain/client/UI/Widgets.luau` (read the header comments at the top and above each `W.*`), tokens `mountain/client/UI/Theme.luau`.

## Hard rules
- No TweenService, no task loops that animate. Animated pieces only get `SetAttribute('Motion','<intel §6 token>')` and are built in their static end state (P6 wires motion).
- Kit controls: use `fn` / `W.bind`, never `.Activated` on a kit control (the invisible `Hit` child takes input). Every tappable thing is a GuiButton whose hit area is ≥ 44 px (`W.hit`), with a focus ring (`W.focus`) and `Selectable` so a gamepad reaches it.
- Tag decoration that may poke outside its box (glows, rays, lips, streaks) with attribute `Decor=true`; parts meant to straddle the panel edge (title, X, wallet) with `Overhang=true`.
- Text: `T.size(n)` + `SetAttribute('BaseTextSize',n)` (large-text path). Fonts `T.fontDisplay` (LuckiestGuy) / `T.fontBody` (FredokaOne).
- Match surrounding style: compact Luau, tabs-free one-space indent, short comments citing intel lines (`L###`).
- Keep names stable: `MountainHUD`, `SafeRoot`, `HubShade`, `HubShade.Hub`, `HubShade.Hub.Tabs.Tab<name>`, `Hub.Back` (the X), UIProbe actions.
- Containment (intel §3, plan §5): every element inside the panel except `Overhang` (inside the screen, clear of the core zone x<116,y<56) and `Decor`. ScrollingFrame children must fit its width; no horizontal canvas. Must hold at 749×330, 844×390, 932×430, 1024×700, 1180×780, 1600×860.
- Compile-check every file you touch: `"C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau.exe" --mode=... ` is not needed; run `bash tools/run_all_tests.sh` (must end `SUITES pass=40 fail=0`) and, for a syntax check of client files, `"C:/Users/HOME!/Desktop/climb&collect/tools/.luau/luau-analyze.exe"` if it exists, otherwise `luau.exe` on a tiny wrapper is fine — report what you ran.

## Report back (short)
Files changed, functions added, every `GAP:` you wrote, anything you could not do.

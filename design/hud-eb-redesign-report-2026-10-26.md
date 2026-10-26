# E+B HUD review — October 26, 2026

## Open this playable file

`C:/Users/HOME!/Desktop/ClimbCollect-HUD-EB-Review-2026-10-26/ClimbCollect.HUD.EB.Review05.rbxl`

SHA256: `72118419291110636f04db796c471bf146f2b00c64b9de3a2975ff8f4eee1e8e`.

The same binary is committed under `outputs/`. Editable runtime/world source is beside the Desktop file in `source/`, and in this branch's `mountain/`. `ClimbCollect.HUD.EB.SourcePackage.rbxlx` is an additional Rojo source package; use Review05 for playtesting the preserved baked world. Earlier Review01–04 are checkpoints, not the delivery candidate. Do not publish or merge before owner review.

## Integration evidence

- Inspected fetched main `23ee172`, functional HUD `6019525`, tycoon `0751c9b` and draft PR #1. Main has the blueprint; the latter two branches contain actual runtime and sanctuary services.
- The verified later lineage includes tycoon progression `913a0cc`, HUD completion `5831582`, free-climb custody/persistence, sprint and entrances, then MountainQuality Review06 `b97ddc0`. Git ancestry confirms tycoon is an ancestor of this base. The source and artifact evidence supersede the older Desktop navigation checkout.
- Selected committed `b97ddc0` with baked Review06 SHA `bff89f92041687ddfc1cb815a728a1adeef9ca34939324b450cf9217917b09be`. The concurrently active `codex/compact-mountain-review` remains dirty/uncommitted at final reconciliation; it and the separate offspring work were preserved. This delivery does not claim integration of that unfinished compact prototype or new production creature assets.
- Packaging uses `mountain/tools/package_free_climb.py`. All **1,697 non-Source chunks** are byte-identical: world geometry, terrain, sanctuary, instance parents, settings and Lighting are retained. All **79 current runtime sources** match editable files. Seven runtime sources change behavior/presentation; the eighth changed saved Source is MountainQuality CRLF normalization only, proven equivalent after newline normalization. No world helper or gameplay source was edited on this branch.
- The actual Desktop Review05 was opened in a fresh Studio process and played: direct sanctuary spawn, six sections, 18 checkpoints, one HUD and three active slots. No QA fixture is in the saved binary. Stop Play leaves the file unchanged.

## Visual system and behavior

The supplied image is a visual target, not gameplay instructions. E contributes colorful companion portraits, illustrated navigation tiles, bright rims and bold rounded typography. B contributes compact status and corner progress, with a quiet climbing center. No mock gems, hearts, counts or unimplemented purchase buttons were adopted.

Shared Widgets/Theme style cards, tabs, buttons, disabled controls, tooltips, confirmations, notifications, loading and milestone portraits. All eight hub headers use the same local vector icon vocabulary. No externally hosted icon assets or uploads are required. The three creature slots retain real species, rarity, level and authoritative special cooldowns. Navy-backed state pills render above portraits. Mutating controls retain the existing correlated server request, rejection, pending, timeout and safe-retry boundary.

Navigation collapses during combat. Desktop expands to a two-column sidebar; touch expands to a horizontal scroll strip above the complete native thumbstick gesture region. Sprint shares CoreGui-safe geometry with combat actions and hides behind menus/modals. Native joystick, jump and Roblox top-left menu are preserved. Contextual management now opens Sanctuary without an unnecessary PutDown mutation or misleading collection toast. Wallet/save/timer, real height and minimal objective remain visible in appropriate states.

## Screen/service status

| Hub | Connected behavior | Genuine unavailable dependencies |
|---|---|---|
| Creatures | Collection/search/filter/sort, three-slot team, stats, training, automatic level-stage evolution and specialization | None added by this redesign; existing eligibility/cost checks apply |
| Discovery | Legacy secured eggs, three incubators, free timed hatch, field guide; current break/carry/exit objective | Production eggs are explicitly not hatchable; new runtime asset/catalog integration remains separate |
| Sanctuary | Own-plot habitat assignment/swap, collection/bank, upgrades, automation, attunement, free palettes, facilities | Existing affordability/progression/own-plot restrictions remain truthful |
| Mountain | Six open sections, discovered checkpoint travel, run-abandon confirmation, progress and Trials | Claimable daily/quest reward service absent |
| Social | Nearby encounter membership, defense snapshot registration, UserId challenge and labeled practice | Party finder/invitations/readiness, live raid layout and friend matching absent |
| Profile | Server profile stats, collection, discoveries, trophies and earned milestones | Rankings, platform badge awards and title ownership/equip absent |
| Shop | Routes to real free sanctuary palettes; explicit fair-convenience explanation | Approved paid catalog, receipts and entitlements absent; checkout disabled |
| Settings | Server-validated text/contrast/motion/VFX/audio/hints preferences and quick settings | Hosted persistence certification remains open; Studio memory resets on Stop |

## Fresh verification

- **27 inherited CLI suites / 105,322 checks**, plus **110 new layout cases** and navigation-policy assertions. All pass. All **79 runtime Luau files compile**. Rojo7.6.1 builds the source package. `git diff --check` passes. Compiler success is not a claim of clean Roblox-aware static type analysis.
- Review05 cold Play: **26 tabs** across all eight hubs at phone7 safe667×317 and desktop1920×1022; zero reported text-fit, touch-target or native-control errors. Review05 large-text/high-contrast matrix: phone7, iPhone16Pro750×344 and iPad1180×762 also pass26tabs each. Expanded tablet navigation has an additional zero-error run. A750×450 intermediate-height regression passed during the source-equivalent Review03 run.
- Read-only refresh fixture passes picker reset, tab scroll, draft team, zero unsolicited intents, stale purchase lock and duplicate focus. Actual mouse input saved larger text/high contrast; server acknowledgments were observed. During implementation, real mouse input assigned c1, collected one naturally produced egg and banked it for one coin. `actual-server-actions.json` contains the authoritative results. No grants/time acceleration were used. Keyboard W moved14.40studs after hub close with nil GUI focus.
- Independent review found two P2 layout defects and one minor color-order bug. All were repaired. A later review found the initial hint covering expanded tablet navigation; a fresh Play regression failed first, then passed after hiding hints during expansion. Additional native-region checking exposed and repaired expanded tablet navigation. Evidence: `independent-review.md`, device JSON and screenshots in `evidence/hud_eb_2026-10-26/`.
- Visual comparison repaired missing panel rims (TextButton Contextual strokes), joystick-region overlap, clipped state labels, intermediate-height panel overlap, tablet navigation and inherited sprint placement. The final screenshot gallery includes actual gameplay HUD and all eight hubs; images show real profile values.

## Owner playtest

1. Open the exact **Review05.rbxl** above and press Play. Confirm direct sanctuary spawn, three colored slots, real zero starting coins and the compact top/corner panels.
2. Open Menu, scroll all eight hubs, then close it and walk/jump/sprint. On phone emulation, check the full native movement region and notched safe area.
3. Sanctuary → Habitats: assign starter companions. Wait for natural production, collect and bank. Check affordability/disabled reasons before trying upgrades.
4. Creatures: change team, inspect training/evolution. Shop should offer free palettes and honest disabled paid checkout. Settings should save text/contrast/motion preferences for this Play session.
5. Climb through the mountain entrances, strike an egg, carry the reveal downhill and secure it at the exit. Inspect real Guardian/Trial cooldowns during your playtest. The server gameplay is preserved; a fresh full natural Guardian/custody/multiplayer run was not added by this UI pass.
6. Stop without publishing. Studio memory resets by design.

## Remaining acceptance

Physical phones/tablets/controllers, low-end GPU/memory/battery performance, hosted DataStore/save/rejoin/network faults, fresh eight-client acceptance and owner aesthetic/human pacing review remain open. Existing party/daily/ranking/badge/title/live-raid/paid-commerce dependencies remain explicitly unavailable. The active compact-mountain prototype and separately produced creature assets require their own reviewed integration. This is a complete local UI review build, not public-release certification.

Graph/vault freshness and the final PR URL are recorded in the final handoff after backed-up project/vault updates. The navigation graph excludes this isolated implementation source.

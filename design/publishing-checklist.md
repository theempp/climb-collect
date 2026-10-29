# Mountain Empire publishing checklist

> October 25, 2026 status overlay: use [current workspace review](workspace-review-2026-10-25.md) before interpreting historical unchecked items. Integration is built; habitats/production/automation and newest HUD are implemented in separate durable feature clones; actual eight-client tycoon and Review06 cold-start tests are recorded. Latest branch consolidation, premium visual acceptance, hosted persistence, phones and remaining advanced services are still open. Original full public-release scope remains. Historical acceptance checkboxes below are retained, not silently treated as current evidence.

Updated October 24, 2026 (America/New_York). **Owner target: full Mountain Empire vision before public release, including advanced services.** Private alpha/beta tests are steps toward that release. No feature below is silently deferred. [Overview](../START-HERE.md) Â· [Evidence/workspace audit](project-audit-2026-10-24.md).

Check an item only after its acceptance evidence is attached. Status: **done** = verified in the stated scope; **open** = work/test needed; **decision** = owner or design contract needed; **blocked** = named prerequisite absent. P0 protects work/data and establishes one candidate; P1 is required for the agreed public launch; P2 is optional expansion. Codex owns engineering/evidence; owner owns creative/product acceptance and account actions; testers own human device observations. Those are responsibilities, not claims that future work has begun.

## Completed foundation

- [x] A01 â€” Inventory current workspaces, refs, PR, connected Studio sessions and review artifacts. [Evidence](../evidence/release_audit_2026-10-24/inventory.json). Missing HUD checkout explicitly identified; nothing cleaned up.
- [x] A02 â€” Establish full-vision public launch and initial testers. Owner: iPhone 16 Pro; girlfriend: reported iPhone 18 Pro Max. Hardware tests remain open.
- [x] A03 â€” Recheck current mountain source/bake: 120 rules, 131 traversal, 657 geometry checks; 80 Luau files compile; 44 saved sources and intended terrain match. [Evidence](../evidence/release_audit_2026-10-24/fresh-checks.json). This is not combined-game acceptance.
- [x] A04 â€” Record historical scope separately: old Fairground/private place, hall/sunny and legacy creature art. [Audit](project-audit-2026-10-24.md). Preserve all originals.

## M0 â€” preserve work and settle integration decisions

Priority P0. Next actionable milestone; prerequisite for implementation work.

- [x] W01 â€” **Codex:** preserve current continuation source, Final56/Final54 terrain authority, generated asset templates and all necessary untracked evidence in a verified backup/commit set. Acceptance: manifest covers tracked + untracked inputs; restore rehearsal reproduces hashes; no unrelated staging, resets or removals. The current branch tip predates Final56.
- [x] W02 â€” **Codex:** restore HUD commit `6019525` into a new valid isolated workspace, preserving the remnant and open Studio. Acceptance: source/evidence present, clean recovered baseline; review hash checked against LF/CRLF representation; do not recreate bytes by saving an unknown Studio state.
Verified W01/W02 on October 24, 2026: [preservation, independent restore and HUD recovery evidence](workspace-recovery-2026-10-24.md). Studio reported no connected instances; no session was altered.

- [ ] D01 â€” **Owner + Codex:** review sanctuary Step 3 and natural mountain Final56 at player scale. Acceptance: explicit accepted areas/change list, including lodge access, empty construction courtyards, mountain silhouette, all six regions and creature/Guardian quality. Step 2 acceptance already exists; do not repeat it unnecessarily.
- [x] D02 â€” **Owner + Codex:** agree sanctuaryâ†”mountain contract: same or separate place, three gate purposes, source of profile truth, spawn/return coordinates, plot reservation, carry/egg state across travel, failed travel recovery. Acceptance: written interfaces and state transitions; no guessed coordinates or schema mixing. Owner approved one place and all three gates entering Blossom; existing mountain profile and assigned-plot return. Contract and evidence: [local integration record](local-alpha-integration-2026-10-24.md).
- [ ] D03 â€” **Owner + Codex:** complete launch rules for habitats/build upgrades/income, party/raid/defense behavior, rank/reward resets, dailies and fair catalog; resolve Caeloryn abilities 2â€“4 and practice rewards. Acceptance: locked versus provisional values explicit, no UI mockup treated as a service contract. Break design discussions into feature groups, using the question widget.
- [ ] D04 â€” **Owner:** select current experience owner/universe, target audience and supported devices. Acceptance: a release configuration record, old private place treatment, controller decision, lower-end mobile test plan, and roster for eight-client testing. No platform settings change at this step.

## M1 â€” one integrated local alpha

Priority P0. Depends on W01/W02 and D01/D02. D03 detail can proceed in parallel where independent.

- [ ] I01 â€” **Codex:** prepare an isolated integration branch and manifest. Acceptance: selected source commits/dirty snapshot, exact sanctuary and Final56 hashes, explicit prerequisite history, reviewed plan for `main`; no automatic merge/retarget of PR #1.
- [ ] I02 â€” **Codex:** integrate HUD runtime with latest mountain. Acceptance: resolve `Main.server.luau` deliberately, preserve analytical mover fix, new routes/Catalog/TerrainProfile and Final56 terrain; one HUD root; all 23 tabs render/navigate correctly and existing service actions work. Later M2â€“M5 services remain truthfully unavailable at this intermediate milestone. Do not replace Final56 with HUD's older ArtPassVerified Workspace.
- [ ] I03 â€” **Codex:** implement plot assignment, correct sanctuary spawn, gate travel and correct-plot return using the reviewed contract. Acceptance: two simultaneous joins get distinct plots; local session reload reclaims correctly; slot-exhaustion/late-join and invalid travel tests fail safely; no cross-player ownership leaks. Hosted rejoin and actual eight-client acceptance belong to M6/M7.
- [ ] I04 â€” **Codex + owner:** bridge the existing incubation/hatch/training services to the minimum sanctuary interaction points agreed in D02, then demonstrate: fresh spawn â†’ team â†’ Blossom encounter/nest â†’ egg â†’ secure/extract â†’ sanctuary return â†’ incubate â†’ free hatch â†’ equip/train. Acceptance: no grants/position injection in the acceptance run; correct authoritative HUD and failure messages. This uses existing service behavior in the sanctuary; buildable/upgradable facilities, habitat income and full progression integration remain M2 work.
- [ ] I05 â€” **Codex:** save, close/reopen a new named alpha and verify startup, source parity, terrain, protected originals and no QA artifacts. Acceptance: exact hash/manifest and recorded loop; previous artifacts intact. A source-only Rojo package is insufficient.

**M1 exit:** one recoverable local build proving the connection of all three workstreams, with the minimal existing-service sanctuary bridge. All tabs must remain honest about which later services are unavailable. It is an internal milestone; full-launch services below remain required.

## M2 â€” complete sanctuary and collection progression

Priority P1. Depends on M1 and relevant D03 decisions.

- [ ] S01 â€” **Codex:** habitat/build/upgrade/placement services and UI. Acceptance: buy/place/move/upgrade within owned plot; bounds, collision, capacity, costs and ownership server-validated; insufficient funds/duplicate request/cancel/rejoin produce correct results.
- [ ] S02 â€” **Codex:** creature placement, exhibit/roaming limits and passive/offline income. Acceptance: intended eligible creatures determine income; no double settlement; cap/timestamps documented; moving creatures or upgrading settles old rate correctly; persisted placement and ownership agree. Current all-owned-creature income must be reconciled explicitly.
- [ ] S03 â€” **Codex:** functional training/evolution/hatching facilities. Acceptance: costs/XP/timers/capacity/stages/specialization reflect approved rules; duplicate and early hatch refused; one creature awarded once; all changes persist after hosted rejoin in M7.
- [ ] S04 â€” **Codex + owner:** collection catalog, unlock roadmap and onboarding. Acceptance: actual 36+6 content maps to UI/world; new player understands first egg, return, hatch, placement and next kingdom without an instruction wall; hints skippable and persistent; no invented rewards.
- [ ] S05 â€” **Codex + testers:** fall/cargo recovery, full inventory/incubators, disconnect mid-action and checkpoint/fast-travel boundaries. Acceptance: bounded intended loss only, no duplication, no bank/extraction bypass, reasons visible in HUD.

## M3 â€” finish mountain gameplay and art acceptance

Priority P1. Depends on M1; art review can progress alongside M2.

- [ ] G01 â€” **Codex + testers:** all six normal Guardian wins and all six Legendary Trials on the integrated final geometry. Acceptance: correct eligibility, resolved patterns/dodges/objectives, one permanent capture, replay without duplicate capture, correct UI; repeat after relevant changes. Older Trial evidence is insufficient for this candidate.
- [ ] G02 â€” **Codex + testers:** twelve optional branches, nests, puzzles, sand/gravity/rope mechanics, six moving-platform reward/return loops, all checkpoints and **shortcut travel as well as attunement**. Acceptance: earned progression, no stuck/headroom/landing failures, latency cases retained with fixes.
- [ ] G03 â€” **Owner + testers:** human pacing and combat balance. Acceptance: measured novice/experienced sessions, deaths/stalls/backtracking and enjoyment; compare with current request's 18â€“25 minute experienced-ascent target, document any approved adjustment. Do not reuse old 25â€“30/60-minute targets or bot seconds as human results.
- [ ] G04 â€” **Owner + Codex:** sanctuary, six biomes, transitions, nests, arenas, landmarks, all regular creatures and six Guardian boss/collectible forms meet agreed visual quality. Acceptance: player-scale captures + owner signoff; grounded geometry, readable routes/cues, animation quality and coherent materials; no placeholder presented as final.
- [ ] G05 â€” **Codex:** reconcile assets/animation/audio manifest. Acceptance: actual mesh/texture/sound/animation IDs, ownership/source/license and final use recorded; abandoned templates marked historical without deleting them; no automatic import of legacy Budskip/43-species roster.
- [ ] G06 â€” **Owner + testers:** audio audition and accessibility. Acceptance: audible ambience, footsteps/actions/combat/rewards as agreed; separate settings, consistent levels, reduced-motion/VFX paths and visual equivalents; hosted assets load in M7.

## M4 â€” complete parties, raids, rewards and recognition

Priority P1, required before public release. Depends on M1/M2 and D03 contracts.

- [ ] C01 â€” **Codex:** party creation/invites/accept/leave/kick as designed, finder, readiness and coordinated portal travel. Acceptance: authoritative membership; stale invites, full party, disconnect and leader departure recover; no player stranded by partial travel.
- [ ] C02 â€” **Codex + testers:** cooperative exploration and Guardian participation/rewards. Acceptance: two then eight clients, late join/leave/defeat/reconnect cases, contribution/capture eligibility and UI consistent; no accidental reward duplication or progression bypass.
- [ ] C03 â€” **Codex:** full offline raid/defense loop. Acceptance: versioned saved defenses/layouts as designed, opponent selection, deterministic/validated results and durable reward transaction, replay protection/cooldowns, reconnect recovery, no unauthorized defender changes. Existing numeric-UserId stat battle is only a starting point.
- [ ] C04 â€” **Codex + testers:** friend challenges. Acceptance: valid invite/matching/accept/decline/timeout/disconnect, correct rules/results, privacy/access constraints respected. Practice is labeled and its reward/ranking policy enforced.
- [ ] C05 â€” **Codex:** trophy/ranking services and in-world displays. Acceptance: authoritative scores, pagination/update behavior, tie/reset rules, invalid-write protection, consistency after reconnect and replay; practice cannot unintentionally farm competitive rank.
- [ ] C06 â€” **Codex:** achievements, Roblox badges where specified, titles, trophy gallery and public profile. Acceptance: server-approved criteria, idempotent grants/equip, correct visibility, failed grants retried without invented success.
- [ ] C07 â€” **Codex:** quests and daily reward claims. Acceptance: configured goals/rewards, timezone/reset rule, authoritative progress, one claim per period across sessions/servers, late/repeated/failed requests safe; roadmap and HUD match actual state.

## M5 â€” implement and verify the approved shop

Priority P1. Depends on D03/D04, shared wallet/persistence and relevant facilities. Platform setup happens only after the concrete catalog and destination are ready and separately authorized.

- [ ] E01 â€” **Owner + Codex:** finalize cosmetic/noncompetitive-convenience offers, prices, fulfillment and refund/failure messaging. Acceptance: no pay-to-win or legacy multiplier/external-pass catalog silently reused; visual previews correspond to real deliverables.
- [ ] E02 â€” **Codex:** receipt/entitlement service and real UI checkout. Acceptance: server trusts platform receipt/ownership, durable exactly-once grant across retries/rejoin/server changes, no client-confirmed purchase success; cancellation, pending, already-owned and unavailable states correct. [Roblox developer-product guidance](https://create.roblox.com/docs/production/monetization/developer-products).
- [ ] E03 â€” **Owner + Codex:** configure approved product/pass IDs for the selected experience and verify price/ownership display. Acceptance: catalog-to-ID manifest, permissions and actual fulfillment tests; spending/test purchases only when specifically authorized. UI request caching alone does not fulfill E02.

## M6 â€” integrated reliability, security and device acceptance

Priority P0 for data integrity, P1 otherwise. Start early on each subsystem; exit after M2â€“M5.

- [ ] Q01 â€” **Codex:** review/test shared state boundaries: profile version/migrations, session locking, rate limits, ownership/proximity, stale actions, forged prices/rewards, raid/capture/hatch duplicates and failed-save mutation freeze. Acceptance: adversarial tests against actual handlers; no unresolved data-loss/duplication or release-blocking defect.
- [ ] Q02 â€” **Codex:** healthy toolchain checks. Acceptance: targeted suites + current source build/compilation, Roblox-aware type analysis with actionable diagnostics resolved, scoped whitespace/binary attributes verified and new hashes recorded. Preserve original evidence bytes.
- [ ] Q03 â€” **Codex + owner:** eight-player load and slot capacity. Acceptance: eight occupied plots, filled habitats, companions, simultaneous combat/raids/travel and respawns; actual hosted capacity verified; report server/client frame time, memory, replication and failures. Local MaxPlayers 12 in sanctuary does not satisfy the target 8.
- [ ] Q04 â€” **Owner:** iPhone 16 Pro physical test. **Girlfriend:** reported iPhone 18 Pro Max physical test. Acceptance: exact model/OS/client/network noted; fresh onboarding, all HUD hubs, joystick/jump/dodge/specials, notches/safe areas, landscape rotation, settings, heat/battery behavior, 20â€“30-minute session and save/rejoin recorded. Two phone tests do not establish lower-end coverage.
- [ ] Q05 â€” **Codex + testers:** desktop mouse/keyboard and agreed tablet/Android/controller coverage. Acceptance: real focus/navigation/input including gamepad if shipped; no text/control overlap; chosen hardware matrix and graphics tiers explicit. Obtain lower-end mobile evidence or agree a narrower supported-device target openly.
- [ ] Q06 â€” **Codex + testers:** set and meet performance budgets before exit. Proposed targets pending profiling: stable 30 FPS floor on agreed lower-end phone tier, 60 FPS desktop target; record frame-time percentiles, worst spikes, memory, loading/streaming and thermal degradation. Baseline and thresholds must be accepted, not inferred from Studio's 60 FPS cap.
- [ ] Q07 â€” **Codex:** long-session and interruption tests. Acceptance: repeated menu/respawn/travel/combat loops, streaming out/in, network delay/drop, suspended app, server shutdown/restart; no growing instance/connection leak or duplicate HUD; deterministic recovery and clear save status.

## M7 â€” private hosted beta and platform readiness

Priority P1. Requires an identified candidate and selected universe; publication/access/invitations require explicit authorization when ready. A private beta may start with M1 to discover issues; public-release acceptance requires the final full-feature candidate.

- [ ] P01 â€” **Codex + owner:** prepare a separate test environment and data policy. Acceptance: exact place/universe IDs, candidate hash/commit, isolated test namespace, legacy-data migration/reset decision and rollback copy. Keep October 22 private Fairground separate unless explicitly selected for replacement. [Data-store guidance](https://create.roblox.com/docs/cloud-services/data-stores).
- [ ] P02 â€” **Owner + Codex:** verify publishing eligibility, target audience and maturity/access requirements in the actual account. Acceptance: dated dashboard record, questionnaire/evaluation as required, appropriate playtest access and agreed eight-player/device settings. Current Roblox flow depends on audience; do not assume old requirements. [Official release guidance](https://create.roblox.com/docs/production/publishing/publish-games-and-places).
- [ ] P03 â€” **Codex + testers:** after authorized private publication, test real DataStore: leave/rejoin, second server lock contention, timeout/throttling, delayed save+leave, shutdown, offline income/incubation, settings/placements, raids/dailies/receipts and schema rejection. Acceptance: observed saved records/result before/after; no silent loss, duplicated grant or lock theft. Studio currently deliberately uses memory, even if API access is enabled.
- [ ] P04 â€” **Owner + testers:** invite the selected testers after authorization and complete two-human then eight-client hosted tests. Acceptance: reproducible issue list with build/device/account role/network, evidence and retest status. Roblox currently offers early-tester access; check account/age/access rules at invite time. No invitation was sent by this audit.
- [ ] P05 â€” **Codex:** hosted asset load/permissions review. Acceptance: mesh/texture/animation/audio loads for ordinary players under final owner/universe; correct credits, moderated assets and fallback behavior. [Asset privacy guidance](https://create.roblox.com/docs/projects/assets/privacy) covers images/meshes; audio/animations have their own access rules.
- [ ] P06 â€” **Owner + Codex:** final listing/title/description, icon/thumbnails, supported devices, audience/maturity answers and public-facing claims. Acceptance: captures represent the actual Mountain Empire build, moderation complete, no inherited Fairground readiness claim, no misleading availability of features.

## M8 â€” release candidate and public publication

Priority P1. Depends on all required gates above. No fixed date or completion percentage is assigned before evidence exists.

- [ ] R01 â€” **Codex:** freeze a full release candidate; save/reopen, manifest/hash/source/terrain checks, regression suite and owner walkthrough. Acceptance: checklist has no unchecked required feature/test; known issues explicitly accepted and not release blockers; exact rollback artifact preserved.
- [ ] R02 â€” **Codex + owner:** review integration PR(s) and final branch ancestry; merge only when separately authorized. Acceptance: reproducible selected `main` build matches candidate, no accidental historical design or untracked-only dependency; attached PR/evidence and release notes.
- [ ] R03 â€” **Codex:** prepare launch/rollback runbook and telemetry. Acceptance: track joins, loading failures, onboarding, egg/hatch, save failures, purchase failures and server errors; define who watches launch, when to stop rollout, and how to restore code without corrupting newer saves.
- [ ] R04 â€” **Owner:** explicitly approve public publication of the exact candidate, destination and audience. **Codex/owner:** execute only that approved change. Acceptance: correct version and settings verified in Creator Hub and real client; no unrelated listings/purchases/access changes.
- [ ] R05 â€” **Owner + testers:** post-release smoke checks and initial monitoring. Acceptance: new and returning account, ordinary player access, saves, shop/receipts, multiplayer and error metrics confirmed; urgent defects trigger the agreed rollback/hotfix process.

## Optional after the agreed full launch

P2 only: extra kingdoms beyond the six, additional roster/cosmetic content, seasonal events and broader localization/support expansion. Trading and extra currencies are not approved additions. Parties, raids, rankings, daily rewards and the approved shop remain **P1 launch work**, not this optional list.

## Keep the checklist current

For each completed ID, append: `date | build/commit/hash | result | evidence path | remaining limitation | owner acceptance if needed`. After each material milestone update the relevant project record and concise Climb & Collect vault pointer; run graph freshness/refresh and state its coverage. Reopen a checked item when its relevant code, geometry, data contract or platform setting changes.

The working order is **M0 â†’ M1 â†’ M2/M3/M4/M5 â†’ M6/M7 â†’ M8**. Independent art/service work may overlap once contracts are stable. Finish one reviewed milestone before growing the next batch; keep owner questions grouped in the widget.


### Local integration evidence — October 24, 2026

D02 is resolved for the local alpha. I01–I05 implementation and verified portions are recorded in [the integration record](local-alpha-integration-2026-10-24.md); milestone boxes remain open pending the exact remaining acceptance, including D01 and actual reconnect/late join. No full-launch deferral or publishing is implied.

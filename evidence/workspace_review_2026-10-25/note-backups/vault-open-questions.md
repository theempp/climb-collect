# Open Questions — Climb & Collect
- #todo Approve v4 P3 (full routes)?
- #todo Phone + human playtest (feel, timing)
- #todo Verify real DataStore on a published place
- #todo On the private published test place, verify claim → bank → leave → rejoin on the creator's phone; record save result, loading, touch controls, route feel and device performance. PlaceId and evidence: repo `design/phone-playtest-publish-2026-10-22.md`.
- #todo Device targets / mobile perf matrix
- #todo Art pass: climb walls read as plain rock; creature art is stubs

- Per-player day/night clock vs co-op + jackpot beacon visibility; cycle length; cairn/glow cue look (no reference); crevasse ladder gap vs wall.
- UI round: typeface (FredokaOne provisional); per-screen colour mix boards vs K2; rarity colour accent order; shop/gear/Points/O2 vs Round 3 exclusions (R1); no reference for hatch egg, bank confirm, fall-loss, touch layout, loading look, audio.
- v6: hands-on below 35 % (more faces vs slower climb speed?); tutorial bot fails on leg 1 (rope + pup net, likely v5 P1 geometry); tall ladder reads poorly; your playtest of Camp 1 -> Camp 2 decides the rollout.

- 2026-10-22 #todo Review the saved movement implementation plan and select execution method together in the widget. Reconcile a separate Climb & Collect local review in Studio (only DRS Rush instances were connected during planning); verify rig/run animation, real input and device behavior. Repo `design/movement-planning-audit-2026-10-22.md`.
- 2026-10-23 #todo Save the movement review place (Ctrl+S, Studio PID 40092), then reopen-verify; decide when to copy movement source from the Codex worktree into the main folder; two-client + phone/controller feel test of sprint values. Guardian 'hit' event has no emitter in current source (stagger lock unreachable).

- 2026-10-23 #todo Start the lobby+sunny build in a new chat with repo `design/lobby-sunny-new-chat-prompt-2026-10-23.md`; first owner gate = approve the generated hall concept images.

- 2026-10-24 #todo Review Mountain Empire Step1 scale and outer-plot travel (~32s from rear spawn estimate). Hosted8-player capacity remains unset (local MaxPlayers12); physical mobile and8-client performance pending. Evidence: repo design/mountain-empire-step1-review.md. Do not begin Step2 without user approval.


- 2026-10-24 #todo Review Step2 lodge appearance in the separate saved review; Step1 enlarged layout was accepted and Step2 authorized. Earlier request to approve Step2 is superseded. Physical mobile/eight-client testing and hosted8 capacity remain open (local MaxPlayers12). Repo design/mountain-empire-step2-review.md. No automatic continuation.

- 2026-10-24 #todo Review Step3 environment; Step2 lodges are owner-approved. Hosted8 capacity (local12), physical mobile/controller and eight-client performance remain unresolved. Repo design/mountain-empire-step3-review.md. No automatic continuation.

- 2026-10-24 #todo Slice terrain keeps dry red/yellow material colours that clash with the C4 sunny preview; changing them needs Terrain material colours (currently forbidden). No waterfall sightline on trailhead→Camp 1.

- 2026-10-24 #todo Impossible Mountain acceptance: premium art/animation and biome transitions; functional rope/shifting-sand/gravity variety; optional branches and five remaining natural Trial captures; 18–25 minute ascent tuning; real co-op/eight-client and physical phone/controller checks; published DataStore/audio validation; final Phase 1 gateway/profile integration; confirm Caeloryn abilities 2–4 because the supplied request truncates after ability 1. Saved playable milestone and exact evidence: repo `design/mountain-empire-six-kingdom-build-2026-10-24.md`. Original graph freshness does not imply isolated worktree source coverage.
- 2026-10-24 #todo Owner review of the hall + sunny slice build (captures in worktree evidence/lobby_sunny_2026-10-23/captures). Open: audio listening pass, genuine summit+reset on this build, HUD region label in the hall, C1 gallery, slice hands-on ~6%.

- 2026-10-24 #todo Impossible Mountain Review16: premium art still unaccepted (terraces/flat shelves/rounded foliage); Astral stationary reward landing still fails, remaining platform matrix open. Newly walkable backdrops need readable combat exits; original 58-stud rule remains. Central and both diagonal Blossom exit/return paths now pass after a preserved column-waypoint failure; next baked marking revision must cover the full support intersection. Evidence: repo design/mountain-empire-six-kingdom-build-2026-10-24.md and continuation mountain/ENVIRONMENT-PASS.md. Do not carry these terrain/art decisions into the separate lobby slice.

- 2026-10-24 update: Review32 closes the reproduced Astral landing defect and all-six moving-platform coverage for automated solo play (interrupted runs; failures retained), with150ms simulated Astral/Violet repeats. Premium art remains open: terraced silhouette/draft forms, real multiplayer/device performance, human timing and hosted validation still unverified. Current intended terrain is Shoulder29. See repo `design/mountain-empire-six-kingdom-build-2026-10-24.md` for exact scope.

- 2026-10-24 Final56 update: route redesign and full fresh automated solo traversal are now verified, including all twelve branch nests and six movers. Owner aesthetic review, human timing, real co-op, physical devices, hosted persistence/audio, remaining Trials and Phase 1 integration remain open. Shortcut attunement was tested; shortcut travel was not. Exact evidence: repo `design/mountain-empire-six-kingdom-build-2026-10-24.md`.

## Current release queue — 2026-10-24
Use repo `design/publishing-checklist.md` for current ordered tasks; older open snapshots above may be superseded by later evidence. Full vision is the public target. Remaining decisions: Step3/Final56 visual acceptance; same/separate-place gateway/profile/plot contract; habitat/economy/party/raid/rank/daily/catalog rules; Caeloryn abilities2–4 and practice ranking rewards; final universe/audience/device coverage and eight-player roster. Initial phones: owner iPhone16Pro and girlfriend reported iPhone18ProMax. Remaining work includes HUD checkout recovery and latest continuation preservation, full integration, all advanced services, human/device/multiplayer/live-save acceptance. Exact current inventory and corrected assumptions: `design/project-audit-2026-10-24.md`.


## 2026-10-24 — preservation and HUD recovery verified

W01/W02 complete: all 4,952 mountain files preserved with hashes and Git bundle; independent restore passed 908 checks and saved-world audit. HUD recovered clean at 6019525 in `C:/Users/HOME!/.codex/worktrees/mountain-hud-recovered/climb&collect`; 419 checks passed. Backup: `C:/Users/HOME!/Documents/ClimbCollect-Recovery/2026-10-24-030555Z`. Evidence and limitations: `C:/Users/HOME!/Desktop/climb&collect/design/workspace-recovery-2026-10-24.md`. Earlier missing-HUD statements are superseded. Studio connector reported no instances; no session altered. D01 visual acceptance and D02 integration contract remain open; no combining or publishing occurred.


## Local integration checkpoint — 2026-10-24

Owner approved one place and all three sanctuary gates entering Blossom. Existing mountain profile stays authoritative. Review06 integrates Final56, recovered HUD and Step3 with owned-plot spawn/return and existing services. Verified: 1,102 checks, 56 saved-source matches, 19,914 mountain parts preserved, 3,731 sanctuary parts translated, exact combined terrain after native save; three-client distinct plots/ownership and other-plot denials. Natural solo egg/bank/home/incubate/hatch/equip plus landmark-funded training passed without grants or position injection. D01 visual acceptance, actual late join/reconnect, eight clients, physical devices, hosted persistence and full launch services remain open. Recovered HUD checkout disappeared externally during integration; copied sources, commit6019525 and external recovery preserve the work.

Report: C:/Users/HOME!/.codex/worktrees/f520/climb&collect/design/local-alpha-integration-report.md
Contract: C:/Users/HOME!/.codex/worktrees/f520/climb&collect/design/integration-contract-2026-10-24.md
Recovery checkpoint: C:/Users/HOME!/Documents/ClimbCollect-Recovery/integration-2026-10-24-checkpoint02 (manifest is authority for completed copy). Graph excludes isolated worktree source.

- 2026-10-25 — Guardian production: actual editable Veylith technical trial/exports created, but benchmark FAILED (anatomy, feather coverage, wing deformation); zero accepted pairs. Specialist assistance proposed, none engaged. Owner Actuallytherealzo/UserId11718983250 resolved; Studio import/access/devices untested. Verified evidence and corrected assumption: repo `design/guardian-production-2026-10-25.md`; external `Documents/ClimbCollect-GuardianProduction/2026-10-24/QUALITY-HOLD.txt`.

- 2026-10-25 AI-base continuation: owner explicitly requested an AI-generated Veylith base plus Blender refinement before any artist. Free Studio generation/export succeeded; six eagle mesh parts14,640 triangles, local weld/anatomy/material refinement and six independent prisms saved. Fresh Blender/GLB round trip12 meshes14,784 triangles passes, but visual benchmark still FAILS (rounded feathers, feet/talons, face, material detail). No finished pair, paid credits, artist or game-place edits. Full evidence: C:/Users/HOME!/Documents/ClimbCollect-GuardianProduction/2026-10-25/veylith-ai-base/RESULT.txt. Higgsfield lists Meshy image-to-3D but connected generate_3d tool is absent; price/execution unverified. Previous artist recommendation is superseded by owner AI-first instruction, not quality approval.

- 2026-10-25 tycoon: Review04 simulations establish starter20 coins at9.1min/third habitat50 at20.9min with continuous banking, not human timing. Retained provisional rates/prices. Eight-profile sequential rules/memory tests are not eight live clients. Remaining: eight-client session, hosted save/reconnect and budgets, low-end physical phones, late-game economy/human pacing and premium visual approval. Evidence: C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/work/climb-collect/design/tycoon-polish-2026-10-25.md. No publish/merge; original world preserved.

- 2026-10-25 Guardian continuation: five real 3D silhouette studies and measured lineup saved; fresh Blender/GLB checks agree at238 meshes/34,676 triangles with required limb counts. Still provisional blockouts; no finished Veylith pair. Reference-conditioned Studio generation now verified, correcting earlier uncertainty, but full-board input produced disconnected birds and was rejected. Single-bird crop experiment pending local-image-edit permission. Evidence and limitations: repo `design/guardian-production-2026-10-25.md`; external `Documents/ClimbCollect-GuardianProduction/2026-10-25/CONTINUATION.txt` and `silhouette-studies/reopen-roundtrip-audit.json`. No paid service, artist or experience publish.


## HUD review verified — 2026-10-25
Review02 saved/reopened, 30 runtime source matches, preserved world/terrain; 1,316 CLI checks, 26-tab four-simulator large-text audit, real assignment/production bank input and two independently reviewed refresh repairs. Exact evidence/Q1–Q28/action status: original repo `design/hud-completion-2026-10-25.md`; full report C:/Users/HOME!/Documents/ClimbCollect-HUD-2026-10-25/design/hud-completion-report-2026-10-25.md. Corrected assumption: habitats/production are available. Party/daily/live raids/rankings/badges/titles/paid checkout and physical-device/hosted/eight-client acceptance remain open. Graph excludes durable isolated source; existing notes and other chats preserved.

- 2026-10-25 Guardian crop follow-up: owner approved local crop; permission blocker resolved. Single-eagle input fixed multiple-view output, but six-part18,818-triangle and single-mesh18,822-triangle trials both fail feather/face/talon quality in actual Blender renders. No finished Veylith pair or premium acceptance. Saved five silhouette studies remain provisional. Current blocker is demonstrated art quality, not crop permission. Evidence: `Documents/ClimbCollect-GuardianProduction/2026-10-25/veylith-ai-base/CROP-TRIAL-RESULT.txt`; repo `design/guardian-production-2026-10-25.md`. No paid service, artist, target reduction or publish.

- 2026-10-25 tycoon overnight: actual8 clients, late join and replacement now verified locally; earlier eight-client gap superseded within this scope. Hosted same-account reconnect/budgets/cross-server faults, physical low-end devices, human timing and premium visual acceptance remain open.48h strategy tests are simulations; hourly acquisition assumption is sensitivity only. Avatar-scale visual/animation review remains next feasible work. Source/evidence: isolated design/tycoon-overnight-2026-10-25.md, full path in Milestones. No production data/publish.

- Tycoon avatar-scale/animation inspection completed with a small label-clearance correction in Review06. Prior next-step item is superseded. Remaining acceptance: premium aesthetic judgment, measured human pacing/acquisition, physical low-end devices, hosted same-account reconnect/budgets/cross-server faults. No permission to publish or use production data was inferred. Detailed acceptance matrix remains isolated design/tycoon-overnight-2026-10-25.md.

- 2026-10-25 Guardian next work after v006: break regular feather/crest rhythm, refine eye/beak junction and wing roots, author full folding, bake/retopologize the363,634-triangle source and create adult collectible. Imported GLB split-edge count remains unclosed; current rig proves mild idle only. No finished pair/Roblox acceptance. Exact evidence: repo `design/guardian-production-2026-10-25.md`; external `veylith-blender-refinement/v006-reopen-roundtrip.json`. Earlier instruction to stop is superseded by owner continuation authorization.

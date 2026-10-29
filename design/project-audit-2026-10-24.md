# Mountain Empire project audit and workspace map

> Recovery update, 2026-10-24: W01/W02 complete. Full mountain backup and independent restore verified; HUD recovered clean at `6019525` in `.codex/worktrees/mountain-hud-recovered/climb&collect`. Earlier missing-checkout/session statements below are historical. [Recovery record](workspace-recovery-2026-10-24.md). Integration remains pending.

Audit date: October 24, 2026, America/New_York. Scope: planning, read-only inspection and reversible documentation organization. No game source, Studio scene, Git index/branch, platform setting or external message was changed. [Start here](../START-HERE.md) · [Publishing checklist](publishing-checklist.md).

## Current authority

Use the later explicit decisions and their source records to resolve older text. Do not combine incompatible designs merely because they share this repository.

| Area | Governing record | Reconciliation |
|---|---|---|
| Public launch | Owner reply in this organization chat, October 24 | Full Mountain Empire vision, including advanced services. No reduced launch scope approved. |
| Sanctuary | [Phase 1 blueprint](phase1-multiplayer-environment.md), [size amendment](mountain-empire-step1-revision2.md), [Step 3 record](mountain-empire-step3-review.md) | Eight **180 × 220** plots, 8-stud buffers, 60-stud front access, 35 × 30 lodges. Blueprint/HUD references to 110 × 120 are historical. Step 2 accepted; Step 3 visual acceptance pending. |
| Mountain | [Six-kingdom build record](mountain-empire-six-kingdom-build-2026-10-24.md), continuation `mountain/REQUEST.txt` and `mountain/ENVIRONMENT-PASS.md` | One six-kingdom Impossible Mountain with revised unequal contours. Prior circular-transform preservation was explicitly superseded for this continuation. |
| Interface | [Approved Q1–Q28 blueprint, frozen copy](../evidence/release_audit_2026-10-24/hud-6019525-reference/hud-ui-master-blueprint.md) | Playful/bold responsive landscape UI; three active creatures; automatic basics/manual specials; direct sanctuary spawn; no forced main menu. Missing gameplay was deliberately not invented by the HUD task. |
| Data/economy | Current mountain `Rules`, `Profiles`, `Competition`; [HUD report](../evidence/release_audit_2026-10-24/hud-6019525-reference/hud-ui-implementation-report.md) | Mountain schema 1 is distinct from the old expedition schema. No implicit profile migration or old shop/economy import. |
| Monetization | Q14 and blueprint service contract | Cosmetics and noncompetitive convenience; exact offers/prices still need decisions. Old Foothold Exchange multiplier/external-pass offers are not the new catalog. |
| Older work | Fairground, Expedition, four-mountain/hall/sunny and old creature reference project | Preserved history and potential reusable assets. Not active new-world layout or release acceptance. |

Chat checks supported the latest HUD decisions and Guardian one-capture/Trial direction. Some ChatGPT assistant messages are content-reference placeholders, so the committed blueprint and explicit user messages were used rather than reconstructing unavailable answers.

## Workspace inventory

Complete machine-readable paths, refs, file metadata and status lists: [inventory.json](../evidence/release_audit_2026-10-24/inventory.json). Counts include generated/evidence files and do not count unique features.

| Location | Git state at audit | Role and treatment |
|---|---|---|
| `C:/Users/HOME!/Desktop/climb&collect` | `codex/expedition-fairground`, `e126557`; 20 modified tracked files and over 2,000 untracked files; no staged changes | Original project, sanctuary artifacts, old source, current planning/graph/vault pointers. Preserve all existing changes. |
| `C:/Users/HOME!/Desktop/climb-collect-mountain-continuation` | `codex/mountain-continuation`, `8d2d263`; 33 porcelain-modified tracked files, 4,521 untracked; no staged changes | Current mountain implementation. Some status differences are line endings; meaningful later code/art/evidence is also uncommitted. A branch ref alone does not preserve Final56 work. |
| `C:/Users/HOME!/Desktop/climb&collect-lobby` | `claude/lobby-sunny`, `d695bf2`; 87 porcelain-modified tracked files, 298 untracked; no staged changes | Earlier four-mountain hall/sunny build. Retain separately and reconcile before any future reuse. |
| `.codex/worktrees/mountain-hud-ui/climb&collect` | No `.git`, no source checkout, no baked review file; only evidence remnants found | Handoff's “clean HUD worktree” is no longer current. Cause not established. Commit `6019525` and remote branch/PR retain HUD work; open Studio session preserved. |
| `.codex/worktrees/six-kingdom-mountain/climb&collect` | Unregistered remnants | Earlier recovery incident is documented in the mountain record. Not an implementation workspace. |
| `.codex/worktrees/movement-finish/climb&collect` | Unregistered remnants | Prior damaged checkout; do not resume builds here. |
| `Desktop/mountain-continuation-preserved-2026-10-24` and `Desktop/climb&collect-lobby-sunny-backup-2026-10-23` | Preserved directories without Git links | Recovery material; never infer duplicates from names. Leave intact. |

`git worktree list` currently registers only original, lobby and continuation. Other `.codex/worktrees` folders include four-mountain-movement variants; folder presence does not prove a valid registered checkout. No worktrees/chats were created, archived, moved or deleted.

## Remote integration state

Fresh `git ls-remote --heads origin` confirms:

| Ref | Commit |
|---|---|
| `main` | `23ee172ad8315238ed2c2039838dc139b2a80593` |
| `codex/mountain-hud-base` | `8d2d2635035f580f292ab89221200b1f6ed3981b` |
| `codex/mountain-hud-ui` | `6019525bd8bcdc0e1aed775e6ba71b890f80c155` |
| `claude/climb-collect-thumbnails-fwmnfp` | `2e4286e359f0a493c99e5460c5452e1bcbef7c02` |

[PR #1](https://github.com/theempp/climb-collect/pull/1) is open, draft and unmerged, five HUD commits / 42 files against its frozen base. The user's open-PR listing returned this one PR. A separate issue-search endpoint returned no results and was not treated as authoritative absence. Local `main` is `a2134a8` and diverges from remote; it is not a release candidate.

Fresh comparison still shows **386 files** for HUD versus the merge base with `origin/main`. Do not retarget or merge as a routine UI-only change. The prerequisite history, latest uncommitted mountain work and sanctuary package require an explicit integration plan.

The semantic modified-file intersection between HUD changes and continuation changes is `mountain/server/Main.server.luau`; this includes gameplay startup/mover logic versus HUD request/context wiring. Review this intentionally. The HUD bake uses **ArtPassVerified**, not Final56. Taking its whole Workspace would replace the new world with an older one. Preserve Final56 terrain/world and integrate the selected runtime/UI changes in a new artifact. [Comparison evidence](../evidence/release_audit_2026-10-24/integration-inventory.json).

HUD packaging issues remain: 117 doubled-CR whitespace warnings in `UIRequests.luau`; standalone analysis has 381 diagnostic lines including missing Roblox definitions. A future normalization/type-analysis pass must be scoped and reverify artifact hashes.

## Saved build map

| Build | What it contains | Verification and limits |
|---|---|---|
| `redesign/step3/MountainEmpire.Step3.Environment.Review.rbxl` | Eight plots/lodges, boundaries, landscape, three decorative gates, scenery | Fresh SHA `4f0a0176…` matches, 420,269 bytes. Prior 1,133 protected parts/13 walking legs, zero scripts. No recorded reopen or owner Step 3 acceptance. |
| Continuation `evidence/mountain_2026-10-24/ImpossibleMountain.Natural.Final56.rbxlx` | Latest natural mountain, old mountain HUD, runtime services, 42 encounter models, 18 checkpoints | Fresh SHA `abd259ff…`, 95,378,280 bytes; fresh 44-source/terrain audit passes. Prior saved/reopened startup and complete automated solo route evidence. No new HUD/sanctuary. |
| Git `6019525:evidence/hud_ui_2026-10-24/ImpossibleMountain.HUD.Review.rbxlx` | New HUD over ArtPassVerified mountain geometry | Git LF SHA `43647488…`; prior Windows CRLF SHA `7f45b6d8…`. Prior 21 runtime source matches and reopen. Local file now missing; Git content is recoverable. |
| Lobby `ClimbAndCollect.FourMountains.LobbySunny.Review.rbxl` | Earlier hall, dioramas and sunny trailhead–Camp 1 slice, older expedition loop | Fresh SHA `737364cc…`, 20,114,973 bytes. Prior 125 source reopen and two-client evidence. Separate design. |
| Place `134979185642785` / universe `10772485116` | Older private Fairground test | Publication recorded October 22; current access/configuration not checked here. Not evidence of Mountain Empire publication. |

Full key hashes are in inventory.json. Prior Final56 SmoothGrid SHA `ee89e711945f0d05d495a8d85e87eda2420958e10420f9d58d518a81369cffea` was freshly matched to its explicit Final54 authority.

Place inventory found 51 native place files under original root/evidence/redesign, 49 under continuation, and nine under lobby. These are checkpoint/history counts, not separate approved releases; other paths/backups are listed separately. Source-only Rojo packages are not baked review worlds.

Nine connected Studio sessions were read-only enumerated, all in Edit: ArtPass.Working, ArtPass, ArtPassVerified, Continuation, ContinuationFinal, HUD.Review, Natural.Final56, Traversal, VerifiedTraversal. [Exact IDs](../evidence/release_audit_2026-10-24/studio-inventory.json). No session was started, stopped, saved, closed or repointed. The sanctuary/lobby were verified on disk, not opened.

## Workstream findings

| Workstream | Classification | Evidence and remaining work |
|---|---|---|
| Mountain routes | Verified automated solo; owner review pending | Six normal wins, all six mover loops, twelve branch nests/returns, six shortcut attunements and summit in one fresh run. 985 seconds is bot execution, not human pacing. Final56 requires fresh Trials and shortcut travel acceptance; six-Trial success on older geometry does not certify this geometry. |
| Combat/creatures | Implemented, partially verified | 36 regular species + six Guardians, three-creature team, XP, stages, specialization, normal gates and one-capture Trials. Shared framework/balance, animation/silhouette polish and distinct patterns still need acceptance. Caeloryn abilities 2–4 remain provisional because request text ends after Astral Lance. |
| Eggs/progression | Implemented, integration pending | Three carried eggs, extraction/recovery, timestamp incubation/free hatch, travel, training and income. Existing earned egg loop evidence is from prior mountain build; repeat on combined candidate. |
| Sanctuary/tycoon | Environment built; services absent | No plot ownership, spawn/profile bridge, habitats, placement, building upgrades or functional facilities in script-free Step 3. Current income sums owned creatures, not habitat placement; integrate with an approved economy contract. |
| HUD/accessibility | Implemented against existing services | 419 prior checks / 51 compiles / Rojo build; 50 Studio memory checks; four landscape presets, all 23 tabs, plus large text/contrast. Natural Trial UI, physical touch/controller and combined-world regressions remain. |
| Persistence | Implemented; hosted behavior unverified | `Profiles` chooses memory in Studio, `MountainEmpire_FirstDraft_v1` outside; defenses use `MountainEmpire_Defenses_v1`. Legacy data is incompatible. Session/retry/freeze tests do not prove real reconnect or migration. |
| Co-op/parties | Partial; management missing | Combat can track participants. Invites, finder, membership/readiness and coordinated portals need services and multiplayer tests. Earlier lobby two-client evidence is not Mountain Empire co-op evidence. |
| Raids/friends | Partial; full system missing | `Competition` saves a three-creature snapshot and resolves numeric-UserId stat battles. Target 0 is practice and can currently award coins/trophies: competitive launch must settle whether practice contributes, preventing unintended ranking farming. No full raid-layout/friend-match loop. |
| Recognition/dailies | Missing services | Current read-only milestones/trophies are not global rankings, badges/titles or durable daily claims. All remain full-launch requirements. |
| Shop | UI only, backend missing | Needs owner-approved fair catalog, product/pass IDs, authoritative entitlements and durable receipt handling. Connection-scoped UI retries are not a purchase receipt ledger. |
| Art/audio/assets | Draft art, partly reviewed | Step 2 lodges approved; Step 3 and mountain premium look unaccepted. Four ambience assets loaded in an earlier Studio test. Hosted permissions, audible mix, cues and production performance remain. Later terrain art adds generated mesh/textures, so the earlier ASSETS.md “no imported assets” line is historical. |
| Performance/devices | Isolated desktop/emulator evidence only | Final56 saved scene is substantially larger than early tests. Need streamed working-set and frame-time/memory/load/thermal profiling with full habitats/companions/combat; no mobile or eight-client claim. |
| Release platform | Unresolved for current game | Owner/universe choice, target audience/eligibility, eight-player setting, permissions, products, asset access, listing, moderation and rollback remain. |

Current creature `Catalog` differs from the preserved legacy `creatures/` roster. Legacy has 86 concept images, 42/43 reference choices and a limited Budskip stage-one comparison; Snowfold held. These are not approved production assets for the new 36+6 roster. Preserve `creatures/`, `CC_Creatures` and Stage1; any reuse needs an explicit mapping and visual decision.

## Decisions still needed

1. Owner review of sanctuary Step 3 and mountain Final56 visual quality; recorded captures are not acceptance.
2. Same-place versus separate-place gateway architecture, final gate functions, profile ownership and old-test-data policy. **Builder proposal:** prototype a single-place integration because existing MountainGateway is a same-server BindableFunction; validate coordinate separation, streaming and performance before committing. Separate places require teleport/failure/session-lock design. No architecture selected by the owner in this audit.
3. Habitat/upgrade/economy details; party/raid/ranking/daily rules; fair product catalog/prices. Full feature categories are required; exact numerical rules are not invented here.
4. Caeloryn missing ability specification and combat tuning; practice reward/ranking treatment.
5. Final experience owner/universe and audience (including whether to target under-16 audiences), controller/tablet/Android coverage, lower-end test hardware and additional multiplayer testers.

Owner-confirmed devices: iPhone 16 Pro (owner) and iPhone 18 Pro Max (girlfriend), as reported. Exact OS/model, Roblox client version and graphics settings must be recorded during testing. Controller availability unanswered; neither device result exists yet.

## Evidence quality and freshness

Fresh audit: artifact hashes, current Git/remote/PR/Studio inventory, source inspection, 120+131+657 pure checks, 80 Luau compilation and exact 44-source/terrain Final56 audit. [fresh-checks.json](../evidence/release_audit_2026-10-24/fresh-checks.json).

Recorded earlier evidence inspected: `natural56-audit.json`, `natural56-contracts.json`, `natural56-reopen.json`, `route54-validated-summary.json`; HUD device/reopen/report/PR; sanctuary geometry/walk/file audit; lobby P6 handoff. Studio gameplay was not rerun during this organizational audit. Screenshots inspected: Final54 overview, sanctuary lodge/boundary and committed HUD map; no new art approval inferred.

Entry graph status: CURRENT, zero drift, 3,324 merged nodes / 100 cross-links, one historical overview-heading candidate. Scope excludes continuation and HUD source, native places and root START-HERE (not in the configured root-doc allowlist). This indexed audit/checklist and pointers in CLAUDE/master provide discovery without modifying retrieval code. Final refresh/status lives in `evidence/release_audit_2026-10-24/graph-final-status.txt`; report its actual result, not the entry snapshot. The historical overview status will remain labeled history; quality candidates may persist.

## Organization completed and proposed next

Created a short start page, one checklist and this inventory; added current-status pointers above historical root notes and concise vault pointers. Saved exact HUD blueprint/report copies from commit 6019525 so they remain readable locally despite the missing checkout. These frozen copies are reference material, not a restored working tree. Existing files remain in place.

Next workspace work: hash-verified preservation of dirty continuation assets/evidence, a valid HUD recovery checkout, a narrow integration branch and an explicit source/bake manifest. Keep historical archives where they are. **No physical moves or deletions are proposed or needed now.** New code, merge and publication remain separate future actions.

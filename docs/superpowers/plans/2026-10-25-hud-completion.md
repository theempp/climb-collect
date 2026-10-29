# Locked HUD completion implementation plan

> **For agentic workers:** Use superpowers:executing-plans to execute these tasks. The owner explicitly authorized continuous execution without further design/plan approvals on October 25, 2026. Do not reopen the completed interview.

**Goal:** Finish the approved Playful & Bold HUD presentation and connect every available gameplay action in one recoverable playable Mountain Empire build for morning review.

**Architecture:** Continue the existing MountainHUD controller, widgets, screens, view models and correlated server requests. Base the work on the latest integrated tycoon source, which contains sanctuary, Final56 mountain and the recovered HUD, preserving its gameplay and baked world. Inspect and improve the actual rendered interface; a successful source build alone is insufficient.

**Tech stack:** Roblox Luau, native ScreenGui, existing Rojo 7.6.1 and Luau CLI, Studio MCP, Python XML packaging/audits.

**Spec:** `design/hud-ui-master-blueprint.md` in the source checkout below; exact archival copy also exists at original-project `evidence/release_audit_2026-10-24/hud-6019525-reference/hud-ui-master-blueprint.md`. Tycoon behavior follows `design/tycoon-redesign.md`, not superseded passive-income assumptions.

## Verified starting point (October 25, 2026)

- Original project: `C:/Users/HOME!/Desktop/climb&collect`. Its `src/` is older game history, not the Mountain Empire implementation. Preserve all dirty/untracked work.
- Latest integrated source: `C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/work/climb-collect`, clean at `913a0cc8db4ac908afda20ca437b972aee2b18f6`, branch `codex/tycoon-redesign` when inspected.
- Latest playable baseline: `C:/Users/HOME!/Documents/Codex/2026-10-24/referenced-chatgpt-conversation-this-is-an-4/outputs/ClimbCollect.Tycoon.Review04.rbxlx`. Recorded SHA256 `280e55bc8fd355ec20354a4a88f5ed432e886bddde5d80e199ddcf6a09d9b971`; independently verify before use.
- Previous HUD: commit `6019525`, draft PR https://github.com/theempp/climb-collect/pull/1. Eight hubs/23 original tabs, actual state/intent handlers and accessibility exist. Later tycoon work adds six sanctuary tabs; derive the current inventory from source instead of enforcing historical 23.
- `mountain/client/HUD.client.luau` requires `UI.Controller`; Theme implements navy/blue/gold and FredokaOne/Gotham. Screens routes sanctuary into TycoonHub.
- Specific stale integration: `mountain/shared/UIPresentation.luau:P.capabilities()` still declares habitats unavailable and describes old collection income. Actual TycoonHub and server Tycoon action exist. Correct this with regression coverage.
- Genuine dependency gaps in current Screens: party invites/readiness, daily rewards, rankings/badges/titles, live raids/friend matching and approved paid catalog/receipt integration. Do not confuse these with HUD layout defects or label disabled placeholders as completed gameplay.
- Historical integration checkout `C:/Users/HOME!/.codex/worktrees/f520/climb&collect` no longer exists. Do not launch there. Its integrated source survived in the tycoon checkout.
- Studio inventory includes Review03, Review04, Alpha Review04/05/06 and a separate Veylith asset session. IDs are temporary. Open a fresh HUD-specific review copy; preserve existing sessions and other agents' work.
- Graph CURRENT at initial inspection, but it does not index the isolated Mountain Empire implementation. QUALITY_REPORT has one historical overview-heading candidate; no broken edges. Always verify graph claims in source.

## Global constraints

- Locked Q1–Q28 remain authoritative: Playful & Bold, collapsible left navigation, bottom primary/context actions, exactly three creature slots, currency/timer, compact objective/height, native joystick/jump, CoreGui safe insets, one primary hub, contextual combat, direct sanctuary spawn without main menu.
- Concepts are illustrative, not literal production assets. Preserve the approved visual language while improving actual polish, hierarchy and readability. Do not redesign the game or substitute the older expedition HUD.
- Preserve current tycoon economy, three-member combat, existing profile/schema, sanctuary ownership and mountain geometry. No invented currency, paid advantage, reward amounts, product IDs or badges.
- User authorized implementation and local Studio testing overnight without further approvals. Proceed with reversible implementation choices and verification. No public publishing, purchases, production-data changes or unrelated world/Guardian edits are required.
- Save a full baked playable review with scripts and world, not just a Rojo source package. Never overwrite Review04 baseline.
- Missing gameplay dependencies must remain explicitly recorded. Finish every independent UI task despite them; do not claim 100% end-to-end gameplay when those dependencies or hardware acceptance remain unverified.

## Review focus

1. Short/notched landscape phone with native touch controls and large text: no hidden/colliding buttons or clipped primary labels.
2. Profile refresh while scrolling, editing a team or assigning habitat: retain focus/selection/scroll and never send an unintended request.
3. Rejected, delayed, duplicated or timed-out mutation: show accurate pending/error/retry states; retries cannot repeat spending/rewards.
4. Leaving sanctuary, entering combat, respawning or reopening UI: correct contextual actions, exactly one HUD, native movement still works.
5. Newly available tycoon services vs truly missing services: current capabilities and user-facing copy reflect reality; no fabricated purchase or success.

## Task 1 — Preserve base and produce a current screen/action audit

Files: `design/hud-completion-audit-2026-10-25.md`, `evidence/hud_completion_2026-10-25/baseline.json` in the implementation checkout.

- [ ] Recheck latest tycoon HEAD/status and active work before choosing an isolated implementation branch/copy. Preserve source and baseline with hashes outside transient Codex worktrees. Do not mutate the concurrent tycoon checkout.
- [ ] Read current blueprint, tycoon contract, implementation reports and source. Map all 28 decisions to exact screen, request, server handler and runtime evidence. Record real omissions and the accepted visual references.
- [ ] Run existing Luau test suites and `python mountain/tests/run_ui_server.py`; compile all mountain Luau. Preserve failures and baseline output.
- [ ] Open a separate named baked HUD review and capture baseline sanctuary HUD, expanded navigation, inventory, tycoon, combat and phone layouts. Inspect images yourself, not just bounds checks.

## Task 2 — Complete the approved HUD visual shell

Modify: `mountain/client/UI/Controller.luau`, `Theme.luau`, `Widgets.luau`, `Feedback.luau`; pure layout helpers/tests in `mountain/shared/UIPresentation.luau`, `mountain/tests/ui_presentation.luau` where appropriate.

Consumes: ClientState profile/battle/context and existing shared theme. Produces: one responsive MountainHUD with stable navigation, readable widgets, selected/cooldown/disabled/pending states and consistent visual components.

- [ ] Compare rendered shell with locked layout and correct incomplete hierarchy, oversized/obscuring panels, generic button presentation or unclear creature slots. Use consistent labeled icon treatment, spacing, rounded bold hierarchy and restrained blue/gold accents. Keep center world view readable.
- [ ] Keep native joystick/jump and CoreGui unobstructed. Provide three visible creature slots and contextual special/cooldown feedback. Avoid duplicated hub navigation in the bottom actions.
- [ ] Test short/notched phones, tablet and desktop with large text/high contrast. Test sanctuary/exploration/combat, expanded/collapsed navigation and respawn. Add pure tests for any changed layout/state logic before fixes.
- [ ] Verify loading reflects actual readiness, has retry/error feedback and dismisses into playable sanctuary without mandatory menu. Confirm reduced motion and milestone skip behavior.

## Task 3 — Complete available service wiring and truthful capabilities

Modify: `mountain/shared/UIPresentation.luau`, `mountain/client/UI/Screens.luau`, `TycoonHub.luau`, `ClientState.luau`; existing `mountain/server/UIRequests.luau` and `shared/UIProtocol.luau` only as required for actual integration defects.
Tests: existing `ui_presentation.luau`, `ui_client_state.luau`, `ui_protocol.luau`, `ui_server.luau`, `tycoon_requests.luau`, `run_ui_server.py`.

Consumes: existing `UIRequest(id, action, payload)` / `UIResult` and Tycoon action (`assign`, `swap`, `collect`, `bank`, `upgrade`, `attune`, `cosmetic`). Produces: all already-implemented services reachable through coherent UI with accurate eligibility and authoritative acknowledgements.

- [ ] Add failing regression assertions for stale habitat/income capability descriptions, then align capabilities and objectives with current tycoon contract. Separate capability from player proximity/affordability/unlock eligibility.
- [ ] Walk all current hubs/tabs. Verify creature filters/details/team edits, training/evolution, discovery/incubation/hatching, map/checkpoints/travel, sanctuary assignment/upgrades/automation/production collection/bank/cosmetics, defense/practice, profile and preferences.
- [ ] Fix broken/missing routes, stale context and silent disabled controls. Use concise player-facing reasons; keep backend terminology in developer records rather than prominent game UI.
- [ ] Preserve pending intents through refresh; test timeout and same-ID retry after mutation, rejection, late result and duplicate tap. Show rewards only after authoritative results.
- [ ] Search current source for the missing service dependencies before declaring blockers. Connect any existing approved implementations found. Do not manufacture whole party/economy/commerce systems from option letters or concept art; record exact remaining requirements.

## Task 4 — Interaction, accessibility and visual acceptance pass

Modify/check: `mountain/tools/ui_smoke.client.luau`, `ui_audit.client.luau` and tests alongside changed logic; evidence in the new run folder.

- [ ] Run every current tab through actual Studio UI. Check scroll/focus retention, dismissal, confirmations, tooltips and feedback. Exercise actual mouse/keyboard inputs and emulator touch where supported; keep scripted fixtures labeled.
- [ ] Test native movement after opening/closing menus, death/respawn, repeated hub opening, battle transitions, empty/full inventory/habitats/incubators, insufficient funds and wrong-plot actions.
- [ ] Capture and inspect clean screenshots at small landscape phone, notched phone, tablet and desktop, including large text. Fix clipping, overlap and poor visual hierarchy; repeat affected checks.
- [ ] Run bounded repeated-open/close and connection/instance checks. Report measured scope; do not represent emulator as physical phone or sequential profiles as eight live clients.
- [ ] Obtain independent code review per applicable review skill and resolve important findings. Run necessary final tests once after repairs.

## Task 5 — Bake, reopen and deliver morning review

Files: `outputs/ClimbCollect.HUD.Complete.Review01.rbxlx` (increment rather than overwrite), audit JSON, screenshots, `design/hud-completion-report-2026-10-25.md`.

- [ ] Package using `python mountain/tools/package_hud.py <verified Review04 baseline> <new output>`. Verify exact runtime sources and unchanged protected service/world/terrain hashes. If final native save changes terrain, retain failure and restore intended payload with existing verified tools.
- [ ] Reopen the final disk file in a dedicated Studio session; confirm correct HUD/client startup and available UI actions from the saved build. Keep memory fixtures out of saved source/world.
- [ ] Record exact branch/commit/hash, playable path, current Q1–Q28 coverage, button/service status, screenshots, tests and unresolved external dependencies. Provide a simple morning walkthrough. Completion is evidenced implementation, not merely accounted-for placeholders.
- [ ] Commit only scoped implementation/evidence in its isolated repository; keep an external recoverable source checkpoint. Do not merge/publish as a side effect.
- [ ] Append a concise verified pointer to original project and relevant Climb & Collect vault notes. Run original graph status, refresh if stale, and status again; disclose isolated-source exclusion and remaining drift.

## Autonomous execution and stop rule

Keep working through all authorized tasks, repairing failures rather than stopping at the first limitation. The owner will be asleep and explicitly waived additional routine approval rounds. Checkpoint each meaningful milestone so interruption does not lose progress. If a genuinely unavailable service, credential or physical device prevents an acceptance item, finish the independent UI work and leave an exact blocker; never fabricate completion. End only after a saved, reopened, verified review and actionable report, or a hard environmental block with all independent work exhausted.

## Plan self-review

Q1–Q7/Q10/Q23/Q25/Q27/Q28 are covered by shell and runtime tasks; Q8–Q9/Q11–Q22/Q24/Q26 by screen/action and feedback tasks. The five review risks have explicit checks. Current tycoon replaces obsolete income/habitat assumptions. This is an implementation continuation of the approved blueprint, not a new design requiring a fresh interview.

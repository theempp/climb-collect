# Fairground, portfolio, daily practice and summit review

Local implementation of all four phases is saved on `codex/expedition-fairground`. The final review binary has been reopened and verified. Acceptance remains incomplete for a genuine whole ascent, real multiplayer and physical devices; the exact limitations below must accompany any completion claim.

## Recoverable starting state

The Commerce review was enumerated and reconciled before changes. `ClimbAndCollect.BeforeFairground.rbxl` is the exact starting binary (SHA256 `0a64394b7c34fcb59bba1fe1c773c6e58b3af9439ea42a24c317b5173846ef07`). `evidence/fairground_2026-10-22/starting-source.zip` preserves 1,925 baseline files, including untracked and modified work. The starting manifest and status are beside it. No reset, clean, publishing, access change, purchase, or Robux spending was performed.

Do not reconstruct this project from Git alone. Many preserved baseline sources and large assets were already untracked. The source archive, binary snapshot and working tree form the recoverable project.

## Phase checkpoints

| Phase | Source commit | Local place |
| --- | --- | --- |
| Compact lobby | `be2f7aa` | `Fairground.Lobby.Review.rbxl` |
| Portfolio and HUD | `877be3f` | `Fairground.Profile.Review.rbxl` |
| Daily practice | `92b2f4a` | `Fairground.DailyPractice.Review.rbxl` |
| Summit finale | `ff1f1d5` + `ffb15a2` | `Fairground.Finale.Review.rbxl` |

The final review is `C:\Users\HOME!\Desktop\climb&collect\Fairground.Finale.Review.rbxl`; `ClimbAndCollect.Fairground.Review.rbxl` is an identical working copy. SHA256: `f43448b824929032460c72de3640a2838374c77b6357b14d8d03547d2dc08b45`. Reopening confirmed all 101 manifest sources, zero compile failures, exact original terrain serialization, and unchanged protected assets. Earlier three phase binaries were also reopened and verified against their historical source commits. `Fairground.Practice.Review.rbxl` is an identical alias of the daily-practice checkpoint.

Each phase's saved-source, terrain and reopened protected-asset reports belong in `evidence/fairground_2026-10-22/phase-N/`. Roll back by opening the phase snapshot with its matching sources, rather than rerunning world generators over a mixed scene. The historical source verifier uses unchanged files from the complete starting archive, not incomplete Git HEAD.

## Delivered behavior

The compact Foothold has striped service pavilions, an oversized lantern/carabiner/compass treatment, animated expedition attractions, explicit service anchors, a visible relocated practice crag and two marked open-route approaches. Old structures are recoverable in `ServerStorage.BeforeFairgroundStructures`. Mountain terrain, routes, checkpoint geometry and the protected creature library remain outside the replacement boundary. The existing home allocation and commerce systems use the new anchors. New starter pennant, lantern and frame designs are previews only, with no new active listing or price.

The bright portfolio combines permanent species completion, summit totals, rarity progress, an equipped companion, three owned showcase selections, equipped cosmetics and earned milestones. The owner can open private details and select titles/showcase creatures. Public snapshots exclude private cargo, balance, transaction and failure information. Nearby tags use server-authorized safe-zone/range checks, client visual occlusion, distance simplification and R3 inspection. The own-profile HUD action is separate from Shop. The mountain illustration is original native geometry; portraits reuse existing creature visuals, including existing fallback orbs where the baseline has no species model.

Daily practice is free and rotates at 00:00 UTC among two-, three- and five-section sequences. Timing is optional. Seven nonconsecutive saved daily stamps earn the Practice Pennant. Server events enforce section order, bounds and current day. The monotonic day marker protects grants even after receipt pruning; existing paid training unlocks and stamina progression remain separate.

A fresh expedition records observed route movement, height bands, ordered safe camps, the merge and real traversal events. A safe true-peak arrival commits the finish and immutable result once before presentation. The personal 18-second scene includes an original native rescue helicopter, avatar celebration, winch pickup and departure. Skip, death, respawn, load failure and a watchdog share camera/input cleanup. The result lists route, elapsed time, finds, safely carried creatures, new species, confirmed prizes and the next earned cosmetic. Back to Camp returns beside the bank and preserves cargo without banking. Pending and acknowledged return state survive profile reload; delayed saves keep the character on the protected arrival deck without a permanent input lock.

## Provisional local-review economy

`SummitConfig.reviewEconomy` and `DailyPracticeRules.reviewEconomy` are true. Review values are 50 coins per valid finish plus 100 on the first ever finish; 60 Summit Points plus 140 for the first finish of that route. Earned cosmetic thresholds are 1, 5, 15 and 30 summits. These are not release balancing acceptance. The starter set has no approved pricing or active product IDs.

The scene uses Roblox audio assets 1836473422 (Victory Fanfare Sting, APMOfficial) and 126966962086051 (Helicopter Rotors, roblox_user_3823533951). Both loaded in the local client. Metadata and load provenance are recorded in `audio-provenance.json`; no purchase or permission change was made. Permission at a future published destination is not established by local playback.

## Verification and independent review

The integration fixture suites pass persistence 12/12, Summit 16/16, Daily Practice 19/19, Portfolio 9/9, Commerce 24/24, Expedition 15/15 and Traversal 10/10 with 57 definitions. Separate CLI regressions pass training 4/4, cargo visibility 9/9, traversal rules 14/14, route access 10/10 and summit rules 8/8. All 101 manifest sources compile. These counts are fixtures/automated checks, not real DataStore or multi-client evidence.

The independent reviewer found and the implementation addressed checkpoint allowance recovery, empty-cargo post-acknowledgment lobby recovery, pending-save status, mixed-route credit, accessibility text reflow, safe pending-result containment and tag bounds/occlusion. Public artwork/whitelist additions and audio-load fallback received a further review. The final independent pass confirmed that opaque noncolliding objects block tags, the bounded invisible-volume filter fails closed, and the revised camera framing retains cleanup/fallback behavior. No remaining actionable code findings were reported. This does not substitute for the outstanding runtime checks.

Additional isolated service checks cover delayed-save containment/recovery (3/3) and active/acknowledged reconnect state (4/4). They use real service modules with fake players and private in-memory stores. The landscape portfolio fixture at 705×280 and largest text has zero overflowing labels; it is not real-phone testing.

Actual Play-session observations:

- WalkSpeed-12 walking from a reset spawn position reached Bank in 4.95 s, Collection in 5.03 s, Route Board in 7.32 s, Exchange in 7.03 s, Practice in 7.15 s and Home in 2.05 s. Movement used Humanoid.MoveTo; only each initial spawn position was a fixture. The real home prompt, home entry and return worked.
- Three- and five-stage daily challenges completed using the real traversal controller and physical return loop, with day/start selection injected for coverage. Two stamps were credited; paid training remained level zero. A harness HTTP-export error occurred after the passing assertions; the report preserves this distinction.
- An injected eligible summit with one carried creature and one Rare Heartstone committed 150 coins and 200 points before presentation. Same-server release/reload recovered its pending result without extra prizes. Actual Back to Camp UI input preserved both cargo identities and left bank/codex counts unchanged. Only the subsequent physical bank deposit collected them. Acknowledged empty-cargo reload also returned beside the bank. These are in-memory release/reload checks, not actual network reconnects.
- The reopened final binary played the full cinematic with both audio assets loaded. Replay and actual Space skip restored CameraType.Custom, removed the input action and scene, and showed results. Actual Back to Camp input returned to `(34, 51.98, 2068)` with the original 150 coins/200 points. Console output was empty in this fresh final smoke session.

## Outstanding acceptance and exact reproduction

The genuine full-ascent attempt used normal walking and the real traversal controller, with no position or ascent-evidence injection. It reached Camp 2, band 11, approximately 6,031 observed studs and nine authored traversal sections. It stopped at a preserved Terrain overhang near `(914, 1183, -843)` on Shepherd's Road. Head-level raycasts hit the underside; a navigation sample was above the obstruction. An outward detour caused an ordinary fall back to the earned checkpoint. No summit was awarded. `actual-ascent-attempt.json` records this incomplete run. Terrain/routes were deliberately preserved; a human route investigation or separately scoped route repair and a completed fresh ascent are still required.

Actual two-client testing was not completed. Attempts to access Studio's native Test menu were blocked by foreground-window targeting conflicts; no fake player check is labeled multiplayer. Nearby tag click/occlusion, R3 access, independent simultaneous finales and departure during a real remote response remain two-client/controller checks. PS5-sized viewport rendering and small landscape UI fixtures do not establish physical controller or phone touch behavior. The final files do not contain temporary walking scripts or injected fixture profiles.

## Evidence

All evidence is under `evidence/fairground_2026-10-22/`. Key reports: `final-automated-suites.json`, `service-walk.json`, `daily-physical-circuits.json`, `pending-service-check.json`, `reconnect-service-check.json`, `summit-unfinished-rejoin.json`, `summit-cargo-return.json`, `physical-bank-after-extraction.json`, `summit-empty-cargo-rejoin.json`, `phase-4/reopened-runtime.json`, and each phase's saved/protected verification reports.

Screenshots: `lobby-final-reopened.png`, `profile-art-desktop-fixture.png`, `profile-art-landscape-fixture.png`, `starter-preview.png`, `phase-4/summit-reveal-final-fixture.png`, `phase-4/helicopter-pickup-final-fixture.png`, `phase-4/helicopter-departure-fixture.png`, and `phase-4/winner-banner-cargo-fixture.png`. Profile population and summit eligibility in the labeled screenshots are fixtures; the displayed artwork, UI, camera and helicopter are the implemented native assets.

## Release checks outside this local review

Real DataStore networking requires a separately authorized published test destination. Real phones, physical controllers, human route feel and cinematic pacing require human/device checks. Existing baseline fallback creature artwork remains unchanged. Do not describe injected summit fixtures as a genuine ascent, fake-player service checks as multiplayer, or frame-size fixtures as device emulation.

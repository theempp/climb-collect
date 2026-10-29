# A1 adversarial review (2026-10-20)

Method: Workflow `a1-persistence-review` (run `wf_e66c7d6f-f86`): 4 reviewers (data loss, duplication, session locks / DataStore API, schema) read `Store`, `Profile`, `Bank`, `Inventory`, `Progression`, `CC_CoreService`, `Tests`; each finding then went to an independent skeptic told to refute it. 20 findings, 19 confirmed, 1 rejected. After merging duplicates across lenses: 12 distinct defects. All fixed; 4 regression tests added (suite now 12/12 PASS, live A1 flow re-run PASS).

Notes: findings about real Roblox shutdown/UpdateAsync behaviour come from the reviewers' knowledge of the platform; they could not be run here (unpublished place). Severity = the skeptic's verdict.

| # | Severity | Defect | Fix |
|---|---|---|---|
| 1 | high | `BindToClose` ignored leave-releases already in flight (they lived only in `profiles.active`), so a solo player's last deposit could be cut off at shutdown and rolled back to the last autosave. | `BindToClose` now releases every session in `ctx.sessions` ∪ `pendingRelease` ∪ `profiles.active` and waits (≤ 25 s). Test: "shutdown covers a leave-release already in flight". |
| 2 | medium | An older-build server downgraded a newer-schema profile (version > 1) and stripped unknown fields on load. | Load refuses `version > P.VERSION` without writing ("outdated" banner, retry). Test added. |
| 3 | medium | Same-server rejoin could reuse a pending session while its release was mid-write; the live session then became "released" and silently stopped saving. | Reuse waits for the in-flight write; if it released the profile, load normally. |
| 4 | medium | `save()` waited at most 30 s for an in-flight write, so two writes could overlap and an older snapshot commit last. | Per-session write mutex without a cap. |
| 5 | low | `save()` didn't re-check `released`/`lost` after waiting, so a queued autosave re-took the lock after a release. | Re-check after the wait. Test added. |
| 6 | low | Deposits accepted between a release snapshot and its commit (shutdown with players connected) were acknowledged then dropped. | `session.closing` set when a release starts; `Bank.deposit` refuses while closing. Test added. |
| 7 | low | `pendingRelease` kept a session after the 5-min give-up; a later same-server rejoin could reuse stale data. | Give-up clears it, marks the session lost and drops it from `profiles.active`. |
| 8 | medium (latent) | A player joining while module init yielded got two `loadLoop`s. | `loading[plr]` guard. |
| 9 | medium | Banking stayed open while autosaves failed, so finds banked during an outage could be discarded later. | A failed autosave sets "unavailable" (banner, banking paused) and retries every 15 s; "ok" again after a successful save. |
| 10 | medium | A size-refused save was silent (state stayed "ok"). | Same path as #9 (any failed save → banner + paused banking). |
| 11 | low | No migration for stub ids retired by the Codex roster: codex double-count, first-species XP twice. | `remapRetired` on load (bank, Heartstones, codex keys). |
| 12 | low | Locker items were checked only for uid/species; a malformed item could make `Bank.deposit` throw after `Inv.takeAll`. | `Profile.cleanItem` validates every field; `Bank.deposit` puts malformed items back in the backpack instead of failing. Test added. |

Rejected (1): "save accepts non-finite numbers and the mock stores undecodable values" — the skeptic showed the JSON encode guard already refuses them.

Residual risk (stated honestly): the documented window remains — if the store is down when a player leaves and stays down for the whole 5-min retry, changes since the last successful save are lost (inherent to any DataStore design; banking is paused while saves fail, so no deposit is acknowledged in that window). Real-DataStore behaviour is UNVERIFIED.

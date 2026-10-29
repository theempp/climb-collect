# Movement planning audit — 2026-10-22

The full four-mountain written design remains approved. The scoped [movement plan](../docs/superpowers/plans/2026-10-22-four-mountain-movement.md) is saved and self-reviewed; its implementation review/execution choice is pending. No game source or Studio state was changed in this planning pass.

Verified evidence:

- `evidence/movement_2026-10-22/planning-baseline.json`: four saved builds inspected read-only. FinalCheck retains the recorded SHA256, all 104 current manifest source texts and exact original terrain. Acceptance has terrain serialization drift. Exchange is older; the publish copy is stripped.
- `evidence/movement_2026-10-22/planning-checks.json`: 104 sources compiled, traversal 14/14, route access 11/11, summit rules 8/8 and flight continuity passed. These are existing local code checks, not runtime movement acceptance.
- Studio enumeration contained only `DRS_RUSH_Coastal_RaceControlV3_RC7.rbxl` and `DRS_RUSH_PhoneReview_RC1_NEVER_PUBLISH_local-play.rbxl`. Neither was inspected or modified. Climb & Collect must be opened/reconciled in a separately named local review copy before execution.
- Starting graph status was CURRENT, with no review candidates in QUALITY_REPORT. Starting Git state was extensively dirty/untracked at `e126557`; all such work was retained.

Corrected assumption: the historical bank minimum-travel formula is no longer the active check. Source uses physical distance, Traversal.canBank and checkpoint movement validation plus durable transaction/outcome guards. The plan targets those paths and preserves the one server stamina pool.

Still unresolved: plan review/execution method, actual avatar rig/run asset, actual input/animation/lock behavior, device performance and live persistence. Exact movement values are provisional tuning, not new owner-selected constraints. The absence of a connected Climb & Collect place does not prevent code planning; it prevents claiming live inspection/testing.

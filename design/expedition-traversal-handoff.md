# Expedition traversal handoff — 2026-10-22

The v6 P1 world boundary is preserved. No route/terrain rebuild was performed by this implementation. Root observed `AuthorTraversal` produce 57 authored sections with zero failures and `terrainChanged=false` from the saved V6P1 geometry. The first run had two ladder probes fail; existing LadderGrip geometry now supplies those sections directly.

## Ownership and integration

- `TraversalConfig` and `TraversalRules` belong under `ReplicatedStorage.CC_Core`.
- `Traversal` and `TraversalTests` belong under `ServerScriptService.CC_CoreServer`. Boot Traversal after Camps and before Coop/Training.
- `author_traversal.luau` is the Edit-mode `ServerStorage.CC_DevTools.AuthorTraversal` module. It reads existing authored route tracks, the tutorial markers, and three existing practice walls. It serializes hold graphs under `ReplicatedStorage.CC_TraversalDefs`, disables the old tutorial TrussPart's collisions, and performs no terrain writes.
- `traversal_smoke.luau` is the Studio-only server `CC_DevTools.TraversalSmoke` module. It uses the live DevBridge and returns explicit observations.
- `traversal_route_smoke.luau` is `CC_DevTools.TraversalRouteSmoke`. Call it with `(startIndex, count)` for sorted registry batches; it reports actual entry/clip/selected-section/step/landing observations, continues after failures, returns `nextIndex`, and never writes stamina.
- `traversal_gate_probe.luau` is a read-only Studio probe that reports real supported closed-route candidates outside the old entrance box and a shared/open control. It does not move players or modify objects.
- `CC_ClimbClient` is input/presentation only. Disable the obsolete `CC_TraverseClient` if present. `CC_AscentClient` retains hazards; its independent fall reporter/toast was removed. `CC_WeatherClient` reads authoritative headlamp state.
- `CC_CheckpointService` retains the existing Fell/CampReached/SetCheckpoint contracts and adds server-only AuthorizeMove and synchronous ValidateMovement.

## Behavior

The server owns authored hold IDs, alternating hand state, stamina, rope occupancy, harness catches, flight, movement authorization and checkpoint outcomes. Waiting never incurs mistakes or drains stamina. Stable alternate footholds regenerate a modest amount; wrong/early input costs one stamina and cannot itself cause a fall. Timing assistance keeps the same rewards. Keyboard uses Q/R to avoid the existing E interaction prompt; L1/R1 and touch use separate hand actions. X/B is deliberate release. F/Y is context interaction; C/DpadDown descends an authored section from its top anchor.

Personal harnesses clip once at the lower anchor. Only an active protected climb can become hanging; ordinary walkoffs receive normal fall outcomes. Recover while hanging or accept another player's help, with no rescue currency. Shared ropes use authored top anchors, reduced stamina cost, automatic lower-anchor attachment, and occupancy-safe retirement on expiry/owner departure.

Parachutes are introduced at a valid major camp. They require a fresh server-validated grounded-jump receipt in a camp launch area. Grounding consumes the receipt. Walkoffs and climbing slips cannot deploy. Gentle steering expires safely when input stops. Only the Foothold or a camp no higher than the launch camp is a valid landing. Other landings return to launch with cargo intact; no flight grants checkpoint progression or banks items. This conservative explicit landing rule prevents short-gap and gated-route shortcuts.

Ice effects use actual Ice/Glacier material or `Icy=true`; headlamp state uses night, authored `DarkZone`, or roof/wall occlusion. No altitude oxygen/canister logic remains in traversal. Gear owns avatar visual attachment changes.

`Traversal.travel(plr, rootPosition, kind)` authorizes server movement, preserves cargo, records an expedition travel receipt, and resets fall tracking. Home/shuttle/resume/reconnect travel requests destination streaming while the root is anchored. Home sets character `CC_HomeVisit=true` before homeEnter and clears it after homeReturn. `Traversal.canBank(plr)` requires safe grounded state, no recent unauthorized displacement, and a synchronous displacement validation so a bank request cannot race the next movement heartbeat. A measured fall awaiting its heartbeat outcome also keeps cargo unbankable until that outcome completes.

Closed-route access checks cover the existing Ledge/Spire `CC_Route` and `CC_Track` corridors as well as the Coming Soon entrances. Static segments are spatially binned once, then checked at 5 Hz; nearby open/shared paths, authored open climb graphs, and camp pads take priority. The matching gate's small front approach is exempt so its return point does not repeatedly eject the player; the exemption never extends behind the gate and uses no cooldown. Rejection waits for settled ground so it cannot rescue an ordinary fall. No collision rails or terrain changes are involved. The saved closed route data remains inaccessible; it is not a world-expansion approval.

## Verification and limits

Traversal-owned Luau sources compile with `tools/.luau/luau-compile.exe --null`. The pure CLI tests passed 14 traversal-rule checks plus 10 route-access geometry checks. Root reported the actual tutorial smoke passed 10/10 after its entry was repaired to the measured stable approach, with seven authored holds. All 57 scripted section clip/step/landing checks passed after a targeted repair of `Waterfall:storm:45`: its old exit was a 45.1-degree terrain lip with missing foot support. Its repaired exit uses existing flatter terrain with an eight-point foot support check and clear headroom; root's six-second follow-up remained grounded with no fall. The other 56 section definitions remained unchanged. Root owns Studio tests and final source/place reconciliation. Final gate/flight tests, mobile feel, two-player rope/rescue behavior, and performance remain separate checks; compiler and rule tests do not establish them. Use `TraversalTests.run()` for ten rule/graph checks, `TraversalSmoke()` for actual tutorial transitions, and `TraversalRouteSmoke(start,count)` for batched section validation. The tutorial smoke temporarily disables timing assistance and restores it and the player's starting position.

The authoring tool now resolves unsupported legacy bot entry coordinates against existing stable ground and marked faces, and reports `entryWarnings` separately from graph construction failures. Root's latest Edit-mode validation reported 57 sections, zero failures and zero entry warnings, with world/protected object counts unchanged. Post-authorized-move grace suppresses displacement rejection only; it no longer suppresses physical fall sampling, including a walkoff immediately after topping out.

Persistent HUD/menus/settings/message queue, Gear, Training purchases/completion, camp shuttle transaction, cargo persistence and home courts are other agents' integration responsibilities. The world expansion playtest gate remains explicitly unapproved.

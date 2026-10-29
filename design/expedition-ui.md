# Expedition interface handoff — 2026-10-22

## Implementation

Owner: `src/runtime/CC_CoreClient.client.luau`. Root integration owns Studio sync, runtime verification and the saved place. The protected creature project was not edited.

- Compact HUD: stamina, altitude with region markers, backpack capacity/full state, level and slim XP progress. Currencies live inside Backpack. Home courts show `HOME` instead of their off-map construction altitude.
- Expedition tabs: Backpack, Collection, Routes, Settings. Collection has paginated Creatures, Heartstones and Memories views. Heartstone progress is readable anywhere; placing/hatching and earning assignments remain physical home actions.
- Shared slate sheet with warm trim, restrained display typography, scrolling content, pinned close/continue actions and 48–50 px minimum menu targets. No screen-scale shrinking. Default content page size is 12 entries to bound UI instances.
- Station sheets: camp locker, compare/swap, home directory and visitors, home nests/habitats/earnings/upgrades, finite practice sections. Visitors receive no owner action buttons.
- Settings: standard/larger/largest text, reduced motion, timing assistance, automatic/manual-darkness headlamp preference. The server persists settings and validates their values.
- Existing fallback creature artwork is retained. Its display labels now use readable region/ecology names such as Foothill Hopper; stub IDs, rarity, ecology and roster replacement behavior are unchanged. Real roster names and protected creature assets were not edited.
- Tutorial objective, edge arrow, wisp and per-player creature/nest/guardian/drop visibility are retained. Obsolete shop, canister, timer and camera-takeover paths are removed.
- One prioritized notice queue. Save recovery, notices and tutorial prose share one message band in that priority order. On the shortest phones the band defers while traversal controls need its space; a save-status summary remains in the HUD. Hidden notices retain their dwell time. Menus show notices in their footer. Loss cards, hatch/discovery messages, level and welcome reveals wait until the player is grounded and no menu is open. No camera takeover.

## Connected contracts

All outcomes use `CoreState`, `CoreToast` and `CoreFx`; the UI never awards or moves inventory locally.

- Bank: `st.bank.status/message/retryable`; `bankRetry{}`. A bank success message comes only from the server's committed `bank` effect. Retry remains subject to the campfire proximity check. Loading requests are read-only status checks every five seconds.
- Cargo: `st.swapOffer{token,item,sourceName,expiresAt}`; `swapConfirm{token,uid}` or `swapLeave{token}`. Closing the sheet leaves the encounter. Locker movement uses `lockerStore/lockerTake{uid}` and `lockerClose{}`.
- Travel: `st.travelOffer`; `shuttle{}` returns cargo to the Foothold entrance. No landing/travel action claims to bank items. Stored items appear as camp summaries from `st.lockers`.
- Home entry: physically interact with an existing cabin doorway, choose own home or another current player's home in `st.homeDirectory`, then arrive beside the home station with its sheet open. The physical station reopens management. `homeReturn{}` returns to the same doorway. `st.inHome` keeps a return action available in Backpack.
- Home management: server `st.home` drives two nest slots, stone selection, earning spaces, explicit Equip Best, collect, pet and upgrades. Collection favorites/companion requests work anywhere. Income is displayed **per hour** and the amount is marked as the last check. Collect remains enabled so the server can settle income accrued since that snapshot; no stale client estimate blocks collection. Nest progress preserves fractions.
- Practice: interact with the existing StartGate, unlock/start a section using `practiceBuy{id}` / `practiceStart{id}`. The server validates actual authored wall completions. UI has no completion timer or reward-generation code.
- Routes: server descriptors use `status`; Ledge and Spire always display Coming Soon. Routes/Map provides information without remote entry or teleport actions.

## Input

- Expedition: `M` keyboard or `Select` gamepad; 50 px touch button.
- Close an open panel: `B` gamepad at CAS priority 3100. It sinks the input before traversal's deliberate-release binding. Outside menus it passes through.
- Traversal owns Q/R, L1/R1, F/Y, Tab/D-pad right (foothold choice), C/D-pad down, X/B and its bottom contextual controls. Ordinary proximity prompts use E/ButtonX; traversal anchor prompts explicitly use F/ButtonY. `CC_MenuOpen` suppresses traversal inputs while sheets are open. Global HUD remains at the top; the traversal action bar remains at the bottom.
- Proximity-prompt holds cancel when menus open/close, active input device changes, window focus is lost, traversal state changes or stagger occurs. Device changes update help text in place, so the first touch/click is not swallowed by rebuilding its target. Native movement/camera controls are not rebound.

## Verification status

**Verified locally:** Luau compilation using `tools/.luau/luau-compile.exe --null src/runtime/CC_CoreClient.client.luau` passed for the final UI including the Studio probe and compact/input-switch fixes (67 KB bytecode). Cross-checked visible actions with Home, Cargo, Camps, Training and CoreService handler names. Home agent independently reviewed the home contract. Static inspection found no canister/shop/Heartstone timer/camera-takeover path.

**Studio results reported by root in this session (before the subsequent overlap/compact-header repair):** desktop Settings sheet rendered at 920×650 with no targets below 48 px. iPhone 13 landscape safe viewport 749×330, sheet 725×314 at (12,8), Backpack content canvas 225 px / view 137 px; readable screenshot and no small targets. Galaxy A06 safe viewport 705×280, sheet 681×264 at (12,8), Settings text scale 1.3 canvas 844 px / view 87 px; no small targets or TextBounds clipping. Keyboard M opened the menu. Injected ButtonSelect did not change the active input type or menu state, so actual gamepad operation remains unverified.

**QA repair following those observations:** compact landscape Expedition headers use the tab row as the header when sheet height is under 330 px. This adds 55 px of content height without shrinking buttons (expected Galaxy view 142 px; awaiting remeasurement). Static overlap inspection found the former bottom notice band overlapped traversal by 10 px at safe height 330; messages now share one top band and defer if it intersects the actual traversal panel on shorter screens. The Studio probe now includes `textOverflows` from rendered `TextFits`/`TextBounds`. A device-switch review also removed sheet rebuilding from `LastInputTypeChanged`, preserving the first click/tap when input changes. Compilation passes after these changes (67 KB bytecode).

**Later gameplay evidence reported by root:** actual Studio loops passed bank failure/retry, full-backpack swap, manual home hatch, shuttle/locker/rejoin and practice lesson 1. These results are separate from the local checks below; the root delivery report owns complete runtime evidence and saved-place identity.

**Final practice persistence repair:** the server retains an actually completed lesson while a save is busy, retries every 0.5 seconds, waits for its original durable callback when uncertain, and prevents a new start from replacing the queued finish. `python tools/training_regression.py` reproduced the original lost finish, then passed 4/4 actual-module tests: busy save/overwrite, uncertain confirmation, receipt replay and invalid wall/leave cleanup. `Training.luau` compiles (7 KB). Success feedback is never emitted for an unconfirmed or replayed receipt.

**Hidden Heartstone outcomes:** `Cargo.clientItem` copies client views and removes only a Heartstone's unrevealed species. Swap, Backpack, camp locker, banked home stone and loss-effect views use that projection; authoritative species, identity and discovery provenance remain intact. Nest snapshots and bank effects already omitted hidden species. Hatched creatures/companions still expose their visible species. `python tools/cargo_visibility_regression.py` reproduced the preview leak, then passed 9/9 assertions against the actual Cargo and Inventory modules. All five touched modules compiled (63 KB combined).

**Still pending at this handoff:** fresh post-repair phone/touch measurements, actual gamepad input and final source/checksum verification. Root is performing fresh Studio checks. No human playtest or real-device test is claimed.

Studio-only, visual/read-only probe under `LocalPlayer.PlayerGui.CC_CoreUI.CC_UIProbe`:

```lua
probe:Invoke("open", {tab = "Settings"}) -- Backpack / Collection / Routes / Settings
probe:Invoke("audit") -- viewport, sheet bounds, smallTargets, button count, scrolling heights
probe:Invoke("close")
```

The probe does not mutate profile or inventory state. It exists because Studio MCP and running LocalScripts do not share `_G`.

## Ordered player review

1. Join, check loading clears, then inspect stamina/pack/altitude/XP and tutorial guidance.
2. Open all four tabs on desktop and a landscape phone. Change text size; scroll every sheet; confirm the close action remains reachable. Ledge/Spire must say Coming Soon.
3. Fill the backpack, compare a new find, swap one and reclaim the safely returned original. Verify capacity and item descriptions update only after server confirmation.
4. Store/retrieve at a camp locker; inspect its remote summary; take the shuttle with cargo and walk to the campfire. Confirm no travel action banks items.
5. Bank; inspect Collection/Heartstones/Memories. Trigger a save-failure test through the root test harness and verify pending/retry copy never claims success early.
6. Enter a cabin, place two banked stones, leave and bank fresh expedition finds, inspect fractional progress, return and deliberately hatch. Assign creatures, Equip Best, pet, favorite/companion, collect and upgrade. Visit another player's home and verify it is read-only.
7. At practice StartGate, unlock/start lessons and complete authored walls. Repeat an earned lesson and verify no duplicate gain.
8. Switch keyboard/gamepad/touch while climbing; open/close a menu; lose focus while holding a prompt. Verify no stuck held inputs or accidental release. Check release remains separate from primary climbing actions.
9. Cause a real fall and confirm calm loss guidance waits for ground. Discover a creature during traversal and confirm no camera takeover or blocking celebration interrupts it.

## Known verification limits

There are no newly sourced audio assets in this UI. Functional feedback is visual and does not require audio. Phone emulation does not measure real-device performance. The runtime tests and final saved-place identity belong in the root expedition delivery report.

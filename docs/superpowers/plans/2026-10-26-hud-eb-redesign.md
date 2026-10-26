# E+B playable HUD redesign

**Goal:** Apply the owner's approved E+B image direction across the actual playable HUD and eight existing hubs.
**Architecture:** Retain the current server/profile/request boundaries; replace shared visual components and responsive placement. Patch runtime Source into a new baked Review06 binary, preserving every non-Source chunk. Rojo builds an additional editable source package.
**Spec:** `design/hud-ui-master-blueprint.md` plus the October 26 owner request and attached E+B target.

## Integration ruling
Main contains the blueprint but not the functional runtime. PR #1 / 6019525 adds the HUD. Tycoon 0751c9b descends from it; later HUD completion and free-climb/sprint/mountain work descend through the local implementation history to b97ddc0. Use that committed Review06 source and its exact baked place. The active compact-mountain dirty checkout and Play session belong to ongoing work and are excluded. Never rebuild the mountain or restore older terrain.

## Visual decisions
Navy enamel panels, cyan rims, gold actions, Fredoka headings and Gotham body. Layered illustrated icons with readable labels, large three-slot creature portraits, compact top status, corner objective and collapsible navigation. Quiet climbing center; native movement stays untouched. No mock hearts, gems, commerce or rewards.

## Tasks and checks
- [x] Shared visual system: Theme/Widgets/Feedback/Screens. Consistent icons, cards, tabs, dialogs, disabled states and loading. Compile and inspect all hubs.
- [x] HUD: Controller plus pure responsive geometry module. Test short/notched/tablet/desktop bounds, native control avoidance, combat and expanded navigation. Preserve exactly three slots and authoritative cooldowns.
- [x] Integrate Sprint into the same safe action region without changing server-owned speed or locomotion.
- [x] Build a source package and source-patched playable binary; assert all non-Source bytes unchanged and all current runtime sources match.
- [x] Cold-open Studio, Play, audit every hub/tab and loading/settings/respawn; capture actual phone/desktop HUD and hubs. Compare to target and repair gaps.
- [x] Run full inherited regression/compilation, review diff, commit branch and draft PR. Append backed-up project/vault records and report graph freshness. Stop before merge/publish.

## Review focus
Short phone native movement bounds; large text; scrolling/focus during profile refresh; sprint versus combat actions; trustworthy success only after server acknowledgment.

User explicitly requested continuous implementation and routine autonomous decisions; no further design interview or plan approval is needed.

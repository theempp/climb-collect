# Independent review and repairs

October 26, 2026. Read-only reviewer inspected the current diff against b97ddc0. No critical server-authority regression found. Two P2 findings:

1. Portraits rendered over the upper eight pixels of level/cooldown labels. Corrected by giving the state pill an explicit ZIndex above its portrait and an opaque navy backing. `hud_state_audit.client.luau` asserts this ordering.
2. Expanded horizontal navigation overlapped the journey panel between safe heights390 and549. Corrected by using the horizontal-navigation breakpoint550 to hide journey during expansion. The state audit asserts this condition; a750x450 simulator run is required on the final artifact.

Minor repaired: slot background color was overwritten by W.enable; assignment now follows W.enable.

All final checks and captures are recorded separately; review alone is not runtime verification.

Later review: initial hints could cover touch tablet navigation during the first24seconds. Reproduced as a failing fresh-Play assertion on Review04; fixed with not-expanded visibility. Review05 cold tablet audit verifies the repair. A tablet native-region audit also moved touch navigation to the horizontal strip; desktop retains its sidebar.

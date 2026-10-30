# HUD polish review (P4), 2026-10-29

Judged against `hud-polish-plan`, build plan §2 P4 + Owner answers, and `hud-polish-tokens` (A1–A10 + owner answers). Studio captures only, so pixel values are estimates. Blank device icons are out of scope (R1).

## Verdict: **ship with fixes**
All 7 tasks are visibly done at i16p and 844. Two items still need evidence before the phone republish: the touch controls at i16pm, and a cash/s readout that has only been seen at 0.00.

## SHOULD FIX
1. **i16pm touch controls are missing from every capture.** `after/states/i16pm_rest.png`, `i16pm_sanctuary.png`, `i16pm_sanctuaryOpen.png` show no thumbstick or jump button (i16p and 844 show both). This means "no overlap with jump/thumbstick" is unverified on the largest phone, and the expanded card (bottom H−78, w 262) has not been checked against the jump button there. Fix: recapture i16pm with touch enabled (rest, sanctuaryOpen, chase, carry, battle; chase/carry/battle are also missing for i16pm and 844 lacks carry/battle). No layout change is expected.
2. **Cash/s has only been seen at "0.00 coins/s" while showing "3 creatures".** `i16p_sanctuary.png`, `844_sanctuaryOpen.png`. Per A10 that is valid only if nothing is producing. Fix: add one capture with a producing fixture (for example "0.03 coins/s") to confirm the Q2 client calculation and the `%.2f coins/s` copy actually render. Otherwise "readable numbers" (P4) is unproven.

## NIT
3. **Compact sub-line legibility at i16p.** `i16p_sanctuary.png`: "3 creatures · 0.00 coins/s" at `T.t.smallHud` 11, `T.textDimT[3]`, sits over a bright world backdrop and is the weakest text on the HUD. It is within spec (L174), so leave it unless the owner flags it on the phone. If they do, use `T.t.pcardMeta` weight at 11 rather than a new size.
4. **Shop wallet pill crowds the close button.** `hubs_844/20_Shop_Featured.png`, `hubs_i16p/20_Shop_Featured.png`: the "0 +" wallet sits about 6 px from the × and straddles the panel edge. This predates this pass and is not in the 7 tasks; note it for a later pass, don't fix it now.

## Verified, no finding
- **Title pills:** centred on the panel axis and straddling the top edge in all sampled hubs (Settings, Profile, Shop at both sizes). They hug their text, and the 23-on-36 text is optically centred (O6 OK). Shop text is centred with the chest overhanging left and the right tail visible (A5, O4 as answered).
- **Tabs:** label (and icon group) centred both ways, with equal height and gap. "Achievements" fits with margin (`hubs_844/18_Profile_Achievements.png`). The active state reads clearly (gradCta + glow).
- **Top-right:** coin pill + gear sit in the topbar row, clear of the Roblox buttons. No health bar or "SAFE RETURN" HUD element.
- **Card:** compact shows exactly name·Lv, XP, creatures · coins/s. Expanded reveals 5 circles with about 10 px clear above the dock and is centred on the dock axis (O5). The motion/tap JSON reports collapse on tap-again, tap-outside and hub-open.
- **Dialogs:** confirm = pink pill (`i16p_dialog_confirm.png`). Reward = gold pill, no chest or tails, still reads as a reward (`i16p_dialog_reward.png`).

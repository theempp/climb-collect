# Private phone playtest overwrite #2 — 2026-10-27

Supersedes the earlier same-day overwrite (`phone-playtest-republish-2026-10-27.md`).

**Why the phone showed the old build:** the first overwrite did land (API `updated` 14:18 UTC, PlaceVersion 5). It published HUD E+B Review05, which is built on the MountainQuality Review06 world and has **no home promenade**. The build that combines the HUD with the promenade, PhoneCandidate02, had gone to a different place, 139426549461023 ("Phone Candidate"). Old servers may also have kept the earlier version. I could not read the Creator Hub version list because neither browser was signed in.

**Owner choice (popup):** home base = Home Promenade; publish PhoneCandidate02 as-is.

- Published: `C:\Users\HOME!\Desktop\ClimbCollect-PhonePublish-2026-10-27b\ClimbCollect.PhonePlaytest.Candidate02.rbxl`, SHA256 `482deef4a17290961bd04448dd8aff445e951514fef2d9eaf9d5a1792026e017`. It is identical to `climb-collect-integration/outputs/ClimbCollect.PhoneCandidate02.rbxl`. Never saved in Studio, so the terrain is untouched and no SmoothGrid restore was needed.
- Contents: E+B HUD, compact mountain, Home Promenade with GrandGate, bats and theft, and Mossbun (clips on owner-owned asset ids).
- Target: File › Publish As › "Climb & Collect - Private Playtest" › Overwrite, with asset permissions granted. Afterwards Studio showed PlaceId 134979185642785, GameId 10772485116, PlaceVersion 7 (was 5). The games API showed `updated` 2026-10-27T19:12:57Z.
- Checks on the copy: HTTP off; `StudioAids=false`; no dev-tool, QA or StudioTests objects (only gameplay `Checkpoints`); 99 script containers. Studio Play: one `MountainHUD`, HomePromenade and GrandGate present, console only the ready line.
- Unchanged: access (private, creator-only per the API), devices, products, Robux, the thumbnail, MaxPlayers 12 (the file value; 8 still to set in Creator Hub). HUD Review05 source is unmodified (`72118419…1E8E`).
- **Owner on the phone:** fully close the Roblox app, reopen it, and join from the game page. Any server started before 19:12 UTC still runs the old version.
- Not verified: real phone play, live DataStore save and rejoin, Mossbun clip playback on the live server, multi-client play on the live server, and the Creator Hub version list.

## Owner phone result (2026-10-27, after full app restart)
- Phone shows the new build, home promenade included. **HUD rejected:** "super basic, super sloppy", not the locked-in look. Compared side by side: the approved E+B target (`climb-collect-integration/evidence/hud_eb_2026-10-26/approved-layout-reference.png`, options B+E: illustrated icon tiles, glossy buttons, hearts, currency pills with +, quest card, creature portraits) against the build (`final-phone7-hud.jpg`: flat text tiles). The build kept the layout but not the visual style.
- Owner wants the HUD rebuilt in the style of Steal an Egg / Break and Steal an Egg. Per the no-defaults rule, this needs real screenshots of both games in `references/ui/` before atlas or any build work.
- Max Players: owner sets 8 in Creator Hub (guided); not yet confirmed.
- Still unverified: live DataStore save and rejoin, Mossbun clip playback on the live server.

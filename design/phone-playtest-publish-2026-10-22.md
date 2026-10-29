# Private phone playtest publish — 2026-10-22

## Verified result

Roblox Studio published **Climb & Collect - Private Playtest** as a new experience owned by the signed-in creator account. Studio's completion dialog said it was ready to test and available only to the creator and collaborators. Phone support was checked in the publish form; no testers were invited and no public release was selected.

- Place ID: `134979185642785`; universe ID: `10772485116` (read from the linked Studio DataModel after publication).
- Phone entry: `https://www.roblox.com/games/134979185642785` while signed in to the creator's Roblox account.
- Publish source: `Fairground.Polished.FinalCheck.rbxl`, SHA256 `ea4b63e78c20f7b25ac8fcb90c1db1de248df339fd34d91fd35a50c02e5930bc` (the previously verified acceptance bytes).
- Separate stripped local copy: `ClimbAndCollect.PhonePlaytest.Publish.rbxl`, SHA256 `016b0db8dae65a3123f7d88b7e0e6c8cfcb2b1354b0272c480f350eab2ce2b22`. Studio's file save reserialized `Terrain.SmoothGrid`; the copy was backed up and that one property restored to exact source serialization. All other Terrain properties matched. The cloud upload was made from the same stripped Studio DataModel.
- The publish strip removed `CC_DevTools`, `CC_Checkpoints`, `CC_Generators`, `CC_Prototypes`, and `CC_CoreServer.Tests`. Saved-file inspection found none of those named roots, no added script sources, and exact terrain relative to the verified source. HTTP was off. A stripped Studio Play session loaded the core server and one client with no console output; this used the in-memory store at PlaceId 0, before publication.
- Product platform IDs remained zero; checkout was not activated. No Robux was spent. Summit and daily-practice rewards retain provisional local-review balancing.

Evidence: `evidence/publish_phone_2026-10-22/terrain-restoration.json`, `evidence/publish_phone_2026-10-22/PhonePlaytest.BeforeTerrainRestore.rbxl`, `scratchpad/verify_phone_publish.py`, the linked Studio PlaceId/GameId readout, and the private-ready confirmation dialog. The original acceptance file was not overwritten.

## Limits and next review

No physical phone run, live DataStore bank/leave/rejoin, or same-account network reconnect has been observed yet. The creator should open the link in the Roblox phone app using the same account, run the first claim → bank loop, leave and rejoin to check persistence, and report controls, route feel, load time and any errors. Friends remain uninvited until the owner approves.

The publish wizard showed Team Create and Roblox data sharing enabled by default; neither setting was changed in this session. The publish copy is a private review build, not a public or monetized release.

Corrected assumption: the file named `Fairground.Polished.Acceptance.rbxl` had drifted to a different SHA256 after its handoff. `Fairground.Polished.FinalCheck.rbxl` retained the exact handoff hash, so it was used as the source of this publication.

## Thumbnail update — 2026-10-22

The owner-selected `C:\Users\HOME!\Desktop\thumbnail2.png` (1344×752, 1,848,659 bytes; SHA256 `3D07E4C69F186DC5FE196187834427A4A121C2709244111D383199F13212BAAA`) was uploaded to the Creator Dashboard's Home Page and Experience Detail Page thumbnail tabs for this place. The Home Page upload initially showed `In review`. On a later check the activation checkbox became available; it was selected and **Save Changes** was clicked. The dashboard then showed the uploaded image with status **Active**.

Evidence: Creator Dashboard `https://create.roblox.com/dashboard/creations/experiences/10772485116/places/134979185642785/thumbnails`, Home Page tab showing the exact image and **Active** status. The Experience Detail Page upload was submitted, but its final display state was not independently verified. Remaining review: confirm the image appears in the Roblox phone app's experience listing.

## Experience icon correction — 2026-10-22

The owner's phone screenshot (`C:\Users\HOME!\Desktop\Photo Oct 22 2026, 9 27 22 PM.png`) showed the default Roblox square icon beside the title, while the chosen wide art appeared in the large thumbnail area. This corrected the assumption that activating the Home Page thumbnail would also populate the experience icon.

A square icon using the owner's chosen art was generated and saved at `design/climb-collect-experience-icon-2026-10-22.png` (SHA256 `8D54AC924F243A0526FEB03F35666E86B1625B4DFA6B0A7148ABA6549B30FDFC`). Prompt: recompose the provided thumbnail for a 1:1 mobile experience icon with the cracked rainbow egg, red-hoodie adventurer, shadow creature, sky islands, and exact Climb & Collect title. Creator Dashboard preview showed the intended square image. `Save Changes` was clicked on `https://create.roblox.com/dashboard/creations/experiences/10772485116/places/134979185642785/icon`. The post-save icon briefly changed to Roblox's white checklist/hourglass moderation placeholder, then showed the chosen image. A full dashboard reload again showed the chosen image with Save Changes disabled, verifying it persisted in the icon slot. Appearance in the phone app remains unverified.

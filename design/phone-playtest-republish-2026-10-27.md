# Private phone playtest overwrite — 2026-10-27

Overwrote PlaceId `134979185642785` (UniverseId `10772485116`, "Climb & Collect - Private Playtest") via Studio File > Publish As > existing place > Overwrite. Studio then reported the place name/ID and universe as above; no new place created.

- Source: `ClimbCollect.HUD.EB.Review05.rbxl` (HUD E+B Review05 on MountainQuality Review06), SHA256 `72118419291110636F04DB796C471BF146F2B00C64B9DE3A2975FF8F4EEE1E8E`, left unmodified.
- Published copy: `C:\Users\HOME!\Desktop\ClimbCollect-PhonePublish-2026-10-27\ClimbCollect.PhonePlaytest.Review05.rbxl`, SHA256 `908C53347C4BDED94FA95CBBAE50F40E13FBBC580D4B498911439D3EA2151F77` (saved after strip).
- Strip: removed only `ServerScriptService.MountainServer.StudioTests` (unreferenced). No CC_DevTools/bridges/checkpoint/generator roots or QA agents existed in this build; 85 scripts remained (84 after strip). HTTP off. Terrain not touched (copy not re-serialized beyond Studio's normal save; SmoothGrid restore check NOT run).
- Studio asked to grant asset permissions to the destination experience; accepted (needed for assets to load).
- Not changed: access (still creator/collaborator-only), phone eligibility, products, Robux. Thumbnail/icon from 2026-10-22 untouched.
- Unverified: real phone play, real DataStore persistence, stripped-copy Play session, SmoothGrid exactness, hosted load.

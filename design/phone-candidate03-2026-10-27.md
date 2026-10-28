# PhoneCandidate03 — 2026-10-27

`outputs/ClimbCollect.PhoneCandidate03.rbxl`, SHA256 `9a1f4fec0b3fedd107901fc2eeb7ff51167ca7bf19baff760dea71ad7d8f7eae` (2,691,912 bytes). Base: PhoneCandidate02 (`482deef4…e017`, re-hashed after this build: unchanged).

## What changed
Only `ServerScriptService.MountainServer.Profiles` (the brief said `CC_CoreServer`; Profiles is under `MountainServer`, one copy in the place). Source = `mountain/server/Profiles.luau` at `80dcd52`: `[CC-SAVE]` prints on load OK/FAIL and save OK/FAIL, skipped in Studio.

## Build method
1. PC02 file copied to the PC03 path, opened in Studio, Profiles source set via the Studio MCP (stdio client). The write was guarded: the Studio source had to equal `80dcd52^` exactly (it did).
2. Studio Ctrl+S (owner). Raw save kept as `outputs/ClimbCollect.PhoneCandidate03.StudioSave.rbxl` (`388b789c…e671`).
3. That save changed Terrain `SmoothGrid` + `Materials` bytes with no terrain edit (the known Studio save drift, as in PC01). Both restored from PC02 with `mountain/tools/restore_terrain_payloads.py` into the final file. Audit: `evidence/phone_candidate03_2026-10-27/phonecandidate03-terrain-audit.json`.

## Verified (final file decoded offline against PC02)
- All 70 Terrain properties byte-identical to PC02; the other 1,796 chunks untouched by the restore.
- Same 89 classes / 13,707 instances; parent tree and every reference property identical once referents are resolved.
- Of 99 scripts only Profiles differs, and it equals the repo file (normalized text; project checksum 1665938709 in Studio). Compiles (`luau-compile`, Studio `loadstring`).
- Remaining byte diffs are Studio noise: editor Camera CFrame/Focus/OrthographicSize, `UniqueId` of 4 Studio `FilteredSelection` objects, referent renumbering.
- `ReplicatedStorage` attribute `StudioAids = false`; `HttpEnabled = false`; no `UIProbe`, `StudioTests`, QA or fixture objects.

## Not verified
- Final file not reopened in Studio (checked by decoding only).
- API Services: an experience setting, not in the place file; not touched.
- No Studio persistence test (none gated for this; `[CC-SAVE]` prints are skipped in Studio anyway).
- `[CC-SAVE]` output itself: only appears on a hosted server. Not published; experience untouched.
- Studio still has PC03 open. Saving it again would overwrite the final file and bring back the terrain byte drift.

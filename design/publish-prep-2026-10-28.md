# Publish prep (2026-10-28)

Docs only. No code, Studio file, platform setting, product or Robux was touched. The integration worktree (P6 motion) was not edited. Related: [D03/E01](d03-e01-launch-rules-2026-10-28.md) · [D04](d04-release-config-2026-10-28.md) · [checklist](publishing-checklist.md).

## 1. Owner decisions recorded today

| Topic | Decision | Effect |
|---|---|---|
| Season length | **Weekly**, Monday 00:00 UTC (matches the locked scope doc and the built `Seasons`). | D03's "monthly" line is superseded. |
| Login streak | **Hard reset on a miss**, 7-day track. | D03's "no penalty for missing days" is superseded. Open flag stays: harsh for casual and young players; no streak-saver. |
| Q01 | Closed for server logic. | See section 2. |

Both D03 lines were written the same day as the scope doc. Treat the table above as final and update `d03-e01-launch-rules-2026-10-28.md` when convenient.

## 2. Q01 triage

`design/q01-server-review-2026-10-28.md` does not exist. The Q01 record is the "Q01 adversarial pass" section of `Desktop/climb-collect-v1services/design/v1-services-build-report.md` (branch `codex/v1-services`, 39/39 suites, 113/113 compile, 194 service checks).

| # | Finding | Status |
|---|---|---|
| 1 | Client could drain the DataStore budget and starve profile saves | Fixed + regression test |
| 2 | Old vault transfers re-credit after the applied ring rolls | Fixed + regression test |
| 3 | Revenge chains forever and skips the attack cap | Fixed + regression test |
| 4 | Abandon/disconnect dodged the trophy loss; client could pre-run plans | Fixed + regression test |
| 5 | Loot reported as granted when not saved | Fixed + regression test (`saved` flag) |
| 6 | Robux exclusion relied on an untagged field | Fixed + regression test (allowlist) |
| 7 | `UIPresentation.quest` still checks `schema==2` | **Open, HUD chat.** One token: `>=2`. |
| 8 | Friendly raids unlimited | Fixed + regression test (10/day) |

Still open for the hosted beta (not Q01 blockers): live DataStore, OrderedDataStore, MemoryStore party codes, TeleportService, BadgeService, `GetFriendsAsync` and budget guard are untested. Studio was never run for v1-services. Boost effects and egg-ticket redemption are not wired. Accepted residuals: free reroll, practice and friendly counters can be restored by a crash before autosave, with no reward granted.

Integration order from the report: land HUD P2 server additions, then merge `codex/v1-services` (dry run clean), apply the `quest` token, run a Studio pass on a new copy, then the hosted alpha.

**Conflict with D03 to resolve later:** D03 says offline raids take only a small capped amount of coins. The built outpost raid has a capped vault plus trophies, shield and revenge. Check the vault cap against "small" before the hosted beta.

## 3. D04 tester roster (eight-client test)

Target: 8 clients, 8 plots. Known testers are from the checklist (A02). Slots 3-8 are blank on purpose.

| # | Role | Device / platform | Account | Status |
|---|---|---|---|---|
| 1 | Owner | iPhone 16 Pro, phone touch | owner | Known |
| 2 | Girlfriend | iPhone 18 Pro Max (reported), phone touch | not collected | Known, model unverified |
| 3 | Owner desktop | Windows keyboard/mouse | owner alt or same | Proposed |
| 4-8 | Open | Owner chose a **mixed plan**: 1-2 owner desktop clients plus friends the owner names; task to borrow an iPhone XR-class device for the floor | not collected | **Open: friend names** |

Gaps that matter more than head count:
- No device at the declared floor (iPhone XR-class). The 30 FPS claim in the listing has no evidence until one is found. Borrow one, or raise the floor.
- Eight real humans are not required for Q03. Owner can run extra clients on desktop (Studio Test Session), but that does not replace phone coverage.
- Hosted tests need Creator Hub access for each tester, which needs separate authorization when P04 starts. No invitation has been sent.

## 4. G06 audio picks

### What exists (all load in Studio; loop audit 2026-10-24)

| Use | Name | Asset id | Source note |
|---|---|---|---|
| Blossom/birds ambience | Mountain Birds 1 (SFX) | 9112832288 | Creator Store, 31.5 s loop |
| Waterfall ambience | WaterfallLoop | ~~137800539959141~~ → **9120550423** | Was a 2.7 s individual upload. Now Waterfall Cu 1 (SFX), ProSoundEffects, 36.0 s, on branch `codex/audio-swap` (see §6) |
| Astral wind | AstralWind | 9125742262 | Creator Store, 33.2 s loop |
| Lava ambience | LavaLoop | ~~318794788~~ → **9112823563** | Was a 74.9 s individual upload. Now Lava Rumble 2 (SFX), ProSoundEffects, 59.8 s, on branch `codex/audio-swap` |
| Summit fanfare | Victory Fanfare Sting | 1836473422 | APMOfficial; load-checked 2026-10-22 |
| Helicopter | `rotor` (SummitConfig) | ~~126966962086051~~ → **9113417759** | Now Bell Huey Helicopter Rises For Takeoff 2 (SFX), ProSoundEffects, 8.5 s one-shot played looped, on branch `codex/audio-swap` |
| UI click | volume_slider.ogg | `rbxasset://sounds/volume_slider.ogg` | Roblox built-in |

Loading in a local Studio client does **not** prove ordinary players can hear them under the new universe (P05). Creator Store assets are usually fine; re-check after publish.

### Gaps (nothing exists yet)
Music for sanctuary and each kingdom; footsteps by surface; egg strike, hatch and reward stings; Guardian combat and telegraph cues; UI per-action sounds; Trial and raid music. Only four ambience loops exist for six kingdoms; which kingdoms they map to is not recorded here.

### Proposed approach
1. Owner approves a short list of categories (popup below).
2. I search the Creator Store through Studio's `search_asset` and return candidates with name, creator, length and loop notes. I will not assign ids I have not seen.
3. Owner auditions in a Studio copy. I verify each pick with `GetProductInfo` + `PreloadAsset` and log it in the G05 manifest.
4. Settings: separate Music / SFX / Ambience levels and a visual equivalent for combat cues. The Glassbloom Settings board has an Audio section (commit `91c0ce0`); which sliders it holds is unverified.

### Search results (2026-10-28, Creator Store, free, via Studio `search_asset`)

Searched through an unnamed Studio instance that had no named place; nothing was inserted and no place was changed. Owner chose all four categories. **Nothing below is auditioned, length-checked or load-checked.** Names and lengths come from search metadata only. Id = Creator Store asset id.

Trust rule: only `APMOfficial` and `ProSoundEffects` (licensed libraries, as already used for the fanfare and birds) are shortlisted. Random-uploader hits were dropped, including rips of other games' audio (Half-Life 2, Sonic, Lobotomy Corporation) that carry copyright risk.

| Category | Candidate | Id | Creator | Note |
|---|---|---|---|---|
| Area music (calm/sanctuary) | Circadian (b 60) | 9043416517 | APMOfficial | 60 s, "awe, rich strings, warm piano". Loop seam unchecked. |
| Area music (mountain) | Summits (a 60 b) | 9048114707 | APMOfficial | 60 s per name; genre unknown. |
| Area music (astral/night) | Time and Stars (a 60) | 1841880628 | APMOfficial | Name only. |
| Area music (cold) | The Thaw (a) 60 / (c) 60 | 1841379361 / 1841379381 | APMOfficial | Name only; may suit snow kingdom. |
| Guardian fight | Battleground | 9048538012 | APMOfficial | Name only. |
| Guardian fight | Honour Thy Enemy - Underscore | 9045526997 | APMOfficial | 193 s, "ominous, tense hybrid orchestra", edit points 0:52 / 1:42 / 2:11. Good for phases. |
| Guardian fight | Pavane (60 Sec) | 9042354071 | APMOfficial | 60 s, heroic choir/percussion. |
| Capture / victory | First Prize | 9043483039 | APMOfficial | 80 s triumphant hybrid with climax + outro. |
| Egg/hatch sting | none found | | | Searches returned only novelty uploads and Christmas jingles (Kosinus "Folky Christmas 2" glockenspiel cues: wrong season). Keep the existing Victory Fanfare Sting for rare reveals; need a different search. |
| Footsteps | none trustworthy | | | Only hobbyist uploads. Fallback: Roblox's default character footsteps until a licensed set is found. |

Limits: the Studio search is weak at SFX; ProSoundEffects footstep/sparkle sets did not surface. A manual browse of the Creator Store audio tab by the owner, or a paid library, may do better. Several music picks are 60 s clips and need a loop-seam check.

## 5. P06 listing prep (draft, not entered anywhere)

- **Title:** Climb & Collect (working; owner confirmed 2026-10-28). The October 22 private place is "Climb & Collect - Private Playtest" and stays separate.
- **Short description (draft):** Climb the Impossible Mountain, find hidden nests, hatch creatures, and build a sanctuary for your collection. Face six Guardians. Play on phone or PC.
- **Supported devices to state:** iPhone XR-class or newer, desktop keyboard/mouse. Gamepad, tablet and low-end Android not supported at launch (D04).
- **Players per server:** 8.
- **Claims to avoid until verified:** performance numbers; "free to play" wording that hides Robux offers; any feature not in the shipped build (raids, rankings, shop) if it launches disabled; anything about the egg skip or coin packs not being pay-to-win, since E01 flags them.
- **Paid-content disclosure:** the Robux shop is live at launch per E01, so the listing needs Roblox's paid-item and random-item rules checked at P02. Eggs with odds and pity must show odds.
- **Questionnaire (audience/maturity):** owner answers in Creator Hub; not drafted. Suggested honest flags: fantasy combat vs creatures, in-experience purchases, social chat.
- **Icon/thumbnails:** `design/climb-collect-experience-icon-2026-10-22.png` is Fairground-era and should not be reused as is (P06 forbids inherited Fairground claims). Needs new captures from the Glassbloom build. Capture after P6 motion lands.
- **Moderation:** icon and thumbnails need Roblox review before launch; allow lead time.

## 6. G05 asset manifest (current, partial)

| Class | State |
|---|---|
| Audio | 6 Creator Store ids + 1 Roblox built-in. Creator/license looked up 2026-10-28 from Roblox's public asset-details endpoint (table below). After the swap on `codex/audio-swap` (commit `a01dc31`), all 6 are ProSoundEffects/APMOfficial library assets. |
| Animation | `Sprint.client.luau` uses Roblox default animations 507767714 (R15) and 180426354 (R6). Guardian motion is procedural. |
| Meshes/textures | No `MeshId` or texture asset ids appear in `mountain/` or `src/`. World geometry is parts/CSG/terrain. |
| Creature art | 86 concept PNGs and Blender/GLB source for Guardians exist outside Roblox (`creatures/`, `Documents/ClimbCollect-GuardianProduction/`). **None are uploaded**; no 43-species or Budskip import (checklist rule). Catalog is 36 species + 6 Guardians. |
| Products | All ids 0. Checkout disabled. |

### Audio provenance (looked up 2026-10-28)

Source: `economy.roblox.com/v2/assets/{id}/details`. "Free" means the Creator Store lists it as free to use. It is not a license grant, and the endpoint does not return license terms.

| Id | Registered name | Creator (user id) | Created | Free | Risk |
|---|---|---|---|---|---|
| 9112832288 | Mountain Birds 1 (SFX) | ProSoundEffects (7462895450) | 2022-03-16 | yes | Low. Licensed library, "Courtesy of Pro Sound Effects". |
| 9125742262 | Plasma Trails Constant Airy Whooshing Windy (SFX) | ProSoundEffects (7462895450) | 2022-03-17 | yes | Low. Library. The game calls it "AstralWind". |
| 1836473422 | Victory Fanfare Sting | APMOfficial (7462718749) | 2018-05-25 | yes | Low. Library. |
| 137800539959141 | waterfall1_looped | SpectrumSprinkles (557158590) | 2024-11-03 | yes | Medium. Individual upload, no license text. Only 2.7 s loop. |
| 318794788 | Lava Bubbling Boiling Loop | dearjournal (34021456) | 2015-11-10 | yes | Medium. Individual upload from 2015; description is a kitchen-sound tag list, and the game uses it as lava. |
| 126966962086051 | Helicopter Rotors | roblox_user_3823533951 (3823533951) | 2024-09-01 | yes | Medium. Anonymous-style account, empty description. Fairground-era; check whether the sanctuary still uses it. |
| **9120550423** | Waterfall Cu 1 (SFX) | ProSoundEffects (7462895450) | 2022-03-17 | yes | Low. **Replaces 137800539959141.** Checked 2026-10-28. |
| **9112823563** | Lava Rumble 2 (SFX) | ProSoundEffects (7462895450) | 2022-03-16 | yes | Low. **Replaces 318794788.** Checked 2026-10-28. |
| **9113417759** | Bell Huey Helicopter Rises For Takeoff 2 (SFX) | ProSoundEffects (7462895450) | 2022-03-16 | yes | Low. **Replaces 126966962086051.** Checked 2026-10-28. |

The three replacements were applied 2026-10-28 on branch `codex/audio-swap`, commit `a01dc31` (worktree `Desktop/climb-collect-audio`, cut from `0b3eceb`; not merged). Status: **metadata verified, not auditioned by ear**, not load-checked in Studio (no safe Studio instance was free). The endpoint returned `IsPublicDomain: true` for each (shown here as "free").

None is verified-badge. Three individual uploads have no provable license and could be taken down or flagged after publish.

Recommendation: keep the three library assets. Replace the waterfall, lava and helicopter with ProSoundEffects/APM equivalents before launch, or accept the risk. The waterfall is also too short to loop cleanly. The replacement search is part of the G06 audition. The same rule applies to the music shortlist (APM only).

### Replacement candidates for the three individual uploads (owner approved replacing them, 2026-10-28)

All ProSoundEffects (same licensed library as the birds and wind), free, found through Studio `search_asset`. Lengths and descriptions are from search metadata. **Not auditioned, not load-checked.** First picks applied on `codex/audio-swap` (see "Applied swap" below). Audition in a Studio copy and check loop seams before merging.

| Replaces | Candidate | Id | Length | Note |
|---|---|---|---|---|
| WaterfallLoop (2.7 s) | Waterfall Cu 1 (SFX) | 9120550423 | 36.0 s | "Constant, liquid rushing, washing over, airy". Best first try for a distant-to-mid fall. |
| | Waterfall Cu 2 (SFX) | 9120550276 | 55.6 s | "Midway up, heavy water flow, constant". Heavier and longer. |
| | Waterfall Cu 1 (SFX), second take | 9120550180 | 27.0 s | Same family, shorter. Two different assets share this name. |
| LavaLoop | Lava Rumble 2 (SFX) | 9112823563 | 59.8 s | Category tagged "Loop": thick, rumbling, eruptive. Closest to the old role. |
| | Lava Rumble 1 (SFX) | 9112823552 | 46.0 s | Same family, shorter. |
| | Toxic Fire 2 (SFX) | 9112887827 | 50.8 s | Deep growl and thuds; more menacing alternate. |
| Helicopter Rotors | Bell Huey Helicopter Rises For Takeoff 2 (SFX) | 9113417759 | 8.5 s | One-shot takeoff, not a loop. Fits the helipad moment; a hover loop was not found. |

Searches for helicopter loops returned only community uploads (some taken from other games), so those were skipped. "Lava Rumble" is rumble, not bubbling; the old kitchen-pot bubbling had a different character, so expect the lava to sound less liquid.

### Applied swap (2026-10-28, branch `codex/audio-swap`, commit `a01dc31`)

Metadata check 2026-10-28 (`economy.roblox.com/v2/assets/<id>/details`): all seven candidates above show creator ProSoundEffects (7462895450), AssetTypeId 3 (Audio), `IsPublicDomain: true`, not for sale. Name, creator and duration match the search notes. **No Studio load check** was run: the only open Studio instances were an unnamed one, the Glassbloom review file (off limits) and a DRS Rush file. **None is auditioned by ear.**

The first picks ship as defaults. To try an alternate, edit the id line:
- `mountain/world/World.luau:254`: `WaterfallLoop='9120550423'` → `'9120550276'` (Cu 2, 55.6 s, heavier) or `'9120550180'` (Cu 1 second take, 27.0 s).
- Same line: `LavaLoop='9112823563'` → `'9112823552'` (Lava Rumble 1, 46.0 s) or `'9112887827'` (Toxic Fire 2, 50.8 s).
- `src/core/shared/SummitConfig.luau:5`: `rotor='rbxassetid://9113417759'`. No alternate yet.

Behaviour notes, from reading the code only:
- **Helicopter.** `SummitCinematic.luau:49` creates `rotor` with `Looped=true`. It starts at t=4 s and runs until the 18 s cinematic ends (14 s), with volume ramped by flight phase. The new clip is an 8.5 s takeoff, so it **restarts once at about t=12.5 s**, close to the departure at t=13. The code still works, but the restart may sound like a hiccup. The owner should judge by ear. Fixes if it sounds wrong: find a true hover loop, or set `Looped=false` (silent from about 12.5 s to 18 s). Also, `SummitCinematic.luau:50–53` **skips the whole cinematic** if either sound fails to preload, so a load check matters here.
- **Existing place files keep the old ids.** `World.luau:255–256` sets `SoundId` only when it creates a missing Sound. Any saved place that already holds `SoundService.WaterfallLoop` / `LavaLoop` (for example the Glassbloom review copy) keeps the old ids until those two Sounds are deleted before the world build, or the line is changed to always set `SoundId`. The helicopter is unaffected because it is created fresh from config on each cinematic.
- **Stale-id fix (commit `daab403`, same branch).** `World.luau` now sets `SoundId` on every build, not only on creation, so existing places pick up the new ids without deleting the Sounds first. Guarded by `mountain/tests/run_world_sounds.py` (fails on the old code). Suites 41/41 pass.
- **Studio load check** (new unsaved Place1, closed without saving): ContentProvider:PreloadAsync -> Waterfall 9120550423 IsLoaded true, TimeLength 36.02 s; Lava 9112823563 true, 59.80 s; Helicopter 9113417759 true, 8.50 s. Run through the Studio command bar via computer use; all three load, so the cinematic preload gate passes.
- Sound names, volumes (Controller.luau:264) and loop flags are unchanged. Tests: `tools/run_all_tests.sh` 40/40 pass. The task named `mountain/tools/run_all_tests.py`, which does not exist at this commit. No suite loads these ids.

Other classes (animations, meshes, creatures, products) have nothing to fill: see rows above. Nothing is uploaded and nothing is copied from old manifests.

**Audio LOCKED (2026-10-28, owner):** the three first picks are final; the ear check was waived and the helicopter restart is accepted. Only the merge and the hosted hearing check remain.

# Audio + juice plan (2026-10-28)

Design only. No game, Studio, asset or Robux change. Builds on [publish-prep §4 and §6](publish-prep-2026-10-28.md) (audio search, provenance). Grep of the integration worktree finds sound code only in `mountain/world/World.luau` (ambience) and `mountain/client/UI/Controller.luau`; no `HapticService` anywhere. So nearly everything below is new.

## Rules
- One module, `Sfx.luau` (ids, volumes, groups, cooldowns), mirroring how `Motion.luau` is the one motion-tokens file. No sound ids inline elsewhere.
- Four SoundGroups: **Music, SFX, Ambience, UI**. The Settings board's Audio section (commit `91c0ce0`) must drive all four; verify it does.
- Only licensed-library sources (ProSoundEffects, APMOfficial). No asset id is assigned until checked with `GetProductInfo` + `PreloadAsset` and logged in the G05 manifest. Never invent ids.
- Every audio cue that carries information (Guardian telegraphs, danger) also gets a visual equivalent. Respect "Reduce effects".
- Limits (PROPOSED): max 24 concurrent sounds, per-event cooldowns, pooled Sound instances, preload only the current area's set, lower caps on LOW graphics.
- Haptics: `HapticService`, phone only, check `IsVibrationSupported`, off under "Reduce effects", own toggle in Settings.

## Tier 1 — build first (most feel per effort)
| Moment | Sound | Juice | Haptic |
|---|---|---|---|
| Egg strike / grab | short impact + crack layer | small hit-pause (2-3 frames), egg wobble | light |
| Egg secured (bank) | warm confirm chime | coin burst, counter tick | medium |
| Hatch reveal | build-up riser -> reveal sting (rarity-tiered, Victory Fanfare Sting stays for rare+) | screen flash, camera push, creature pop-in | heavy on reveal |
| Catch / rank-up | rising sting | banner slide + particle ring | medium |
| Fall / egg lost | low thud + dropout sting | brief desaturate, shake (gated) | strong |
| UI | tap, open, close, back, locked, purchase success | existing Motion tokens | none or very light on purchase |

## Tier 2
- Footsteps by surface (grass, stone, snow, wood). Search found no trustworthy licensed set yet; fall back to Roblox default footsteps meanwhile, and source via manual Creator Store browse or a paid library.
- Guardian telegraph, attack, hit and defeat cues + matching visual flash.
- Ladder purchases (new): escalating "level up" sting per step, bigger at x16/x32, so the doubling ladder feels rewarding.
- Quest complete, daily claim, streak milestone.

## Tier 3
- Area music per kingdom (APM shortlist exists in publish-prep §4: Circadian, Summits, Time and Stars, The Thaw, Honour Thy Enemy, Pavane, First Prize). Check loop seams; crossfade 2 s; music ducks under stings.
- Home-base sounds: habitat ambience, creature idle voices (a few shared per body type, pitch-shifted, not one per species).
- Sanctuary ambience mix by time of day if the day cycle ships.

## Juice beyond sound (Motion.luau owns animation; coordinate with HUD chat)
- Reward count-up with ease-out and a final "pop".
- Idle creature micro-animation in the Collection screen.
- Shop step card: next-ladder-step pulse, price/effect preview.
- Screenshot-friendly hatch reveal card (rarity, name, share-sized framing).

## Mix targets (PROPOSED, tune by ear on phone speakers and headphones)
Music -18 dB below SFX peaks; ambience under music; UI quietest of the SFX; stings duck music 3-4 dB for 1 s.

## Build order (after the merge settles; HUD and Motion files belong to other chats)
1. Settings audio sliders verified, SoundGroups created.
2. `Sfx.luau` + Tier 1 cues with placeholder-safe fallbacks (silent if load fails; nothing blocks gameplay or the summit cinematic).
3. Haptics layer + Settings toggle.
4. Tier 2, then Tier 3.
5. Owner ear pass on a real phone; log final ids in the G05 manifest.

## Open
1. Owner approves tier order and the haptics default (on).
2. Source for footsteps and egg/hatch stings (search found none).
3. Who edits HUD-adjacent files, since the HUD chat owns them.

# Foothold Exchange — local implementation handoff

Implemented 2026-10-22 against the explicitly approved integration plan. Open **ClimbAndCollect.FootholdExchange.Review.rbxl**, then Play. This is an unpublished local review file with PlaceId/GameId 0. No publishing, access changes, product listings or Robux spending occurred. All 15 product/pass IDs remain zero and native checkout is disabled.

## Delivered

- Gold/purple responsive shop, scrolling catalogue, next-tier ladder, contextual offer details, shared owned/partial/pending states, HUD offers, and confirmed-grant reward reveals. Phone HUD offers sit between movement controls; shop entry avoids the existing status and tutorial areas.
- Six permanent total earnings tiers: 2×/4×/6×/8×/10×/12×, draft step prices 3/9/19/39/79/149 Robux. Bank discovery rewards and home income multiply once; home income settles at the old rate before a tier changes. Existing balance, XP and earned-only Summit Points are unaffected.
- Exact purchased packs: 100/350/900/2,000 coins at draft 9/25/59/119 Robux, never multiplied. The receipt ledger, balance and reveal commit atomically through Profile; paid IDs survive the 96-entry general receipt trim.
- Camp Glow 19 Robux; lantern/banner individually 19, pennant 3, trail 5. Bundle ownership unions components. Partial bundles direct to the missing item. Equipping changes the headlamp casing, back pennant, bounded trail and cabin banner; respawn/reconnect restore them. Reduced effects disables the trail, while original lamp illumination remains unchanged.
- Three market plinths and two bank displays in `World.CommerceDisplays`; server distance checks and per-player ownership labels. Separate 1,500-coin permanent lamp decoration, owner-station purchase/equip only; no automatic spending after a coin purchase. Existing home upgrades remain 60/180/420 coins.
- Dynamic client Roblox prices expire and recover after transient failure. Unknown/unavailable prices disable checkout. Savings/value comparisons use returned prices. Native prompt completion alone cannot grant coins. External upper passes remain pending until earlier tiers are owned; overlapping entitlements union without duplicate benefits.

## Verification

| Check | Result |
|---|---|
| Commerce suite | 24/24, fake Store/Marketplace adapters |
| Existing persistence / Expedition | 12/12 and 15/15 |
| Studio traversal | 10/10; 57 authored sections |
| Browser commerce model | 8/8 |
| Training / cargo visibility | 4/4 and 9/9 |
| CLI traversal rules / access | 14/14 and 10/10 |
| Compilation / embedded saved source | 73 files compile; all 72 manifest sources present |
| UI | Desktop; 844×390, 667×375 and Galaxy A06; largest text 1.3, categories/detail scrolling, no audited small targets/text overflow/horizontal overflow |
| Fresh runtime console | Empty after final focus/open/close checks |

Failure cases include unknown/forged input, missing/lost/closing sessions, concurrent/replayed receipts, 110 intervening general transactions, uncertain commit/reconnect, metadata/ownership failure, stale ownership after a yield, duplicate checkout, cancellation, size-limit rejection and client-price spoofing. Button B reward dismissal was reproduced failing, fixed, and verified without a reopening loop; transient-price recovery also followed a failing-to-passing regression.

Single-client gameplay verified real market prompt selection and OWNED label, disabled zero-ID checkout, costume respawn/reconnect and unequip, reduced effects, remote lamp-purchase rejection, 2,000→500 coin installation, duplicate install rejection, lamp equip/unequip, and lamp ownership/visual restoration after reconnect. Buying the pack left the lamp uninstalled until explicitly purchased.

**Still unverified:** real Roblox metadata/regional prices/native purchase dialogs, restrictions/top-up/cancellation, paid receipt delivery, real DataStore networking/shutdown across live servers, external storefront visibility, real devices/controllers, and actual simultaneous multi-client home visits/ownership. Separate-player balances and concurrent writes were tested in fixtures; visitor authorization uses the existing owner-and-physical-station guard, but an actual visitor session was not run. These are release checks, not claimed passes.

## Evidence and preservation

See [evidence](../evidence/commerce_2026-10-22): desktop shop/reveal, phone shop/HUD/reveal, market owned merchandise, bank displays, cabin offer and equipped decoration, JSON test reports, saved verification and source preservation report. [Product setup checklist](commerce-product-setup.md) lists separately authorized launch work.

Backups: `starting-source.zip`, `ClimbAndCollect.BeforeCommerce.rbxl`, and the pre-terrain-restoration review snapshot in that evidence folder. Work is on `codex/foothold-exchange`; existing unrelated working changes were retained. Six pre-existing files under src/ changed for integration; the sync manifest was updated and ten manifest modules/tools were added. The 1,663 baseline concept/creature files are hash-identical, including the original six-concept prototype and approved concept. Protected Studio folders retain 179/186 descendants, two development checkpoints and 24 gameplay checkpoints.

Studio reserialized Terrain.SmoothGrid when saving. The review file restores the backup's exact serialized terrain property using `tools/restore_commerce_terrain.py`; all other terrain properties already matched. The saved verifier now confirms every Terrain property byte-for-byte and all embedded sources. Repeat this verification after future Studio saves; do not regenerate terrain. The pre-restoration file is recoverable. The restored review file reopened successfully: 24/24 commerce checks, a grounded character, five displays and an empty console. Studio is left in Edit with HTTP off and the default viewport.

Paid ledger measurement: 1,000 GUID-sized purchase IDs add 43,999 JSON bytes (~44/ID), excluding pending reveals and other profile data; the existing profile budget is 3,500,000 bytes. There is deliberately no eviction. Model expected usage before launch; if growth approaches the budget, a tested atomic archival design is required. An independent datastore write is not an atomic replacement.

## Reproduce locally

`python tools/verify_commerce.py ClimbAndCollect.FootholdExchange.Review.rbxl`

In unpublished Studio Server Play: `require(game.ServerStorage.CC_DevTools.CommerceChecks).run()`.

Studio-only grant example: `game.ServerStorage.CC_DevBridge:Invoke("commerceTestGrant", {offerId="bundle"})`. For coins, use `{offerId="coins2000", purchaseId="review-unique-id"}`; replay the same ID to verify no duplicate grant. These hooks require unpublished Studio and are absent from player UI. The PlaceId 0 store resets when Play stops. No real account persistence is implied.

Client UI audit: `game.Players.LocalPlayer.PlayerGui.CC_CoreUI.CommerceRoot.Review:Invoke("open")`; `"section", "Coins"` or `"audit"`. Production purchase actions carry only stable offer IDs. Reward reveals are delivered from durable CoreState rather than transient CoreFx; CoreFx handles opening the selected offer.


## Fairground redesign local review — 2026-10-22

All four implementation phases are saved in `Fairground.Finale.Review.rbxl` (identical working copy: `ClimbAndCollect.Fairground.Review.rbxl`). Final integration source: `ffb15a2`; phase commits: `be2f7aa`, `877be3f`, `92b2f4a`, `ff1f1d5`. Read [the implementation handoff](fairground-implementation-handoff-2026-10-22.md) before continuing. Reopened binary verification passed for 101 sources, exact terrain and protected assets. Independent code review findings are resolved. Genuine whole-ascent acceptance remains incomplete at a preserved Shepherd terrain overhang; real multiplayer, physical phone/controller and DataStore networking remain unverified. Do not treat injected summit eligibility or profile release/reload fixtures as these tests. No publishing or commerce activation occurred. Starting dirty/untracked work is recoverable in the local starting-source archive; Git alone is not the whole project.

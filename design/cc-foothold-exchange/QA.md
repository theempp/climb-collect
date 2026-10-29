# Verification record — 22 October 2026

## Automated economy checks

`node --test design/cc-foothold-exchange/model.test.cjs`: **8 passed, 0 failed**. Tests initially failed with the missing model, then passed after implementation.

- All six next-only upgrades at 3, 9, 19, 39, 79, 149 Robux; total 298; permanent cap 12×.
- Purchased packs grant exact amounts at 12×; bank earnings multiply to 600.
- Replayed receipt ID does not debit or grant again.
- Bundle grants both cosmetics; fully owned items cannot be repurchased.
- Partial ownership blocks bundle and allows only missing item.
- Insufficient balance does not mutate state; top-up return permits subsequent purchase.
- Stale tier quote cannot grant a second tier; duplicate cosmetics blocked.
- Cabin requires enough coins and spends 1,500 once.

## Executed live browser checks

- Open and close shop, including return to gameplay and retained balances.
- All four category buttons scroll the actual catalogue. Header position stayed constant while catalogue scroll changed; catalogue overflow is vertical only.
- All six upgrade purchases completed through details → simulated native prompt → pending receipt → confirmed receipt → reveal. Browser-verified prices and granted tier names matched the brief.
- Coin packs bought at 12×: balances **1,250 → 1,350 → 1,700 → 2,600 → 4,600**. Collect then produced **5,200**, exactly +600 earned coins.
- Insufficient Robux, cancellation at native prompt, cancellation from top-up, return with demo Robux, cancellation at receipt stage, and eventual confirmed bundle receipt. No cancelled stage granted ownership; selected bundle remained available.
- Full bundle ownership showed both lantern and banner in reveal and an owned message on the map. Separate lantern purchase caused the bundle to show a missing-item action directing to the banner.
- Each of five physical displays opened the correct product: bundle, pennant, sparkle trail, next multiplier, 100 coins.
- At 12× with pennant and sparkle owned, the first HUD offer became the repeatable **100 coins / 9 Robux**, and opened that exact detail. The capped upgrade banner has no misleading purchase CTA.
- Cabin: 1,250 balance → 250 shortfall → optional 350-coin pack → 1,600 balance → no-Robux install → 100 coins and installed state.
- Local save survived reload; reset restored starting values and ownership.
- Browser error/warning log was empty after desktop purchase tests.

## Layout and visual verification

Visually inspected desktop shop, map/HUD, cabin shortfall and purple reward reveal. Inspected real embedded **844 × 390** and **667 × 375** landscape viewports, including shop, gameplay and compact-phone purchase flow.

Layout audit at both phone sizes: page horizontal overflow false, catalogue horizontal overflow false, open catalogue scrollable true, shop within viewport true, visible gameplay-control overlap list empty. Closed shop naturally reports catalogue scrollable false because it has no rendered box.

Fixes found during review and visual QA:

- Removed the capped 12× banner's ambiguous fallback CTA; cheap offers remain in HUD and catalogue.
- Removed the unexplained HUD percentage badge; the shop retains the explicit bundle-vs-separate comparison.
- Shortened partial-bundle physical tag and gave ownership labels their own smaller, wrapping button typography.
- Compressed short landscape shop header and made its featured bundle horizontal, keeping reward, contents and price visible together.
- Separated cabin and bank actions from physical product buttons; shortened cabin preview copy.
- Made dialog close sticky and compacted phone detail/reveal layouts.

Reduced-motion CSS disables animation, transitions and smooth scrolling; category navigation also checks the system preference. This was verified in source, not by changing the user's OS preference.

## Evidence

- `previews/desktop-shop.png`: combined shop.
- `previews/gameplay-hud.png`: gameplay HUD and physical market/bank displays.
- `previews/physical-displays.png`: merchandise detail crop.
- `previews/cabin-shortfall.png`: contextual coin offer beside cabin.
- `previews/reward-reveal.png`: guaranteed two-item reveal.
- `previews/phone-shop.png`: 844 × 390 shop.
- `previews/compact-phone-shop.png`: 667 × 375 shop.
- `previews/phone-reward.png`: compact-phone reveal.

Full captures and exact crop bounds are retained beside crops. No external publishing, real purchases or Roblox production changes occurred.

## Portable build check

The self-contained packaged HTML was opened through the existing local HTTP server. Reset, bundle purchase, receipt grant, two-item reveal and empty browser error log were verified. Direct file:// opening was blocked by Codex browser URL policy, so direct-disk behavior was not browser-tested. Static checks confirm all CSS, scripts and SVG artwork are embedded, with no external runtime dependencies.

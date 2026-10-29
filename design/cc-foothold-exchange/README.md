# CLIMB & COLLECT — Foothold Exchange

One combined design concept, completed 22 October 2026. Browser simulation only; no Roblox purchase, product listing, game script or place file is modified.

## Open

- Live local concept: http://127.0.0.1:8791/cc-foothold-exchange/#stage
- Portable, self-contained file: `CC-Foothold-Exchange.html` (open directly in a modern browser; no network, font or art dependencies).
- Editable sources: `index.html`, `styles.css`, `art.js`, `model.js`, `app.js`.
- Screenshots: `previews/`.
- Original six-concept prototype is preserved at `../cc-shop-concepts/CC-Shop-Artboards.html`.

If the local server has stopped, run from the repository root:

```powershell
python -m http.server 8791 --bind 127.0.0.1 --directory design
```

Rebuild the portable file and evidence crops: `python design/cc-foothold-exchange/package.py` (Pillow required for crops).
Run economy tests: `node --test design/cc-foothold-exchange/model.test.cjs`.
The concept itself has no package dependencies. `.tools/` contains optional locally installed test tooling and is ignored by Git.

## Explore

The catalogue scrolls independently of the gold header, close button and category navigation. Click any category to reach that section. Close the shop to see five physical product displays, two HUD offers and the cabin. Every offer resolves through the same catalogue, ownership and balances.

In a product detail, use the clearly marked simulation controls to set enough (500) or insufficient (0) demo Robux. Continue through the native-handoff illustration, confirm the simulated purchase, then simulate the confirmed receipt. Only that last step deducts demo Robux and grants the reward. Cancellation returns to the selected offer without granting. Returning from top-up adds 500 **demo** Robux, an illustrative amount, never a promise of a Roblox package.

Reset demo restores 1× earnings, 1,250 Cairn Coins, 500 demo Robux and no owned purchases. Browser-local state survives refresh when local storage is available. It is not a real account or cross-device save. Use one tab for a review session; separate tabs are independent in-memory snapshots of the same local demo save.

## Draft economy and assumptions

| Offer | Robux | Result |
| --- | ---: | --- |
| Permanent earned-coin tiers | 3 / 9 / 19 / 39 / 79 / 149 | Total 2× / 4× / 6× / 8× / 10× / 12×; next tier only |
| Coin packs | 9 / 25 / 59 / 119 | Exactly 100 / 350 / 900 / 2,000 Cairn Coins |
| Camp Glow | 19 | Lantern skin + banner; versus 19 each separately |
| Trail pennant | 3 | Permanent cosmetic |
| Sparkle trail | 5 | Permanent cosmetic |

The 2,000 pack has the highest coins/Robux: 16.81, versus 11.11 / 14.00 / 15.25. The bundle comparison is 19 versus 38 for the two separately offered products. Partial bundle ownership blocks the bundle and directs to the missing standalone cosmetic. Fully owned items cannot be charged again.

Demo-only assumptions: each bank collection awards 50 base coins times the permanent multiplier; the cabin lamp set costs 1,500 coins. Summit Points are displayed as earned and never sold. The interaction with the existing timely-collection bonus remains unresolved and is not applied here. Cosmetic grants record ownership; this prototype does not implement a separate equipping system or playable navigation.

## Design and references

Gold header and purple shop shell; large warm featured bundle beside cool compact offers; rainbow HUD stickers and green prices; visible physical merchandise; clear permanent tier progression; guaranteed purple reveal. Original SVG illustrations adapt the existing C&C prototype artwork. No reference-game art or branding is copied.

The supplied video’s local contact sheet and detailed study were used as the primary style evidence. Existing prototype notes retain the five-pin Pinterest study; those remote pins were not re-reviewed in this run.

## Future Roblox integration

Use supported native `MarketplaceService` purchase prompts. The official [developer products documentation](https://create.roblox.com/docs/production/monetization/developer-products) and [MarketplaceService reference](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) were checked during this build. For developer products, grant through validated server receipt handling, not prompt-close events. Durable receipt deduplication and ownership persistence require a real server implementation; this local model only simulates them.

Roblox controls available Buy Robux packages, current product pricing and account/device restrictions. No exact-shortfall package is guaranteed. Product IDs, regional pricing, entitlement choice and published-device validation remain production work outside this design task.

## Verification

See `QA.md` for executed checks and captured evidence. Tested in the Codex in-app Chromium browser, including embedded real 844 × 390 and 667 × 375 viewports. This is viewport testing, not physical iOS/Android device or Roblox Studio certification. Direct file:// opening is blocked in Codex; the packaged HTML was browser-tested over localhost and checked for fully embedded dependencies.

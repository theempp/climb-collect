# Foothold Exchange Roblox Integration Plan

> **For agentic workers:** Use superpowers:executing-plans to implement task by task only after explicit plan approval and the user's implementation handoff. This document is a proposal, not implementation authorization.

**Goal:** Integrate the approved Foothold Exchange design into the existing Expedition game without replacing its economy, saves, traversal or world.

**Architecture:** One server-owned catalogue and entitlement view serves the shop, HUD, physical merchandise and cabin offers. Permanent purchases use passes; four repeatable coin packs use developer products and a durable purchase ledger. Existing Profile transactions remain the only ownership/balance mutation boundary.

**Tech Stack:** Luau, Roblox GUI/ProximityPrompt/MarketplaceService, existing Profile/Store/CoreState modules; existing local Studio sync and Luau tools. No Rojo.

**Spec:** README.md, QA.md, editable concept sources and previews in this folder; design approved in chat on 2026-10-22. This integration plan awaits approval.

## Inspected baseline — 2026-10-22

- Read repository instructions, master.md, Expedition handoff and relevant shared/server/client code. Current explicit design approval supersedes older documentation that limits monetization to cosmetics, only for the approved offers.
- Studio b87eac59-ff9d-48d7-adbd-be508b7b072a, ClimbAndCollect.rbxl: Edit, PlaceId/GameId 0. Read-only scans found no MarketplaceService/ProcessReceipt integration in active scripts outside ServerStorage.
- Eight integration sources match Studio by byte length and rolling checksum: Profile, Bank, Home, Gear, CoreConfig, Net, CC_CoreService, CC_CoreClient.
- ClimbAndCollect.Expedition.rbxl is also open, in Play mode. Five corresponding server/template scripts match local source. Did not stop Play, change instances or run gameplay mutations.
- Profile schema v2 has session locks, atomic transactions, uncertain-commit recovery and a general transaction result list trimmed to 96. It is not yet a permanent paid-purchase ledger.
- Bank.deposit awards rarity-based Cairn Coins for newly credited creature discoveries. Home.rate/settle/collect implements assigned-creature income and an eight-hour offline cap. Neither uses the prototype's fixed 50-coin collection.
- Gear preserves legacy owned/equipped cosmetics and Summit Points but registers no shop purchase handlers. Profile sanitization filters gear ownership through the legacy C.SHOP catalogue.
- Four identically named MarketStall models exist in Workspace.World.Regions.Foothold.Districts.ProvisionsMarket. The bank is the existing Foothold Core.Campfire, exposed by Camps.bankPart. Nine cabin entrances lead to owner-only home courts supporting the actual player capacity.
- Working tree contains substantial existing changes. No resets, bulk sync, terrain regeneration or edits to protected creature work are permitted by this plan.

## Global constraints

- Permanent total earned-coin multipliers: 1x baseline, then 2x/4x/6x/8x/10x/12x. Draft step prices: 3/9/19/39/79/149 Robux; total 298. Next tier only; never stack multiplicatively.
- Coin packs: exactly 100/350/900/2,000 Cairn Coins for draft 9/25/59/119 Robux. Never multiply purchased coins or existing balances.
- Camp Glow: lantern skin plus camp banner, 19 Robux bundle versus 19 each standalone. Trail pennant 3; Sparkle trail 5. All permanent cosmetics.
- Shared ownership: bundle owns both components; owning both means owned everywhere; partial bundle ownership blocks the bundle and directs to the missing standalone. No owned cosmetic or tier is offered for purchase again through game UI.
- Summit Points remain earned only. No paid creature odds, cargo protection, claim advantage or traversal kit changes. Existing coin sinks remain unchanged; bought coins use the existing Cairn Coin balance.
- Native Roblox checkout owns confirmation, account restrictions and any Robux top-up. Never query/display a fabricated Robux balance or promise an exact-shortfall top-up. Remove simulation controls from game UI.
- Guaranteed reveal follows a durable confirmed grant, not merely a closed prompt. Preserve selected offer after cancellation; no grant on cancel.
- Preserve design/cc-shop-concepts and this approved browser concept. Preserve terrain, route metadata, creature folders and two-checkpoint limit.
- No product listing creation, publication, access changes, real purchases or production rollout without separate explicit authorization. Missing IDs disable checkout, never use guessed IDs.

## Proposed integration decisions for approval

1. Use 11 permanent passes (six tiers, four individual cosmetics and Camp Glow) plus four repeatable developer products. Roblox recommends passes for one-time benefits and developer products for repeat purchases.
2. Bank discovery coin rewards and home income are both earned coins and receive the permanent multiplier. XP, discovery/adventure credit, Heartstone progress, Summit Points, training and costs do not. Home income accrues at the multiplier active during that interval; settle at the old rate before changing tiers. Existing uncollected income is not retroactively multiplied. Keep the eight-hour cap and fractional remainder. Leave the unresolved timely-collection bonus unchanged.
3. Add the prototype's 1,500-coin lamp set as a separate permanent home decoration. Keep current functional home upgrades at 60/180/420 coins and current training costs. Select the smallest pack covering the shortfall, or the largest pack with remaining shortfall explicitly shown; offer continued earning. Buying coins never auto-spends them or auto-installs the decoration.
4. New cosmetics get a separate entitlement/equip namespace, preserving legacy gear. Lantern skin changes the existing lantern/headlamp appearance without changing illumination or traversal; banner decorates the owner's court; pennant is cosmetic display/back accessory; trail is a bounded cosmetic effect. Provide explicit equip/unequip, respawn/rejoin restoration and reduced-effects behavior.
5. Preserve draft prices as intended default listing prices. At runtime display Roblox's actual player-visible prices; recompute bundle savings and pack-value badges rather than hard-code 50% or best value when pricing differs. Unavailable prices disable purchase. No pricing experiment or listing setting changes are included in implementation authorization by default.

## Platform boundary: prerequisites and overlapping passes

In-game server checks enforce next-tier-only offers and partial/full ownership rules before opening a prompt. Passes prevent repeat purchase of the identical pass, but Roblox's external checkout cannot enforce our cross-pass prerequisites or bundle overlap rules. Do not advertise an absolute platform-wide no-overlap-charge guarantee.

If an upper-tier pass is owned externally, record it as pending and activate only the highest contiguous sequence starting at 2x; explain which earlier tiers are required, never silently grant a skipped tier or erase ownership. Bundle and standalone entitlements are unioned, never double-granted. Unlist external storefront offers where supported and verify that behavior before launch; direct purchase paths remain a limitation. Strict prevention of all externally overlapping purchases requires a revised sales structure and separate approval, not a silent change to this design. Keep native purchasing disabled until the owner accepts this limitation or approves an alternative.

## File structure and tasks

All paths below are repository-relative. New module names are proposed; existing modules are extended narrowly.

### Task 1 — Catalogue, profile migration and canonical ownership

**Create:** src/core/shared/CommerceConfig.luau; src/core/server/CommerceRules.luau; src/core/server/CommerceTests.luau.
**Modify:** src/core/server/Profile.luau; tools/sync_core.luau.
**Interfaces:** CommerceRules.multiplier(data) -> number; CommerceRules.offerState(data, offerId) -> {status, missingItem?, nextTier?}; CommerceRules.coinPackForShortfall(shortfall) -> offerId. Config holds stable offer IDs, exact draft values and separate zero/unconfigured pass/product IDs.

- [ ] Add failing tests for all six next-only tiers, 298 total, 12x cap, bundle union/partial/full ownership, exact packs and shortfall selection.
- [ ] Migrate schema v2 to v3 with commerce = {tier = 0, owned = {}, equipped = {}, passOwned = {}, processedPurchases = {}, pendingReveals = {}} and home decoration ownership. Sanitize known IDs and valid tiers while preserving legacy balances, gear, bank, cargo, homes and settings. Default to 1x and no new purchases; never copy demo balances.
- [ ] Make all offer states derive from this canonical ownership view; do not place new cosmetic IDs in the legacy sanitizer where they would be stripped.
- [ ] Verify migration twice produces identical ownership/balances and preserves every existing v2 fixture. Run CommerceTests and existing Profile/Expedition suites, expecting zero failures.

### Task 2 — Native purchases and durable grant boundary

**Create:** src/core/server/Commerce.luau.
**Modify:** src/runtime/CC_CoreService.server.luau; src/core/shared/Net.luau only if needed; Profile.luau; sync manifest.
**Interfaces:** Commerce.init(ctx), onLoaded(plr, session), onLeave(plr), state(plr, snapshot); server action commercePurchase({offerId}); Commerce.processReceipt(receiptInfo) -> ProductPurchaseDecision. Server emits commerce reveal payloads with stable grant IDs through existing CoreFx; CoreState includes commerce offer states and pending reveals.

- [ ] Write tests with fake MarketplaceService and Store for forged/unknown IDs, missing sessions, duplicate clicks, concurrent grants, locked/lost profiles, cancellation, store failure, timeout-after-commit, reconnect and replay after over 96 unrelated transactions.
- [ ] Before prompting, validate catalogue ID, actual ownership, next tier, profile readiness and one pending checkout per player. Never accept client prices, rewards, tiers or ownership. Revalidate after yields. Rate-limit requests.
- [ ] For passes, reconcile server-verified Roblox ownership on join and after native completion. Persist the resulting union and tier through Profile transactions before success/reveal. Retry delayed ownership lookups without charging again; lookup failure never revokes stored ownership. Settle home income before effective tier changes.
- [ ] For packs, register one receipt dispatcher. Atomically commit exact coins AND processedPurchases[PurchaseId] AND pending reveal in the same profile transaction. This ledger is independent of the trimmed 96 general receipts. Return PurchaseGranted only once durable commitment or its durable prior record is confirmed. Return NotProcessedYet for unavailable profiles, unknown products or uncertain writes. Receipt grant must not depend on still being near a display or having a client quote.
- [ ] Do not evict paid purchase IDs to save space. Measure ledger growth; fail closed on profile-size limits and leave the receipt unresolved. Before launch, require a tested archival design if projected growth approaches the existing profile byte budget; a separate datastore write alone is not an atomic grant strategy.
- [ ] Keep pending reveals durable until client acknowledgement; acknowledgement removes presentation only and never affects paid ownership. Reconnect can recover the reveal; replay cannot grant or debit twice. Run all new tests, expecting zero failures.

### Task 3 — Real earned income and owner-only cabin decoration

**Modify:** Bank.luau, Home.luau, HomeConfig.luau, Commerce.luau and CommerceTests.luau.
**Interfaces:** Bank retains deposit(session, userId, txId); Home.rate/settle retain current signatures. Add owner-station homeDecorBuy({id, txId}) and homeDecorEquip({id, enabled, txId}) through existing transactional handlers. Add decoration state to Home.state.

- [ ] Test bank rarity rewards at 1x/12x, duplicate discovery suppression, exact purchased packs at 12x, unchanged XP/points, home offline cap and fractional income, and income across a tier boundary.
- [ ] Apply the multiplier once at earned-reward calculation. Home.rate includes the current multiplier; Home.settle accrues that rate; homeCollect transfers already accrued coins without multiplying again. Settle before every tier change. Do not modify existing base yield tables or pack amounts.
- [ ] Add the lamp set at 1,500 coins as a separate sink; require owner presence at the actual home station, server price lookup, sufficient balance and a one-time durable spend. Visitors cannot buy/install/equip their host's decorations. Reuse current transaction failure/retry feedback.
- [ ] Test exact shortfall, cheapest sufficient pack, earn-instead/cancel, no auto-install after top-up, duplicate install, remote spoof and visitor rejection. Existing home upgrades/training retain their prices and behavior. Run CommerceTests and existing Expedition tests, expecting zero failures.

### Task 4 — Approved shop/HUD, physical merchandise and cosmetic presentation

**Create:** src/core/client/CommerceUI.luau (ModuleScript under ReplicatedStorage.CC_Core.Client); src/core/server/CommerceDisplays.luau; src/core/server/CommerceCosmetics.luau.
**Modify:** CC_CoreClient.client.luau, CC_CoreService.server.luau, Home.luau and sync manifest.
**Interfaces:** CommerceUI.init({parent, request, closeOtherPanels, onModalChanged}), update(state), open(offerId?), close(); CommerceDisplays.init(ctx) resolves the real market and Camps.bankPart; CommerceCosmetics refreshes only its own named accessory/effect folder and home-decoration subtree.

- [ ] Port the approved gold/purple shop, warm featured bundle, cool offer cards, green price buttons, fixed header/categories, independently scrolling catalogue, permanent tier ladder and guaranteed reveal using Roblox UI. Use the existing client for input/modal arbitration; no competing fullscreen controller.
- [ ] Add closed-shop HUD offers and shop entry. Hide/defer purchase interactions during unsafe traversal and restore focus/input on close or native-prompt return. Respect current text size, reduced motion, safe insets, keyboard, touch and gamepad selection.
- [ ] Add three Market plinths and two bank displays as an additive named CommerceDisplays subtree. Locate duplicate-named stalls by inspected position/pivot and assign stable attributes only inside the added subtree. Place bank merchandise beside, without blocking, the campfire deposit prompt. Validate prompt distance server-side. Per-player owned/next-tier labels render locally, never rewrite global display ownership for everyone.
- [ ] Build visible cosmetic merchandise and actual equip/unequip results, not just entitlement records. Preserve Gear.dress and automatic kit behavior. Bound trail particles and disable/reduce them according to effects preferences; cabin banner/lamp persist visually for visitors without visitor mutation.
- [ ] Capture matching desktop gameplay/shop, physical displays, cabin offer and reward reveal, plus 844x390 and 667x375 layouts and the existing smaller safe-area checks. Test largest text, scrolling, focus return and no overlap with movement/jump/climb controls. No small-target, clipped-action or horizontal-overflow failures are acceptable.

### Task 5 — Reconciliation, regressions and implementation handoff

**Modify/create:** sync manifest, tools/commerce_checks.luau, new monetization evidence folder and implementation handoff documentation. Update project decision docs only to record approved changes accurately.

- [ ] Before implementation, re-enumerate Studio instances and reconcile local/live sources; preserve unrelated work. Create a recoverable local backup and branch without discarding untracked files. Never overwrite either existing place snapshot by default.
- [ ] Sync only changed manifest files to the confirmed working Studio in Edit mode, after source comparison. Do not stop another active playtest without coordination. No generator/world rebuild. Keep HTTP off after sync. Verify changed sources match local.
- [ ] Run the browser model's 8 tests, the new CommerceTests suite, existing A1/Expedition/traversal suites, training/cargo regressions and Luau compilation. Confirm terrain/protected creature/checkpoint invariants. Save a new local monetization review .rbxl and verify its embedded source; do not publish.
- [ ] Exercise multi-client ownership, visitors, separate balances, concurrent requests and reconnects in disposable tests; capture native cancellation, receipt replay and store-failure evidence. Clearly separate fake-service tests from actual platform tests.
- [ ] At PlaceId 0, real product metadata, paid transactions and persistent DataStore networking are unavailable. Deliver a working local build with a Studio-only injected fake service and disabled production checkout when IDs are missing. Never expose fake grants outside Studio.
- [ ] Provide a separate product setup checklist for the intended universe: 11 pass IDs, four product IDs, draft prices, pricing behavior and external-sales boundary. Product creation, a published test destination, real purchase tests and release remain separately authorized steps. No invented IDs or claimed real purchase validation.

## Review focus / release blockers

- Paid receipt replay after general receipt eviction: Task 2 retains permanent PurchaseId records and tests >96 intervening transactions.
- Save ambiguity and shutdown/concurrent server requests: Task 2 tests uncertain commit and profile ownership loss; acknowledgement follows durable confirmation only.
- Partial bundle and externally acquired upper tiers: Tasks 1/2 test union, pending prerequisites and clear UI; external checkout limitation requires owner acceptance before sales activation.
- Home income spanning tier purchase/rejoin: Task 3 tests old-rate settlement, no double multiplier and unchanged cap/fraction handling.
- Phone modal/native-prompt cancellation during gameplay: Task 4 verifies safe-area controls, focus restoration and no stuck traversal inputs.

## Approval and next-chat handoff

This chat stops at review. Ask the owner to approve or revise the proposed integration decisions, including the external-pass limitation. Once explicitly approved, reply with a short, detailed copy-and-paste prompt here in chat referencing this exact plan and approved concept. Do not start implementation in this chat. The new chat must preserve separate authorization boundaries for listings, test publication, real purchases and release.

Official references checked 2026-10-22: https://create.roblox.com/docs/production/monetization/passes ; https://create.roblox.com/docs/production/monetization/developer-products ; https://create.roblox.com/docs/reference/engine/classes/MarketplaceService ; https://create.roblox.com/docs/production/monetization/regional-pricing .

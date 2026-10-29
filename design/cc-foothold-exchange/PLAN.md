# Foothold Exchange implementation plan

Goal: One polished interactive monetization concept, preserving all existing prototype and game files.
Spec: User's attached request, 22 October 2026. Autonomous implementation and verification explicitly authorized.
Architecture: Offline HTML/CSS/JavaScript; pure shared economy model, SVG artwork, DOM interface, local demo persistence. All surfaces resolve product IDs through one catalogue. Native checkout is simulated, never connected to Roblox.

Design: Crown gold #ffd361, vault purple #482580, ink #24153c, glacier cyan #70e1ed, alpine green #8ee35b, sunset pink #f77bb8. Heavy rounded display lettering with dark outlines; Segoe UI body. Signature: a tiny walkable-looking mountain village with physical merchandise and the same illustrated objects in a purple shop. Featured bundle beside compact deals; permanent tiers have their own prominent progression section. Sticky shell with independently scrolling catalogue.

- [x] Model: tests first for six sequential tiers (3/9/19/39/79/149), cap, exact packs, duplicate receipts, cosmetics and partial bundles, insufficient balance, stale selections, cancellation and cabin spend. Implement model.js.
- [x] UI: index.html/styles.css/art.js/app.js; responsive shop, HUD and physical displays, cabin context, shared detail/handoff/reveal flow, focus and reduced motion.
- [x] Verification: Node model tests, browser actions at desktop and landscape phone sizes, overflow checks, screenshots and visual critique. Fix findings.
- [x] Package: portable HTML, README assumptions/platform notes and QA results, local server and Codex browser left open.

Assumptions: 1,250 starting Cairn Coins; 500 simulated Robux; 50 base earned coins per bank collection; cabin lamp set costs 1,500 coins. These are demonstration values only. Summit Points remain earned. Timely-collection bonus is not simulated or changed. Session persists in this browser's local storage; reset explicitly clears it. A partial bundle is unavailable and directs to missing standalone item, avoiding repeat charges. At the cap, pennant/trail or repeatable 100-coin pack remains accessible.

Review focus: receipt replay; partial ownership; cancellation preserving selection; small-height modal overflow; state update without resetting catalogue scroll. Existing repository contains unrelated modifications: no game files, root docs or original prototype changed.

Completion ledger: model tests passed; live desktop and 844×390 / 667×375 browser flows inspected; reviewer findings corrected; packaged HTML smoke-tested via localhost. Direct file:// browser test blocked by Codex URL policy. Source files and original prototype remain separate.

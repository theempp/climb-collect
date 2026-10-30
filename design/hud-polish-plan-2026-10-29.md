# HUD polish plan — 2026-10-29

Source: user's phone screen recording (`Desktop\Video Oct 29 2026, 8 04 48 PM.mp4`). Live build: `game/homebase-c` (Glassbloom HUD). Design values come only from the existing Glassbloom tokens and references; invent nothing.

## Decisions (user-approved)
- Codebase: `Desktop\ClimbCollect\game\homebase-c`.
- Health bar (top right, "SAFE RETURN"): **remove entirely**.
- Compact profile card: **lock the five stats**, no sixth.
- Expanded profile card closes on **tap again or tap outside**; also closes when any page opens.

## Tasks
1. **Page titles centered above pages.** Every popup/page title pill (Shop, Settings, and all other hubs) is centered on the panel's horizontal axis, not the screen's, and sits on the top edge consistently. Audit every popup and screen label, not only Shop.
2. **Tighter title pill.** Shrink the pill to the text: smaller vertical and horizontal padding, text optically centered, no dead space. Same pill component everywhere.
3. **Side tabs.** Shop and every other hub: tighter tabs, text centered both ways (video shows left-aligned text in tall, wide boxes), consistent height and gap, active state clear. Check long names ("Accessibility", "Convenience") still fit.
4. **Top-right cluster.** Remove the health bar. Keep coins pill. Put a real gear icon in the empty circle button (settings). Check the coins pill also has a coin icon, since it currently shows only "0".
5. **Profile widget, compact by default.** Shows only: player name, level, XP progress bar, creature count, cash per second. Smaller than today's card, sitting above the inventory bar.
6. **Profile widget, expanded on tap.** Tap raises the card and reveals the five circle slots underneath. Tap again or tap outside collapses. Animated, and the widget opens/closes without covering the inventory bar. Collapse automatically when a page opens.
7. **Verify** on phone-size viewport (video is 2622x1206): safe-area insets, no overlap with Roblox top bar, jump and action buttons, or the inventory bar.

## Open details for the builder to settle (no design values invented)
- Cash/sec source: use the existing tycoon production rate in profile data; confirm field name.
- Gear icon and coin icon: use existing icon assets if present; otherwise ask before creating.

## Pipeline
architect → atlas (confirm Glassbloom tokens) → component-builder → motion (expand/collapse) → design-reviewer.

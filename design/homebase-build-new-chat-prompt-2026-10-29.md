# New-chat prompt: home base + tier-up VFX build (first build)

Read first: `CLAUDE.md`, `START-HERE.md`, `design/homebase-redesign-interview-2026-10-29.md` (decisions + follow-ups), `design/lake-world-and-vfx-reference-analysis-2026-10-29.md`, `design/core-loop-upgrade-spec-2026-10-28.md`, `design/hud-glassbloom-intel.md`, memory `homebase-redesign-decisions-2026-10-29`, Obsidian Home.md + Climb & Collect overview.

Goal: build the redesigned per-player home base in a NEW Studio copy of Integrated Review06 + Glassbloom HUD (never the original, never the published place): layout C (4 blocks of 2 plots ~80x100, cross-shaped commons, one gate, shared garden strips), 6 habitats per plot, Training Beast, stable at habitats, hatchery with big hatch moment, 14 decor slots, commons (gate plaza + XP arrival pop-up, notice board + streak shrine, lake portal, collection hall/leaderboard), tier-based plot growth with the deconstruct -> cube swirl -> reconstruct VFX (frames in `references/lake-world/02-*`). Shop stays UI-only; no sky-menu or forest world in this build.

Removed (do not build): Defense Outpost and all player raids, shop shields, weekly seasons, duo/party feature and party portal.

Process: preflight (Studio instance, hashes), then Atlas on `references/` for home references, then PROPOSE plot tier themes and count via AskUserQuestion popup (owner asked me to propose; none exist yet), then architect plan with STOP gates, then build in phases with evidence. Pipeline order: architect -> atlas -> component-builder -> motion -> design-reviewer. Motion through `Motion.luau` tokens only (Reduce effects / LOW gates, capped cube pool, skippable).

Hard rules: no publishing, products or Robux; design values only from project references (sanctuary/lodge values + Glassbloom intel); server-authoritative tier, XP and decor with versioned save (fail closed); reconcile with `HomeLayout.luau` and its checks; preserve other chats' work; phone 44 px targets and 30 FPS floor; ask decisions via popups, concise.

Open for this chat: tier count/themes, XP-by-rarity numbers, update v1 scope docs + checklist (remove party C01/C02, seasons C05, raid C03/C04, shields), profile schema subrecords (decor, tier, rank XP).

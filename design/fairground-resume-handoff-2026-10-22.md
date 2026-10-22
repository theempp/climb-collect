# Resume handoff: Fairground, portfolio/HUD, practice, and summit finale

Saved 2026-10-22. Workspace: `C:\Users\HOME!\Desktop\climb&collect`.

## Exact resume point

The owner completed three interview rounds, approved the design direction, and then explicitly approved the detailed implementation plan. Latest execution instruction: “approved - give me a prompt to copy and paste into a new chat to continue and finish this”. The owner then requested that everything, including the recording and screenshot, be saved in the project.

**Design approval and implementation-plan approval are complete.** The statement that plan approval is pending in the earlier committed plan index is superseded by this handoff and the updated index. No product implementation was performed during this planning session. The next chat should start implementation preflight, not restart brainstorming or request the same approvals.

The supplied continuation prompt uses native implementation in the new chat and a final independent code review. Do not proactively delegate implementation unless the owner changes that method; the prompt explicitly permits the final review. Keep reward balancing provisional. The user prefers questions/choices in the pop-up widget when questions are necessary.

## Read in order

1. `CLAUDE.md` and `master.md`, including current overrides.
2. [Approved design](lobby-portfolio-summit-design-2026-10-22.md).
3. [Implementation index](../docs/superpowers/plans/2026-10-22-expedition-redesign.md) and all four linked phase plans.
4. [Commerce handoff](commerce-handoff-2026-10-22.md) and [Expedition handoff](expedition-handoff-2026-10-22.md).
5. [Reference package](../references/duck-duck-tag-2026-10-22/README.md): full original recording, full original screenshot, derived contact sheet, verified checksum manifest.
6. [Copy/paste continuation prompt](fairground-new-chat-prompt-2026-10-22.txt).

Planning checkpoint commit: `b49d8fa` contains the design and five implementation-plan documents. Later documentation/reference-save work records the final approval and this handoff. Use `git log` for its final commit identity rather than assume b49d8fa includes this handoff.

## Owner decisions to preserve

- Lobby first, then portfolio/HUD together, followed by daily practice and summit finale as sequenced in the approved plans.
- High-energy expedition fairground, oversized props and animated attractions. Core services about 5–8 seconds from spawn. Direct mountain connection and clear mountain/entrance view. Compact Exchange with previewable merchandise; bank, collection showcase, route information, and one distinctive home entrance nearby. Larger-feeling multi-stage practice activity remains outside the essential service loop and visible from the court.
- HUD closely follows the reference's chunky panels, bright colors, and oversized icons, using original mountain art. Landscape phones first. One Shop button and at most one contextual offer, reduced while climbing. Real countdowns only for real offers/events.
- Public portfolio plus owner Details. Headline summit count, unique permanently collected species, current obtainable collection completion; rarity totals count species once. Mutations separate. Showcase companion, three selected creatures, equipped cosmetics. Omit unsuccessful outcomes entirely from portfolio views.
- Overhead display name, level, and one equipped earned title. Nearby readable, simplified at medium range, hidden behind solid obstacles. Inspect within about 25 studs in lobby/safe camps without camera takeover; own Profile button and Collection link.
- Earned summit/collection titles remain separate from paid cosmetic tag frames. New permanent starter cosmetic set is a proposal; exact content/price review precedes activation. Existing approved Commerce remains intact.
- Free rotating daily practice challenge and an earned cosmetic milestone; optional timed runs. No paid entry. Existing purchased training progression is preserved.
- Summit completes each individual's expedition. Trigger only after a validated ascent and safe grounded true-peak arrival. Personal 15–20-second cinematic, always skippable, shows success and helicopter pickup/departure. Other players continue normally.
- Every valid fresh finish awards coins and earned Summit Points, plus earned cosmetic progress. First-ever finish adds an exclusive earned title/cosmetic and enhanced reward. Amounts/thresholds remain provisional.
- Winner's banner: route, run time, finds/carried creatures, new species, confirmed prizes, next milestone. Back to Camp returns beside the new lobby bank/showcase. Extraction preserves cargo but never auto-banks it.
- Server commits completion/rewards once; reconnect recovers unfinished result. Reentering summit zone cannot farm rewards. A rewarded repeat requires lobby return and a fresh validated ascent.
- Separate local review build; replace central Foothold while preserving mountain routes/terrain, personal homes, and protected creatures.

## Important implementation findings

- `CommerceDisplays.luau` assumes four stalls under the old ProvisionsMarket and uses old Campfire offsets. The lobby plan replaces those dependencies with explicit anchors.
- `Camps.onLoaded` can restore highest-camp position; cargo/home recovery also owns movement. Summit return needs explicit precedence even when cargo is empty. Do not erase active ascent reconnect behavior accidentally.
- `Profile` already stores codex, banked identities/rarities, historical `gear.summits`, and expedition metadata. Storage does not prove a working summit award: local source search found configured 60/140 Summit Point values but no ordinary summit increment/grant path. Audit the actual active saved sources before integration.
- Existing training lessons use paid permanent unlocks and validated `traversalSection` events. Daily free access needs a temporary guarded permission path, not automatic permanent lesson ownership or duplicate stamina rewards.
- The working tree has substantial pre-existing tracked modifications and untracked sources/assets. Do not reset/clean or create an isolated checkout of HEAD that silently omits these files. Reconcile and inventory the complete baseline.
- Historical Studio IDs are not reliable; re-enumerate instances and verify the correct review place. Start from the verified Commerce review baseline and create backups/new review snapshots before edits.

## Saved artifacts and boundaries

**Execution update:** this planning-era resume point has been superseded by [the implementation handoff](fairground-implementation-handoff-2026-10-22.md). All four phases now exist in `Fairground.Finale.Review.rbxl`, with integration source `ffb15a2` and saved/reopened verification. Consult that handoff for the incomplete genuine ascent and outstanding multiplayer/device checks; do not restart implementation from this older planning state.

All original references are inside `references/duck-duck-tag-2026-10-22/`. The 109 MB recording is local project content, deliberately excluded from ordinary Git history; copying/cloning only Git history is insufficient to transport it. Both original media copies matched their source SHA-256 checksums. The original desktop files were left in place.

No game code, Studio scenes, product listings, access permissions, or live purchases were changed by this planning/reference-save session. Documentation pointers in the already-modified `CLAUDE.md` and `master.md` were updated without staging their unrelated prior changes.

No publishing, access changes, live purchases, or Robux spending. No unrelated mountain expansion. Preserve existing protected creatures and terrain; author the summit presentation stage without regenerating terrain. Report actual verification evidence and unresolved real-device/multiplayer/DataStore limitations. Complete the plans rather than claiming partial scaffolding is finished.

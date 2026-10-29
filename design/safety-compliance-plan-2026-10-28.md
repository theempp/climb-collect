# Safety + compliance plan (2026-10-28)

Design only. Not legal advice. No questionnaire was answered and nothing was changed in Creator Hub or the game. Built from a code grep of `climb-collect-integration` plus Roblox's current docs (links in the chat summary). Extends [publish-prep §5](publish-prep-2026-10-28.md) and [publishing-checklist](publishing-checklist.md).

## What the code audit found (integration worktree, 2026-10-28)
- **No `FilterStringAsync`, no `PolicyService`, no `TextChatService` use anywhere.**
- Only two TextBoxes: the Collection **search** box (local-only, fine) and `OpponentId` in `Screens.luau:697` (numeric UserId entry for the old stat battle, which the home-base redesign removed; confirm it is gone before launch).
- No player-typed names exist yet, so nothing needs text filtering today. This changes the moment we add creature nicknames, home names, signs or party/room names.

## 1. Maturity & Compliance Questionnaire (owner answers in Creator Hub: Audience > Maturity & Compliance)
Roblox restricts the experience for everyone if the answers are missing or inaccurate, and moderators re-check answers against abuse reports. Accuracy beats a flattering label.
Likely topics to answer honestly (owner decides, I only list what the game contains):
- **Violence:** fantasy combat against Guardians and creatures; egg theft by bats; falling and losing an egg. No blood or gore is planned: confirm in the art.
- **Scary elements:** Guardian telegraphs, dark or storm areas; judge against the actual art.
- **Paid random items:** yes (Robux eggs). Must be declared.
- **Social / chat:** Roblox's chat is used; parties (duo) and friends. No custom chat.
- **Real-money transactions:** yes (Robux).
- **Generative AI / extended AI interactions:** none planned.
Minimal/Mild labels unlock Roblox's Kids/Select audiences but add publishing requirements (verify current list on Creator Hub); decide whether that audience matters before choosing designs that push the label up.

## 2. Paid random items (Robux eggs, egg skip, any gacha)
- Show every outcome with exact percentages that sum to 100%, before purchase, including pity and anything that boosts odds. The shown odds must update when a boost is active.
- Gate access with `PolicyService:GetPolicyInfoForPlayerAsync` and `ArePaidRandomItemsRestricted`. For restricted players: hide the item, or block with a message. They must not trade the outcomes.
- Build a server-side check on every purchase path, not only a hidden button.
- The doubling ladders (coin income, hatch speed) are not random, so no odds screen needed.

## 3. Text filtering (needed before any custom text ships)
- Filter every displayed player-written string with `TextService:FilterStringAsync(text, fromUserId)` after submit, inside `pcall`, and show `GetNonChatStringForBroadcastAsync()` (public) or `...ForUserAsync()` (per viewer). Store the raw text; filter on every display, including names loaded from DataStore.
- Roblox says experiences without filtering can be taken down.
- Recommendation: **launch without free-text names** (use preset names). Add nicknames later with filtering done properly.

## 4. Spending, children and dark patterns (our choices, to defend with data later)
- No fake scarcity or countdown pressure on cheap ladders; show effect and price plainly ("Coins x8 -> x16 for 16 R$").
- Clear Robux labelling on every paid item; no purchase from a single accidental tap (confirm step).
- No gifting-from-pressure prompts; no push toward purchases right after a loss (fall/egg loss).
- Roblox applies its own parental spend controls; we do not collect payment details.

## 5. Data and privacy
- Use Roblox-native `AnalyticsService` only (owner-approved earlier). No external HTTP backend, no personal data, no free-text logging.
- Store only what the game needs: UserId-keyed profile (progress, purchases). Do not log chat or names in analytics fields.
- Check Roblox's current privacy and analytics requirements before launch (April 2026 policy revisions mentioned in news; the exact developer-facing rules were not found in my search).
- Provide a public contact/support path in the listing and a data-deletion note only if Roblox requires one (verify).

## 6. Moderation and live safety
- Reports go through Roblox's built-in report flow; make sure its entry stays reachable from our HUD/Settings (do not cover or remove it).
- Live-ops kill switches (planned in the live-ops tools item): disable shop items, ladders, events or a specific feature instantly without republishing; plus a feedback/report-a-bug button.
- Keep an incident runbook: who disables what, and how to restore saves (backup/restore exists for profiles).
- Anti-exploit (Q01) already covers server authority; re-run after the merge, especially receipts and ladder grants.

## 7. Listing and assets
- Icon and thumbnails: no copyrighted or lookalike content; honest depiction of the build; Roblox reviews them.
- Description: disclose Robux items; no performance or "free" claims that hide paid content.
- Audio: licensed libraries only (the three individual uploads were replaced).

## 8. Pre-launch checklist
1. Owner completes the questionnaire with the answers above (accurate, then review the resulting label).
2. Code: add PolicyService gate + odds screen for paid eggs; remove or confirm removal of `OpponentId` battle UI; no free text at launch, or full filtering.
3. Test as a restricted player (PolicyService returns restricted) and as an eligible one.
4. Verify report button reachable on phone and desktop.
5. Kill switches and incident runbook written and tested on a private place.
6. Re-check Roblox policy pages the week of launch; they changed in 2026.

## Decided (owner, 2026-10-28)
- **Launch with preset names only, no player-typed text.** Text filtering becomes a post-launch item.

## Open
1. ~~Player-written text at launch~~ — decided: none.
2. Target audience: broad/Kids-Select (Minimal/Mild) versus 9+ or 13+? This changes the monetization risk.
3. Who owns the runbook and the Creator Hub questionnaire answers: owner.

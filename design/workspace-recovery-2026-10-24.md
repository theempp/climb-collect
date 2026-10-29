# Workspace preservation and HUD recovery — 2026-10-24

Owner authorized preservation and checkout recovery before integration. Checklist W01 and W02 are complete for saved disk files and Git history. No integration, merge, publication, source cleanup or Studio save occurred.

## Recovery locations

- Full backup: `C:/Users/HOME!/Documents/ClimbCollect-Recovery/2026-10-24-030555Z`.
- Original active mountain: `C:/Users/HOME!/Desktop/climb-collect-mountain-continuation`, branch `codex/mountain-continuation`, HEAD `8d2d2635035f580f292ab89221200b1f6ed3981b`. Its later uncommitted work remains in place.
- Recovered HUD: `C:/Users/HOME!/.codex/worktrees/mountain-hud-recovered/climb&collect`, clean detached HEAD `6019525bd8bcdc0e1aed775e6ba71b890f80c155`, attached to this chat. The former missing checkout was not reused.
- Independent mountain restore: backup folder's `restore-test/mountain`. This is a verified recovery copy, not the integration workspace.

## Verified preservation

`mountain-complete.zip` includes all 4,952 files (6,306,368,965 bytes before compression), including ignored/untracked files and empty directories. `manifest.json` records each file SHA-256. Every archive entry and every restored file matched; the original mountain files were rehashed afterward and still matched. The worktree `.git` pointer is preserved separately as `restore-test/original-git-link.txt`; the recovery copy has independent Git storage cloned from the verified all-refs bundle. Do not reuse the original pointer in a standalone restore.

Archive SHA-256: `1b3abbec2f922a0ce0421faa2fc3e060e19decd143465a0d136b6b4e93188fb3`.
Git bundle SHA-256: `88eb55463afddf783513076a379aba9dd7662be5c08a93b5e86e25090519ec05`.

Restored mountain passed 120 rules + 131 traversal + 657 geometry checks. Final56 saved-source/current-world/Final54 terrain audit passed. Raw porcelain status differs after restoring exact bytes into a fresh checkout; tracked binary content diff is identical to the source and all file hashes match. The raw-status assertion initially failed and is not represented as passing.

HUD passed 419 checks, Luau compilation and Rojo build. Its saved review matches Windows SHA-256 `7f45b6d844cee26b84e8984076e7bf50d0d8e5d6c4d5c01dac88194917a8a3a4`; 21 runtime sources match. Build output was placed in the backup folder, leaving the recovered checkout clean. Existing original/mountain/lobby HEADs, branches and staged content remain unchanged.

Evidence: [restore verification](../evidence/recovery_2026-10-24/restore-verification.json), [HUD verification](../evidence/recovery_2026-10-24/hud-recovery-verification.json), [protected Git verification](../evidence/recovery_2026-10-24/protected-git-verification.json). Full file manifest, history bundle, original indexes/patches and pre-update documentation backup are in the backup folder.

## Limits and next step

The Studio connector reported zero connected instances during recovery. No Studio session was saved, closed or altered; unsaved in-memory content was not inspected or backed up. Historical open-session inventory must not be treated as current connectivity.

D01 visual review and D02 sanctuary/mountain state-and-travel contract remain open. HUD's older baked world must not overwrite Final56. Combining work begins only in a separate integration workspace. Graph freshness covers the original project/vault, not isolated HUD/mountain source; see recovery evidence for the final freshness result.

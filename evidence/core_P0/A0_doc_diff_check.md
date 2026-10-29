# A0 doc diff check (2026-10-20)

Method: `git diff --word-diff=porcelain HEAD -- master.md CLAUDE.md`, listing every removed word run (HEAD = commit 544c03f; files already had uncommitted edits from earlier sessions before Run 1).

| File | Removed text vs HEAD | Who | LOCKED? |
|---|---|---|---|
| master.md | `2.1` (version line → 2.2) | Run 1 A0 | No (version label) |
| master.md | `awaiting approval, nothing built)` in the §0.6 heading | earlier session (plan approved) | No (status) |
| CLAUDE.md | `and next action (V3 plan approval pending; older text below` | earlier session | No (status) |
| CLAUDE.md | `pre-V3` | earlier session | No (status) |

Run 1 edits to `master.md` are insertions only (new §0.7, four in-place "superseded/added" notes, version label). Result: **no LOCKED text erased**.

Consistency: §0.7 restates `design/core-loop-plan.md` §3–§6 LOCKED items and `autonomous-build-brief.md` §1; §0.5 egg/camp/Hatchery lines and §1 Claiming carry pointers to §0.7.

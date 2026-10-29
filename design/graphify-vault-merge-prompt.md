AUTONOMOUS RUN. Goal: finish the Climb & Collect graphify knowledge graph and merge it into the Climb & Collect part of my Obsidian vault so both graphs work in tandem. Do the whole job end to end without coming back to me. Every decision below is already made; use these defaults and only stop on a hard stop (section "Hard stops"). Report once at the end.

Paths
- Project: C:\Users\HOME!\Desktop\climb&collect (the `&` needs quoting in Git Bash). Existing `graphify-out/` has graph.json, GRAPH_REPORT.md, graph.html, manifest.json, cache/.
- Vault: C:\Users\HOME!\Documents\Obsidian Vault (folders: `Climb & Collect/`, `DRS Rush/`, `Roblox Shared/`, `Inbox/`).
- graphify: pip `graphifyy` 0.9.93, already installed and the `/graphify` skill is installed. The exe is not on PATH: use `python -m graphify ...` (interpreter in `graphify-out/.graphify_python`) or the `/graphify` skill. Write multi-line Python to a scratchpad .py file, not `python -c`, when you need parallel workers.
- Vault graph work dir (outside the vault): C:\Users\HOME!\Documents\graphify-vault-out\

Standing rules (my global CLAUDE.md)
- Concise. No popups needed in this run: the decisions are made here.
- Design values never cross games. DRS Rush stays out of everything. Only `Climb & Collect/` and `Roblox Shared/` from the vault are in scope.
- Read-only: `creatures/`, `ServerStorage.CC_Creatures`, Roblox Studio. Never touch them.
- Additive only in the vault: never edit, move, rename or delete an existing note.

Graph state at start (built 2026-10-21): 1,288 nodes, 2,348 edges, 117 communities. `.graphifyignore` limited it to 67 code files (src/, tools/) + 36 docs (CLAUDE.md, master.md, OVERNIGHT_BRIEF.md, design/*.md, evidence/*.md). Known issues: community 1 is mislabeled "UI Plan & Reference Boards" but holds v5 trails-plan nodes; 40 small communities are labeled only with their first node; MountainGen.luau has a parser error at line 42 (19 symbols extracted); CoreConfig, WorldConfig, checkpoint, publish_strip yielded no symbols; 63 dangling-endpoint edges and 7 collapsed edges; community 0 cohesion 0.06.

Pre-made decisions
- Coverage: ADD `src_legacy_v2/` (tag its nodes legacy), ADD the Claude memory folder `C:\Users\HOME!\.claude\projects\C--Users-HOME--Desktop-climb-collect\memory\`, ADD `creatures/` CODE ONLY via AST (no docs, no images, no LLM on it; mark source as Codex-owned/read-only), ADD `references/` and evidence images NO. Update `.graphifyignore` accordingly, then run an incremental `--update` so unchanged files come from cache.
- Semantic extraction (docs/memory/vault notes) uses subagents of type general-purpose in parallel chunks of at most 25 files and about 6000 lines, per the graphify skill. No API keys. Do not run `--mode deep`.
- Vault scope: `Climb & Collect/` and `Roblox Shared/` notes only. Include `Inbox/` notes only if they name Climb & Collect.
- Export shape: NOT one note per node. Write, inside `Climb & Collect/graphify/`: one hub note per community (what it is, key nodes, `[[wikilinks]]` to existing vault notes where a match exists, source file paths), `Graph Index.md`, and the canvas. Never write outside that folder, except step 7 note appends.
- Git: add `graphify-out/` to the project .gitignore. Do NOT install the git hook. Do NOT run `graphify claude install`. Do NOT commit anything.

Steps (all of them, in order)

0. Safety. Before writing anything into the vault, create a backup: zip `Climb & Collect` and `Roblox Shared` to C:\Users\HOME!\Documents\vault-backup-graphify-<date>.zip and record a file list with sizes and mtimes of both folders (needed for the step 8 check). If the zip cannot be made, that is a hard stop.

1. Orient. Read CLAUDE.md, master.md, `graphify-out/GRAPH_REPORT.md`, vault `Home.md` and the Climb & Collect overview note. Inventory vault note titles, tags and links (do not read every note in full yet).

2. Extend and update the project graph per the pre-made coverage decisions. Re-run detect, AST on new code, semantic extraction on new docs/memory only, merge, rebuild, recluster.

3. Repair the project graph.
   - MountainGen.luau: read the file and add its generators/functions as nodes by hand (extraction JSON with EXTRACTED edges) if the parser cannot.
   - Add CoreConfig, WorldConfig, checkpoint, publish_strip as document-style nodes with a one-line description each.
   - Inspect dangling edges with `python -m graphify diagnose multigraph`; fix the extraction for real causes, drop edges whose endpoint truly does not exist.
   - Relabel ALL communities with meaningful 2-5 word names (fix community 1). No placeholder labels may remain. Regenerate GRAPH_REPORT.md and graph.html.
   - Verify with three `graphify query` / `path` / `explain` calls whose answers you check against the source files.

4. Build the vault graph: run graphify (AST not needed, semantic on markdown) on the scoped vault notes. Output goes to C:\Users\HOME!\Documents\graphify-vault-out\, never into the vault.

5. Merge. `python -m graphify merge-graphs <project graph.json> <vault graph.json> --out <graphify-vault-out>\merged-graph.json`. Then add explicit cross-links where a vault note and a project node are the same thing (decision, milestone, gotcha, module, open question), matching by title/ID/content. Mark each EXTRACTED or INFERRED with a score. Ambiguous matches get AMBIGUOUS and go into a list in the final report; do not guess. Also register both graphs with `graphify global add` (tags `climb-collect-project` and `climb-collect-vault`) so queries can span them. Report merged counts and the top cross-graph bridges.

6. Export into the vault per the pre-made export shape, with `python -m graphify export obsidian --graph <merged> --dir "<vault>\Climb & Collect\graphify"` or `--wiki` or your own writer, whichever yields hubs + index + canvas. Check before writing that no target path already exists; if one does, write the new note with a `-graphify` suffix instead of overwriting. Add `Roblox Shared/` links only for truly cross-game gotchas.

7. Record. Append 1-2 lines each to the vault's Climb & Collect Milestones and Decisions notes (append only: what was built, where graph and backup live, scope decisions). Add a short "Graphify" section to this project's CLAUDE.md (update/query commands, where graphify-out lives, how to refresh the vault export). Add `graphify-out/` to .gitignore.

8. Verify. Re-list the vault folders and diff against the step 0 list: only new files under `Climb & Collect/graphify/` plus the appended lines in the two named notes may differ. Run two queries that cross project and vault (for example a decision recorded in the vault and the code or doc node it governs). Confirm graph.html opens and the Graph Index lists every community.

Hard stops (the only reasons to come back to me)
- The backup zip cannot be created.
- Any step would overwrite, delete, move or rename an existing vault file.
- The diff in step 8 shows an unexpected vault change (restore from the backup, then report).
- Extraction would need an API key, a login, or a paid service.
- A single step is estimated at more than about 40 subagent calls.
Anything else: choose the safest sensible default, note it, keep going.

Final report (one message, short): files and folders created (paths), node/edge/community counts before and after, how many project nodes were linked to vault notes, the AMBIGUOUS list, what you skipped or could not verify, and the exact commands to refresh everything later.

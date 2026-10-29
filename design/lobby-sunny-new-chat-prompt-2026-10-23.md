Build the CLIMB & COLLECT expedition hall + sunny slice. The plan is APPROVED; build it, don't re-plan or redo any interview.

Read first, in order:
1. CLAUDE.md and master.md (project root C:\Users\HOME!\Desktop\climb&collect)
2. The approved plan: C:\Users\HOME!\.codex\worktrees\movement-finish\climb&collect\docs\superpowers\plans\2026-10-23-lobby-sunny-slice.md (owner choices are at the top)
3. docs/superpowers/specs/2026-10-22-four-mountain-lobby-design.md (§4, §7, §9 step 2) and quad.md
4. design/movement-handoff-2026-10-23.md (movement state and gotchas)
5. Obsidian vault: Home.md, then Climb & Collect overview, Milestones, Decisions, Open Questions

State at handoff (2026-10-23):
- Work in worktree C:\Users\HOME!\.codex\worktrees\movement-finish\climb&collect on branch claude/lobby-sunny (off claude/four-mountain-movement @ 833bbce). The plan is committed there. Leave the worktree's existing dirty/untracked files unstaged.
- Review file: ClimbAndCollect.FourMountains.LobbySunny.Review.rbxl in that worktree. It is a byte copy of the movement review, SHA256 7737b1f84fa543781953ccf2407929c1f64b20ca9463de7071933873c34844cd. It was opened in Studio (id was 3f15b0e6); nothing was changed or saved. Checked there: HTTP off, walk 16, 2 checkpoints (PreP3, PreV5). Re-enumerate with list_roblox_studios first.

Owner decisions already made (don't ask again):
- An isolated hall far off-map (about 1,400+ studs past the map edge), so the mountain streams out. The old Fairground, FairgroundFinish and CommerceDisplays are archived to ServerStorage.BeforeHall, not deleted.
- Hall look: generate about 6 concept images (credit spend approved) with the connected image generator, from the spec §4 wording only. The owner keeps or rejects each one in the popup. Kept images go to references/lobby/ with a manifest. Then write design/hall-intel.md, where every value cites an approved image. No hall art before that; use neutral blockout until then.
- Sunny slice = Shepherd trailhead → Camp 1 only. Above Camp 1 stays as it is.
- Window previews = 3D dioramas behind enchanted glass. Rainforest, volcanic and snow are Coming Soon previews (no departure, no paid offer).
- Ambient sound may use the free Roblox Creator Store audio library (audio only; no marketplace models or meshes). Record the asset ids.

Build in plan order, Phases 0–6. Update the handoff, CLAUDE.md, master.md and the vault after each phase.

Hard rules:
- Ask every decision through the AskUserQuestion popup, several questions batched, with the recommended option first.
- Design values only from approved references, the spec and hall-intel.md. Never invent or borrow a palette, font or material.
- Never regenerate existing terrain. Preserve creatures/, CC_Creatures, CC_CreatureStage1, all 7 protected groups and the two-checkpoint limit.
- Sync only through tools/sync_core.luau on localhost:8771 (worktree root) in Edit mode, with checksums checked against Studio. HTTP must be off when you save.
- After any Studio save, rerun the Terrain.SmoothGrid restore from ClimbAndCollect.BeforeFairground.rbxl and verify on disk.
- No publishing, product setup, access changes or Robux spending. Never click the Windows taskbar. Don't touch DRS Rush. Don't stage unrelated dirty work.
- Don't claim anything is finished or tested without evidence. Mock-store tests are not DataStore tests.

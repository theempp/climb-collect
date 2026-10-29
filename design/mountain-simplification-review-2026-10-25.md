# Mountain simplification review

## Complete draft approved — October 25, 2026

Owner explicitly approved the complete written design, including connective proposals, and requested the implementation plan here with actual building in a new chat. Evidence: popup reply `call_ca2f477541e04e0296f902076851f86b`, “Looks good, approve the draft…” followed by the new-chat/no-generation instruction. Prior pending whole-draft statements below are superseded. [Plan](../docs/superpowers/plans/2026-10-25-free-climb-mountain.md); [build handoff](free-climb-build-handoff-2026-10-25.md). Planning-only changes in this chat; no game source/assets/places or publication changed.

October 25, 2026 (America/New_York). Design continuation only.

## Selected layout

Owner selected **A — Open mountain face: visible eggs, direct downhill escape** in the popup. Evidence: reply in chat `01a175d3-e389-7060-b6b2-e9f285aff8f5` to the layout question, with comparison at `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175d3-e389-7060-b6b2-e9f285aff8f5/simpler-mountain.html`.

The selected concept is: see an egg, go up to it, break it on the mountain, carry the revealed creature downhill to the clearly marked mountain exit into the sanctuary. Crossing that exit permanently secures the creature; carry it home afterward. This retains the chosen tap-per-pickaxe-strike input, sculpted-fantasy creatures and two-arm cradle for small creatures.

Alternatives shown: B, one winding trail with a retraced return; C, three broad terraces connected by stairs. Neither was selected. A was recommended for immediate objective/exit readability and direct return potential. No human pacing or retention result has been measured.

Corrected assumption: an open face simplifies navigation; it does not remove sectioned mountain progression. Owner subsequently clarified that different sections should remain, with guardians progressively more aggressive and harder to beat. Exact section count, boundaries, biome mapping and progression gates remain open; the original six are not automatically removed or locked unchanged. Existing source, places, art and history remain preserved. This does not cancel unrelated launch work.

## Selected danger

Owner selected **C — Both: guardian pursuit plus a few mountain hazards** in the danger popup in chat `01a175d3-e389-7060-b6b2-e9f285aff8f5`. This is the selected new-loop danger direction. The letters label danger alternatives, not the earlier layout or safety question. Builder had recommended pursuit alone; that recommendation is superseded by the owner's choice. Exact activation trigger, speed, duration, number of guardians, hazard type/count, loss/recovery, boss combat, multiplayer interactions and travel remain undecided. The choice does not require a boss battle before every egg or reinstate all old puzzles/mover loops. Existing art and source stay preserved.

Visual comparison: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175d3-e389-7060-b6b2-e9f285aff8f5/mountain-danger.html`. Schematic stages are illustrative, not production animation, map dimensions, escape timing or working game code.

## Selected egg-triggered guardian reaction

Owner selected **A — First pickaxe strike: the guardian starts approaching while you break it** in the reaction popup in chat `01a175d3-e389-7060-b6b2-e9f285aff8f5`. This confirms pressure during egg breaking. Alternative B delayed the egg-triggered reaction until creature reveal and was not selected. Visual evidence: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175d3-e389-7060-b6b2-e9f285aff8f5/guardian-reaction.html`. Warning duration, approach speed, proximity behavior and strike count remain unspecified. This does not decide that guardians cannot notice nearby players independently. Guardian pursuit, a few mountain hazards and permanent mountain-exit safety remain selected.

## Trip-length proposal — not selected; section progression retained

Proposed target ranges were A, 1–2 minutes; B, 3–5 minutes; C, 6–10 minutes, measured from mountain entry to returning across the safe exit with a revealed creature. Owner did not select a range. Instead, owner replied: “We should still have the different \"sections\" - with each of the guardians progressively getting more aggressive + harder to beat”. This confirms sections and rising guardian aggression/difficulty, not trip duration. The short-run recommendation must not be treated as approval or a reason to flatten the whole mountain into one uniform encounter area. Human timing remains unmeasured.

## Selected difficulty progression — fights and pursuits

Owner selected **Both — tougher guardian fights and more dangerous pursuits** in chat `01a175d3-e389-7060-b6b2-e9f285aff8f5`. Section progression therefore includes increasing combat and escape difficulty; it must not be reduced to chase speed alone. Existing source has guardian combat and increasing guardian attack/health (`Documents/ClimbCollect-HUD-2026-10-25/mountain/shared/Catalog.luau`, `C.guardians` and following loop). Exact behavior, balance, obligatory fights and new-loop unlock rules remain unresolved. No implementation authorized.

## Selected combat/access rule — no guardian-victory requirement

Current durable HUD source, freshly checked: `mountain/shared/Rules.luau`, `R.winGuardian` sets the normal win and increases `p.unlocked` to the next kingdom; `R.canEnter` checks this. `mountain/server/Combat.luau` applies the win and announces next-kingdom access. This is existing implementation evidence, not proof of final acceptance of the simplified loop.

Owner selected **A — No: guardian fights are optional for access; choose another progression rule later** in chat `01a175d3-e389-7060-b6b2-e9f285aff8f5`. This supersedes the builder's recommendation to retain guardian-victory section gates for the new design. It is not a decision to remove guardian combat, section progression or difficulty. The owner subsequently selected free climbing into all sections from the start (below), resolving the replacement access question. First-strike guardian approach, tougher fights/pursuits, a few hazards and permanent mountain-exit safety remain selected. Fighting rewards, defeat/recovery behavior and the guardian's return to defending eggs remain open. The current implementation still has the old normal-win access gate until a separately approved implementation changes it.

Concept comparison: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175d3-e389-7060-b6b2-e9f285aff8f5/guardian-progression.html`. Its win toggle illustrates access only, not a combat demo or implementation.

## Selected section access — free climbing from the start

Owner explicitly selected **A — let players climb freely from the start. The tougher guardians and hazards higher up should be what makes progressing harder.** This replaces guardian-win section gates in the intended design and rejects the proposed collection-milestone access alternative. All sections can be attempted from the start; skill, traversal and increasing danger provide the practical challenge. This does not grant teleports, skip travel, decide carry/fall recovery, or move permanent safety away from the sanctuary exit.

Owner also directed using **Steal an Egg** and **Break and Steal an Egg** as the close concept references, with thoughtful tweaks/improvements to make Climb & Collect more engaging, and explicitly requested a new chat to continue and finish this review. Reference fidelity is a goal; exact gameplay claims still need verification. Do not interpret the instruction as approval of every unreviewed addition or as erasing the locked creature/art/section choices. New continuation: `design/free-climb-mountain-handoff-2026-10-25.md`.

## Selected optional guardian rewards — October 25, 2026

Owner selected **Brief raid opening + companion XP; harder Trial earns the guardian** in the continuation chat's combat-reward popup. Normal combat gives temporary respite for an egg raid and companion experience; the guardian returns to defending its section afterward. A normal win does not permanently disable danger or grant section access. The harder Trial remains the guardian-collectible route. This resolves the previously open combat-purpose question without removing optional fights or changing free section access.

Evidence: explicit popup reply to `call_d66bc9e565b74f9586f7ab05a2c81ebf`, question “What should winning an optional guardian fight give you?” Exact respite duration, XP amount, multiplayer eligibility, encounter transition and Trial custody remain design details to settle. Do not treat an immediate permanently owned Trial reward as approved custody semantics; sanctuary-exit safety for carried mountain creatures remains fixed. Current `mountain/shared/Rules.luau` in the durable HUD clone still grants Trial ownership directly and normal-win access; no game code changed.

The following recovery choice supersedes the proposed recoverable drop. No timer or trip duration approved.

## Selected caught/fall consequence — October 25, 2026

Owner selected **Lose that unsecured creature and retry an egg; already secured creatures stay safe** in reply to the caught/serious-fall popup (`call_37fb2e8ecb37456d9867eebd0abd4eb6`). A guardian catch or serious drop-causing fall ends that creature's unsecured run. No recoverable creature pack/rescue window in this intended loop. Crossing the mountain exit into sanctuary still permanently protects the creature; failure cannot remove already secured collection. This supersedes the builder's recovery recommendation and existing recoverable cargo-pack behavior for new-loop creatures. Minor stumbling versus a serious fall, respawn location, disconnect and travel semantics remain to specify; no exact severity threshold approved.

## Selected six-section retention — October 25, 2026

Owner selected **Keep all six; simplify their layout and give each a distinct danger** in reply to popup `call_515cd14c834d4469bcb6d281f6471ad6`. Retain Blossom Gardens, Azure Falls, Sunstone Desert, Violet Crystals, Inferno Heights and Astral Crown. This closes the section-count question; earlier statements that six was only existing evidence are superseded by this explicit choice. Exact hazard mapping/layout remains a proposal, not new owner approval.

Coherent draft for review: [free-climb mountain design](../docs/superpowers/specs/2026-10-25-free-climb-mountain-design.md). It separates confirmed choices from connective proposals for one-creature carry, shared/bounded pursuit, Trial custody, safe return/travel/disconnect and existing-save preservation. Section map: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175ef-b1d3-70a3-a028-dbf5958962b5/six-section-mountain.html`. Schematic/proposed danger mapping, not game footage or approved timing. Fresh builder review requested by brainstorming workflow; shared encounter priority clarified in draft. Whole draft approval remains pending. No game source/place changes.

## Scope and evidence

No game source, place, publication or purchase changes. Current playable mountain remains the six-kingdom implementation described in the handoff. Graph CURRENT at this continuation's start covered intended original-repo/vault inputs, not isolated feature source. Recheck after recording this decision.

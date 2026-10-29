# Egg and creature direction review

October 25, 2026 (America/New_York). Design discussion only; no gameplay code or saved place changed. This records owner choices, not approval of an implementation specification.

## Confirmed owner choices

1. **Egg loop B:** break the egg on the mountain, reveal the creature, then carry the creature home. Owner submitted the egg-review selection in this chat. This supersedes home-hatching as the intended new acquisition presentation; detailed custody/security/progression rules remain to be decided.
2. **Creature art B — Sculpted fantasy:** defined anatomy, expressive face, springy animal movement. Owner selected this in the question popup after reviewing the A/B/C Mossbun board. The chosen board is an art target, not a finished model/rig/animation, runtime budget or promise of identical rendering on mobile.
3. **Small-creature carry A — Two-arm cradle:** owner selected this after reviewing front/rear carry-pose concepts. Applies to small creatures such as Mossbun; large creatures, birds, carrying scale/capacity and any movement penalty remain undecided.
4. **Breaking method A — Player tool:** owner selected visible pickaxe strikes with progressive shell cracks and chips. Input cadence, duration, tool progression and impact/reveal timing remain undecided; no tool shop or weapon economy is approved by this choice. This closes the breaking-method popup mentioned in the earlier review snapshot below.
5. **Pickaxe input A — Tap each strike:** owner selected one tap per pickaxe strike using the interactive comparison. The four-hit sample, its speed and any egg-health values are illustrative, not approved balance. This supersedes the earlier pending-input snapshot below. No gameplay code changed.
6. **Securing point C — Mountain exit:** owner explicitly locked C: the revealed creature becomes permanently safe at the mountain exit into the sanctuary, then is carried home for placement. Mountain checkpoints do not permanently secure it under this proposed direction. Fall recovery and travel/teleport behavior remain undecided. This supersedes the pending securing-point snapshot below; no code changed.
7. **Mountain simplification review:** owner wants to revisit and simplify the mountain, making the game more straightforward and closer to Steal an Egg's clarity/intensity. Existing six-kingdom route structure and mountain complexity are open for reconsideration. In the continuation, owner selected layout A, an open mountain face with visible eggs and a direct downhill escape. This selects a design direction, not a removal list, difficulty, finished specification or rebuild. Handoff: `design/mountain-simplification-handoff-2026-10-25.md`; ongoing decisions: `design/mountain-simplification-review-2026-10-25.md`.

Art comparison: `references/egg-creature-review-2026-10-25/mossbun-art-directions.png`. Selected direction is the middle column. Alternative A was rounder/playful; C naturalistic. Guardian designs remain individually subject to their established anatomy and review; this choice does not approve deleting/replacing Veylith source or scaling every species to Mossbun.

## Existing rules affected by the new loop

Verified in durable HUD source `mountain/shared/Rules.luau`, functions collect/extract/incubate/hatch/drop/recover, and `mountain/server/Journey.luau`; UI in `mountain/client/UI/Screens.luau`.

- Currently acquiring an egg adds `{id, species}` to unsecured cargo, capped at three. Its species is already selected by the server; revealing it on the mountain does not inherently require a new random reward roll.
- Checkpoint extraction currently moves cargo into secured eggs. Successful same-server journey/travel also extracts after moving.
- Incubation currently starts a rarity timer on a secured egg, with three active incubators; hatch converts it into an owned level-one creature. No automatic deletion of incubation facilities or stored eggs is approved.
- Falling currently creates a recoverable egg pack with a 180-second expiry. Carrying a revealed creature needs a clear corresponding failure/recovery rule, still undecided.
- Owned creatures currently support collection/team/training and separate habitat assignments. A revealed carried creature needs an explicit point at which ownership/equipping/production becomes available. Mountain reveal alone must not silently grant permanent ownership if return-home extraction is intended to matter.
- Production eggs are a separate non-hatchable currency loop; the new acquisition direction does not change them.
- Existing protection against stealing already-owned creatures remains unless the owner explicitly changes it. Selecting mountain egg breaking does not authorize player-base raids/theft or a new combat/chase system.

## Builder proposals, not owner decisions

Propose a clear visual sequence: impact anticipation → shell crack stages/chips → creature reveal/reaction → secure pickup pose → run with secondary ear/tail motion → home arrival acknowledgment. Server authorizes reward/custody; presentation should not create another reward when replayed. A skip/reduced-motion path should preserve the outcome.

Propose separating revealed cargo from permanently owned roster until the agreed securing event. Decide whether checkpoint safety remains, becomes a rest stop only, or grants partial protection. Decide whether existing stored eggs keep their old incubation path or migrate. These are pending design questions, not implementation instructions.

The chosen fantasy movement target suggests anatomy-specific idle, walk, run, start/stop, turn, reveal reaction, carry and put-down states. Mossbun can use a compressed hind-leg push, short airborne phase, forepaw landing, and delayed ear motion. Birds/fish/heavy creatures require their own movement language. These are proposed animation targets; no timings or physics effects have been approved.

## Carry-pose alternatives reviewed

Visual board: `references/egg-creature-review-2026-10-25/mossbun-carry-options.png`.

| Option | Proposed pose | Review concern |
|---|---|---|
| A | Two-arm cradle | Strong protective read; custom run/arm pose and trail visibility need testing |
| B | Shoulder hold | One arm swings; head/ears may obstruct the chase camera |
| C | Cloth carry harness | Both arms free; pack and animal silhouette may obstruct the rear view |

Owner selected A in the question popup. No carrying penalty, creature scale, capacity, pickup delay or guardian transport rule is approved by the image. The board illustrates Mossbun scale only. Rendering/gait poses are illustrative and cannot establish mobile performance or actual animation quality.

## Concept generation record

Built-in image generation was used. First prompt: compare the same original Mossbun in three labeled 3D game art directions, Playful / Sculpted fantasy / Naturalistic, with matching idle, running and cradled pose studies; leafy green rabbit, cream muzzle/chest, pink blossom, no cube-body pet, neutral studio lighting; mark as concept art. Second prompt: use only the selected middle-column sculpted fantasy character as reference; compare two-arm cradle / shoulder hold / carry harness with gray block avatars and front/rear running views, same Mossbun size, mountain path, mark as carry-pose concepts rather than animation. Original generated images remain preserved in the thread's generated_images directory; copies above make the review available to Claude Code and future sessions.

## Next questions

Carry posture and player-tool breaking are now chosen. Reviewed alternatives were A player pickaxe/tool, B equipped companion assistance, C direct held interaction. Board: `references/egg-creature-review-2026-10-25/egg-breaking-options.png`. This choice does not authorize a tool shop, weapon progression, new combat damage rules or paid upgrades. Third built-in image-generation prompt compared the same mossy shell on a Blossom ledge, gray avatar, identical shell-crack stages, with tool strike / selected sculpted Mossbun leaf-paw assistance / direct hands-on interaction. Concept art only; environment shown is illustrative, not a current mountain screenshot or approved terrain redesign.

After breaking method: breaking input/impact and reveal pacing → securing point and fall recovery → treatment of existing eggs/incubators → creature family animation samples → each mountain kingdom's escape paths and appearance. Present visual alternatives with each relevant question; do not implement before the design is settled and approved.

## Pickaxe input review

Current interactive comparison: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175b4-a9a1-7d40-a703-f251da15cdcd/egg-strike-input.html`. Options: A tap each strike, B hold for repeated swings, C timed strikes. Builder recommends B for reduced repeated finger input on phones. Owner selected A, tap each strike; this closes the input question. Four hits, interval/sweep speeds and target width are illustrative comparison parameters, not approved egg HP, difficulty or pacing. Shell drawing is a placeholder input study, not production egg art or game code.

## Securing-point review

Next visual comparison: `C:/Users/HOME!/.codex/visualizations/2026/10/26/01a175b4-a9a1-7d40-a703-f251da15cdcd/creature-safety-review.html`. Options are A permanently safe only at the owned home plot, B safe at a mountain checkpoint, C safe at the mountain exit into the sanctuary. Schematic stages do not represent actual terrain distances. A is the builder recommendation for preserving meaningful return-home stakes; none is chosen yet. This decision will need separate fall-recovery and teleport/travel rules, and does not introduce player theft. Current checkpoint egg extraction is verified source behavior; the new revealed-creature custody semantics are proposals.

## Owner egg-rule decisions — 2026-10-26
- Egg breaks at the nest, on the spot; creature appears and is carried down.
- Carry limit: one creature at a time (two-arm cradle for small creatures).
- Theft: other players MAY steal a creature while it is unsecured only. Secured/owned creatures stay protected. This changes the earlier protected-ownership rule; shield window and anti-grief limits still to be designed.
- Failure (guardian catch / serious fall): carried unsecured creature is lost; secured collection is kept.
- Status: decisions only, nothing implemented.

## Owner theft/bat decisions — 2026-10-26 (later)
- No shield timer: a carried creature can be stolen any time until secured at the gate (then safe forever).
- Theft is done with a bat (reference: Steal an Egg). A bat hit knocks the carrier flying; the creature drops for 3 s; anyone nearby can grab it; if nobody does it returns to the carrier.
- Bat progression: completing each section's creature index set unlocks a new bat; coins upgrade the equipped bat's level.
- Better bats improve knockback distance and reach; each bat also has its own look/trail.
- Anti-grief: owner had no preference; builder defaults proposed = same-victim cooldown, no hits inside the gate/home area or at checkpoints.
- Status: decisions only.

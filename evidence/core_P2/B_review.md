# B adversarial review (2026-10-20)

Method: Workflow `b-coreloop-review` (run `wf_8088711a-820`): 4 reviewers (malicious-client exploits, duplication/loss, soft-locks, performance at 30 players) read Prompts, Claims, Nests, DropPacks, Camps, Tutorial, Inventory/Bank/Profile, CC_CoreService, CC_CheckpointService and CC_CoreClient; each finding went to an independent skeptic told to refute it. 19 findings: 15 confirmed (about 11 distinct), 4 rejected. All confirmed items were fixed except two noted below; the whole test set was re-run on the fixed code (A1 12/12, B checks 10/10, timing run, 20-run batch).

| Severity (skeptic) | Defect | Fix |
|---|---|---|
| high | Resetting the character kept the whole backpack and respawned at the checkpoint or next to the bank: a free teleport home that also dodged fall loss and guardians. | On death with cargo (after the first bank) every unbanked item goes into a 3-min pack where it happened; loss card "You respawned: your cargo stayed behind." Live check: 2 items → 1 pack, carrying 0. |
| medium | No movement validation: teleporting from a nest to the campfire banked fresh cargo instantly. | Travel-time check at the bank: a find must have been carried ≥ distance(origin, bank)/(12 × 1.5) − 2 s, otherwise it stays in the backpack (never dropped). Live check: instant teleport-bank held; same find banked after the walking time. Studio-only bot speed factor keeps fast bots honest. |
| medium | A deposit was confirmed before it was saved. | Save immediately after every deposit (coalesced if a write is in flight); a failed save switches to the "Saving paused" banner. |
| medium | Every player's guardians replicated to and rendered on every client, re-pivoted every frame. | Movement replicated at 20 Hz; each client shows only its own guardians (others are hidden locally, including their "!" / "◉"). |
| medium | The cliffhanger guardian stayed Persistent-streamed and never despawned (one per player per session). | Watch flag and Persistent streaming end 20 s after the shot; normal despawn rules apply. |
| medium | Guardian state changes never refreshed the HUD alert. | State changes push a state update. |
| low | Fall loss relied on the client reporting its own falls. | Server-side fall detection from grounded height (0.25 s samples); the client report is only a fast hint; server moves (spawn, resume) reset the baseline. |
| low | Disconnect before the first bank consumed the tutorial common and left step 3 a dead end. | Step 3 with an empty backpack and no pack gives the first common back (step 2). |
| low | Full backpack at step 7 refused the Heartstone with no new objective. | Step 7 switches to "Your backpack is full. Bank at the campfire, then come back." |
| low | The Rare nook stayed hidden after its cooldown until an unrelated state push. | Hidden per-player spawns carry an `untilAt` time the client checks every second. |
| low | Bank double-tap table keyed by Player was never cleared. | Weak-keyed table. |

Not fixed (stated, low): drop-pack losses are not reported when the owner is offline when the pack fades (the next join shows the "last trip" notice for disconnects only). Full server-side anti-teleport (e.g. racing to respawned shared commons) is out of Run 1 scope; only the bank travel check is in.

Rejected by the skeptics (4): holding a prompt away from danger and returning at the last instant (prompt holds end when out of range); highest camp set by touching Camp 4 (needs a teleport exploit; travel/movement validation is the general fix); chase never ending on an unreachable player / ledge (LoseYou triggers on line-of-sight loss and leash; a stall give-up was added anyway).

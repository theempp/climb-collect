# Expedition persistence and home implementation

Implementation source checkpoint, 2026-10-22. Studio integration and tests are coordinated by the root agent; this file does not claim a human playtest or real DataStore verification.

## Ownership and schema

`Profile.VERSION = 2` deliberately keeps `CC_Profiles_v1` and the existing `p_` keys. Currency, bank identities, codex, progression, lockers, timer cooldowns, legacy gear ownership and retired-species migration remain. New data contains durable cargo, drop manifests, transaction receipts, original discovery credit, memories, journal, settings, expedition travel metadata and home state. Invalid or duplicate persisted identities go to quarantine rather than silently disappearing.

`Inventory.bind(userId, session)` reads the current `session.data.cargo`; replacing a profile after a commit cannot leave the runtime bag pointed at an old table. Ownership changes use `ctx.transaction` / `Profile:transact`, not legacy in-memory mutation helpers. `Inventory.locked` includes active saves, pending transactions and queued physical outcomes. Banking's compatibility adapter never overwrites populated durable cargo or imports another bound session's bag.

`Profile:transact(session, transactionId, transform)` runs a pure candidate transformation, then writes the candidate and result receipt in one session-owned `UpdateAsync`. Only a confirmed receipt produces `ok = true`. A failed response retains the pending candidate and original cargo; subsequent ownership changes are blocked. `recover` replays the same identity and checks the stored receipt. A committed response lost during server failure is reconciled on reconnect from the durable envelope. Item discovery credit remains after the bounded receipt history is trimmed.

Root service completion callbacks apply world effects only after confirmation, including retries. Save/release resolves pending state before writing a newer snapshot. `Store.memory.failAfterCommit` models a committed write whose response is lost.

Falls during an unavailable save enter a persistent outbox with the exact selected cargo identities. Recovery merges newly queued outcomes before releasing economic actions; the outcome transaction moves those identities once and starts the pack recovery window when committed. There is no elapsed retry deadline that grants cargo immunity. Monotonic reached-camp and parachute practice facts survive pending receipt replay. Departure location and a completed physical home return also survive that replay.

Shared claims reserve one spawn generation. A claimant leaving with an uncertain result conservatively consumes that occurrence and schedules its normal respawn, so another player cannot receive the same possibly committed occurrence and the spawn cannot remain locked forever. Replayed transaction callbacks do not repeat world mutations.

## Heartstones

Old Common/Rare/Legendary timers convert their elapsed fraction into 4/9/18 adventure progress. Already ready stones remain ready, all stored species/mutations/identities remain, and every stone goes to safe storage. No stone is silently discarded when there are more than two. Old unspecified outcomes have a deterministic identity-seeded fallback; specified outcomes are never rerolled.

Players manually occupy either of two nests at the home station. A bank transaction records which nests were occupied before it began, then advances both for each newly credited original discovery. Newly banked stones stay in storage and cannot advance themselves. Reclaimed/swapped/rebanked identities cannot create new progress. Hatching is an explicit durable transaction and retains identity/provenance; it awards no adventure credit or hatch XP.

## Home and economy

Nine existing cabin doors are entry/visit stations for all 30 player slots. A compact personal court is instantiated only while visited, outside the mountain at y=5000. Entry durably saves the same doorway as the return location. Traversal-authorized movement preserves cargo and excludes home movement from checkpoint/fall validation. Occupancy is reserved before destination streaming yields, allowing an owner departure to safely interrupt a visitor's entry. Owner departure returns visitors; reconnect from a temporary court returns to its recorded doorway. Visitors can observe but cannot mutate their host's home.

Three earning displays expand to six through three finite upgrades costing 60/180/420 coins. Nests gain efficiency 1/1.25/1.5/2. Players assign manually or explicitly select Equip Best. Other collection items remain safe. The server settles the old assignment's accrued income before assignment/upgrades and collection. Offline accrual is capped at eight hours. One collect pad transfers whole earned coins; fractional earnings stay accrued. Income does not affect banking or adventure progress.

Habitats adapt their labeled ecology to assigned creatures. Favorites and one cosmetic companion are ownership-validated; the companion tucks away off safe ground. Petting has feedback and no reward. Display models are static, with expensive rarity emitters/beams disabled, and courts unload when empty.

## API

- `Home.rate(data)`, `Home.settle(data, now)`, `Home.best(data)` are deterministic economy helpers.
- `Bank.deposit(session, userId, transactionId)` retains its established signature but is now durable.
- `Bank.hatchData(data, slot)` is the pure candidate transform; `Bank.hatch(session, slot, transactionId)` is its test/tool wrapper.
- `Bank.ripen` is a compatibility no-op: time never advances or hatches stones.
- Snapshot/actions match the connected Expedition UI: `collection`, `memories`, `settings`, `homeDirectory`, `inHome`, `home`; `homeEnter`, `homeVisit`, `homeReturn`, nest actions, earning assignment/collection/upgrades, favorite/companion/pet.

## Verification status

The old baseline passed 12 A1 tests, but an adversarial probe confirmed its durability defect: storage forced unavailable, banking still returned success and removed cargo. After implementation and the stale-session reason classification fix, the root-coordinated Studio run passed `Tests.runA1()` **12/12** and `ExpeditionTests.run()` **12/12**, including deferred falls after an unknown committed write and uncertain claimant departure.

The later cross-review reproduced three additional defects: practice flags were stripped on load/replay, the legacy deposit adapter could discard restored cargo, and a host departure during destination streaming left a guest registered in an unloaded court. It also reproduced duplicate identity acceptance across bank/stone storage and malformed recovery records escaping quarantine. The corrected actual source passes **5/5 local Luau probes** using deterministic Roblox service/world stubs (`python scratchpad/profile_cross_review_probe.py`). The flags probe was also observed red in Studio. These local probes are not substitutes for a multiplayer playtest.

Expedition coverage is now **15 cases**; the last three add flags/physical-home-return replay, restored-cargo binding and invalid-import quarantine. The final Studio rerun after those last source fixes is pending. All 13 owned/reviewed Luau modules compile successfully with the bundled compiler. Run `Tests.runA1()` and `ExpeditionTests.run()` after syncing the latest sources and record the new results in the final evidence report.

The root's scripted live Studio feature-loop checks verified: guardian chime/net/Heartstone reward; physical cabin doorway entry; manual nest placement; Equip Best at 46 coins/hour; advancing the test clock one hour and collecting increased coins 49→95; upgrading decreased coins 95→35 with four spaces and efficiency 1.25; banking from a home was rejected for distance; four new banked discoveries advanced the occupied stone to 4/4; replaying one hatch transaction kept bank count at 11 after the first 10→11 hatch and preserved identity; one locker item persisted; a shuttle preserved one carried item and left bank count 11; remote locker withdrawal was rejected; and scripted release/rejoin preserved the exact cargo UID plus the locker contents. These are scripted checks, not human usability or real-device acceptance.

Real DataStore service behavior remains unverified until authorized private publishing/service access; this session does not publish. Real multi-client contention and human visitor/mobile play remain separate acceptance work.

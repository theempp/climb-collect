-- Tests (ServerScriptService.CC_CoreServer): scripted A1 acceptance tests for persistence, run on the Server
-- datamodel during a Studio playtest:  require(game.ServerScriptService.CC_CoreServer.Tests).runA1()
-- Every test uses its own in-memory store (Store.memory) and fake user ids, so it never touches a live session.
-- Two Profile services sharing one backend stand in for two game servers. Clock.offset simulates time away.
-- What this proves: server session locks, durable idempotent deposits, failure handling and deliberate hatching.
-- What it cannot prove: real DataStore behavior (UNVERIFIED; the place is unpublished, PlaceId = 0).
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local C = require(RS:WaitForChild("CC_Core"):WaitForChild("CoreConfig"))
local Species = require(RS.CC_Core.Species)
local Store = require(script.Parent.Store)
local Profile = require(script.Parent.Profile)
local Inv = require(script.Parent.Inventory)
local Bank = require(script.Parent.Bank)
local Clock = require(script.Parent.Clock)

local T = {}

local FAST = { lockWait = 0.05, backoff = 0.01, loadTries = 3, saveTries = 4 }
local function svc(store, job, extra)
	local o = { jobId = job }
	for k, v in pairs(FAST) do
		o[k] = v
	end
	for k, v in pairs(extra or {}) do
		o[k] = v
	end
	return Profile.new(store, o)
end
local function creature(rarity, species)
	return Inv.newItem("creature", { species = species or Species.query({ region = 1, rarity = rarity, kind = "creature" })[1].id, rarity = rarity, region = 1, source = "test" })
end
local function heartstone(tier)
	local sp = Bank.rollHatch(tier, 1, Random.new(7))
	return Inv.newItem("heartstone", { tier = tier, species = sp, region = 1, source = "test" })
end
local function fill(uid, items)
	Inv.clear(uid)
	Inv.setCapacity(uid, C.SLOTS_MAX)
	for _, it in ipairs(items) do
		assert(Inv.add(uid, it), "fill failed")
	end
end

local cases = {}
local function case(name, fn)
	cases[#cases + 1] = { name = name, fn = fn }
end

case("rejoin keeps bank (same server and another server)", function(log)
	local store = Store.memory()
	local A, B = svc(store, "srvA"), svc(store, "srvB")
	local uid = 910001
	local s = assert(A:load(uid))
	fill(uid, { creature("Common"), creature("Rare"), heartstone("Common") })
	local r = Bank.deposit(s, uid, "tx-" .. HttpService:GenerateGUID(false))
	assert(r.ok and r.creatures == 2 and r.heartstones == 1, "deposit result")
	local coins, xp, banked = s.data.coins, s.data.xp, #s.data.bank
	assert(A:save(s, true), "release failed")
	local s2 = assert(A:load(uid), "same-server reload failed")
	log(string.format("same server: bank %d->%d coins %d->%d xp %d->%d heartstones %d", banked, #s2.data.bank, coins, s2.data.coins, xp, s2.data.xp, #s2.data.heartstones))
	assert(#s2.data.bank == banked and s2.data.coins == coins and s2.data.xp == xp and #s2.data.heartstones == 1, "same-server mismatch")
	assert(A:save(s2, true))
	local s3 = assert(B:load(uid), "other-server load failed")
	assert(#s3.data.bank == banked and s3.data.coins == coins, "other-server mismatch")
	log(string.format("other server: bank %d coins %d", #s3.data.bank, s3.data.coins))
	B:save(s3, true)
end)

case("double deposit yields once", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910002
	local s = assert(A:load(uid))
	local items = { creature("Common"), creature("Uncommon") }
	fill(uid, items)
	local r1 = Bank.deposit(s, uid, "tx-double-1")
	local r2 = Bank.deposit(s, uid, "tx-double-1") -- same request replayed
	local r3 = Bank.deposit(s, uid, "tx-double-2") -- second press, backpack already empty
	log(string.format("r1 creatures %d coins %d | r2 dup %s creatures %d | r3 creatures %d", r1.creatures, r1.coins, tostring(r2.dup), r2.creatures, r3.creatures))
	assert(r1.creatures == 2 and r2.dup and r2.creatures == 0 and r3.creatures == 0, "replay deposited twice")
	-- replay of the same item uids (forged re-add) must not duplicate bank entries or rewards
	local coins = s.data.coins
	fill(uid, items)
	local r4 = Bank.deposit(s, uid, "tx-double-3")
	assert(r4.creatures == 0 and s.data.coins == coins and #s.data.bank == 2, "same uid banked twice")
	-- two concurrent deposits with different tx ids
	fill(uid, { creature("Common"), creature("Common"), creature("Rare") })
	local results = {}
	for i = 1, 2 do
		task.spawn(function()
			results[i] = Bank.deposit(s, uid, "tx-par-" .. i)
		end)
	end
	task.wait()
	local total = (results[1] and results[1].creatures or 0) + (results[2] and results[2].creatures or 0)
	log(string.format("concurrent: %d + %d = %d (expected 3); bank %d", results[1].creatures, results[2].creatures, total, #s.data.bank))
	assert(total == 3 and #s.data.bank == 5, "concurrent deposits wrong")
	assert(A:save(s, true))
end)

case("store failure: load refused safely, data untouched, retries on save", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910003
	local s = assert(A:load(uid))
	fill(uid, { creature("Rare") })
	Bank.deposit(s, uid, "tx-fail-1")
	assert(A:save(s, true))
	local _, before = store:read(A:key(uid))
	-- 1) store down at join -> no session, reason "store"; nothing written
	store.failAll = true
	local s2, reason = A:load(uid)
	store.failAll = false
	local _, after = store:read(A:key(uid))
	log(string.format("load while down -> session %s reason %s; stored bank %d -> %d", tostring(s2 ~= nil), tostring(reason), #before.data.bank, #after.data.bank))
	assert(s2 == nil and reason == "store", "load should fail with reason store")
	assert(HttpService:JSONEncode(before.data) == HttpService:JSONEncode(after.data), "data changed during failed load")
	-- 2) deposit with no session -> refused, items stay in the backpack
	fill(uid, { creature("Common") })
	local r = Bank.deposit(nil, uid, "tx-fail-2")
	assert(r.ok == false and r.reason == "unavailable" and Inv.used(uid) == 1, "deposit without session must keep items")
	-- 3) flaky store on release: 2 failures then success (save retries with backoff)
	local s3 = assert(A:load(uid))
	Bank.deposit(s3, uid, "tx-fail-3")
	store.failNext = 2
	local ok = A:save(s3, true)
	log(string.format("release with 2 transient failures -> %s (update calls %d, failed %d)", tostring(ok), store.calls.update, store.calls.failed))
	assert(ok, "release should survive transient failures")
	local s4 = assert(A:load(uid))
	assert(#s4.data.bank == 2, "bank after flaky release")
	A:save(s4, true)
end)

case("Heartstone waits for adventure progress and deliberate hatch across offline gaps", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910004
	local s = assert(A:load(uid))
	fill(uid, { heartstone("Common") })
	local r = Bank.deposit(s, uid, "tx-hs-1")
	local hs = s.data.heartstones[1]
	assert(r.heartstones == 1 and hs and hs.progress == 0 and hs.required > 0, "heartstone not stored")
	assert(A:save(s, true))
	local base = Clock.offset
	Clock.offset = base + 100 -- time alone gives no adventure progress
	local s2 = assert(A:load(uid))
	local early = Bank.ripen(s2)
	local left = s2.data.heartstones[1].required - s2.data.heartstones[1].progress
	assert(#early == 0 and #s2.data.heartstones == 1, "ripened too early")
	assert(A:save(s2, true))
	Clock.offset = base + 400 -- beyond the old timer; explicit progress/hatch still required
	local s3 = assert(A:load(uid))
	local idle = Bank.ripen(s3)
	assert(#idle == 0 and #s3.data.heartstones == 1, "time advanced or hatched a stone")
	s3.data.heartstones[1].progress = s3.data.heartstones[1].required
	s3.data.heartstones[1].ready = true
	s3.data.home.nests[1] = hs.id
	local result = Bank.hatch(s3, 1, "manual-hatch-offline")
	local hatched = result.ok and { result.hatched } or {}
	local again = Bank.ripen(s3)
	Clock.offset = base
	log(string.format("offline 100 s: %d auto-hatched, %.1f adventure remaining | after explicit completion: %d hatched -> %s (%s); repeat auto-pass %d; stored stones %d", #early, left, #hatched, hatched[1] and hatched[1].species or "-", hatched[1] and hatched[1].rarity or "-", #again, #s3.data.heartstones))
	assert(#hatched == 1 and #again == 0 and #s3.data.heartstones == 0, "deliberate hatching wrong")
	assert(s3.data.bank[1].creatureId == hs.id, "hatched creature must keep the Heartstone id")
	assert(A:save(s3, true))
end)

case("session lock: live lock blocks a second server, release unblocks", function(log)
	local store = Store.memory()
	local A, B = svc(store, "srvA"), svc(store, "srvB")
	local uid = 910005
	local s = assert(A:load(uid))
	local sB, reason = B:load(uid)
	log("second server while locked -> " .. tostring(reason))
	assert(sB == nil and reason == "locked", "second load should be blocked")
	assert(A:save(s, true))
	local sB2 = assert(B:load(uid), "load after release failed")
	B:save(sB2, true)
end)

case("session lock: stale lock is taken over; the old server can't overwrite", function(log)
	local store = Store.memory()
	local A, B = svc(store, "srvA"), svc(store, "srvB")
	local uid = 910006
	local base = Clock.offset
	local s = assert(A:load(uid))
	fill(uid, { creature("Common") })
	Bank.deposit(s, uid, "tx-stale-1")
	assert(A:save(s, false)) -- autosave, lock kept; then server A "freezes"
	Clock.offset = base + C.PERSIST.lockTTL + 5
	local sB = assert(B:load(uid), "takeover failed")
	fill(uid, { creature("Uncommon") })
	Bank.deposit(sB, uid, "tx-stale-2")
	assert(B:save(sB, false))
	-- server A wakes up and tries to write its older copy
	fill(uid, { creature("Legendary") })
	Bank.deposit(s, uid, "tx-stale-3")
	local okA, why = A:save(s, true)
	Clock.offset = base
	local _, env = store:read(A:key(uid))
	log(string.format("B stole lock %s; A save -> %s (%s); stored bank %d (expected 2: A's 1st + B's)", tostring(sB.stoleLock), tostring(okA), tostring(why), #env.data.bank))
	assert(sB.stoleLock and okA == false and why == "lost" and s.lost, "old server must stop writing")
	assert(#env.data.bank == 2, "stored data overwritten by the stale server")
	B:save(sB, true)
end)

case("migration + sanitize keep valid data and quarantine junk", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910007
	store.backend[A:key(uid)] = HttpService:JSONEncode({
		data = { coins = "lots", xp = 120, bank = { { creatureId = "c1", species = "stub_common_1", rarity = "Common" }, "junk", { creatureId = "c1", species = "stub_common_1" } }, heartstones = { { id = "h1", tier = "Bogus", readyAt = 5 } } },
	})
	local s = assert(A:load(uid))
	require(script.Parent.Progression).refresh(s.data) -- CC_CoreService does this after every load
	log(string.format("version %d coins %d xp %d level %d bank %d quarantine %d heartstones %d", s.data.version, s.data.coins, s.data.xp, s.data.level, #s.data.bank, #s.data.quarantine, #s.data.heartstones))
	assert(s.data.version == Profile.VERSION and s.data.coins == 0 and s.data.xp == 120 and s.data.level == 2, "migration fields")
	assert(#s.data.bank == 1 and #s.data.quarantine == 3, "sanitize: 1 valid entry, 3 quarantined (junk, duplicate id, bad heartstone)")
	A:save(s, true)
end)

case("UpdateAsync retry semantics: transform runs twice, result applied once", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910008
	store.conflicts = 1
	local s = assert(A:load(uid))
	fill(uid, { creature("Common") })
	Bank.deposit(s, uid, "tx-conf-1")
	store.conflicts = 1
	assert(A:save(s, true))
	local _, env = store:read(A:key(uid))
	log(string.format("bank %d, lock %s, saves %d", #env.data.bank, tostring(env.lock), env.meta.saves))
	assert(#env.data.bank == 1 and env.lock == nil, "conflict replay changed the result")
end)

-- regression tests for the A1 adversarial review (evidence/core_P1/A1_review.md)
case("review: shutdown covers a leave-release already in flight (profiles.active)", function(log)
	local store = Store.memory({ latency = 0.3 })
	local A = svc(store, "srvA")
	local uid = 910009
	local s = assert(A:load(uid))
	fill(uid, { creature("Rare") })
	Bank.deposit(s, uid, "tx-shut-1")
	local leaveDone = false
	task.spawn(function() -- PlayerRemoving release, in flight
		A:save(s, true)
		leaveDone = true
	end)
	task.wait(0.05)
	assert(A.active[uid] == s and s.saving, "in-flight release must still be listed in profiles.active")
	-- BindToClose logic: save every active session and wait
	local ok, why = A:save(s, true)
	local _, env = store:read(A:key(uid))
	log(string.format("shutdown save -> %s (%s); leave done %s; stored bank %d, lock %s", tostring(ok), tostring(why), tostring(leaveDone), #env.data.bank, tostring(env.lock)))
	assert(ok and leaveDone and #env.data.bank == 1 and env.lock == nil, "shutdown did not wait for the release")
end)

case("review: a newer-schema profile is never downgraded by an older server", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910010
	local raw = HttpService:JSONEncode({ data = { version = 99, coins = 5, futureField = { a = 1 } } })
	store.backend[A:key(uid)] = raw
	local s, reason = A:load(uid)
	log("load -> " .. tostring(reason) .. ", stored unchanged " .. tostring(store.backend[A:key(uid)] == raw))
	assert(s == nil and reason == "newer" and store.backend[A:key(uid)] == raw, "newer profile was touched")
end)

case("review: a save queued behind a release does not re-take the lock", function(log)
	local store = Store.memory({ latency = 0.2 })
	local A = svc(store, "srvA")
	local uid = 910011
	local s = assert(A:load(uid))
	task.spawn(function()
		A:save(s, true)
	end)
	task.wait(0.02)
	local ok, why = A:save(s, false) -- autosave arriving while the release is in flight
	local _, env = store:read(A:key(uid))
	log(string.format("queued autosave -> %s (%s), lock %s", tostring(ok), tostring(why), tostring(env.lock)))
	assert(ok and why == "released" and env.lock == nil, "autosave re-took the lock after release")
end)

case("review: no deposit acknowledged while closing; malformed items stay in the pack", function(log)
	local store = Store.memory()
	local A = svc(store, "srvA")
	local uid = 910012
	local s = assert(A:load(uid))
	fill(uid, { creature("Common") })
	s.closing = true
	local r1 = Bank.deposit(s, uid, "tx-close-1")
	s.closing = false
	assert(r1.ok == false and Inv.used(uid) == 1, "deposit acknowledged while closing")
	Inv.bag(uid).items[#Inv.bag(uid).items + 1] = { uid = "bad-1", kind = "creature", species = "stub_common_1", slots = 1 } -- no rarity
	local r2 = Bank.deposit(s, uid, "tx-close-2")
	log(string.format("closing -> %s; malformed: deposited %d, kept %s, left in pack %d", tostring(r1.reason), r2.creatures, tostring(r2.kept), #Inv.bag(uid).items))
	assert(r2.creatures == 1 and r2.kept == 1 and #Inv.bag(uid).items == 1, "malformed item handling")
	local clean = Profile.cleanItem({ uid = "x", kind = "creature", species = "stub_common_1" })
	assert(clean == nil, "cleanItem accepted an item without rarity")
	A:save(s, true)
end)

function T.runA1()
	local lines, pass, fail = {}, 0, 0
	for _, c in ipairs(cases) do
		local logs = {}
		local t0 = os.clock()
		local ok, err = pcall(c.fn, function(s)
			logs[#logs + 1] = s
		end)
		local dt = os.clock() - t0
		if ok then
			pass += 1
		else
			fail += 1
		end
		lines[#lines + 1] = string.format("[%s] %s (%.2f s)", ok and "PASS" or "FAIL", c.name, dt)
		for _, l in ipairs(logs) do
			lines[#lines + 1] = "    " .. l
		end
		if not ok then
			lines[#lines + 1] = "    ERROR: " .. tostring(err)
		end
	end
	Clock.offset = 0
	table.insert(lines, 1, string.format("A1 persistence tests: %d pass, %d fail (store = in-memory mock; real DataStore UNVERIFIED)", pass, fail))
	return table.concat(lines, "\n"), pass, fail
end

return T

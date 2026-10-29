-- Behavioral regression tests. Only private mock stores/fake ids; never live player saves.
local F = script.Parent
local P, Store, Inv, Bank = require(F.Profile), require(F.Store), require(F.Inventory), require(F.Bank)
local Clock = require(F.Clock)
local Tests = {}
local function session(id, store)
	local p = P.new(store or Store.memory(), { jobId = "expedition-tests", loadTries = 1, saveTries = 2, backoff = 0.001 })
	local s = assert(p:load(id))
	Inv.clear(id)
	if Inv.bind then Inv.bind(id, s) end
	return p, s, p.store
end
local function item(id, kind)
	local i = Inv.newItem(kind or "creature", { species = "stub_common_1", rarity = "Common", tier = "Common", acquiredAt = Clock.now(), source = "test_nook" })
	i.uid = id
	i.discovery = { id = id, place = "test_nook", method = "encounter", at = i.acquiredAt }
	return i
end
function Tests.run()
	local pass, fail, lines = 0, 0, {}
	local function test(name, fn)
		local ok, err = pcall(fn)
		if ok then pass += 1 else fail += 1 end
		lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (ok and "" or (": " .. tostring(err)))
	end
	test("bank never acknowledges unavailable storage", function()
		local p, s, store = session(991101)
		Inv.add(s.userId, item("durable-a"))
		store.failAll = true
		local r = Bank.deposit(s, s.userId, "bank-unavailable")
		assert(not r.ok, "bank acknowledged before durable write")
		assert(Inv.used(s.userId) == 1, "unconfirmed bank consumed cargo")
		store.failAll = false
		assert(p:recover(s).ok)
		assert(#s.data.bank == 1 and Inv.used(s.userId) == 0)
	end)
	test("commit then response loss reconciles once", function()
		local p, s, store = session(991102)
		Inv.add(s.userId, item("uncertain-a"))
		store.failAfterCommit = 1
		local r = Bank.deposit(s, s.userId, "bank-uncertain")
		if not r.ok then assert(p:recover(s).ok) end
		local coins = s.data.coins
		assert(#s.data.bank == 1 and Inv.used(s.userId) == 0)
		local again = Bank.deposit(s, s.userId, "bank-uncertain")
		assert(again.ok and again.dup and #s.data.bank == 1 and s.data.coins == coins)
	end)
	test("uncertain bank survives server loss without duplicate cargo or credit", function()
		local p, s, store = session(991106)
		Inv.add(s.userId, item("crash-a"))
		assert(p:save(s, false))
		store.failAfterCommit = 2
		local r = Bank.deposit(s, s.userId, "crash-bank")
		assert(not r.ok and r.pending, "injected response loss did not become uncertain")
		local before = Clock.offset
		Clock.offset += 250
		local other = P.new(store, { jobId = "another-server", loadTries = 1, saveTries = 1, backoff = 0.001 })
		local loaded = other:load(s.userId)
		Clock.offset = before
		assert(loaded, "committed profile could not reconnect")
		Inv.bind(s.userId, loaded)
		assert(#loaded.data.bank == 1 and Inv.used(s.userId) == 0)
		local coins = loaded.data.coins
		assert(Bank.deposit(loaded, s.userId, "crash-bank").dup and loaded.data.coins == coins)
	end)
	test("both previously occupied nests advance; incoming stones stay stored", function()
		local _, s = session(991103)
		s.data.heartstones = {
			{ id = "nest-a", tier = "Common", species = "stub_common_1", progress = 0, required = 4, discovery = { id = "nest-a" } },
			{ id = "nest-b", tier = "Rare", species = "stub_rare_1", progress = 0, required = 9, discovery = { id = "nest-b" } },
		}
		s.data.home.nests = { "nest-a", "nest-b" }
		Inv.add(s.userId, item("new-find"))
		Inv.add(s.userId, item("new-stone", "heartstone"))
		assert(Bank.deposit(s, s.userId, "nest-progress").ok)
		assert(s.data.heartstones[1].progress == 2 and s.data.heartstones[2].progress == 2)
		assert(s.data.heartstones[3].progress == 0 and s.data.home.nests[2] == "nest-b")
		Inv.add(s.userId, item("new-find"))
		assert(Bank.deposit(s, s.userId, "nest-replay").ok)
		assert(s.data.heartstones[1].progress == 2, "rebank manufactured progress")
	end)
	test("legacy stones preserve elapsed progress, ready outcomes, overflow and balances", function()
		local now = Clock.now()
		local old = P.default()
		old.version, old.home, old.coins = 1, nil, 154
		old.heartstones = {
			{ id = "half", tier = "Common", startedAt = now - 150, readyAt = now + 150, species = "stub_common_1", mutation = "glow" },
			{ id = "ready", tier = "Rare", startedAt = now - 1900, readyAt = now - 100, species = "stub_rare_1" },
			{ id = "overflow", tier = "Legendary", startedAt = now, readyAt = now + 14400, species = "stub_legendary_1" },
		}
		local d = P.sanitize(P.migrate(old))
		assert(d.coins == 154 and #d.heartstones == 3)
		assert(d.heartstones[1].progress >= 2 and d.heartstones[1].mutation == "glow")
		assert(d.heartstones[2].ready and d.heartstones[2].species == "stub_rare_1")
		assert(d.home.nests[1] == "" and d.home.nests[2] == "")
	end)
	test("reconnect preserves cargo and original discovery", function()
		local p, s = session(991104)
		Inv.add(s.userId, item("travel-a"))
		assert(p:save(s, true))
		Inv.clear(s.userId)
		local s2 = assert(p:load(s.userId))
		Inv.bind(s.userId, s2)
		assert(Inv.used(s.userId) == 1 and Inv.bag(s.userId).items[1].discovery.place == "test_nook")
	end)
	test("locker and released world manifests retain unique identities on reconnect", function()
		local p, s = session(991107)
		local a, b, c = item("cargo-unique"), item("locker-unique"), item("released-unique")
		s.data.cargo = { a }
		s.data.lockers.Camp1 = { b }
		s.data.drops = { { id = "released:c", reason = "released", expiresAt = 0, pos = { x = 1, y = 2, z = 3 }, items = { c } } }
		assert(p:save(s, true))
		local loaded = assert(p:load(s.userId))
		assert(loaded.data.cargo[1].uid == a.uid and loaded.data.lockers.Camp1[1].uid == b.uid)
		assert(loaded.data.drops[1].items[1].uid == c.uid and loaded.data.drops[1].expiresAt == 0)
		assert(loaded.data.drops[1].items[1].discovery.id == c.discovery.id)
	end)
	test("hatch is deliberate, keeps identity and never advances another nest", function()
		local _, s = session(991105)
		s.data.heartstones = { { id = "hatch-a", tier = "Common", species = "stub_common_1", mutation = "glow", progress = 4, required = 4, ready = true, discovery = { id = "hatch-a", place = "hollow", method = "heartstone", at = 1 } } }
		s.data.home.nests[1] = "hatch-a"
		assert(#Bank.ripen(s) == 0 and #s.data.heartstones == 1, "automatic hatch remains")
		local r = Bank.hatch(s, 1, "hatch-deliberate")
		assert(r.ok and #s.data.heartstones == 0 and s.data.bank[1].creatureId == "hatch-a")
		assert(s.data.bank[1].mutation == "glow" and s.data.bank[1].discovery.place == "hollow")
		assert(Bank.hatch(s, 1, "hatch-deliberate").dup)
	end)
	test("income settles old choices before reassignment and caps offline time", function()
		local Home = require(F.Home)
		local d = P.default()
		d.bank = { { creatureId = "income-a", species = "stub_common_1", rarity = "Common" }, { creatureId = "income-b", species = "stub_legendary_1", rarity = "Legendary" } }
		d.home.assigned = { "income-a" }
		d.home.settledAt = 100
		Home.settle(d, 100 + 24 * 3600)
		assert(math.abs(d.home.uncollected - 8) < 0.001, "offline cap wrong")
		d.home.assigned = { "income-b" }
		Home.settle(d, 100 + 25 * 3600)
		assert(math.abs(d.home.uncollected - 158) < 0.001, "income used new rate retroactively")
	end)
	test("refresh preserves previously earned finite level and pack upgrades", function()
		local d = P.default()
		d.level, d.slots, d.xp = 5, 9, 100
		require(F.Progression).refresh(d)
		assert(d.level == 5 and d.slots == 9, "refresh revoked earned upgrades")
	end)
	test("fall during uncertain commit survives reconnect and consumes exact identities once", function()
		local p, s, store = session(991108)
		local a, b = item("outcome-original"), item("outcome-other")
		Inv.add(s.userId, a); Inv.add(s.userId, b)
		store.failAfterCommit = 2
		local pending = p:transact(s, "outcome-preceding-save", function(d) d.coins += 1; return {} end)
		assert(pending.pending, "commit response loss not exercised")
		P.queueOutcome(s, { id = "queued-fall", selected = { [a.uid] = true }, pos = { x = 4, y = 5, z = 6 }, reason = "fall", at = Clock.now() })
		s.data.highestCamp = 2
		assert(p:recover(s).ok)
		assert(s.outcomePending and #s.data.expedition.outcomes == 1 and s.data.highestCamp == 2, "confirmation lost deferred physical outcome or camp")
		assert(p:save(s, true))
		local loaded = assert(p:load(s.userId))
		Inv.bind(s.userId, loaded)
		assert(loaded.outcomePending, "reconnect did not block economic actions for queued fall")
		local DropPacks = require(F.DropPacks)
		local r = p:transact(loaded, "outcome:queued-fall", function(d) return DropPacks.applyOutcome(d, "queued-fall", Clock.now(), 180) end)
		assert(r.ok and #loaded.data.cargo == 1 and loaded.data.cargo[1].uid == b.uid)
		assert(not loaded.outcomePending and #loaded.data.drops == 1 and loaded.data.drops[1].items[1].uid == a.uid)
		assert(loaded.data.drops[1].items[1].discovery.id == a.discovery.id and loaded.data.stats.shaken == 1)
		assert(p:transact(loaded, "outcome:queued-fall", function(d) return DropPacks.applyOutcome(d, "queued-fall", Clock.now(), 180) end).dup)
		assert(loaded.data.stats.shaken == 1 and #loaded.data.drops == 1)
	end)
	test("departing uncertain claimant cannot strand or immediately reopen a shared occurrence", function()
		local Claims = require(F.Claims)
		local fakePlayer = {}
		local spawn = { id = "test_departure", perPlayer = false, generation = 7, reservedGeneration = 7, reserved = fakePlayer, available = true, respawn = 1 }
		Claims._spawns[spawn.id] = spawn
		Claims.onLeave(fakePlayer)
		assert(spawn.reserved == nil and spawn.available == false, "uncertain reservation remained locked or reopened immediately")
		Claims.onLeave(fakePlayer)
		assert(spawn.available == false, "repeat departure reopened the occurrence")
		-- Prevent this isolated fixture's delayed respawn from entering the actual world.
		spawn.generation = 8
		Claims._spawns[spawn.id] = nil
	end)
	test("physical practice flags and home departure survive uncertain replay and reconnect", function()
		local p, s, store = session(991109)
		s.data.expedition.homeReturn = { x = 1, y = 2, z = 3 }
		store.failAfterCommit = 2
		assert(p:transact(s, "physical-before-replay", function(d) d.coins += 1; return {} end).pending)
		s.data.flags.parachuteIntroduced, s.data.flags.parachutePractice = true, true
		P.clearHomeReturn(s)
		assert(p:recover(s).ok)
		assert(s.data.flags.parachuteIntroduced and s.data.flags.parachutePractice, "confirmation lost physically earned practice")
		assert(s.data.expedition.homeReturn == nil, "confirmation restored an already departed home")
		assert(p:save(s, true))
		local loaded = assert(p:load(s.userId))
		assert(loaded.data.flags.parachuteIntroduced and loaded.data.flags.parachutePractice, "reconnect stripped practice flags")
		assert(loaded.data.expedition.homeReturn == nil)
	end)
	test("binding a deposit never overwrites restored durable cargo with an empty legacy bag", function()
		local p, s = session(991110)
		s.data.cargo = { item("restored-original") }
		assert(p:save(s, true))
		Inv.clear(s.userId)
		local restored = assert(p:load(s.userId))
		assert(Bank.deposit(restored, s.userId, "restored-bank").ok)
		assert(#restored.data.bank == 1 and restored.data.bank[1].creatureId == "restored-original", "deposit binding discarded restored cargo")
		assert(restored.data.bank[1].discovery.place == "test_nook")
	end)
	test("invalid recovery manifests and duplicate bank stone identities are quarantined", function()
		local d = P.default()
		d.bank = { { creatureId = "same-original", species = "stub_common_1", rarity = "Common" } }
		d.heartstones = { { id = "same-original", tier = "Common", species = "stub_common_1" } }
		local malformed = { items = { item("quarantined-original") } }
		d.drops = { malformed, { id = "missing-expiry", pos = { x = 1, y = 2, z = 3 }, items = {} } }
		local clean = P.sanitize(d)
		assert(#clean.bank == 1 and #clean.heartstones == 0, "one identity occupied both bank and stone storage")
		assert(#clean.drops == 0 and #clean.quarantine == 3, "malformed owned record was discarded or exposed to runtime")
		assert(clean.quarantine[2].value.items[1].uid == "quarantined-original", "quarantine lost original cargo")
	end)
	return table.concat(lines, "\n"), pass, fail
end
return Tests

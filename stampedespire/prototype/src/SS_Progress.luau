-- Progression logic (ServerScriptService.SS_Progress, P3): the saved profile, the run validator that turns
-- client distance + score reports into checkpoints, coins and ascents, upgrade purchases, and the store
-- adapter (DataStore, or an in-memory JSON store when the place is unpublished). Pure apart from the store,
-- so SS_Save's Studio debug remote can run M.selfTest() with synthetic reports. Tunables: SS_Config.Progress.
local RepS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local C = require(RepS:WaitForChild("SS_Config"))
local P = require(RepS:WaitForChild("SS_Path"))

local G = C.Progress
local M = {}
M.Version = 2 -- 2: section medals, best times, Herd Journal ridden counts (P4)

-- Fastest legit mount and best score multiplier over every species (rares and flyers included).
local maxSpd, maxScore = 1, 1
for _, list in C.Species do
	for _, spec in list do
		maxSpd = math.max(maxSpd, spec.Speed or 1)
		maxScore = math.max(maxScore, spec.Score or 1)
	end
end
M.MaxSpd, M.MaxScore = maxSpd, maxScore

-- Studs per second the rider may legitimately cover at d (herd speed x fastest tier, plus leap steering).
function M.vmax(d)
	return (P.speedAt(d) * maxSpd * (1 + C.SpeedJitter) + C.Leap.AirSpeed) * G.Slack
end

local upgradeById = {}
for _, u in C.Upgrades do
	upgradeById[u.Id] = u
end

-- Profile ---------------------------------------------------------------------------------------
function M.newProfile()
	local medals, times = {}, {}
	for k = 1, #C.Zones do
		medals[k], times[k] = 0, 0 -- 0 = none yet (arrays keep JSON round trips exact)
	end
	return { v = M.Version, coins = 0, ascents = 0, best = 0, score = 0, upgrades = {}, medals = medals, times = times,
		ridden = {} }
end

-- Species names per section (the Herd Journal; a ridden report must name one of the rider's section or the
-- one below, for a mount carried over a border).
local speciesIn = {}
for k, list in C.Species do
	speciesIn[k] = {}
	for _, spec in list do
		speciesIn[k][spec.Name] = true
	end
end
function M.medalFor(secs)
	return secs <= C.Medals.Gold and 3 or secs <= C.Medals.Silver and 2 or 1
end

-- Any stored record (older, partial or junk) -> a clean current profile. Unknown upgrades are dropped and
-- levels are clamped to each upgrade's Max.
function M.migrate(raw)
	local p = M.newProfile()
	if type(raw) ~= "table" then
		return p
	end
	local function num(v, lo, hi)
		v = tonumber(v)
		if not v or v ~= v then
			return lo
		end
		return math.clamp(v, lo, hi or math.huge)
	end
	p.coins = math.floor(num(raw.coins, 0))
	p.ascents = math.floor(num(raw.ascents, 0))
	p.best = math.floor(num(raw.best, 0, #C.Zones))
	p.score = math.floor(num(raw.score, 0)) -- whole points: JSON round trips stay exact
	if type(raw.medals) == "table" and type(raw.times) == "table" then
		for k = 1, #C.Zones do
			p.medals[k] = math.floor(num(raw.medals[k], 0, 3))
			p.times[k] = math.floor(num(raw.times[k], 0, 36000) * 10 + 0.5) / 10
		end
	end
	if type(raw.ridden) == "table" then
		for name, n in raw.ridden do
			for k in C.Zones do
				if speciesIn[k][name] then
					p.ridden[name] = math.floor(num(n, 0, C.Medals.RiddenMax))
					break
				end
			end
		end
	end
	if type(raw.upgrades) == "table" then
		for id, lvl in raw.upgrades do
			local u = upgradeById[id]
			if u then
				p.upgrades[id] = math.floor(num(lvl, 0, u.Max))
			end
		end
	end
	return p
end

function M.equal(a, b)
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for k, v in a do
		if not M.equal(v, b[k]) then
			return false
		end
	end
	for k in b do
		if a[k] == nil then
			return false
		end
	end
	return true
end

-- Herd Journal: the client names each species it mounts with its d. It is queued and counted at the next report
-- (the first mount of a run can arrive before that run's first report) if the run is valid, the mount's d is
-- within RiddenNear of the reported d, and the species lives in that section or a neighbour (a mount carried
-- over a border, or a next-section overtaker spawned below its start). Returns true if queued.
function M.ridden(t, name, d)
	if type(name) ~= "string" or type(d) ~= "number" or d ~= d or math.abs(d) > 1e6 then
		return false
	end
	t.pending = t.pending or {}
	if #t.pending >= 8 then
		return false
	end
	table.insert(t.pending, { name = name, d = d })
	return true
end
local function creditRidden(t, prof, ev)
	local r = t.run
	for _, q in t.pending or {} do
		local k = P.zoneOf(math.clamp(q.d, 0, P.Total - 1))
		local here = speciesIn[k][q.name] or (speciesIn[k - 1] and speciesIn[k - 1][q.name])
			or (speciesIn[k + 1] and speciesIn[k + 1][q.name])
		if r and r.valid and here and math.abs(q.d - r.d) <= C.Medals.RiddenNear then
			prof.ridden[q.name] = math.min((prof.ridden[q.name] or 0) + 1, C.Medals.RiddenMax)
			ev.ridden = (ev.ridden or 0) + 1
		end
	end
	t.pending = nil
end

function M.buy(prof, id)
	local u = upgradeById[id]
	if not u then
		return false, "unknown"
	end
	local lvl = prof.upgrades[id] or 0
	if lvl >= u.Max then
		return false, "max"
	end
	local cost = u.Cost[lvl + 1]
	if prof.coins < cost then
		return false, "coins"
	end
	prof.coins -= cost
	prof.upgrades[id] = lvl + 1
	return true, cost
end

-- Run validator -----------------------------------------------------------------------------------
-- tracker = { run, lastScore, frac } per player. Each report: rider distance d and the client's cumulative
-- score. Returns the events of this report; mutates prof (coins, score, best, ascents).
function M.newTracker()
	return { frac = 0 }
end

-- spawn: the client's flagged spawn report (SS_Save checks d <= 0 and its rate): always starts a new run, so a
-- reset near the bottom (no 200-stud drop) restarts the section-1 clock too.
function M.step(t, prof, d, score, now, spawn)
	local ev = { accepted = 0, rejected = 0, coins = 0 }
	if t.lastScore == nil or score < t.lastScore then
		t.lastScore = score
	end
	local dScore = score - t.lastScore
	t.lastScore = score
	local r = t.run
	local pd, pt -- the previous report, for crossing times
	if not r or d < r.d - G.NewRun or spawn then
		local ok = d <= G.RunStartMax
		r = { start = now, d = d, t = now, valid = ok, reason = (not ok) and "start" or nil, cp = 0, top = false,
			budget = M.vmax(d) * G.Burst, bank = r and r.bank or 0, enter = {} }
		-- section 1 is timed from the d = 0 crossing only: a run whose first report is already past 0 (its spawn
		-- report was lost, e.g. before the profile loaded) gets no section-1 medal rather than a short time
		t.run = r
		ev.newRun = true
	else
		pd, pt = r.d, r.t
		local hi = math.max(d, r.d)
		r.budget = math.min(r.budget + M.vmax(hi) * math.max(now - r.t, 0), M.vmax(hi) * G.Burst)
		local fwd = math.max(d - r.d, 0)
		if r.valid and fwd > r.budget + 1e-6 then
			r.valid, r.reason = false, "speed"
			ev.invalid = true
		end
		r.budget = math.max(r.budget - fwd, 0)
		if r.valid then
			local perStud = C.ScoreRate * maxScore * G.ScoreSlack
			r.bank = math.min(r.bank + fwd * perStud, G.ScoreBank * perStud)
		end
		r.d, r.t = d, now
	end
	if r.valid and dScore > 0 then
		ev.accepted = math.min(dScore, r.bank)
		r.bank -= ev.accepted
	end
	ev.rejected = math.max(dScore, 0) - ev.accepted
	if ev.accepted > 0 then
		prof.score += ev.accepted
		t.frac += ev.accepted * G.CoinPerScore
		ev.coins = math.floor(t.frac)
		t.frac -= ev.coins
		prof.coins += ev.coins
	end
	local function cross(x) -- when the rider passed x, linear between the last two reports
		if pd and d > pd then
			return pt + (now - pt) * math.clamp((x - pd) / (d - pd), 0, 1)
		end
		return now
	end
	if r.valid and not r.enter[1] and pd and pd < 0 and d >= 0 then
		r.enter[1] = cross(0)
	end
	creditRidden(t, prof, ev)
	if r.valid and not r.top then
		while r.cp < #C.Zones and d >= P.zoneEnd(r.cp + 1) do
			r.cp += 1
			ev.cp = r.cp
			local k, tEnd = r.cp, cross(P.zoneEnd(r.cp))
			if r.enter[k] then -- section medal (C.Medals)
				local secs = math.floor((tEnd - r.enter[k]) * 10 + 0.5) / 10
				local tier = M.medalFor(secs)
				prof.medals[k] = math.max(prof.medals[k], tier)
				if prof.times[k] == 0 or secs < prof.times[k] then
					prof.times[k] = secs
				end
				ev.medal = { k = k, tier = tier, secs = secs }
			end
			r.enter[k + 1] = tEnd
			if r.cp > prof.best then
				prof.best = r.cp
				ev.best = true
			end
		end
		if r.cp == #C.Zones then
			r.top = true
			prof.ascents += 1
			prof.coins += G.AscentBonus
			ev.ascent = true
		end
	end
	return ev
end

-- Store -------------------------------------------------------------------------------------------
local function retry(fn)
	local ok, res
	for i = 1, G.Retries do
		ok, res = pcall(fn)
		if ok then
			return true, res
		end
		if i < G.Retries then
			task.wait(i)
		end
	end
	return false, res
end

-- Returns store, mode ("datastore" | "memory"), and why the DataStore was not used. Both stores keep plain
-- JSON-safe tables; the memory store JSON-encodes, so a round trip proves the profile serialises.
function M.openStore()
	local DSS = game:GetService("DataStoreService")
	local ok, ds = pcall(DSS.GetDataStore, DSS, G.Store)
	local why
	if ok and ds then
		local ok2, err = pcall(ds.GetAsync, ds, "probe")
		if ok2 then
			return {
				load = function(key)
					return retry(function()
						return ds:GetAsync(key)
					end)
				end,
				save = function(key, data)
					return retry(function()
						return ds:UpdateAsync(key, function()
							return data
						end)
					end)
				end,
			}, "datastore"
		end
		why = tostring(err)
	else
		why = tostring(ds)
	end
	local mem = {}
	return {
		load = function(key)
			return true, mem[key] and HttpService:JSONDecode(mem[key]) or nil
		end,
		save = function(key, data)
			mem[key] = HttpService:JSONEncode(data)
			return true
		end,
	}, "memory", why
end

-- Self-test (Studio BOT) --------------------------------------------------------------------------
-- Synthetic report streams through M.step: legit tier-1 and rare-flyer climbs, cheats, a faceplant, jitter,
-- the summit reset and profile migration. Returns { { name, ok, detail } }.
function M.selfTest()
	local out = {}
	local function add(name, ok, detail)
		table.insert(out, { name = name, ok = ok, detail = detail })
	end
	-- climb from d0 to past the summit at tier spd with mount score mul; hook(i, d) may return a new d
	local function climb(prof, t, d0, spd, mul, hook)
		local d, score, now, evs = d0, 0, 0, {}
		M.step(t, prof, d, score, now)
		local i = 0
		while d < P.Total + 20 and i < 2000 do
			i += 1
			local step = P.speedAt(d) * spd
			d += step
			score += step * mul
			now += 1
			if hook then
				d = hook(i, d) or d
			end
			table.insert(evs, M.step(t, prof, d, score, now))
		end
		return score, evs, now
	end
	local function sum(evs, key)
		local s = 0
		for _, e in evs do
			s += (e[key] == true and 1) or (type(e[key]) == "number" and e[key]) or 0
		end
		return s
	end

	-- 1. legit tier-1 climb on a Score-1 mount: every checkpoint, one ascent, nothing clamped
	local prof, t = M.newProfile(), M.newTracker()
	local score, evs, secs = climb(prof, t, 10, 1, 1)
	local cps = 0
	for _, e in evs do
		if e.cp then
			cps = e.cp
		end
	end
	local wantCoins = math.floor(score * G.CoinPerScore) + G.AscentBonus
	add("legit tier 1", t.run.valid and cps == #C.Zones and prof.best == #C.Zones and prof.ascents == 1
		and sum(evs, "rejected") < 1e-6 and math.abs(prof.coins - wantCoins) <= 1,
		string.format("%.0f s, cp %d, best %d, ascents %d, score %.0f, coins %d (want %d), rejected %.1f", secs, cps,
			prof.best, prof.ascents, score, prof.coins, wantCoins, sum(evs, "rejected")))

	-- 2. fastest rare flyer (top tier + jitter, Score max): still valid, all its score accepted
	prof, t = M.newProfile(), M.newTracker()
	score, evs = climb(prof, t, 10, maxSpd * (1 + C.SpeedJitter), maxScore)
	add("legit fastest rare", t.run.valid and prof.best == #C.Zones and sum(evs, "rejected") < 1e-6,
		string.format("valid %s, best %d, score %.0f, rejected %.1f", tostring(t.run.valid), prof.best, score,
			sum(evs, "rejected")))

	-- 3. faceplant drops (FallDistance) and a late + early report pair (jitter) keep the run valid
	prof, t = M.newProfile(), M.newTracker()
	climb(prof, t, 10, 1, 1, function(i, d)
		if i % 25 == 0 then
			return d - C.FallDistance
		end
	end)
	local tj, pj = M.newTracker(), M.newProfile()
	M.step(tj, pj, 100, 0, 0)
	local v = P.speedAt(100)
	M.step(tj, pj, 100 + v * 1.9, 0, 1.0) -- the 1-s report covering 1.9 s arrives early...
	M.step(tj, pj, 100 + v * 2.0, 0, 2.0) -- ...the next one is short
	add("faceplants + jitter", t.run.valid and prof.best == #C.Zones and tj.run.valid,
		string.format("faceplant run valid %s best %d; jitter run valid %s", tostring(t.run.valid), prof.best,
			tostring(tj.run.valid)))

	-- 4. teleport ahead: run invalid, no checkpoints, no coins after it
	prof, t = M.newProfile(), M.newTracker()
	M.step(t, prof, 50, 0, 0)
	local e1 = M.step(t, prof, P.Starts[5] + 10, 500, 1)
	local e2 = M.step(t, prof, P.Starts[5] + 40, 530, 2)
	add("teleport cheat", (not t.run.valid) and t.run.reason == "speed" and prof.best == 0 and prof.coins == 0
		and e1.accepted == 0 and e2.accepted == 0,
		string.format("valid %s (%s), best %d, coins %d", tostring(t.run.valid), tostring(t.run.reason), prof.best, prof.coins))

	-- 5. too fast but small steps (3x the fastest legit pace): caught within a few reports
	prof, t = M.newProfile(), M.newTracker()
	local d, n = 10, 0
	M.step(t, prof, d, 0, 0)
	while t.run.valid and n < 30 do
		n += 1
		d += M.vmax(d) * 3 / G.Slack * 0.25
		M.step(t, prof, d, 0, n * 0.25)
	end
	add("speed hack", not t.run.valid and n <= 12 and prof.best == 0,
		string.format("caught after %d reports at d %.0f, best %d", n, d, prof.best))

	-- 6. score inflation on a legit climb (20x the ridden distance): capped at MaxScore x ScoreSlack per stud
	prof, t = M.newProfile(), M.newTracker()
	score = climb(prof, t, 10, 1, 20)
	local cap = (t.run.d - 10) * C.ScoreRate * maxScore * G.ScoreSlack
	add("score inflation", prof.score <= cap and prof.score < score * 0.5,
		string.format("claimed %.0f, accepted %.0f (cap %.0f)", score, prof.score, cap))

	-- 7. joining high up (no climb from the bottom) is invalid; the summit reset starts a fresh valid run
	prof, t = M.newProfile(), M.newTracker()
	M.step(t, prof, P.Starts[8], 0, 0)
	local high = t.run.valid
	local t2, p2 = M.newTracker(), M.newProfile()
	climb(p2, t2, 10, 1, 1)
	local eReset = M.step(t2, p2, 15, 0, 9999)
	add("start + summit reset", (not high) and eReset.newRun and t2.run.valid and t2.run.cp == 0 and p2.ascents == 1,
		string.format("high start valid %s; reset new run %s valid %s cp %d ascents %d", tostring(high),
			tostring(eReset.newRun), tostring(t2.run.valid), t2.run.cp, p2.ascents))

	-- 8. migration: partial / junk records become clean profiles
	local m = M.migrate({ coins = "12", best = 99, upgrades = { Ring = 9, Bogus = 3 }, junk = true })
	local m0 = M.migrate(nil)
	add("migrate", m.v == M.Version and m.coins == 12 and m.best == #C.Zones and m.upgrades.Ring == upgradeById.Ring.Max
		and m.upgrades.Bogus == nil and m.junk == nil and M.equal(m0, M.newProfile()),
		string.format("coins %s best %s Ring %s Bogus %s", tostring(m.coins), tostring(m.best), tostring(m.upgrades.Ring),
			tostring(m.upgrades.Bogus)))

	-- 9. buying: costs, max level, not enough coins
	prof = M.newProfile()
	prof.coins = 10000
	local u = C.Upgrades[1]
	local spent, okAll = 0, true
	for lvl = 1, u.Max do
		local ok, cost = M.buy(prof, u.Id)
		okAll = okAll and ok and cost == u.Cost[lvl]
		spent += ok and cost or 0
	end
	local okMax, whyMax = M.buy(prof, u.Id)
	local poor = M.newProfile()
	local okPoor, whyPoor = M.buy(poor, u.Id)
	add("buy", okAll and prof.coins == 10000 - spent and not okMax and whyMax == "max" and not okPoor and whyPoor == "coins",
		string.format("spent %d for %d levels, then %s / %s", spent, u.Max, tostring(whyMax), tostring(whyPoor)))

	-- 10. section medals (P4): from the normal start at -30, a tier-1 climb times every section at ~40 s
	-- (BRONZE/SILVER), a 1.5x mount at ~27 s (GOLD); best times keep the fastest; a teleport run earns none
	local function medalRun(spd, p)
		local tt = M.newTracker()
		climb(p, tt, -30, spd, 1)
		return p
	end
	prof = medalRun(1, M.newProfile())
	local t1, m1 = table.clone(prof.times), prof.medals[1]
	local okSlow = true
	for k = 1, #C.Zones do
		okSlow = okSlow and prof.medals[k] >= 1 and prof.medals[k] <= 2 and math.abs(prof.times[k] - C.Zones[k].Time) <= 4
	end
	medalRun(1.5, prof)
	local okFast = true
	for k = 1, #C.Zones do
		okFast = okFast and prof.medals[k] == 3 and prof.times[k] < t1[k] and prof.times[k] <= C.Medals.Gold
	end
	local cheat = M.newProfile()
	t = M.newTracker()
	M.step(t, cheat, -30, 0, 0)
	M.step(t, cheat, P.Total + 10, 0, 1)
	local okCheat = cheat.medals[#C.Zones] == 0
	local mig = M.migrate({ v = 1, coins = 5 })
	add("medals", okSlow and okFast and okCheat and #mig.medals == #C.Zones and mig.medals[1] == 0,
		string.format("tier 1: s1 %.1f s %s, s10 %.1f s; 1.5x: s1 %.1f s %s, s10 %.1f s; teleport none %s; v1 migrates %s",
			t1[1], C.Medals.Names[m1] or "-", t1[#C.Zones], prof.times[1],
			C.Medals.Names[prof.medals[1]] or "-", prof.times[#C.Zones], tostring(okCheat), tostring(mig.medals[1] == 0)))

	-- 11. Herd Journal ridden counts: a mount reported before its run's first report still counts; a far-away d,
	-- an unknown name and an invalid run do not
	local rp, rt = M.newProfile(), M.newTracker()
	local s1 = C.Species[1][1].Name
	M.ridden(rt, s1, 10) -- before any report (join / summit reset)
	M.step(rt, rp, -30, 0, 0)
	M.step(rt, rp, 5, 0, 1)
	M.ridden(rt, s1, 5000) -- far from the reported d (and the wrong section)
	M.ridden(rt, s1, 700) -- section 1, but 670 studs from the next reported d (RiddenNear 300)
	M.ridden(rt, "Bogus", 10)
	M.step(rt, rp, 30, 0, 2)
	local okFirst = rp.ridden[s1] == 1
	local bad = M.newProfile()
	rt = M.newTracker()
	M.step(rt, bad, 1000, 0, 0) -- starts too high: invalid run
	M.ridden(rt, C.Species[2][2].Name, 1000)
	M.step(rt, bad, 1010, 0, 1)
	add("journal ridden", okFirst and rp.ridden.Bogus == nil and (bad.ridden[C.Species[2][2].Name] or 0) == 0,
		string.format("%s %d (first mount, far d ignored), invalid run counted %d", s1, rp.ridden[s1] or 0,
			bad.ridden[C.Species[2][2].Name] or 0))
	return out
end

return M

-- Tutorial (ServerScriptService.CC_CoreServer): the ~10-min diegetic onboarding (LOCKED: companion + short prompts,
-- skippable on return, guardian-free Rare by minute 5, cliffhanger ~min 10). Beats follow brief §3.6 (PROPOSED):
--   1 look around · 2 claim a common · 3 bank it at the campfire · 4 Shepherd's Road + short rope climb ·
--   5 Rare nook · 6 gentle guardian pup + cloth net · 7 take the Heartstone · 8 bank it (it ripens at home) ·
--   9 while it ripens, claim two finds on the Foothold outskirts · 10 bank them ·
--   11 cliffhanger: the camera finds a bigger guardian on the valley lip while the ripen timer runs · 12 done.
-- Beats 9-10 (B-polish 2026-10-20, PROPOSED) lengthen the onboarding toward ~10 min after the Rare (still <= 5:00)
-- and repeat the claim -> bank loop once on the player's own; they never block (timeout, shared commons).
-- Each step completes on a predicate over server state (not on client claims), checked on events and every 0.5 s,
-- so out-of-order play and mid-tutorial rejoins still progress. The step is saved in profile flags.tutorial.
-- One line per beat, no paragraphs; the companion (glow-wisp, PROPOSED) and objective marker are client visuals.
local Players = game:GetService("Players")

local Tut = {}
local ctx, C, Clock, Inv
local started = {} -- [plr] = { t, pos }
local cliff = {} -- [plr] = os.clock() when the cliffhanger began
local round = {} -- [plr] = { n = claims during beat 9, t = os.clock() at entry, banked = beat 10 bank seen }
local CLIFF, DONE = 11, 12
local VERSION = 2 -- step numbering (v1: cliffhanger 9, done 10)
local homePortals={}

local function marker(name)
	local core = workspace.World:FindFirstChild("Core")
	local m = core and core:FindFirstChild("Props") and core.Props:FindFirstChild(name)
	return m and m.Position or nil
end
local function hasTimer(s, key)
	return s.data.timers[key] ~= nil
end
local function packHas(plr, kind)
	for _, it in ipairs(Inv.bag(plr.UserId).items) do
		if it.kind == kind then
			return true
		end
	end
	return false
end
local function near(plr, pos, r)
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	return hrp and pos and (hrp.Position - pos).Magnitude < r
end

local STEPS = {
	[1] = {
		line = "Welcome to the Foothold. Look around, then follow me.",
		done = function(plr)
			local st = started[plr]
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			return st and (os.clock() - st.t > 8 or (hrp and (hrp.Position - st.pos).Magnitude > 12))
		end,
	},
	[2] = {
		line = "A creature! Walk up and hold to claim it.",
		target = function()
			return ctx.Claims.spawnPos("tut_common"), "Creature"
		end,
		done = function(plr, s)
			return hasTimer(s, "spawn:tut_common")
		end,
	},
	[3] = {
		line = "Finds are only safe once banked. Bank at the campfire.",
		target = function()
			return ctx.Camps.bankPart and ctx.Camps.bankPart.Position, "Bank"
		end,
		done = function(plr, s)
			return s.data.flags.firstBankAt > 0
		end,
	},
	[4] = {
		line = "Follow Shepherd's Road. Clip the anchor, then alternate left and right.",
		target = function()
			return marker("RopeBase"), "Rope"
		end,
		done = function(plr, s)
			return near(plr, marker("NookTop"), 9) or hasTimer(s, "spawn:nook_rare_r1")
		end,
	},
	[5] = {
		line = "Something rare hides up here. Hold to claim it.",
		target = function()
			return ctx.Claims.spawnPos("nook_rare_r1"), "Rare"
		end,
		done = function(plr, s)
			return hasTimer(s, "spawn:nook_rare_r1")
		end,
	},
	[6] = {
		line = "Ring the wind chimes, then hold to net the guardian's pup.",
		target = function(plr)
			local s=ctx.sessions[plr]
			if not (s and s.data.expedition.puzzles and s.data.expedition.puzzles.nest_r1_hollow) then
				return ctx.Nests.distractionPos("nest_r1_hollow"), "Wind chimes"
			end
			return ctx.Nests.pupPos("nest_r1_hollow"), "Pup"
		end,
		done = function(plr, s)
			-- netting is the lesson, but taking the Heartstone first must not soft-lock the tutorial
			return hasTimer(s, "pup:nest_r1_hollow") or hasTimer(s, "nest:nest_r1_hollow") or packHas(plr, "heartstone")
		end,
	},
	[7] = {
		line = "Take the Heartstone from the nest, then head home.",
		target = function()
			return ctx.Nests.hsPos("nest_r1_hollow"), "Heartstone"
		end,
		done = function(plr, s)
			return hasTimer(s, "nest:nest_r1_hollow") or packHas(plr, "heartstone")
		end,
	},
	[8] = {
		line = "Bank the Heartstone, then place it in a nest at your home.",
		target = function()
			return ctx.Camps.bankPart and ctx.Camps.bankPart.Position, "Bank"
		end,
		done = function(plr, s)
			if #s.data.heartstones > 0 then
				return true -- banked and ripening
			end
			-- nothing left to bank (shaken loose and the pack faded): move on instead of soft-locking
			if packHas(plr, "heartstone") then
				return false
			end
			for _, p in pairs(ctx.DropPacks._packs) do
				if p.ownerId == plr.UserId then
					for _, it in ipairs(p.items) do
						if it.kind == "heartstone" then
							return false
						end
					end
				end
			end
			return true
		end,
	},
	[9] = {
		line = "Claim two more finds. Newly banked discoveries advance occupied nests.",
		target = function(plr)
			-- nearest outskirts find that is still there (shared commons: someone else may have claimed one)
			local hrp = plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			local best, bd
			for _, id in ipairs(C.TUT_OUTSKIRTS) do
				local sp = ctx.Claims._spawns[id]
				if sp and sp.available then
					local d = hrp and (sp.pos - hrp.Position).Magnitude or 0
					if not bd or d < bd then
						best, bd = sp.pos, d
					end
				end
			end
			return best, "Creature"
		end,
		done = function(plr,s)
			local r = round[plr]
			if #s.data.heartstones>0 and (s.data.home.nests[1] or "")=="" and (s.data.home.nests[2] or "")=="" then return false end
			return r and (r.n >= 2 or os.clock() - r.t > C.TUT_OUTSKIRTS_TIMEOUT or Inv.free(plr.UserId) < 1)
		end,
	},
	[10] = {
		line = "Bank them at the campfire.",
		target = function()
			return ctx.Camps.bankPart and ctx.Camps.bankPart.Position, "Bank"
		end,
		done = function(plr)
			local r = round[plr]
			return (r and r.banked) or (Inv.used(plr.UserId) == 0 and #ctx.DropPacks.ownedBy(plr.UserId) == 0)
		end,
	},
	[11] = {
		line = "Up on the lip, a bigger guardian keeps a richer nest.",
		done = function(plr)
			return cliff[plr] and os.clock() - cliff[plr] > 7
		end,
	},
}

local function current(plr)
	local s = ctx.sessions[plr]
	return s and s.data.flags.tutorial or DONE
end

local function enter(plr, s, step)
	s.data.flags.tutorial = step
	s.dirty = true
	plr:SetAttribute("CC_Tutorial", step)
	plr:SetAttribute("CC_TutorialAt", os.clock())
	if step == 9 then
		round[plr] = { n = 0, t = os.clock(), banked = false }
	end
	if step == CLIFF and not cliff[plr] then
		cliff[plr] = os.clock()
		local g = ctx.Nests.watch(plr, "nest_r1_lip")
		local focus = ctx.Nests.nestPos("nest_r1_lip")
		ctx.fx(plr, { kind = "cliffhanger", focus = focus and focus + Vector3.new(0, 6, 0), secs = 4.5 })
		ctx.emit("cliffhanger", plr, g ~= nil)
	elseif step == DONE then
		ctx.toast(plr, "Place banked Heartstones in your two home nests. New discoveries help both.", "good")
	end
	ctx.push(plr)
end

local function advance(plr)
	local s = ctx.sessions[plr]
	if not s or s.pending or s.busy or s.saving or s.outcomePending then
		return
	end
	local step = s.data.flags.tutorial
	if step <= 0 or step >= DONE then
		return
	end
	-- step 3 with nothing to bank (the first common was lost, e.g. a disconnect): give the first common back
	if step == 3 and s.data.flags.firstBankAt == 0 and Inv.used(plr.UserId) == 0 and #ctx.DropPacks.ownedBy(plr.UserId) == 0 then
		s.data.timers["spawn:tut_common"] = nil
		s.dirty = true
		enter(plr, s, 2)
		return
	end
	local guard = 0
	while step < DONE and STEPS[step] and STEPS[step].done(plr, s) do
		step += 1
		guard += 1
		if guard > DONE or step == CLIFF then
			break -- the cliffhanger always plays
		end
	end
	if step ~= s.data.flags.tutorial then
		enter(plr, s, step)
	end
end
Tut.advance = advance

function Tut.init(c)
	ctx = c
	C, Clock, Inv = c.C, c.Clock, c.Inv
	ctx.Tutorial = Tut
	for _, ev in ipairs({ "claim", "bank", "net", "heartstone" }) do
		ctx.on(ev, function(plr)
			local s = ctx.sessions[plr]
			local step = s and s.data.flags.tutorial
			local r = round[plr]
			if r and ev == "claim" and step == 9 then
				r.n += 1
			elseif r and ev == "bank" and step == 10 then
				r.banked = true
			end
			task.defer(advance, plr)
		end)
	end
	ctx.handlers.tutorialSkip = function(plr)
		local s = ctx.sessions[plr]
		if s and s.data.flags.tutorial < DONE then
			enter(plr, s, DONE)
		end
	end
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, plr in ipairs(Players:GetPlayers()) do
				advance(plr)
			end
		end
	end)
	-- Studio-only: restart the tutorial for bots
	if ctx.devHandlers then
		ctx.devHandlers.tutorialReset = function(plr)
			local s = ctx.sessions[plr]
			if s then
				started[plr] = { t = os.clock(), pos = plr.Character and plr.Character:GetPivot().Position or Vector3.zero }
				cliff[plr] = nil
				round[plr] = nil
				enter(plr, s, 1)
			end
		end
		-- Studio-only: replay the beat-11 shot (same guardian watch + fx) for captures; steps are untouched
		ctx.devHandlers.cliffhanger = function(plr, p)
			local g = ctx.Nests.watch(plr, "nest_r1_lip")
			local focus = ctx.Nests.nestPos("nest_r1_lip")
			ctx.fx(plr, { kind = "cliffhanger", focus = focus and focus + Vector3.new(0, 6, 0), secs = p.secs or 4.5 })
			return g ~= nil
		end
	end
end

function Tut.onLoaded(plr, s)
	-- v1 numbering (cliffhanger 9, done 10) -> v2 (outskirts 9, bank 10, cliffhanger 11, done 12)
	if s.data.flags.tutorialV ~= VERSION then
		local old = s.data.flags.tutorial
		if old >= 10 then
			s.data.flags.tutorial = DONE
		elseif old == 9 then
			s.data.flags.tutorial = CLIFF
		end
		s.data.flags.tutorialV = VERSION
		s.dirty = true
	end
	-- new profile -> start; a profile that already banked before the tutorial existed -> skip
	if s.data.flags.tutorial == 0 then
		if s.data.flags.firstBankAt > 0 or #s.data.bank > 0 then
			s.data.flags.tutorial = DONE
			s.dirty = true
		else
			local ch = plr.Character or plr.CharacterAdded:Wait()
			started[plr] = { t = os.clock(), pos = ch:GetPivot().Position }
			enter(plr, s, 1)
		end
	elseif s.data.flags.tutorial < DONE then
		local ch = plr.Character or plr.CharacterAdded:Wait()
		started[plr] = { t = os.clock() - 10, pos = ch:GetPivot().Position }
		if s.data.flags.tutorial == CLIFF then
			enter(plr, s, CLIFF - 1) -- replay the cliffhanger after a rejoin
		elseif s.data.flags.tutorial == 9 then
			round[plr] = { n = 0, t = os.clock(), banked = false }
		end
		ctx.push(plr)
	end
	plr:SetAttribute("CC_Tutorial", s.data.flags.tutorial)
end

function Tut.onLeave(plr)
	started[plr] = nil
	cliff[plr] = nil
	round[plr] = nil
end

function Tut.state(plr, st)
	local s = ctx.sessions[plr]
	if not s or s.pending or s.busy or s.saving then
		return
	end
	local step = s.data.flags.tutorial
	if step >= 1 and step < DONE then
		local def = STEPS[step]
		local t = { step = step, total = DONE - 1, line = def and def.line or "" }
		if def and def.target then
			local pos, label = def.target(plr)
			if pos then
				t.target = pos
				t.label = label
			end
		end
		-- a full backpack at the Heartstone: send the player to bank first instead of a refused claim
		if step == 7 and Inv.free(plr.UserId) < C.HEARTSTONE_SLOTS then
			t.line = "Your backpack is full. Bank at the campfire, then come back for the Heartstone."
			t.target = ctx.Camps.bankPart and ctx.Camps.bankPart.Position
			t.label = "Bank"
		end
		if step==9 and #s.data.heartstones>0 and (s.data.home.nests[1] or "")=="" and (s.data.home.nests[2] or "")=="" then
			t.line="Visit a Foothold cabin and place your banked Heartstone in one of your two home nests."
			local p=plr.Character and plr.Character:GetPivot().Position
			local best,dist
			if #homePortals==0 then for _,x in ipairs(workspace.World:GetDescendants()) do if x:IsA("BasePart") and x.Name=="HomePortalStation" then homePortals[#homePortals+1]=x end end end
			for _,x in ipairs(homePortals) do
				if x.Parent and p then
					local d=(x.Position-p).Magnitude if not dist or d<dist then best,dist=x.Position,d end
				end
			end
			t.target=best t.label="Home cabin"
			if plr:GetAttribute("CC_InHome") then t.target=nil t.label="Home station" t.line="Use the home station to place your Heartstone in a nest. Then bank new discoveries to help it grow." end
		end
		st.tut = t
	end
end

return Tut

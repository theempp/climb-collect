-- LedgeRoute (v4 P3, run 2): Cliff Ledge Line, full route (master.md §0.8 LOCKED form; placements PROPOSED).
--   require(ServerStorage.CC_Generators:Clone().LedgeRoute).build(Kit)       (after B.camps; needs _G.CC_PATHS
--   from Gen.computeField with the Ledge "lines" unstamped, i.e. the terrain written after WorldConfig's lines)
-- Leg 0 is LedgeP1 (gate -> s 645) + the stamped approach to Camp 1. Every switchback climb through a steep band
-- (WorldConfig Ledge.lines) is rebuilt here as a ClimbKit pitch stack; the shelf traverses between them stay
-- narrow stamped benches (hw 3, drop side natural).
local CK = require(script.Parent.ClimbKit)
local LR = {}

-- per stack: tier rise and which tiers / faces carry a feature (all PROPOSED, tuned from bot times)
-- ta/tb = the tier window (theta, unwrapped around the stack's start): the old switchback window of each band
LR.STACKS = {
	forest = { rise = 40, ta = 1.376, tb = 1.546, label = "Forest band rest", features = { rest = { 3 }, traverse = { 2 }, chute = { 4 }, lunge = { 3 } } },
	cliffs = { rise = 42, ta = 2.536, tb = 2.78, label = "Broken Cliffs rest", features = { rest = { 3, 7 }, traverse = { 5 }, chute = { 2, 6 }, lunge = { 4, 8 } } },
	storm = { rise = 44, ta = -2.229, tb = -1.799, minDeg = 44, label = "Storm band rest", features = { rest = { 3, 8 }, traverse = { 2 }, chute = { 4, 10 }, lunge = { 5 } } },
}

-- the P1 section's bot track, read from the built World.LedgeP1 (same order as tools/ledge_bot.luau): approach
-- flags, trailhead, Face B, L1 east -> west with the chute crossing on the marked panel, the pillar, the exit flag
local function p1Segment()
	local W = workspace:FindFirstChild("World")
	local LP = W and W:FindFirstChild("LedgeP1")
	if not LP then
		return nil
	end
	local function v(p)
		return { math.floor(p.X * 10 + 0.5) / 10, math.floor(p.Y * 10 + 0.5) / 10, math.floor(p.Z * 10 + 0.5) / 10 }
	end
	local function flat(p)
		return Vector3.new(p.X, 0, p.Z)
	end
	local nodes = {}
	for _, n in ipairs({ "Flag_1", "Flag_2" }) do
		local f = LP:FindFirstChild(n, true)
		if f then
			nodes[#nodes + 1] = { k = "walk", p = v(f:FindFirstChild("GuideFlag").Position - Vector3.new(0, 4, 0) + Vector3.new(0, 0, 4)) }
		end
	end
	nodes[#nodes + 1] = { k = "walk", p = v(Vector3.new(-482, 101, 1872)) }
	nodes[#nodes + 1] = { k = "walk", p = v(Vector3.new(-488, 101, 1866)) }
	nodes[#nodes + 1] = { k = "climb", into = { 0, 0, -1 }, label = "P1_FaceB" }
	local walkParts = {}
	for _, p in ipairs(LP.L1:GetChildren()) do
		if p.Name == "Ledge" or p.Name == "RestLedge" or p.Name == "FinDeck" then
			walkParts[#walkParts + 1] = p
		end
	end
	table.sort(walkParts, function(a, b)
		return a.Position.X > b.Position.X
	end)
	local panel = LP.L1:FindFirstChild("MarkedPanel")
	local haz = W.Hazards:FindFirstChild("LedgeP1") and W.Hazards.LedgeP1:FindFirstChild("Rockfall_Chute")
	local crossed = false
	for _, p in ipairs(walkParts) do
		local top = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
		if panel and not crossed and top.X < panel.Position.X then
			local o = -panel.CFrame.RightVector
			local prev = nodes[#nodes].p
			if (flat(Vector3.new(prev[1], 0, prev[3])) - flat(panel.Position)):Dot(o) < 0 then
				o = -o
			end
			local along = -panel.CFrame.LookVector
			if along:Dot(Vector3.new(-1, 0, 0)) < 0 then
				along = -along
			end
			along = flat(along).Unit
			local edge = flat(panel.Position) + o * 2.6 - along * 5.2
			nodes[#nodes + 1] = { k = "walk", p = v(Vector3.new(edge.X, top.Y + 3, edge.Z)) }
			if haz then
				nodes[#nodes + 1] = { k = "wait", hz = haz:GetFullName() }
			end
			nodes[#nodes + 1] = { k = "climb", into = v(-o), dir = v(along), label = "P1_panel" }
			crossed = true
		end
		nodes[#nodes + 1] = { k = "walk", p = v(top + Vector3.new(0, 3, 0)) }
	end
	local grip = LP.Pillar.Ladder.LadderGrip
	local oE = grip.CFrame.LookVector
	nodes[#nodes + 1] = { k = "walk", p = v(grip.Position + oE * 2.5 - Vector3.new(0, grip.Size.Y / 2 - 3, 0)) }
	nodes[#nodes + 1] = { k = "climb", into = v(-flat(oE).Unit), label = "P1_pillar" }
	local ex = LP:FindFirstChild("Flag_9", true)
	if ex then
		local fp = ex:FindFirstChild("GuideFlag").Position
		nodes[#nodes + 1] = { k = "walk", p = v(Vector3.new(grip.Position.X, fp.Y - 3, fp.Z)) }
		nodes[#nodes + 1] = { k = "walk", p = v(fp - Vector3.new(0, 4, 0)) }
	end
	return { id = "p1", s0 = 40, s1 = 645, nodes = nodes }
end

-- opts.rewrite = false: the boxes were already rewritten (BuildAll.allLines)
function LR.build(Kit, only, opts)
	local R = _G.CC_PATHS and _G.CC_PATHS.routes.Ledge
	assert(R and R.ctrlS, "LedgeRoute needs _G.CC_PATHS from Gen.computeField (v4 P3 MountainGen)")
	local ck = CK.new(Kit, "Ledge")
	local out = {}
	for i, ln in ipairs(R.def.lines or {}) do
		local st = LR.STACKS[ln.band]
		if ln.kind == "stack" and st and (not only or only == ln.band) then
			local rep = ck:stack({
				name = ln.band,
				R = R,
				s0 = R.ctrlS[ln.c0] + (ln.pad0 or 0),
				s1 = R.ctrlS[ln.c1] - (ln.pad1 or 0),
				rise = st.rise,
				ta = st.ta,
				tb = st.tb,
				foot = st.foot,
				minDeg = st.minDeg,
				top = st.top,
				features = st.features,
				label = st.label,
				guideBase = 100 * i,
				order0 = 10 * i,
				rewrite = not (opts and opts.rewrite == false),
			})
			out[#out + 1] = rep
			task.wait()
		elseif ln.kind == "hang" and (not only or only == ln.band) then
			out[#out + 1] = ck:hang({
				name = ln.band,
				R = R,
				s0 = ln.s0,
				s1 = ln.s1,
				drop = ln.drop,
				outward = ln.outward,
				notch = ln.notch,
				features = ln.features or { traverse = { 0.3 }, chute = { 0.62 }, rest = { 0.47 } },
				label = ln.label or ((R.def.name or "") .. " hang-line rest"),
				ledgeMat = nil,
				guideBase = 100 * i,
				order0 = 10 * i,
				rewrite = not (opts and opts.rewrite == false),
			})
			task.wait()
		end
	end
	local p1 = p1Segment()
	if p1 then
		table.insert(ck.segments, 1, p1)
	end
	-- a full build also removes lines no longer configured (their parts, hazards, checkpoints)
	if not only then
		local keep = {}
		for _, ln in ipairs(R.def.lines or {}) do
			keep[ln.band] = true
		end
		for _, f in ipairs(ck.lines:GetChildren()) do
			if not keep[f.Name] then
				ck:clearLine(f.Name)
			end
		end
	end
	local segs = ck:export(not only)
	local lines = {}
	for _, r in ipairs(out) do
		local t = {}
		for k, v in pairs(r) do
			t[#t + 1] = k .. "=" .. tostring(v)
		end
		table.sort(t)
		lines[#lines + 1] = table.concat(t, " ")
	end
	lines[#lines + 1] = string.format("parts %d, track segments %d", ck.n, segs)
	return table.concat(lines, "\n")
end

return LR

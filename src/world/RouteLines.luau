-- RouteLines (v4 P3, run 2): authored lines for Spire Ridge and Waterfall Stair (Ledge has LedgeRoute.luau, which
-- also carries the P1 section). Each WorldConfig route "lines" entry (kind = "stack") is rebuilt as a ClimbKit pitch
-- stack in the route's own style. Placements and numbers PROPOSED (decision log, run 2).
--   require(ServerStorage.CC_Generators:Clone().RouteLines).build(Kit, "Spire")    (after B.route(name): RouteKit
--   deletes a route's checkpoint triggers; needs _G.CC_PATHS from Gen.computeField with the lines unstamped)
local CK = require(script.Parent.ClimbKit)
local RL = {}

-- route style: Spire = expert knife-ridge line (pale limestone ledges, more faces per stack, lunge bands);
-- Waterfall = moderate wet-rock line (dark slate ledges, steel ladders, one rope-slope crossing on the lip)
RL.STYLE = {
	Spire = {
		ledgeMat = Enum.Material.Limestone,
		ledgeW = 9,
		stacks = {
			forest = { rise = 34, label = "Spire forest rest", features = { rest = { 3 }, traverse = { 2 }, chute = { 4 }, lunge = { 3, 6 } } },
			cliffs = { rise = 36, label = "Spire cliffs rest", features = { rest = { 4 }, traverse = { 3 }, chute = { 2, 6 }, lunge = { 5 } } },
			storm = { rise = 36, minDeg = 48, label = "Spire storm rest", features = { rest = { 3 }, chute = { 4 }, lunge = { 2 } } },
		},
	},
	-- Shepherd = the easy road's "gentle but alive" scrambles: low faces, ladders on every other face, wide ledges
	Shepherd = {
		ledgeMat = Enum.Material.Ground,
		ledgeW = 12,
		faceStyle = "alt",
		stacks = {
			leg1 = { rise = 14, minDeg = 40, foot = "trail", top = "trail", windowLen = 90, label = "Shepherd scramble rest", features = { rest = { 2 } } },
			leg2 = { rise = 14, minDeg = 40, foot = "trail", top = "trail", windowLen = 90, label = "Shepherd scramble rest", features = { rest = { 2 } } },
			leg3a = { rise = 14, minDeg = 40, foot = "trail", top = "trail", windowLen = 90, label = "Shepherd scramble rest", features = { rest = { 2 }, traverse = { 1 } } },
			leg3b = { rise = 14, minDeg = 40, foot = "trail", top = "trail", windowLen = 90, label = "Shepherd scramble rest", features = { rest = { 2 } } },
			leg4 = { rise = 14, minDeg = 40, foot = "trail", top = "trail", windowLen = 90, label = "Shepherd scramble rest", features = { rest = { 2 } } },
		},
	},
	Waterfall = {
		ledgeMat = Enum.Material.Slate,
		ledgeW = 10,
		faceStyle = "ladder",
		stacks = {
			lip = { rise = 36, label = "Falls ledge rest", features = { rest = { 3 }, traverse = { 4 } } }, -- the one rope-slope crossing
			forest = { rise = 36, label = "Waterfall forest rest", features = { rest = { 3 } } },
			cliffs = { rise = 38, label = "Waterfall cliffs rest", features = { rest = { 3 }, chute = { 5 } } },
			storm = { rise = 38, minDeg = 48, ta = -2.48, tb = -2.30, label = "Waterfall storm rest", features = { rest = { 3 } } },
		},
	},
}

-- opts.rewrite = false: the boxes were already rewritten (BuildAll.allLines)
function RL.build(Kit, routeName, only, opts)
	local R = _G.CC_PATHS and _G.CC_PATHS.routes[routeName]
	assert(R and R.ctrlS, "RouteLines needs _G.CC_PATHS from Gen.computeField (v4 P3 MountainGen)")
	local style = RL.STYLE[routeName]
	assert(style, "no style for " .. tostring(routeName))
	local ck = CK.new(Kit, routeName)
	local out = {}
	for i, ln in ipairs(R.def.lines or {}) do
		local st = style.stacks[ln.band]
		if ln.kind == "stack" and st and (not only or only == ln.band) then
			local rep = ck:stack({
				name = ln.band,
				R = R,
				s0 = R.ctrlS[ln.c0] + (ln.pad0 or 0),
				s1 = R.ctrlS[ln.c1] - (ln.pad1 or 0),
				rise = st.rise,
				minDeg = st.minDeg,
				foot = st.foot,
				top = st.top,
				windowLen = st.windowLen,
				ta = st.ta,
				tb = st.tb,
				features = st.features,
				label = st.label,
				ledgeMat = style.ledgeMat,
				ledgeW = style.ledgeW,
				faceStyle = style.faceStyle,
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
				ledgeMat = style.ledgeMat,
				guideBase = 100 * i,
				order0 = 10 * i,
				rewrite = not (opts and opts.rewrite == false),
			})
			task.wait()
		end
	end
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

return RL

-- BuildAll (V3 Ascent): reproducible rebuild of the world from the generator modules.
-- Run in edit mode via execute_luau, one step per call (each stays under a few seconds):
--   local B = require(ServerStorage.CC_Generators:Clone().BuildAll)
--   B.clearWorld()            -- removes Workspace.World (V2 content lives in checkpoint PreV3_2026-10-20)
--   B.terrain(1, opts) ; B.terrain(2) ; B.terrain(3)
--   (terrain(1) also rebuilds _G.CC_PATHS; every later step depends on it. opts.routes = false = P1 terrain only)
--   ... B.player() ; B.foothold() ; B.camps() ; B.route(name) ... ; B.ledgeP1() (v4 P1, after B.camps) ; B.shepherdP2()
--   ; B.ledgeRoute() (v4 P3)
local B = {}
local folder = script.Parent

local function mods()
	return {
		Gen = require(folder.MountainGen),
		Kit = require(folder.Kit),
	}
end

function B.clearWorld()
	local w = workspace:FindFirstChild("World")
	if w then
		for _, c in ipairs(w:GetChildren()) do
			c:Destroy()
			task.wait()
		end
	end
	return true
end

function B.terrain(part, opts)
	local m = mods()
	local rows = m.Gen.BLOCK_ROWS
	local third = math.ceil(rows / 3)
	if part == 1 then
		local res = m.Gen.computeField(opts)
		_G.CC_Gen = m.Gen
		workspace.Terrain:Clear()
		m.Gen.applyColors()
		m.Gen.writeRows(0, third - 1)
		return res
	elseif part == 2 then
		_G.CC_Gen.writeRows(third, 2 * third - 1)
		return true
	end
	_G.CC_Gen.writeRows(2 * third, rows - 1)
	return _G.CC_Gen.writeCrown()
end

-- player movement settings + route export for runtime code (bots now, objective pointer later)
function B.player()
	local TK = require(folder.TraverseKit)
	TK.applyPlayer()
	TK.exportRoute()
	-- every route (and the shared summit stair) as "x,y,z,s;..." for bots and runtime code
	local f = game:GetService("ReplicatedStorage"):FindFirstChild("CC_Route")
	for _, R in pairs(_G.CC_PATHS.routes) do
		local t = {}
		for i = 1, #R.pts, 3 do
			local q = R.pts[i]
			t[#t + 1] = string.format("%.1f,%.1f,%.1f,%.1f", q[1], q[3], q[2], R.S[i])
		end
		local sv = f:FindFirstChild(R.name) or Instance.new("StringValue")
		sv.Name = R.name
		sv.Value = table.concat(t, ";")
		sv.Parent = f
	end
	return true
end

-- V3 P3: Foothold home base
function B.foothold()
	local m = mods()
	return require(folder.FootholdV3).build(m.Kit, _G.CC_Gen)
end

-- V3 P4/P5: camps, then per route: bridges, checkpoints, wayfinding, hazards
function B.camps()
	local m = mods()
	local RK = require(folder.RouteKit)
	local cp = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Checkpoints")
	if cp then
		cp:Destroy()
	end
	return RK.camps(m.Kit, _G.CC_Gen)
end

function B.route(name)
	local m = mods()
	local RK = require(folder.RouteKit)
	return { RK.route(m.Kit, _G.CC_Gen, name), RK.hazards(m.Kit, _G.CC_Gen, name) }
end

-- v4 P1: Cliff Ledge Line first climb section (after B.camps; the terrain already carries the route's stampSkip)
function B.ledgeP1()
	local m = mods()
	return require(folder.LedgeP1).build(m.Kit)
end

-- v4 P3: Cliff Ledge Line pitch stacks (after B.camps; terrain written with WorldConfig Ledge.lines unstamped)
function B.ledgeRoute(only)
	local m = mods()
	return require(folder.LedgeRoute).build(m.Kit, only)
end

-- v4 P3: Spire Ridge / Waterfall Stair pitch stacks (after B.route(name))
function B.routeLines(name, only)
	local m = mods()
	return require(folder.RouteLines).build(m.Kit, name, only)
end

-- v4 P3 (run 2): every pitch stack of every route. Rewrites all stack boxes from the generated field first, then
-- builds them all: a single-route rebuild rewrites its boxes, which overlap neighbouring routes' stacks (Waterfall /
-- Ledge / Spire cliffs) and erased their ledges. Use this after any stack change.
function B.allLines()
	local m = mods()
	local CK = require(folder.ClimbKit)
	local LR = require(folder.LedgeRoute)
	for _, name in ipairs({ "Ledge", "Spire", "Waterfall", "Shepherd" }) do
		local R = _G.CC_PATHS.routes[name]
		for _, ln in ipairs((R and not R.v5 and R.def.lines) or {}) do
			if ln.kind == "stack" and (name ~= "Ledge" or LR.STACKS[ln.band]) then
				CK.rewrite(R, R.ctrlS[ln.c0] + (ln.pad0 or 0), R.ctrlS[ln.c1] - (ln.pad1 or 0))
			elseif ln.kind == "hang" then
				CK.rewrite(R, ln.s0, ln.s1)
			end
		end
	end
	local out = {}
	if _G.CC_PATHS.routes.Ledge then
		out[#out + 1] = "Ledge:\n" .. LR.build(m.Kit, nil, { rewrite = false })
	end
	task.wait()
	for _, name in ipairs({ "Spire", "Waterfall", "Shepherd" }) do
		local R = _G.CC_PATHS.routes[name]
		if R and not R.v5 then
			out[#out + 1] = name .. ":\n" .. require(folder.RouteLines).build(m.Kit, name, nil, { rewrite = false })
			task.wait()
		end
	end
	return table.concat(out, "\n")
end

-- v4 P2: one "gentle but alive" Shepherd's Road stretch (after B.route("Shepherd"))
-- v4 P4 (run 2): the Training Yard annex outside the Foothold (after the terrain + routes: it avoids route paths)
function B.trainingYard()
	local m = mods()
	return require(folder.TrainingYard).build(m.Kit, m.Gen)
end

-- v5 P1: a spline route's world pieces (after the terrain with opts.v5 and B.player / B.camps)
function B.v5Route(name)
	local m = mods()
	return require(folder.SplineKit).build(m.Kit, m.Gen, name)
end

-- v5: whole world in order (P1: v5 Shepherd + v4 Waterfall). opts = computeField opts; returns a report
function B.v5All(opts)
	opts = opts or { routes = true, v5 = true }
	local out = {}
	B.clearWorld()
	B.terrain(1, opts)
	task.wait()
	B.terrain(2)
	task.wait()
	B.terrain(3)
	B.player()
	B.foothold()
	B.camps()
	for _, name in ipairs({ "Shepherd", "Waterfall", "Ledge", "Spire" }) do
		local R = _G.CC_PATHS.routes[name]
		if R and not R.v5 then
			B.route(name)
		end
		task.wait()
	end
	B.route("SummitStair")
	local m = mods()
	local cp = require(folder.CoreProps).build(m.Kit)
	out[#out + 1] = "CoreProps: " .. tostring(cp.commons) .. " | " .. tostring(cp.nook)
	B.allLines()
	-- v6: spline routes after the v4 lines: allLines rewrites terrain boxes +-70 around every v4 stack from the field,
	-- which erased spline-kit terrain pieces (the Shepherd gorge pitch's marked face, beside Waterfall's forest stack)
	for _, name in ipairs({ "Shepherd", "Waterfall", "Ledge", "Spire" }) do
		local R = _G.CC_PATHS.routes[name]
		if R and R.v5 then
			out[#out + 1] = B.v5Route(name)
		end
		task.wait()
	end
	B.trainingYard()
	out[#out + 1] = "World " .. #workspace.World:GetDescendants()
	return table.concat(out, "\n")
end

function B.shepherdP2()
	local m = mods()
	return require(folder.ShepherdP2).build(m.Kit)
end

return B

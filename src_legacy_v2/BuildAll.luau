-- BuildAll: reproducible rebuild of the world from the generator modules.
-- Run in edit mode via execute_luau (split across calls to keep each under a few seconds):
--   local B = require(ServerStorage.CC_Generators:Clone().BuildAll)
--   B.terrain(1) ; B.terrain(2) ; B.dressing() ; B.authored() ; B.regions() ; B.traverse(1..5)
-- (terrain(1) also rebuilds _G.CC_PATHS; every later step depends on it)
local B = {}
local folder = script.Parent

local function mods()
	return {
		Gen = require(folder.MountainGen),
		Kit = require(folder.Kit),
	}
end

-- clearings that keep landmarks and their sightlines free of trees
function B.valleyClearings(Gen)
	local P = _G.CC_PATHS
	local px, pz = Gen.toWorld(1.78, 1222) -- falls pool
	local lx, lz = Gen.toWorld(1.78, 1185) -- falls lip
	local c = P.pads.Camp1
	local clear = { { px, pz, 110 }, { lx, lz, 70 }, { c.x, c.z, 75 } }
	for _, cr in ipairs(P.crossings) do
		if cr.path == "Main" and P.main[cr.i0][3] < 300 then
			local a, b = P.main[cr.i0], P.main[cr.i1]
			local mx, mz = (a[1] + b[1]) / 2, (a[2] + b[2]) / 2
			-- bridge -> falls sightline
			for t = 0, 1, 0.2 do
				clear[#clear + 1] = { mx + (px - mx) * t, mz + (pz - mz) * t, 45 }
			end
		end
	end
	return clear
end

function B.terrain(part)
	local m = mods()
	if part == 1 then
		local res = m.Gen.computeField()
		_G.CC_Gen = m.Gen
		workspace.Terrain:Clear()
		m.Gen.applyColors()
		m.Gen.writeRows(0, 18)
		return res
	end
	_G.CC_Gen.writeRows(19, 37)
	return true
end

function B.dressing(opts)
	local m = mods()
	local Gen = _G.CC_Gen
	opts = opts or {}
	local gv = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Regions") and workspace.World.Regions:FindFirstChild("GreenValley")
	if gv and gv:FindFirstChild("Vegetation") then
		gv.Vegetation:Destroy()
	end
	return require(folder.ValleyDress).dress(m.Kit, Gen, { clear = B.valleyClearings(Gen), rocks = opts.rocks })
end

function B.authored()
	local m = mods()
	local Gen = _G.CC_Gen
	require(folder.BlockoutBuild).build()
	local slice = require(folder.SliceBuild)
	local r1 = slice.build(m.Kit, Gen)
	local fb = require(folder.FootholdBuild)
	fb.buildCore(m.Kit, Gen, slice)
	fb.buildFull(m.Kit, Gen)
	return r1
end

-- Gate D: upper regions (dressing + authored landmarks), in route order
function B.regions()
	local m = mods()
	local Gen = _G.CC_Gen
	local RD = require(folder.RegionDress)
	local out = {}
	local forest = require(folder.ForestBuild)
	out.forest = RD.dress(m.Kit, Gen, forest.dressSpec(m.Kit))
	forest.build(m.Kit, Gen)
	local cliff = require(folder.CliffBuild)
	out.cliffs = RD.dress(m.Kit, Gen, cliff.dressSpec(m.Kit))
	cliff.build(m.Kit, Gen)
	local high = require(folder.HighBuild)
	out.storm = RD.dress(m.Kit, Gen, high.stormSpec(m.Kit))
	out.summit = RD.dress(m.Kit, Gen, high.summitSpec(m.Kit))
	high.build(m.Kit, Gen, cliff)
	return out
end

-- Traversal pass (design/traversal-plan.md): player movement settings + one push's segments.
-- Segments carve terrain and clear props, so run B.traverse(1..n) in order after a fresh build.
function B.traverse(push)
	local m = mods()
	local TK = require(folder.TraverseKit)
	TK.applyPlayer()
	TK.exportRoute()
	return require(folder["TraverseP" .. push]).build(m.Kit, _G.CC_Gen)
end

return B

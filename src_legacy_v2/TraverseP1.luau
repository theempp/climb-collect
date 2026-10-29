-- TraverseP1: push 1, Foothold -> Camp 1 (Green Valley). Verb: climb (tutorial).
-- design/traversal-plan.md. Forgiving: gaps <= 3 studs, platforms >= 8, falls <= 8 studs onto
-- the gully floor, and a short frame climb back to the start of each gully.
local TK = require(script.Parent.TraverseKit)
local M = {}

-- frame on a gully's start wall (inside), so a missed hop costs seconds, not a detour
local function returnClimb(ctx, c, s, floorY, side, h)
	local p = ctx:at(s, side)
	TK.climbFace(ctx, c.model, Vector3.new(p.X, floorY, p.Z), -ctx:dir(ctx:iAtS(s)), h, 6, "frame", 4)
end

function M.build(Kit, Gen)
	local ctx = TK.begin(Kit, Gen, "P1")
	local S = ctx.P.mainS

	-- 1a Meadow Boulder Hop: a gully cut across the trail, five mossy stepping stones
	do
		local sLip = S[395]
		local sEnd = sLip + 2.5 + 5 * 8 + 4 * 2 + 2.5
		local fl = ctx:gully(sLip, sEnd, 6, 14, 18)
		local c = ctx:course("1a_MeadowBoulderHop", sLip, nil, fl)
		local rises = { 0.3, 0.4, -0.2, 0.4, 0.3 }
		local sides = { -1.5, 1.5, -1, 1.5, 0 }
		for k = 1, 5 do
			c:hop(8, k == 1 and 2.5 or 2, rises[k], "boulder", sides[k])
		end
		c:finish(sEnd + 3, true)
		returnClimb(ctx, c, sLip, fl(sLip + 1), 10, 6)
		ctx:sign(ctx:iAtS(sLip) - 6, "Meadow Boulder Hop")
	end

	-- 1b Shepherd's Step: the trail sinks into a cut lane; two framed climbs (8 + ~14 studs).
	-- Climb walls sit inside the cut so their bodies cover the voxel-quantized steps.
	do
		local s0, sB = S[603], S[630] + 3
		local L = sB - s0
		local y0 = ctx:at(s0).Y
		local function floorAt(t)
			return t < 0.5 and (y0 + 2 * t) or (y0 + 9 + 2 * (t - 0.5))
		end
		ctx:clear(599, 636, 26)
		local fl = ctx:gorge(s0, sB, floorAt, 10, 12, Enum.Material.Ground)
		local c = ctx:course("1b_ShepherdsStep", s0 - 2, nil, fl)
		local sStep = s0 + L * 0.5
		c:walk(sStep - 3 - c.s, floorAt(0.49))
		c:climb(8, 8, "frame", 6)
		c:walk(sB - 5 - c.s, floorAt(1))
		c:climb(ctx:at(sB + 4).Y - floorAt(1), 8, "frame", 8)
		c:finish(c.s + 3)
		ctx:sign(597, "Shepherd's Step")
	end

	-- 1c Lookout Rocks: stepping stones, a framed climb onto a high rock, hops back down
	do
		local sLip = S[880]
		local sEnd = sLip + 2.5 + 8 + 2.5 + 8 + 2.5 + 10 + 8 + 2.5 + 8 + 2.5 + 8 + 2.5
		local fl = ctx:gully(sLip, sEnd, 7, 14, 16)
		local c = ctx:course("1c_LookoutRocks", sLip, 7, fl)
		c:hop(8, 2.5, 0.5, "boulder", -1)
		c:hop(8, 2.5, 0.5, "boulder", 1)
		c:hop(10, 2.5, 0, "slab", 0)
		c:climb(8, 8, "frame", 8)
		c:hop(8, 2.5, -3, "boulder", 1.5)
		c:hop(8, 2.5, -3, "boulder", -1)
		c:finish(sEnd + 3, true)
		returnClimb(ctx, c, sLip, fl(sLip + 1), 9, 8)
		ctx:sign(874, "Lookout Rocks")
	end
end

return M

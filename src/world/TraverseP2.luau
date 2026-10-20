-- TraverseP2: push 2, Camp 1 -> Camp 2 (Whispering Forest). Verb: bounce / platform.
-- design/traversal-plan.md. Gaps <= 3 studs; bounce caps (CC_TraverseClient) launch on landing.
-- Falls land on a cut floor that leads back to the start (2a, 2c) or onto floor caps (2b).
local TK = require(script.Parent.TraverseKit)
local M = {}

function M.build(Kit, Gen)
	local ctx = TK.begin(Kit, Gen, "P2")

	-- 2a Falls-side Root Stair: beside the falls the trail sinks into a cut; ten stumps and stones
	-- climb back to it. The floor rises at a walkable grade but ends 8 studs below the trail.
	do
		local s0, s1 = 3612, 3720
		local y0, y1 = ctx:at(s0).Y, ctx:at(s1 + 3).Y
		local rise = y1 - y0
		ctx:clear(ctx:iAtS(s0) - 3, ctx:iAtS(s1) + 4, 26)
		local fl = ctx:gorge(s0, s1 + 3, function(t)
			return y0 + (rise - 8) * t
		end, 11, 12, Enum.Material.Ground)
		local c = ctx:course("2a_FallsRootStair", s0 - 1, 21, fl)
		for k = 1, 10 do
			c:hop(7, 3, y0 + rise * k / 10 - c.pos.Y, (k % 3 == 0) and "boulder" or "stump", (k % 2 == 0) and 2 or -2)
		end
		c:finish(s1 + 6)
		ctx:sign(ctx:iAtS(s0) - 6, "Falls-side Root Stair")
	end

	-- 2b Bounce-cap Grove: a 14-deep gully; caps on its floor launch you onto two fallen logs.
	-- A fall lands beside a cap, so a retry is one step away.
	do
		local sLip = 4905
		local sEnd = sLip + 2.5 + 8 + 2.5 + 16 + 3 + 8 + 2.5 + 16 + 3
		local fl = ctx:gully(sLip, sEnd, 14, 14, 14)
		local yT = ctx:at(sLip).Y
		local c = ctx:course("2b_BounceCapGrove", sLip, 22, fl)
		-- caps stand 3.5 above the floor (readable as mushrooms, one jump up from the floor); a 20-stud
		-- launch clears the 13.5-stud rise to the logs and carries ~8 studs forward
		c:bounce(8, 2.5, fl(c.s + 6.5) + 3.5 - c.pos.Y, 20, 0)
		c:log(16, yT + 3 - c.pos.Y, 2.5, 0)
		c:bounce(8, 3, fl(c.s + 7) + 3.5 - c.pos.Y, 20, 0)
		c:log(16, yT + 3 - c.pos.Y, 2.5, 0)
		c:finish(sEnd + 3, true)
		ctx:sign(ctx:iAtS(sLip) - 6, "Bounce-cap Grove")
	end

	-- 2c Rootway Hollow: the trail drops into a deepening root hollow. Stumps, a cap up onto a root
	-- shelf, stones, a root climb, then stumps back down to the far lip.
	do
		local s0 = 5500
		local L = 3 * 10 + 11 + 12 + 2 * 11 + 6 + 2 * 10 + 3
		local s1 = s0 + L
		local y0 = ctx:at(s0).Y
		ctx:clear(ctx:iAtS(s0) - 3, ctx:iAtS(s1) + 4, 32)
		-- the course ends 3 studs short of s1 - 1, where the far lip (kerb) sits. The cut reaches 24
		-- studs to the valley side: narrower, it left a trail-level rim that bypassed the course.
		local fl = ctx:gorge(s0, s1 - 1, function(t)
			return y0 - 12 * math.min(1, t * 3)
		end, 12, 24, Enum.Material.LeafyGrass)
		ctx:kerb(s1 - 1, -1, 12, 24)
		local c = ctx:course("2c_RootwayHollow", s0 - 1, 23, fl)
		for k = 1, 3 do
			c:hop(7, 3, 0.5, "stump", (k % 2 == 0) and 2 or -2)
		end
		-- 16-stud launch: ~7.8 studs of flight to a shelf 6 ahead and 10 up
		c:bounce(8, 3, -6, 16, 0)
		c:hop(10, 2, 10, "slab", 1)
		c:hop(8, 3, 0, "boulder", -1.5)
		c:hop(8, 3, -1, "boulder", 1.5)
		c:climb(8, 8, "roots", 6)
		c:hop(7, 3, -4, "stump", -1)
		c:hop(7, 3, -4, "stump", 1)
		c:finish(s1 + 2, true)
		ctx:sign(ctx:iAtS(s0) - 6, "Rootway Hollow")
	end
end

return M

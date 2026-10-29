-- ValleyDress: rule-based vegetation and rock dressing for Green Valley (Gate C slice).
-- Not a uniform random scatter: groves follow a low-frequency mask, flower fields have their own
-- mask, lone trees punctuate meadows, bushes hug grove edges and riverbanks, and a view corridor
-- keeps the Foothold -> summit sightline clear (master.md §3 "foreground frame -> objective -> landmark").
local D = {}

local noise = math.noise
local floor, sqrt, abs, atan2, clamp = math.floor, math.sqrt, math.abs, math.atan2, math.clamp
local readf32, readu8 = buffer.readf32, buffer.readu8

local N, CELL, HALF = 1200, 4, 2400

local function smooth(e0, e1, x)
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

-- area spec: theta range (radians, may wrap), re range
function D.dress(Kit, Gen, opts)
	local F = _G.CC_HF
	local H, W, FL, SW, RE = F.H, F.W, F.FL, F.SW, F.RE
	opts = opts or {}
	local th0, th1 = opts.theta0 or -0.45, opts.theta1 or 2.35
	local re0, re1 = opts.re0 or 1205, opts.re1 or 2080
	local stride = opts.stride or 10
	local rng = Random.new(opts.seed or 20261020)
	local world = Kit.folder(workspace, "World")
	local regions = Kit.folder(world, "Regions")
	local gv = Kit.folder(regions, opts.region or "GreenValley")
	local veg = Kit.folder(gv, "Vegetation")
	local fTrees, fFlowers, fBush = Kit.folder(veg, "Trees"), Kit.folder(veg, "Flowers"), Kit.folder(veg, "Bushes")
	local foot = _G.CC_PATHS.pads.Foothold
	local COL = Kit.COL
	local leafSet = { COL.meadow, COL.leafLight, COL.meadow, COL.forestTeal }
	local counts = { trees = 0, flowers = 0, bushes = 0, rocks = 0 }

	local function cellIdx(x, z)
		local i = clamp(floor((x + HALF) / CELL), 1, N - 2)
		local j = clamp(floor((z + HALF) / CELL), 1, N - 2)
		return j * N + i, i, j
	end
	local function slopeAt(i, j)
		local sx = (readf32(H, (j * N + i + 1) * 4) - readf32(H, (j * N + i - 1) * 4)) / (2 * CELL)
		local sz = (readf32(H, ((j + 1) * N + i) * 4) - readf32(H, ((j - 1) * N + i) * 4)) / (2 * CELL)
		return sqrt(sx * sx + sz * sz)
	end
	local function nearWater(i, j, rad)
		for dj = -rad, rad do
			for di = -rad, rad do
				local idx = (clamp(j + dj, 0, N - 1)) * N + clamp(i + di, 0, N - 1)
				if readu8(FL, idx) ~= 0 then
					return true
				end
			end
		end
		return false
	end
	local function inView(x, z)
		-- corridor from the Foothold plaza toward the summit (and the falls, to the north-east)
		local dx, dz = x - foot.x, z - foot.z
		local d = sqrt(dx * dx + dz * dz)
		if d < 60 or d > 900 then
			return false
		end
		local a = atan2(dx, dz) -- 0 = +Z; summit direction from Foothold is -Z (a = pi)
		local toSummit = abs(((a - math.pi) + math.pi) % (2 * math.pi) - math.pi)
		return toSummit < 0.16
	end

	-- authored clearings (landmarks and their sightlines stay open): opts.clear = { {x, z, r}, ... }
	local clearZones = opts.clear or {}
	local function inClearing(x, z)
		for _, c in ipairs(clearZones) do
			local dx, dz = x - c[1], z - c[2]
			if dx * dx + dz * dz < c[3] * c[3] then
				return true
			end
		end
		return false
	end

	local half = stride / 2
	for z = -HALF + half, HALF - half, stride do
		for x = -HALF + half, HALF - half, stride do
			local jx, jz = x + rng:NextNumber(-half, half), z + rng:NextNumber(-half, half)
			local r = sqrt(jx * jx + jz * jz)
			local th = atan2(jx, jz)
			local inArc = (th0 <= th1) and (th >= th0 and th <= th1) or (th >= th0 or th <= th1)
			if inArc then
				local idx, i, j = cellIdx(jx, jz)
				local re = readf32(RE, idx * 4)
				local fdx, fdz = jx - foot.x, jz - foot.z
				local inFoot = (fdx * fdx + fdz * fdz) < (foot.radius + 30) ^ 2
				if re >= re0 and re <= re1 and not inFoot and readf32(SW, idx * 4) < 0.01 and readu8(FL, idx) == 0 then
					local h = readf32(H, idx * 4)
					local wl = readf32(W, idx * 4)
					local slope = slopeAt(i, j)
					if wl < h - 0.5 then
						local grove = noise(jx / 260 + 0.11, jz / 260 + 0.37, 3.1)
						local field = noise(jx / 170 + 0.71, jz / 170 + 0.23, 5.7)
						local edge = smooth(1340, 1260, re) -- forest-edge band below the forest shelf
						local wet = nearWater(i, j, 4)
						local roll = rng:NextNumber()
						local y = Gen.heightAt(jx, jz)
						local placed = false
						-- trees
						local pTree = 0.008 + 0.15 * smooth(0.1, 0.3, grove) + 0.08 * edge
						if slope < 0.65 and not inView(jx, jz) and not inClearing(jx, jz) and roll < pTree then
							local kind
							local k = rng:NextNumber()
							if edge > 0.5 then
								kind = (k < 0.5) and "Pine" or ((k < 0.75) and "TreeTall" or "TreeRound")
							else
								kind = (k < 0.55) and "TreeRound" or ((k < 0.88) and "TreeTall" or "Pine")
							end
							local leaf = (kind == "Pine") and COL.forestTeal or leafSet[rng:NextInteger(1, #leafSet)]
							-- trees are scaled to the landscape (valley spans ~700 studs, summit 2000): 30-60 studs tall
							local s = rng:NextNumber(1.5, 2.6)
							Kit.place(fTrees, kind, Vector3.new(jx, y - 0.4 - slope * 1.5, jz), rng:NextNumber(0, 6.28), s, leaf)
							counts.trees += 1
							placed = true
						end
						-- flower fields
						if not placed and slope < 0.45 then
							local pF = (field > 0.26) and 0.55 or 0.01
							if roll < pF then
								local f = noise(jx / 60 + 0.5, jz / 60 + 0.2, 9.1)
								local kind = (f > 0.12) and "FlowersGold" or ((f < -0.12) and "FlowersMoon" or "FlowersTurq")
								Kit.place(fFlowers, kind, Vector3.new(jx, y - 0.2, jz), rng:NextNumber(0, 6.28), rng:NextNumber(1.3, 1.8))
								counts.flowers += 1
								placed = true
							end
						end
						-- bushes: grove edges and riverbanks
						if not placed and slope < 0.8 then
							local pB = 0.07 * smooth(0.0, 0.12, grove) * (1 - smooth(0.2, 0.35, grove)) + (wet and 0.2 or 0)
							if roll < pB then
								local leaf = (rng:NextNumber() < 0.5) and COL.leafLight or COL.meadow
								Kit.place(fBush, "Bush", Vector3.new(jx, y - 0.8, jz), rng:NextNumber(0, 6.28), rng:NextNumber(1.4, 2.4), leaf)
								counts.bushes += 1
								placed = true
							end
						end
						-- rock outcrops (terrain, so they blend into the ground)
						if not placed and opts.rocks ~= false and rng:NextNumber() < 0.004 + 0.02 * smooth(0.5, 1.1, slope) then
							local rad = rng:NextNumber(2.5, 6.5)
							workspace.Terrain:FillBall(Vector3.new(jx, y - rad * 0.35, jz), rad, Enum.Material.Rock)
							counts.rocks += 1
						end
					end
				end
			end
		end
		if floor(z) % 200 < stride then
			task.wait()
		end
	end
	return counts
end

return D

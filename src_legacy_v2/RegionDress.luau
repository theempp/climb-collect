-- RegionDress: generic rule-based dressing for one elevation band (Gate D regions).
-- spec = {
--   region = "WhisperingForest", re0 = 945, re1 = 1215, theta0/theta1 (optional arc), stride, seed,
--   grove = { scale = 220, lo = -0.05, hi = 0.25 },          -- low-frequency density mask
--   items = { { proto, base, groveBoost, slopeMax, scale = {a, b}, colors = {...}, sink }, ... },
--   rocks = { material, prob, rmin, rmax, slopeBoost },
--   clear = { {x, z, r}, ... },
-- }
-- Items are tried in order; the first that passes its roll is placed (one object per sample).
local D = {}

local noise = math.noise
local floor, sqrt, atan2, clamp = math.floor, math.sqrt, math.atan2, math.clamp
local readf32, readu8 = buffer.readf32, buffer.readu8
local N, CELL, HALF = 1200, 4, 2400

local function smooth(e0, e1, x)
	local t = clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end

function D.dress(Kit, Gen, spec)
	local F = _G.CC_HF
	local H, W, FL, SW, RE = F.H, F.W, F.FL, F.SW, F.RE
	local rng = Random.new(spec.seed or 7)
	local stride = spec.stride or 10
	local half = stride / 2
	local world = Kit.folder(workspace, "World")
	local reg = Kit.folder(Kit.folder(world, "Regions"), spec.region)
	local old = reg:FindFirstChild("Vegetation")
	if old then
		old:Destroy()
	end
	local veg = Kit.folder(reg, "Vegetation")
	local G = spec.grove or { scale = 220, lo = -0.05, hi = 0.25 }
	local clear = spec.clear or {}
	local counts = { rocks = 0 }
	local r0sq, r1sq = (spec.re0 - 80) ^ 2, (spec.re1 + 80) ^ 2

	local function inClear(x, z)
		for _, c in ipairs(clear) do
			local dx, dz = x - c[1], z - c[2]
			if dx * dx + dz * dz < c[3] * c[3] then
				return true
			end
		end
		return false
	end

	for z = -HALF + half, HALF - half, stride do
		for x = -HALF + half, HALF - half, stride do
			local jx, jz = x + rng:NextNumber(-half, half), z + rng:NextNumber(-half, half)
			local r2 = jx * jx + jz * jz
			if r2 >= r0sq and r2 <= r1sq then
				local ok = true
				if spec.theta0 then
					local th = atan2(jx, jz)
					local t0, t1 = spec.theta0, spec.theta1
					ok = (t0 <= t1) and (th >= t0 and th <= t1) or (th >= t0 or th <= t1)
				end
				local i = clamp(floor((jx + HALF) / CELL), 1, N - 2)
				local j = clamp(floor((jz + HALF) / CELL), 1, N - 2)
				local idx = j * N + i
				local re = readf32(RE, idx * 4)
				if ok and re >= spec.re0 and re <= spec.re1 and readf32(SW, idx * 4) < 0.01 and readu8(FL, idx) == 0 then
					local h = readf32(H, idx * 4)
					if readf32(W, idx * 4) < h - 0.5 and not inClear(jx, jz) then
						local sx = (readf32(H, (j * N + i + 1) * 4) - readf32(H, (j * N + i - 1) * 4)) / (2 * CELL)
						local sz = (readf32(H, ((j + 1) * N + i) * 4) - readf32(H, ((j - 1) * N + i) * 4)) / (2 * CELL)
						local slope = sqrt(sx * sx + sz * sz)
						local grove = smooth(G.lo, G.hi, noise(jx / G.scale + 0.33, jz / G.scale + 0.71, (spec.seed or 7) * 0.13))
						local roll = rng:NextNumber()
						local acc = 0
						local placed = false
						for _, it in ipairs(spec.items) do
							if slope <= (it.slopeMax or 0.8) then
								acc += (it.base or 0) + (it.groveBoost or 0) * grove
								if roll < acc then
									local s = rng:NextNumber(it.scale[1], it.scale[2])
									local col = it.colors and it.colors[rng:NextInteger(1, #it.colors)] or nil
									local y = Gen.heightAt(jx, jz) - (it.sink or 0.5) - slope * 1.2
									Kit.place(veg, it.proto, Vector3.new(jx, y, jz), rng:NextNumber(0, 6.28), s, col)
									counts[it.proto] = (counts[it.proto] or 0) + 1
									placed = true
									break
								end
							end
						end
						local R = spec.rocks
						if not placed and R and rng:NextNumber() < R.prob + (R.slopeBoost or 0) * smooth(0.5, 1.2, slope) then
							local rad = rng:NextNumber(R.rmin, R.rmax)
							workspace.Terrain:FillBall(Vector3.new(jx, Gen.heightAt(jx, jz) - rad * 0.35, jz), rad, R.material)
							counts.rocks += 1
						end
					end
				end
			end
		end
		if floor(z) % 240 < stride then
			task.wait()
		end
	end
	return counts
end

return D

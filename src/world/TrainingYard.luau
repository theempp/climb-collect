-- TrainingYard (v4 P4, run 2): the stamina-training annex OUTSIDE the frozen Foothold (concept LOCKED #10).
-- Placement PROPOSED: the flattest spot 380-470 studs from the Foothold centre that is >= 60 studs from every route
-- path (searched, deterministic). A small practice crag: start arch -> three marked practice walls (10 / 16 / 22)
-- with decks between them -> a bell on the top deck -> stairs back down. Parts only (~60). Colors = Kit.COL tokens.
-- Server logic: CC_CoreServer.Training (StartGate / Bell touches, capped gains).
--   require(ServerStorage.CC_Generators:Clone().BuildAll).trainingYard()     (after the terrain + routes)
local TY = {}

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

function TY.site(Gen, C)
	local center = Vector3.new(0, 0, 2160) -- CoreConfig FOOTHOLD_SAFE.center (xz)
	local paths = _G.CC_PATHS and _G.CC_PATHS.routes or {}
	local function nearRoute(p)
		for _, R in pairs(paths) do
			for i = 1, #R.pts, 4 do
				local q = R.pts[i]
				local dx, dz = q[1] - p.X, q[2] - p.Z
				if dx * dx + dz * dz < 60 * 60 then
					return true
				end
			end
		end
		return false
	end
	local best, bestScore
	for deg = 0, 355, 5 do
		local a = math.rad(deg)
		for _, r in ipairs({ 380, 420, 470 }) do
			local p = center + Vector3.new(math.sin(a), 0, math.cos(a)) * r
			if not nearRoute(p) then
				local lo, hi = math.huge, -math.huge
				for dx = -24, 24, 8 do
					for dz = -24, 24, 8 do
						local h = Gen.heightAt(p.X + dx, p.Z + dz)
						lo, hi = math.min(lo, h), math.max(hi, h)
					end
				end
				local score = hi - lo
				if not bestScore or score < bestScore then
					best, bestScore = p, score
				end
			end
		end
	end
	return best, bestScore
end

function TY.build(Kit, Gen)
	local COL = Kit.COL
	local world = workspace:WaitForChild("World")
	local old = world:FindFirstChild("TrainingYard")
	if old then
		old:Destroy()
	end
	local root = Kit.folder(world, "TrainingYard")
	local site, rough = TY.site(Gen)
	assert(site, "no site")
	local y0 = Gen.heightAt(site.X, site.Z)
	-- face the Foothold: the walls stand on the far side, climbers face away from the base
	local toBase = flat(Vector3.new(0, 0, 2160) - site).Unit
	local base = Vector3.new(site.X, y0, site.Z)
	local cf = CFrame.lookAt(base, base - toBase) -- LookVector points away from the Foothold (into the walls)
	-- pad: level terrain (camp-pad material) so the yard sits flat
	workspace.Terrain:FillBlock(cf * CFrame.new(0, -3, -8), Vector3.new(56, 6, 64), Enum.Material.Cobblestone)
	workspace.Terrain:FillBlock(cf * CFrame.new(0, 12, -8), Vector3.new(56, 24, 64), Enum.Material.Air)
	local floorY = y0 + 2 -- rendered pad surface (fills render ~2 proud)
	local function at(x, y, z)
		return cf * CFrame.new(x, floorY - y0 + y, z)
	end
	local n = 0
	local function P(props)
		n += 1
		return Kit.part(root, props)
	end
	-- three stepped blocks (marked, climbable): block k's front at z_k = -6 - 8(k-1), 8 deep, rising to the running
	-- total height; the exposed band of each front is one practice wall (10 / 16 / 22), its top the deck for the next
	local walls = { 10, 16, 22 }
	local top = 0
	for k, h in ipairs(walls) do
		local z = -6 - (k - 1) * 8
		top += h
		local w = P({ Name = "PracticeWall", Size = Vector3.new(14, top, 8), CFrame = at(0, top / 2, z - 4), Material = Enum.Material.Slate, Color = COL.rock })
		w:SetAttribute("Climbable", true)
		-- rope + pitons on the exposed band: the marked-face cue used on the routes
		local y0b = top - h
		P({ Name = "Rope", Size = Vector3.new(0.3, h, 0.3), CFrame = at(-4, y0b + h / 2, z + 0.25), Material = Enum.Material.Fabric, Color = COL.lantern, CanCollide = false })
		for y = 3, h - 1, 6 do
			P({ Name = "Piton", Size = Vector3.new(0.4, 0.4, 1), CFrame = at(-4, y0b + y, z + 0.3), Material = Enum.Material.Metal, Color = COL.slate, CanCollide = false })
		end
	end
	-- the bell on the top deck (block 3's top: z -22 .. -30)
	local deckZ = -26
	P({ Name = "BellPost", Size = Vector3.new(0.6, 7, 0.6), CFrame = at(4, top + 3.5, deckZ - 2), Material = Enum.Material.Wood, Color = COL.timberDark })
	local bell = P({ Name = "BellVisual", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = at(4, top + 6, deckZ - 0.6), Material = Enum.Material.Metal, Color = COL.golden })
	bell.CanCollide = false
	-- the touch volume the server listens to: the whole top deck (a lap ends on arrival)
	P({ Name = "Bell", Size = Vector3.new(14, 6, 8), CFrame = at(0, top + 3, deckZ), Transparency = 1, CanCollide = false })
	-- stairs back down beside the blocks (no climbing needed to leave): 1.2 down per 1.6 out, toward the base
	local steps = math.ceil(top / 1.2)
	for i = 1, steps do
		P({ Name = "Step", Size = Vector3.new(5, 1.2, 2.2), CFrame = at(9.5, top - i * 1.2 + 0.6, deckZ + i * 1.6), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	end
	P({ Name = "Landing", Size = Vector3.new(5, 1, 6), CFrame = at(9.5, top - 0.5, deckZ - 1), Material = Enum.Material.WoodPlanks, Color = COL.timber })
	-- start arch at the foot of wall 1 (walk through it to start a lap)
	for _, sx in ipairs({ -8, 8 }) do
		P({ Name = "ArchPost", Size = Vector3.new(1, 9, 1), CFrame = at(sx, 4.5, 6), Material = Enum.Material.Wood, Color = COL.timberDark })
	end
	P({ Name = "ArchBeam", Size = Vector3.new(17, 1, 1), CFrame = at(0, 9.5, 6), Material = Enum.Material.Wood, Color = COL.timberDark })
	P({ Name = "StartGate", Size = Vector3.new(15, 8, 2), CFrame = at(0, 4, 6), Transparency = 1, CanCollide = false })
	Kit.sign(root, at(-12, 0, 10), { { "Training Yard", 0 }, { "Climb all 3, ring the bell", 0 } }, 9)
	-- the path to the yard is the open foothill (no trail stamp needed: the site is the flattest nearby ground)
	root:SetAttribute("Rough", rough)
	return string.format("Training Yard at (%.0f, %.0f, %.0f), %.0f studs from the Foothold centre, ground range %.1f, %d parts, top %d", site.X, floorY, site.Z, flat(site - Vector3.new(0, 0, 2160)).Magnitude, rough, n, top)
end

return TY

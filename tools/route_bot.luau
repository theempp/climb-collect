-- Route walkability bot (dev tool, not part of the place). Paste into execute_luau on the CLIENT during a
-- playtest after setting ROUTES/SPEED. Walks each route's samples from ReplicatedStorage.CC_Route.<name>
-- (then the shared SummitStair) with Humanoid:MoveTo, in a background thread. Poll _G.CC_RBOT.
-- SPEED > 12 is a walkability check only (same 45 deg slope limit); times are then scaled to 12 studs/s
-- and labeled as BOT ESTIMATES. A target not reached in its timeout is logged STUCK and skipped by teleport;
-- dropping > 10 studs below the trail is logged FELL and reset to the last reached sample.
local ROUTES = _G.CC_RBOT_ROUTES or { "Shepherd", "Waterfall", "Ledge", "Spire" } -- set _G.CC_RBOT_ROUTES first to pick
local SPEED = _G.CC_RBOT_SPEED or 36
local STRIDE = 4 -- samples (x3 studs)

local plr = game.Players.LocalPlayer
local ch = plr.Character or plr.CharacterAdded:Wait()
local hum, hrp = ch:WaitForChild("Humanoid"), ch:WaitForChild("HumanoidRootPart")
local R = game.ReplicatedStorage:WaitForChild("CC_Route")

local function feet()
	return hrp.Position.Y - hum.HipHeight - hrp.Size.Y / 2
end
local function parse(name)
	local out = {}
	for tok in string.gmatch(R[name].Value, "[^;]+") do
		local x, y, z, s = tok:match("([^,]+),([^,]+),([^,]+),([^,]+)")
		out[#out + 1] = { p = Vector3.new(tonumber(x), tonumber(y), tonumber(z)), s = tonumber(s) }
	end
	return out
end

local B = { status = "running", results = {}, log = {} }
_G.CC_RBOT = B

local function walk(name, pts)
	local res = { route = name, stuck = 0, fell = 0, t = 0, len = pts[#pts].s }
	hrp.Anchored = false
	hrp.CFrame = CFrame.new(pts[1].p + Vector3.new(0, 4, 0))
	hrp.AssemblyLinearVelocity = Vector3.zero
	task.wait(3)
	hum.WalkSpeed = SPEED
	local T0 = os.clock()
	local last = pts[1]
	local k = 1 + STRIDE
	while k <= #pts do
		local tg = pts[k]
		B.where = string.format("%s s=%.0f", name, tg.s)
		local d0 = (Vector3.new(tg.p.X, 0, tg.p.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
		local timeout = d0 / SPEED * 2.5 + 1.5
		local t0 = os.clock()
		local ok, jumped, falls = false, false, 0
		while os.clock() - t0 < timeout and falls < 3 do -- 3 falls at one target = STUCK (no endless loop)
			hum:MoveTo(tg.p)
			local d = (Vector3.new(tg.p.X, 0, tg.p.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
			if d < 3 then
				ok = true
				break
			end
			if feet() < tg.p.Y - 10 and feet() < last.p.Y - 10 then
				res.fell += 1
				falls += 1
				B.log[#B.log + 1] = string.format("FELL %s s~%.0f (%.0f,%.0f,%.0f)", name, tg.s, hrp.Position.X, feet(), hrp.Position.Z)
				hrp.CFrame = CFrame.new(last.p + Vector3.new(0, 4, 0))
				hrp.AssemblyLinearVelocity = Vector3.zero
				task.wait(0.5)
				t0 = os.clock()
			end
			if not jumped and os.clock() - t0 > timeout * 0.6 then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				jumped = true
			end
			task.wait()
		end
		if not ok then
			res.stuck += 1
			B.log[#B.log + 1] = string.format("STUCK %s s~%.0f (%.0f,%.0f,%.0f) target y %.0f", name, tg.s, hrp.Position.X, feet(), hrp.Position.Z, tg.p.Y)
			hrp.CFrame = CFrame.new(tg.p + Vector3.new(0, 4, 0))
			hrp.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.3)
		end
		last = tg
		if k == #pts then
			break
		end
		k = math.min(#pts, k + STRIDE)
	end
	res.t = os.clock() - T0
	res.estAt12 = res.t * SPEED / 12
	return res
end

task.spawn(function()
	local stair = parse("SummitStair")
	for _, name in ipairs(ROUTES) do
		local r = walk(name, parse(name))
		local s2 = walk("SummitStair", stair)
		r.stairStuck, r.stairT = s2.stuck, s2.t
		B.results[#B.results + 1] = r
	end
	hum.WalkSpeed = 12
	B.status = "done"
end)
return "started"

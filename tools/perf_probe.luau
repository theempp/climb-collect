-- perf_probe (Studio dev tool, Client): samples frame cost at a spot. Paste into execute_luau on the Client
-- during a playtest, then call _G.CC_PERF.run({ name, pos, secs, orbit }) and poll _G.CC_PERF.out[name].
-- Measures (labels: Studio desktop playtest, NOT a phone): per-frame dt, Stats.RenderCPUFrameTime/GPUFrameTime,
-- draw calls, triangles, streamed World instances, client InstanceCount. orbit = Scriptable camera circling the
-- character at avatar scale (worst case for culling/streaming); otherwise the default follow camera.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Stats = game:GetService("Stats")
local P = Players.LocalPlayer

local M = _G.CC_PERF or { out = {} }
_G.CC_PERF = M

local function pct(t, q)
	if #t == 0 then
		return 0
	end
	local s = table.clone(t)
	table.sort(s)
	return s[math.clamp(math.ceil(#s * q), 1, #s)]
end

local function sample(secs)
	local dts, cpu, gpu, dc, tri = {}, {}, {}, {}, {}
	local t0 = os.clock()
	local conn = Run.RenderStepped:Connect(function(dt)
		table.insert(dts, dt * 1000)
		table.insert(cpu, Stats.RenderCPUFrameTime * 1000)
		table.insert(gpu, Stats.RenderGPUFrameTime * 1000)
		table.insert(dc, Stats.SceneDrawcallCount)
		table.insert(tri, Stats.SceneTriangleCount)
	end)
	while os.clock() - t0 < secs do
		task.wait(0.1)
	end
	conn:Disconnect()
	local n, sum, over33, over50 = #dts, 0, 0, 0
	for _, v in ipairs(dts) do
		sum += v
		if v > 33.4 then
			over33 += 1
		end
		if v > 50 then
			over50 += 1
		end
	end
	return {
		frames = n,
		fps = n / secs,
		avgMs = sum / math.max(1, n),
		p95Ms = pct(dts, 0.95),
		worstMs = pct(dts, 1),
		over33 = over33,
		over50 = over50,
		cpuAvg = pct(cpu, 0.5),
		cpuP95 = pct(cpu, 0.95),
		gpuAvg = pct(gpu, 0.5),
		gpuP95 = pct(gpu, 0.95),
		drawcalls = pct(dc, 0.5),
		drawMax = pct(dc, 1),
		tris = pct(tri, 0.5),
		triMax = pct(tri, 1),
	}
end

M.sample = sample

function M.run(o)
	M.out[o.name] = { status = "running" }
	task.spawn(function()
		local ok, err = pcall(function()
			local ch = P.Character or P.CharacterAdded:Wait()
			local hrp = ch:WaitForChild("HumanoidRootPart")
			if o.pos then
				pcall(function()
					P:RequestStreamAroundAsync(o.pos, 10)
				end)
				hrp.CFrame = CFrame.new(o.pos + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.rad(o.yaw or 0), 0)
				hrp.AssemblyLinearVelocity = Vector3.zero
				task.wait(o.settle or 4)
			end
			local cam = workspace.CurrentCamera
			local res = { static = sample(o.secs or 10) }
			if o.orbit then
				cam.CameraType = Enum.CameraType.Scriptable
				local c0 = os.clock()
				local spin = Run.RenderStepped:Connect(function()
					local a = (os.clock() - c0) / (o.secs or 10) * math.pi * 2
					local p = hrp.Position
					cam.CFrame = CFrame.lookAt(p + Vector3.new(math.cos(a) * 16, 6, math.sin(a) * 16), p + Vector3.new(0, 2, 0))
				end)
				res.orbit = sample(o.secs or 10)
				spin:Disconnect()
				cam.CameraType = Enum.CameraType.Custom
			end
			local w = workspace:FindFirstChild("World")
			res.worldStreamed = w and #w:GetDescendants() or 0
			res.clientInstances = Stats.InstanceCount
			res.memMb = Stats:GetTotalMemoryUsageMb()
			res.pos = tostring(hrp.Position)
			res.status = "done"
			M.out[o.name] = res
		end)
		if not ok then
			M.out[o.name] = { status = "error", err = tostring(err) }
		end
	end)
	return "started " .. o.name
end

return M

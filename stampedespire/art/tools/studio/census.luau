-- Command-bar job (Edit mode, read-only): instance counts per top-level child of the services a client downloads.
return function()
	local out = {}
	local function count(root)
		return #root:GetDescendants()
	end
	for _, svc in { "ReplicatedStorage", "ReplicatedFirst", "StarterPlayer", "StarterGui", "Lighting", "SoundService", "Workspace" } do
		local s = game:GetService(svc)
		local rows = {}
		for _, ch in s:GetChildren() do
			table.insert(rows, { ch.Name .. ":" .. ch.ClassName, count(ch) })
		end
		table.sort(rows, function(a, b)
			return a[2] > b[2]
		end)
		local parts = {}
		for i = 1, math.min(#rows, 8) do
			table.insert(parts, rows[i][1] .. "=" .. rows[i][2])
		end
		table.insert(out, svc .. " total=" .. count(s) .. " | " .. table.concat(parts, ", "))
	end
	local clips = game.ReplicatedStorage:FindFirstChild("SS_Creatures") and game.ReplicatedStorage.SS_Creatures:FindFirstChild("Clips")
	if clips then
		local per = {}
		for _, m in clips:GetChildren() do
			for _, k in m:GetChildren() do
				table.insert(per, m.Name .. "/" .. k.Name .. "=" .. count(k))
			end
		end
		table.insert(out, "CLIPS " .. table.concat(per, ", "))
	end
	table.insert(out, "ServerStorage total=" .. count(game:GetService("ServerStorage")))
	table.insert(out, "StreamingEnabled=" .. tostring(workspace.StreamingEnabled))
	return "CENSUS\n" .. table.concat(out, "\n")
end

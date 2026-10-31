-- Command-bar job (Edit mode): pulls prototype/src into the place so src/ and Studio stay identical.
return function()
	local H = game:GetService("HttpService")
	local RepS = game:GetService("ReplicatedStorage")
	local SSS = game:GetService("ServerScriptService")
	local SPS = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local RF = game:GetService("ReplicatedFirst")
	local map = {
		{ "SS_Config.luau", RepS, "SS_Config", "ModuleScript" },
		{ "SS_Path.luau", RepS, "SS_Path", "ModuleScript" },
		{ "SS_Markers.luau", RepS, "SS_Markers", "ModuleScript" },
		{ "SS_Timeline.luau", RepS, "SS_Timeline", "ModuleScript" },
		{ "SS_Track.server.luau", SSS, "SS_Track", "Script" },
		{ "SS_Ride.client.luau", SPS, "SS_Ride", "LocalScript" },
		{ "SS_Env.client.luau", SPS, "SS_Env", "LocalScript" },
		{ "SS_Loading.client.luau", RF, "SS_Loading", "LocalScript" },
		{ "SS_Bot.luau", RepS, "SS_Bot", "ModuleScript" },
		{ "SS_Shop.luau", RepS, "SS_Shop", "ModuleScript" },
		{ "SS_Journal.luau", RepS, "SS_Journal", "ModuleScript" },
		{ "SS_Perf.luau", RepS, "SS_Perf", "ModuleScript" },
		{ "SS_Progress.luau", SSS, "SS_Progress", "ModuleScript" },
		{ "SS_Save.server.luau", SSS, "SS_Save", "Script" },
		{ "SS_Stream.server.luau", SSS, "SS_Stream", "Script" },
	}
	local out = {}
	for _, e in map do
		local src = H:GetAsync("http://127.0.0.1:8798/src/" .. e[1] .. "?" .. os.clock())
		local s = e[2]:FindFirstChild(e[3])
		if not s then
			s = Instance.new(e[4])
			s.Name = e[3]
			s.Parent = e[2]
		end
		s.Source = src
		table.insert(out, string.format("%s=%d", e[3], #src))
	end
	return "SYNC " .. table.concat(out, " ")
end

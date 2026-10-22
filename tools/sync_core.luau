-- Core sync (dev tool, edit mode). Serve src/ first:  python -m http.server 8771 --bind 127.0.0.1  (in the project root)
-- Lives in Studio as ServerStorage.CC_DevTools.Sync (dev only). Use in execute_luau (Edit):
--   return require(game.ServerStorage.CC_DevTools.Sync:Clone())({ "src/core/shared/CoreConfig.luau", ... })  (nil = all)
-- Creates/updates each instance from the manifest, turns HttpEnabled back off in the same call, and returns the
-- checksum of every synced source (same method as CLAUDE.md: CRLF->LF, lines right-trimmed, h=(h*31+b)%(2^31-1)).
local HS = game:GetService("HttpService")
local BASE = "http://127.0.0.1:8771/"
local only = nil
local MAN = {
 { "src/core/shared/LobbyApproaches.luau", "ReplicatedStorage/CC_Core", "LobbyApproaches", "ModuleScript" },
 { "src/core/shared/EarnedArt.luau", "ReplicatedStorage/CC_Core", "EarnedArt", "ModuleScript" },
 { "src/world/ExpeditionPolish.luau", "ServerStorage/CC_Generators", "ExpeditionPolish", "ModuleScript" },
 { "src/core/shared/EarnedCosmetics.luau", "ReplicatedStorage/CC_Core", "EarnedCosmetics", "ModuleScript" },
	{ "src/core/shared/SummitConfig.luau", "ReplicatedStorage/CC_Core", "SummitConfig", "ModuleScript" },
	{ "src/core/shared/ExpeditionRunRules.luau", "ReplicatedStorage/CC_Core", "ExpeditionRunRules", "ModuleScript" },
	{ "src/core/shared/SummitArt.luau", "ReplicatedStorage/CC_Core", "SummitArt", "ModuleScript" },
	{ "src/core/server/ExpeditionRun.luau", "ServerScriptService/CC_CoreServer", "ExpeditionRun", "ModuleScript" },
	{ "src/core/server/SummitFinish.luau", "ServerScriptService/CC_CoreServer", "SummitFinish", "ModuleScript" },
	{ "src/core/server/SummitTests.luau", "ServerScriptService/CC_CoreServer", "SummitTests", "ModuleScript" },
	{ "src/core/client/SummitCinematic.luau", "ReplicatedStorage/CC_Core/Client", "SummitCinematic", "ModuleScript" },
	{ "src/core/client/ResultsUI.luau", "ReplicatedStorage/CC_Core/Client", "ResultsUI", "ModuleScript" },
	{ "src/world/SummitStage.luau", "ServerStorage/CC_Generators", "SummitStage", "ModuleScript" },
	{ "src/core/shared/DailyPracticeRules.luau", "ReplicatedStorage/CC_Core", "DailyPracticeRules", "ModuleScript" },
	{ "src/core/server/DailyPractice.luau", "ServerScriptService/CC_CoreServer", "DailyPractice", "ModuleScript" },
	{ "src/core/server/DailyPracticeTests.luau", "ServerScriptService/CC_CoreServer", "DailyPracticeTests", "ModuleScript" },
	{ "src/core/client/DailyPracticeUI.luau", "ReplicatedStorage/CC_Core/Client", "DailyPracticeUI", "ModuleScript" },
	{ "src/world/StarterSetPreview.luau", "ServerStorage/CC_Generators", "StarterSetPreview", "ModuleScript" },

	{ "src/core/shared/PortfolioRules.luau", "ReplicatedStorage/CC_Core", "PortfolioRules", "ModuleScript" },
	{ "src/core/shared/AchievementRules.luau", "ReplicatedStorage/CC_Core", "AchievementRules", "ModuleScript" },
	{ "src/core/shared/ExpeditionUITheme.luau", "ReplicatedStorage/CC_Core", "ExpeditionUITheme", "ModuleScript" },
	{ "src/core/server/PublicProfile.luau", "ServerScriptService/CC_CoreServer", "PublicProfile", "ModuleScript" },
	{ "src/core/server/PortfolioTests.luau", "ServerScriptService/CC_CoreServer", "PortfolioTests", "ModuleScript" },
	{ "src/core/client/ProfileUI.luau", "ReplicatedStorage/CC_Core/Client", "ProfileUI", "ModuleScript" },
	{ "src/core/client/NameTags.luau", "ReplicatedStorage/CC_Core/Client", "NameTags", "ModuleScript" },
	{ "src/core/client/ExpeditionHUD.luau", "ReplicatedStorage/CC_Core/Client", "ExpeditionHUD", "ModuleScript" },

	{ "tools/lobby_checks.luau", "ServerStorage/CC_DevTools", "LobbyChecks", "ModuleScript" },
	{ "src/core/server/LobbyAnchors.luau", "ServerScriptService/CC_CoreServer", "LobbyAnchors", "ModuleScript" },
	{ "src/world/FairgroundLobby.luau", "ServerStorage/CC_Generators", "FairgroundLobby", "ModuleScript" },
	{ "tools/commerce_checks.luau", "ServerStorage/CC_DevTools", "CommerceChecks", "ModuleScript" },
	{ "src/core/client/CommercePrices.luau", "ReplicatedStorage/CC_Core/Client", "CommercePrices", "ModuleScript" },
	{ "src/core/shared/CommerceArt.luau", "ReplicatedStorage/CC_Core", "CommerceArt", "ModuleScript" },
	{ "src/core/client/CommerceUI.luau", "ReplicatedStorage/CC_Core/Client", "CommerceUI", "ModuleScript" },
	{ "src/core/server/CommerceDisplays.luau", "ServerScriptService/CC_CoreServer", "CommerceDisplays", "ModuleScript" },
	{ "src/core/server/CommerceCosmetics.luau", "ServerScriptService/CC_CoreServer", "CommerceCosmetics", "ModuleScript" },
	{ "src/core/server/Commerce.luau", "ServerScriptService/CC_CoreServer", "Commerce", "ModuleScript" },
	{ "src/core/shared/CommerceConfig.luau", "ReplicatedStorage/CC_Core", "CommerceConfig", "ModuleScript" },
	{ "src/core/server/CommerceRules.luau", "ServerScriptService/CC_CoreServer", "CommerceRules", "ModuleScript" },
	{ "src/core/server/CommerceTests.luau", "ServerScriptService/CC_CoreServer", "CommerceTests", "ModuleScript" },
	{ "src/core/shared/HomeConfig.luau", "ReplicatedStorage/CC_Core", "HomeConfig", "ModuleScript" },
	{ "src/core/shared/TraversalConfig.luau", "ReplicatedStorage/CC_Core", "TraversalConfig", "ModuleScript" },
	{ "src/core/shared/TraversalRules.luau", "ReplicatedStorage/CC_Core", "TraversalRules", "ModuleScript" },
	{ "src/core/server/Cargo.luau", "ServerScriptService/CC_CoreServer", "Cargo", "ModuleScript" },
	{ "src/core/server/Home.luau", "ServerScriptService/CC_CoreServer", "Home", "ModuleScript" },
	{ "src/core/server/Traversal.luau", "ServerScriptService/CC_CoreServer", "Traversal", "ModuleScript" },
	{ "src/core/server/Discovery.luau", "ServerScriptService/CC_CoreServer", "Discovery", "ModuleScript" },
	{ "src/core/server/ExpeditionTests.luau", "ServerScriptService/CC_CoreServer", "ExpeditionTests", "ModuleScript" },
	{ "src/core/server/TraversalTests.luau", "ServerScriptService/CC_CoreServer", "TraversalTests", "ModuleScript" },
	{ "tools/author_traversal.luau", "ServerStorage/CC_DevTools", "AuthorTraversal", "ModuleScript" },
	{ "tools/traversal_smoke.luau", "ServerStorage/CC_DevTools", "TraversalSmoke", "ModuleScript" },
	{ "tools/traversal_route_smoke.luau", "ServerStorage/CC_DevTools", "TraversalRouteSmoke", "ModuleScript" },
	{ "tools/traversal_gate_probe.luau", "ServerStorage/CC_DevTools", "TraversalGateProbe", "ModuleScript" },
	{ "src/core/shared/CoreConfig.luau", "ReplicatedStorage/CC_Core", "CoreConfig", "ModuleScript" },
	{ "src/core/shared/Species.luau", "ReplicatedStorage/CC_Core", "Species", "ModuleScript" },
	{ "src/core/shared/Net.luau", "ReplicatedStorage/CC_Core", "Net", "ModuleScript" },
	{ "src/core/server/Clock.luau", "ServerScriptService/CC_CoreServer", "Clock", "ModuleScript" },
	{ "src/core/server/Store.luau", "ServerScriptService/CC_CoreServer", "Store", "ModuleScript" },
	{ "src/core/server/Profile.luau", "ServerScriptService/CC_CoreServer", "Profile", "ModuleScript" },
	{ "src/core/server/Progression.luau", "ServerScriptService/CC_CoreServer", "Progression", "ModuleScript" },
	{ "src/core/server/Inventory.luau", "ServerScriptService/CC_CoreServer", "Inventory", "ModuleScript" },
	{ "src/core/server/Bank.luau", "ServerScriptService/CC_CoreServer", "Bank", "ModuleScript" },
	{ "src/core/server/Gear.luau", "ServerScriptService/CC_CoreServer", "Gear", "ModuleScript" },
	{ "src/core/server/Coop.luau", "ServerScriptService/CC_CoreServer", "Coop", "ModuleScript" },
	{ "src/core/server/Training.luau", "ServerScriptService/CC_CoreServer", "Training", "ModuleScript" },
	{ "src/core/server/Weather.luau", "ServerScriptService/CC_CoreServer", "Weather", "ModuleScript" },
	{ "src/world/TrainingYard.luau", "ServerStorage/CC_Generators", "TrainingYard", "ModuleScript" },
	{ "src/runtime/CC_WeatherClient.client.luau", "StarterPlayer/StarterPlayerScripts", "CC_WeatherClient", "LocalScript" },
	{ "src/core/server/Tests.luau", "ServerScriptService/CC_CoreServer", "Tests", "ModuleScript" },
	{ "src/core/server/Prompts.luau", "ServerScriptService/CC_CoreServer", "Prompts", "ModuleScript" },
	{ "src/core/server/Visuals.luau", "ServerScriptService/CC_CoreServer", "Visuals", "ModuleScript" },
	{ "src/core/server/DropPacks.luau", "ServerScriptService/CC_CoreServer", "DropPacks", "ModuleScript" },
	{ "src/core/server/Camps.luau", "ServerScriptService/CC_CoreServer", "Camps", "ModuleScript" },
	{ "src/core/server/Claims.luau", "ServerScriptService/CC_CoreServer", "Claims", "ModuleScript" },
	{ "src/core/server/Nests.luau", "ServerScriptService/CC_CoreServer", "Nests", "ModuleScript" },
	{ "src/core/server/Tutorial.luau", "ServerScriptService/CC_CoreServer", "Tutorial", "ModuleScript" },
	{ "src/world/CoreProps.luau", "ServerStorage/CC_Generators", "CoreProps", "ModuleScript" },
	{ "src/world/MountainGen.luau", "ServerStorage/CC_Generators", "MountainGen", "ModuleScript" },
	{ "src/world/WorldConfig.luau", "ServerStorage/CC_Generators", "WorldConfig", "ModuleScript" },
	{ "src/world/BuildAll.luau", "ServerStorage/CC_Generators", "BuildAll", "ModuleScript" },
	{ "src/world/Kit.luau", "ServerStorage/CC_Generators", "Kit", "ModuleScript" },
	{ "src/world/RouteKit.luau", "ServerStorage/CC_Generators", "RouteKit", "ModuleScript" },
	{ "src/world/LedgeP1.luau", "ServerStorage/CC_Generators", "LedgeP1", "ModuleScript" },
	{ "src/world/ShepherdP2.luau", "ServerStorage/CC_Generators", "ShepherdP2", "ModuleScript" },
	{ "src/world/ClimbKit.luau", "ServerStorage/CC_Generators", "ClimbKit", "ModuleScript" },
	{ "src/world/LedgeRoute.luau", "ServerStorage/CC_Generators", "LedgeRoute", "ModuleScript" },
	{ "src/world/RouteLines.luau", "ServerStorage/CC_Generators", "RouteLines", "ModuleScript" },
	{ "src/world/RouteSpline.luau", "ServerStorage/CC_Generators", "RouteSpline", "ModuleScript" },
	{ "src/world/SplineGen.luau", "ServerStorage/CC_Generators", "SplineGen", "ModuleScript" },
	{ "src/world/SplineKit.luau", "ServerStorage/CC_Generators", "SplineKit", "ModuleScript" },
	{ "src/world/FootholdV3.luau", "ServerStorage/CC_Generators", "FootholdV3", "ModuleScript" },
	{ "tools/route_climb_bot.luau", "ReplicatedStorage/CC_DevTools", "RouteClimbBot", "ModuleScript" },
	{ "src/runtime/CC_CoreService.server.luau", "ServerScriptService", "CC_CoreService", "Script" },
	{ "src/runtime/CC_CoreClient.client.luau", "StarterPlayer/StarterPlayerScripts", "CC_CoreClient", "LocalScript" },
	{ "src/runtime/CC_CheckpointService.server.luau", "ServerScriptService", "CC_CheckpointService", "Script" },
	{ "src/runtime/CC_AscentClient.client.luau", "StarterPlayer/StarterPlayerScripts", "CC_AscentClient", "LocalScript" },
	{ "src/runtime/CC_ClimbClient.client.luau", "StarterPlayer/StarterPlayerScripts", "CC_ClimbClient", "LocalScript" },
	{ "tools/sync_core.luau", "ServerStorage/CC_DevTools", "Sync", "ModuleScript" },
	{ "tools/tutorial_bot.luau", "ReplicatedStorage/CC_DevTools", "TutorialBot", "ModuleScript" },
	{ "tools/b_checks.luau", "ReplicatedStorage/CC_DevTools", "BChecks", "ModuleScript" },
	{ "tools/perf_probe.luau", "ReplicatedStorage/CC_DevTools", "PerfProbe", "ModuleScript" },
	{ "tools/ledge_bot.luau", "ReplicatedStorage/CC_DevTools", "LedgeBot", "ModuleScript" },
}
local function want(p)
	if not only then
		return true
	end
	for _, q in ipairs(only) do
		if q == p then
			return true
		end
	end
	return false
end
local function resolve(path)
	local inst = game
	for seg in string.gmatch(path, "[^/]+") do
		local nxt = inst:FindFirstChild(seg)
		if not nxt then
			if inst == game then
				nxt = game:GetService(seg)
			else
				nxt = Instance.new("Folder")
				nxt.Name = seg
				nxt.Parent = inst
			end
		end
		inst = nxt
	end
	return inst
end
local function ck(src)
	src = src:gsub("\r\n", "\n")
	local lines = {}
	for l in (src .. "\n"):gmatch("(.-)\n") do
		lines[#lines + 1] = (l:gsub("%s+$", ""))
	end
	src = table.concat(lines, "\n"):gsub("%s+$", "")
	local h = 0
	for i = 1, #src do
		h = (h * 31 + string.byte(src, i)) % 2147483647
	end
	return h, #src
end
return function(list)
only = list
local out = {}
HS.HttpEnabled = true
local ok, err = pcall(function()
	for _, m in ipairs(MAN) do
		if want(m[1]) then
			local src = HS:GetAsync(BASE .. m[1], true)
			local parent = resolve(m[2])
			local inst = parent:FindFirstChild(m[3])
			if inst and inst.ClassName ~= m[4] then
				inst:Destroy()
				inst = nil
			end
			if not inst then
				inst = Instance.new(m[4])
				inst.Name = m[3]
				inst.Parent = parent
			end
			inst.Source = src
			local h, n = ck(inst.Source)
			out[#out + 1] = m[1] .. "\t" .. h .. "\t" .. n
		end
	end
end)
HS.HttpEnabled = false
if not ok then
	return "SYNC ERROR: " .. tostring(err) .. "\n" .. table.concat(out, "\n")
end
return table.concat(out, "\n")
end

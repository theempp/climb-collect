-- Run only in the isolated review's Edit DataModel with localhost8791 serving this worktree.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before syncing')
assert(game.Name:find('FreeClimb',1,true) and game.ServerStorage:FindFirstChild('MountainWorld'),'Not this isolated free-climb review')
local Http=game:GetService('HttpService')
local manifest={
 {"ReplicatedStorage.MountainShared", "MovementRules", "ModuleScript", "mountain/shared/MovementRules.luau"},
 {"ServerStorage.MountainWorld", "MountainEntrances", "ModuleScript", "mountain/world/MountainEntrances.luau"},
 {"ServerScriptService.MountainServer", "Movement", "ModuleScript", "mountain/server/Movement.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient", "Sprint", "LocalScript", "mountain/client/Sprint.client.luau"},
 {"ReplicatedStorage.MountainShared", "Catalog", "ModuleScript", "mountain/shared/Catalog.luau"},
 {"ReplicatedStorage.MountainShared", "GuardianRules", "ModuleScript", "mountain/shared/GuardianRules.luau"},
 {"ReplicatedStorage.MountainShared", "HazardRules", "ModuleScript", "mountain/shared/HazardRules.luau"},
 {"ReplicatedStorage.MountainShared", "RaidConfig", "ModuleScript", "mountain/shared/RaidConfig.luau"},
 {"ReplicatedStorage.MountainShared", "Rules", "ModuleScript", "mountain/shared/Rules.luau"},
 {"ReplicatedStorage.MountainShared", "RunRules", "ModuleScript", "mountain/shared/RunRules.luau"},
 {"ReplicatedStorage.MountainShared", "TerrainProfile", "ModuleScript", "mountain/shared/TerrainProfile.luau"},
 {"ReplicatedStorage.MountainShared", "TraversalRules", "ModuleScript", "mountain/shared/TraversalRules.luau"},
 {"ReplicatedStorage.MountainShared", "Tycoon", "ModuleScript", "mountain/shared/Tycoon.luau"},
 {"ReplicatedStorage.MountainShared", "TycoonConfig", "ModuleScript", "mountain/shared/TycoonConfig.luau"},
 {"ReplicatedStorage.MountainShared", "UIPresentation", "ModuleScript", "mountain/shared/UIPresentation.luau"},
 {"ReplicatedStorage.MountainShared", "UIProtocol", "ModuleScript", "mountain/shared/UIProtocol.luau"},
 {"ServerStorage.MountainWorld", "ArenaBoundary", "ModuleScript", "mountain/world/ArenaBoundary.luau"},
 {"ServerStorage.MountainWorld", "Art", "ModuleScript", "mountain/world/Art.luau"},
 {"ServerStorage.MountainWorld", "ArtClearance", "ModuleScript", "mountain/world/ArtClearance.luau"},
 {"ServerStorage.MountainWorld", "BlossomCanopies", "ModuleScript", "mountain/world/BlossomCanopies.luau"},
 {"ServerStorage.MountainWorld", "CliffComposition", "ModuleScript", "mountain/world/CliffComposition.luau"},
 {"ServerStorage.MountainWorld", "CreatureDetails", "ModuleScript", "mountain/world/CreatureDetails.luau"},
 {"ServerStorage.MountainWorld", "CrystalFinish", "ModuleScript", "mountain/world/CrystalFinish.luau"},
 {"ServerStorage.MountainWorld", "Environment", "ModuleScript", "mountain/world/Environment.luau"},
 {"ServerStorage.MountainWorld", "EnvironmentFinish", "ModuleScript", "mountain/world/EnvironmentFinish.luau"},
 {"ServerStorage.MountainWorld", "FoliageFinish", "ModuleScript", "mountain/world/FoliageFinish.luau"},
 {"ServerStorage.MountainWorld", "FreeClimb", "ModuleScript", "mountain/world/FreeClimb.luau"},
 {"ServerStorage.MountainWorld", "FrontShoulder", "ModuleScript", "mountain/world/FrontShoulder.luau"},
 {"ServerStorage.MountainWorld", "GardenGround", "ModuleScript", "mountain/world/GardenGround.luau"},
 {"ServerStorage.MountainWorld", "HeroFalls", "ModuleScript", "mountain/world/HeroFalls.luau"},
 {"ServerStorage.MountainWorld", "HeroGarden", "ModuleScript", "mountain/world/HeroGarden.luau"},
 {"ServerStorage.MountainWorld", "Landmarks", "ModuleScript", "mountain/world/Landmarks.luau"},
 {"ServerStorage.MountainWorld", "Massifs", "ModuleScript", "mountain/world/Massifs.luau"},
 {"ServerStorage.MountainWorld", "MeasuredFinish", "ModuleScript", "mountain/world/MeasuredFinish.luau"},
 {"ServerStorage.MountainWorld", "NaturalRidges", "ModuleScript", "mountain/world/NaturalRidges.luau"},
 {"ServerStorage.MountainWorld", "NaturalSurface", "ModuleScript", "mountain/world/NaturalSurface.luau"},
 {"ServerStorage.MountainWorld", "Polish", "ModuleScript", "mountain/world/Polish.luau"},
 {"ServerStorage.MountainWorld", "Relief", "ModuleScript", "mountain/world/Relief.luau"},
 {"ServerStorage.MountainWorld", "RidgeCrown", "ModuleScript", "mountain/world/RidgeCrown.luau"},
 {"ServerStorage.MountainWorld", "RidgeGroves", "ModuleScript", "mountain/world/RidgeGroves.luau"},
 {"ServerStorage.MountainWorld", "RidgeRockwork", "ModuleScript", "mountain/world/RidgeRockwork.luau"},
 {"ServerStorage.MountainWorld", "Sculpt", "ModuleScript", "mountain/world/Sculpt.luau"},
 {"ServerStorage.MountainWorld", "ShelfGardens", "ModuleScript", "mountain/world/ShelfGardens.luau"},
 {"ServerStorage.MountainWorld", "SlopeGroves", "ModuleScript", "mountain/world/SlopeGroves.luau"},
 {"ServerStorage.MountainWorld", "Strata", "ModuleScript", "mountain/world/Strata.luau"},
 {"ServerStorage.MountainWorld", "TraversalArt", "ModuleScript", "mountain/world/TraversalArt.luau"},
 {"ServerStorage.MountainWorld", "WallGrowth", "ModuleScript", "mountain/world/WallGrowth.luau"},
 {"ServerStorage.MountainWorld", "World", "ModuleScript", "mountain/world/World.luau"},
 {"ServerScriptService.MountainServer", "CarryVisuals", "ModuleScript", "mountain/server/CarryVisuals.luau"},
 {"ServerScriptService.MountainServer", "Combat", "ModuleScript", "mountain/server/Combat.luau"},
 {"ServerScriptService.MountainServer", "Competition", "ModuleScript", "mountain/server/Competition.luau"},
 {"ServerScriptService.MountainServer", "EggRaids", "ModuleScript", "mountain/server/EggRaids.luau"},
 {"ServerScriptService.MountainServer", "Guardians", "ModuleScript", "mountain/server/Guardians.luau"},
 {"ServerScriptService.MountainServer", "Journey", "ModuleScript", "mountain/server/Journey.luau"},
 {"ServerScriptService.MountainServer", "Main", "Script", "mountain/server/Main.server.luau"},
 {"ServerScriptService.MountainServer", "Profiles", "ModuleScript", "mountain/server/Profiles.luau"},
 {"ServerScriptService.MountainServer", "RaidHazards", "ModuleScript", "mountain/server/RaidHazards.luau"},
 {"ServerScriptService.MountainServer", "Sanctuary", "ModuleScript", "mountain/server/Sanctuary.luau"},
 {"ServerScriptService.MountainServer", "SanctuarySessions", "ModuleScript", "mountain/server/SanctuarySessions.luau"},
 {"ServerScriptService.MountainServer", "Store", "ModuleScript", "mountain/server/Store.luau"},
 {"ServerScriptService.MountainServer", "StudioTests", "ModuleScript", "mountain/server/StudioTests.luau"},
 {"ServerScriptService.MountainServer", "Traversal", "ModuleScript", "mountain/server/Traversal.luau"},
 {"ServerScriptService.MountainServer", "TycoonWorld", "ModuleScript", "mountain/server/TycoonWorld.luau"},
 {"ServerScriptService.MountainServer", "UIRequests", "ModuleScript", "mountain/server/UIRequests.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient", "CreatureMotion", "LocalScript", "mountain/client/CreatureMotion.client.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient", "EggCarry", "LocalScript", "mountain/client/EggCarry.client.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient", "HUD", "LocalScript", "mountain/client/HUD.client.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient", "TycoonConveyors", "LocalScript", "mountain/client/TycoonConveyors.client.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "ClientState", "ModuleScript", "mountain/client/UI/ClientState.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "Controller", "ModuleScript", "mountain/client/UI/Controller.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "Feedback", "ModuleScript", "mountain/client/UI/Feedback.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "Screens", "ModuleScript", "mountain/client/UI/Screens.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "Theme", "ModuleScript", "mountain/client/UI/Theme.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "TycoonHub", "ModuleScript", "mountain/client/UI/TycoonHub.luau"},
 {"StarterPlayer.StarterPlayerScripts.MountainClient.UI", "Widgets", "ModuleScript", "mountain/client/UI/Widgets.luau"},
}
local wasEnabled=Http.HttpEnabled;Http.HttpEnabled=true
local sources={}
local ok,err=pcall(function() for i,row in ipairs(manifest) do sources[i]=Http:GetAsync('http://127.0.0.1:8791/'..row[4]);assert(#sources[i]>50,'Empty source '..row[4]) end end)
Http.HttpEnabled=wasEnabled;assert(ok,err)
local summary={}
for i,row in ipairs(manifest) do
 local parent=game;for piece in row[1]:gmatch('[^.]+') do parent=assert(parent:FindFirstChild(piece),'Missing '..piece) end
 local old=parent:FindFirstChild(row[2]);if old then old:Destroy() end
 local replacement=Instance.new(row[3]);replacement.Name=row[2];replacement.Source=sources[i];replacement.Parent=parent
 table.insert(summary,{file=row[4],bytes=#sources[i]})
end
return summary

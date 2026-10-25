local count=0
local function hash(s) s=s:gsub('\r\n','\n');local h=0;for i=1,#s do h=(h*31+s:byte(i))%2147483647 end;return h end
assert(hash(game.ReplicatedStorage.MountainShared.Catalog.Source)==772190205,'Source mismatch: game.ReplicatedStorage.MountainShared.Catalog');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.Rules.Source)==890162465,'Source mismatch: game.ReplicatedStorage.MountainShared.Rules');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.TerrainProfile.Source)==936372506,'Source mismatch: game.ReplicatedStorage.MountainShared.TerrainProfile');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.TraversalRules.Source)==1508702906,'Source mismatch: game.ReplicatedStorage.MountainShared.TraversalRules');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.Tycoon.Source)==832662261,'Source mismatch: game.ReplicatedStorage.MountainShared.Tycoon');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.TycoonConfig.Source)==1025923234,'Source mismatch: game.ReplicatedStorage.MountainShared.TycoonConfig');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.UIPresentation.Source)==1240134,'Source mismatch: game.ReplicatedStorage.MountainShared.UIPresentation');count+=1
assert(hash(game.ReplicatedStorage.MountainShared.UIProtocol.Source)==473606541,'Source mismatch: game.ReplicatedStorage.MountainShared.UIProtocol');count+=1
assert(hash(game.ServerScriptService.MountainServer.Combat.Source)==358125987,'Source mismatch: game.ServerScriptService.MountainServer.Combat');count+=1
assert(hash(game.ServerScriptService.MountainServer.Competition.Source)==204521462,'Source mismatch: game.ServerScriptService.MountainServer.Competition');count+=1
assert(hash(game.ServerScriptService.MountainServer.Journey.Source)==1767868237,'Source mismatch: game.ServerScriptService.MountainServer.Journey');count+=1
assert(hash(game.ServerScriptService.MountainServer.Main.Source)==109346709,'Source mismatch: game.ServerScriptService.MountainServer.Main');count+=1
assert(hash(game.ServerScriptService.MountainServer.Profiles.Source)==1478653472,'Source mismatch: game.ServerScriptService.MountainServer.Profiles');count+=1
assert(hash(game.ServerScriptService.MountainServer.Sanctuary.Source)==1694723534,'Source mismatch: game.ServerScriptService.MountainServer.Sanctuary');count+=1
assert(hash(game.ServerScriptService.MountainServer.SanctuarySessions.Source)==795206613,'Source mismatch: game.ServerScriptService.MountainServer.SanctuarySessions');count+=1
assert(hash(game.ServerScriptService.MountainServer.Store.Source)==1612426582,'Source mismatch: game.ServerScriptService.MountainServer.Store');count+=1
assert(hash(game.ServerScriptService.MountainServer.StudioTests.Source)==1141149606,'Source mismatch: game.ServerScriptService.MountainServer.StudioTests');count+=1
assert(hash(game.ServerScriptService.MountainServer.Traversal.Source)==93200981,'Source mismatch: game.ServerScriptService.MountainServer.Traversal');count+=1
assert(hash(game.ServerScriptService.MountainServer.TycoonWorld.Source)==1153215,'Source mismatch: game.ServerScriptService.MountainServer.TycoonWorld');count+=1
assert(hash(game.ServerScriptService.MountainServer.UIRequests.Source)==778634198,'Source mismatch: game.ServerScriptService.MountainServer.UIRequests');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.CreatureMotion.Source)==946315756,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.CreatureMotion');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.HUD.Source)==1903782239,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.HUD');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.TycoonConveyors.Source)==1321307607,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.TycoonConveyors');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.ClientState.Source)==1507552869,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.ClientState');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Controller.Source)==124764673,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Controller');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Feedback.Source)==1562942517,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Feedback');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Screens.Source)==2014168671,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Screens');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Theme.Source)==1291628820,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Theme');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.TycoonHub.Source)==477940971,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.TycoonHub');count+=1
assert(hash(game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Widgets.Source)==1808414269,'Source mismatch: game.StarterPlayer.StarterPlayerScripts.MountainClient.UI.Widgets');count+=1
return {matchedRuntimeSources=count,mountain=workspace:FindFirstChild('ImpossibleMountain')~=nil,sanctuary=workspace:FindFirstChild('Sanctuary')~=nil}
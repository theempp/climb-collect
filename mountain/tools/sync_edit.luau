-- Run only in the isolated review's Edit DataModel with localhost8791 serving this worktree.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play before syncing')
assert(game.ServerStorage:FindFirstChild('MountainWorld'),'Not the isolated mountain place')
local Http=game:GetService('HttpService')
local manifest={
 {'ReplicatedStorage.MountainShared','Catalog','ModuleScript','mountain/shared/Catalog.luau'},
 {'ReplicatedStorage.MountainShared','Rules','ModuleScript','mountain/shared/Rules.luau'},
 {'ServerStorage.MountainWorld','Art','ModuleScript','mountain/world/Art.luau'},
 {'ServerStorage.MountainWorld','Landmarks','ModuleScript','mountain/world/Landmarks.luau'},
 {'ServerStorage.MountainWorld','World','ModuleScript','mountain/world/World.luau'},
 {'ServerScriptService.MountainServer','Store','ModuleScript','mountain/server/Store.luau'},
 {'ServerScriptService.MountainServer','Profiles','ModuleScript','mountain/server/Profiles.luau'},
 {'ServerScriptService.MountainServer','Combat','ModuleScript','mountain/server/Combat.luau'},
 {'ServerScriptService.MountainServer','Competition','ModuleScript','mountain/server/Competition.luau'},
 {'ServerScriptService.MountainServer','StudioTests','ModuleScript','mountain/server/StudioTests.luau'},
 {'ServerScriptService.MountainServer','Main','Script','mountain/server/Main.server.luau'},
 {'StarterPlayer.StarterPlayerScripts.MountainClient','HUD','LocalScript','mountain/client/HUD.client.luau'},
}
Http.HttpEnabled=true
local sources={}
local ok,err=pcall(function() for i,row in ipairs(manifest) do sources[i]=Http:GetAsync('http://127.0.0.1:8791/'..row[4]);assert(#sources[i]>50,'Empty source '..row[4]) end end)
Http.HttpEnabled=false;assert(ok,err)
local summary={}
for i,row in ipairs(manifest) do
 local parent=game;for piece in row[1]:gmatch('[^.]+') do parent=assert(parent:FindFirstChild(piece),'Missing '..piece) end
 local old=parent:FindFirstChild(row[2]);if old then old:Destroy() end
 local replacement=Instance.new(row[3]);replacement.Name=row[2];replacement.Source=sources[i];replacement.Parent=parent
 table.insert(summary,{file=row[4],bytes=#sources[i]})
end
return summary

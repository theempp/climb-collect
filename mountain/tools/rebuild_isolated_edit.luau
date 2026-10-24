-- Explicit rebuild of the disposable isolated review only, after source sync.
assert(not game:GetService('RunService'):IsRunning(),'Stop Play first')
assert(game.ServerStorage:FindFirstChild('MountainWorld'),'Not the isolated mountain place')
assert(not workspace:FindFirstChild('MountainEmpire_Phase1'),'Phase 1 is protected')
local old=workspace:FindFirstChild('ImpossibleMountain')
assert(old and old:GetAttribute('GeneratorVersion')=='ImpossibleMountain-1','Unknown world: refusing destructive regeneration')
old:Destroy();workspace.Terrain:Clear()
for _,child in ipairs(workspace.Terrain:GetChildren()) do if child.Name=='MountainGatewayEntry' then child:Destroy() end end
for _,effect in ipairs(game.Lighting:GetChildren()) do if effect:IsA('Atmosphere') or effect:IsA('BloomEffect') then effect:Destroy() end end
return require(game.ServerStorage.MountainWorld.World).build()

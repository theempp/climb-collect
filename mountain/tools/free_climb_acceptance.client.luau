-- Read-only, manual Studio Client acceptance probe. Never package as a runtime script.
local player=game.Players.LocalPlayer
local gui=player.PlayerGui
local count=0
for _,v in ipairs(gui:GetChildren()) do if v.Name=='MountainHUD' then count+=1 end end
assert(count==1,'Expected exactly one HUD after respawn')
local world=workspace.ImpossibleMountain
assert(world:GetAttribute('FreeClimbVersion')==1)
assert(#world.Sections:GetChildren()==6 and #world.GuardianBounds:GetChildren()==6)
assert(#world.Checkpoints:GetChildren()==18 and #world.SanctuaryExits:GetChildren()==3)
local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
return {hudCount=count,viewport=workspace.CurrentCamera.ViewportSize,touch=game:GetService('UserInputService').TouchEnabled,
 reducedMotion=player:GetAttribute('MountainReducedMotion'),position=root and root.Position,
 carrying=player.Character and player.Character:GetAttribute('CarryingCreature'),terrainAuthority=world:GetAttribute('TerrainAuthority')}

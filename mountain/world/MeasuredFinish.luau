-- Baked visual finish for the measured terrain sculpt; no gameplay mutation.
local M={}
function M.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(world:GetAttribute('MeasuredSculptRevision')==42,'Requires measured sculpt 42')
 assert(not world:FindFirstChild('ArenaRockFaces'),'Already applied')
 local palette={Rock={115,123,119},Slate={110,119,115},Limestone={128,137,122},Sandstone={132,137,118},Sand={143,140,112},Basalt={91,101,98},Grass={104,139,90}}
 for name,rgb in pairs(palette) do workspace.Terrain:SetMaterialColor(Enum.Material[name],Color3.fromRGB(unpack(rgb))) end
 local root=Instance.new('Folder');root.Name='ArenaRockFaces'
 local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={world}
 local catalog=require(game.ReplicatedStorage.MountainShared.Catalog)
 local template=assert(game.ServerStorage.MountainArtAssets:FindFirstChild('WaterfallCliff'))
 for i,k in ipairs(catalog.kingdoms) do
  local arena=world[k.name].ArenaFloor
  local out=Vector3.new(arena.Position.X,0,arena.Position.Z).Unit
  local side=Vector3.new(-out.Z,0,out.X)
  local heights={48,55,44,33,38,30}
  local widths={64,60,62,43,45,40}
  local tints={{190,166,125},{182,193,174},{228,192,126},{204,180,207},{151,137,123},{237,238,225}}
  for j=0,0 do
   local p=template:Clone();p.Name='RootedArenaCliff_'..i..'_'..j
   p.Size=Vector3.new(widths[i],heights[i],48)
   local pos=arena.Position+out*37-Vector3.new(0,p.Size.Y/2+12,0)
   p.CFrame=CFrame.lookAt(pos,pos+out)*CFrame.Angles(0,(i%3-1)*.09,0)
   for _,near in ipairs(workspace:GetPartBoundsInBox(p.CFrame,p.Size+Vector3.new(2,2,2),overlap)) do
    assert(not near.CanCollide and not near:FindFirstChildOfClass('ProximityPrompt'),'Cliff overlaps gameplay: '..near:GetFullName())
   end
   p.Color=Color3.new(1,1,1)
   local surface=p:FindFirstChildOfClass('SurfaceAppearance');if surface then surface.Color=Color3.fromRGB(unpack(tints[i])) end
   p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=root
  end
  task.wait()
 end
 root:SetAttribute('Revision',2)
 root.Parent=world
 return {faces=#root:GetChildren(),densityChanges=0,colliderChanges=0}
end
return M

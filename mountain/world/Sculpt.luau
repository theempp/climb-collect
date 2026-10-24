-- Controlled erosion/material pass for a NEW local review only.
-- Preserves every voxel within expanded gameplay-part bounds. No Terrain:Clear.
local S={}
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
function S.apply(world)
 assert(not game:GetService('RunService'):IsRunning(),'Edit only')
 assert(game.PlaceId==0 and world.Name=='ImpossibleMountain' and not workspace:FindFirstChild('MountainEmpire_Phase1'),'Isolated local mountain only')
 assert(not world:GetAttribute('SculptRevision'),'Do not repeat erosion on a sculpted checkpoint')
 local bins={}
 local function key(x,y,z) return x..':'..y..':'..z end
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   local extent=Vector3.zero
   for _,a in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do extent+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   local lo=p.Position-extent-Vector3.new(16,20,16);local hi=p.Position+extent+Vector3.new(16,22,16)
   for x=math.floor(lo.X/16),math.floor(hi.X/16) do for y=math.floor(lo.Y/16),math.floor(hi.Y/16) do for z=math.floor(lo.Z/16),math.floor(hi.Z/16) do bins[key(x,y,z)]=true end end end
  end
 end
 local terrain=workspace.Terrain;local stats={carved=0,recolored=0,protected=0,tiles=0}
 for bx=-544,512,64 do for bz=-544,512,64 do
  local near=math.max(0,Vector2.new(bx+32,bz+32).Magnitude-46);local far=near+92
  local bottom=math.max(-32,math.floor(((489-far)/.4-160)/4)*4)
  local top=math.min(840,math.ceil(((489-near)/.4+90)/4)*4)
  if top>bottom and far>110 then
   local region=Region3.new(Vector3.new(bx,bottom,bz),Vector3.new(bx+64,top,bz+64))
   local materials,occupancy=terrain:ReadVoxels(region,4);local changed=false
   for x=1,16 do for z=1,16 do
    local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4;local radius=Vector2.new(wx,wz).Magnitude;local angle=math.atan2(wz,wx)
    if radius>115 then for y=1,#occupancy[x] do
     local wy=bottom+(y-.5)*4
     if occupancy[x][y][z]>0 then
      if bins[key(math.floor(wx/16),math.floor(wy/16),math.floor(wz/16))] then stats.protected+=1
      else
       -- Broad, wandering ravines cut across the horizontal biome terraces.
       local valley=math.max(0,math.sin(angle*5+.6+wy*.0015))^4
       local depth=valley*(32+12*math.sin(wy*.008)^2)
       local limit=489-wy*.4-depth+math.noise(wx/95,wz/95,24)*10
       if radius>limit and radius<550 and wy>0 then
        local next=math.min(occupancy[x][y][z],math.clamp((limit-radius+2)/4,0,1))
        if next<occupancy[x][y][z] then stats.carved+=1;occupancy[x][y][z]=next;changed=true end
       end
       if occupancy[x][y][z]>0 then
        local shift=math.sin(angle*3+.4)*66+math.sin(angle*7-wy/190)*28
        local k=math.clamp(math.floor((wy+shift-16)/136)+1,1,6)
        local material=Enum.Material[C.kingdoms[k].material]
        if valley>.7 and k<5 then material=Enum.Material.Limestone end
        if materials[x][y][z]~=material then materials[x][y][z]=material;stats.recolored+=1;changed=true end
       end
      end
     end
    end end
   end end
   if changed then terrain:WriteVoxels(region,4,materials,occupancy) end
   stats.tiles+=1
  end
  task.wait()
 end end
 world:SetAttribute('SculptRevision',1)
 world:SetAttribute('SculptReport',game.HttpService:JSONEncode(stats))
 return stats
end
return S

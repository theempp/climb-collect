-- Material-only diagonal geology. No density changes; original play corridors excluded.
local S={}
local function key(x,y,z) return x..':'..y..':'..z end
function S.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(world:GetAttribute('MassifRevision')==1 and not world:GetAttribute('StrataRevision'),'Requires unpainted Massif checkpoint')
 local protect={}
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   local e=Vector3.zero
   for _,a in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do e+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   local lo=p.Position-e-Vector3.new(16,20,16);local hi=p.Position+e+Vector3.new(16,22,16)
   for x=math.floor(lo.X/16),math.floor(hi.X/16) do for y=math.floor(lo.Y/16),math.floor(hi.Y/16) do for z=math.floor(lo.Z/16),math.floor(hi.Z/16) do protect[key(x,y,z)]=true end end end
  end
 end
 local painted=0
 for bx=-544,480,64 do for bz=-544,480,64 do
  local near=math.max(0,Vector2.new(bx+32,bz+32).Magnitude-46);local far=near+92
  local bottom=math.max(0,math.floor(((489-far)/.4-160)/4)*4)
  local top=math.min(824,math.ceil(((489-near)/.4+90)/4)*4)
  if top>bottom and far>110 then
   local region=Region3.new(Vector3.new(bx,bottom,bz),Vector3.new(bx+64,top,bz+64))
   local mat,occ=workspace.Terrain:ReadVoxels(region,4);local changed=false
   for x=1,16 do for z=1,16 do
    local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4;local angle=math.atan2(wz,wx)
    for y=1,#occ[x] do
     local wy=bottom+(y-.5)*4
     if occ[x][y][z]>0 and not protect[key(math.floor(wx/16),math.floor(wy/16),math.floor(wz/16))] then
      -- Broad, irregular seams cross several biome heights instead of following level bands.
      local seam=math.sin(angle*3-wy*.0038+.7)+math.noise(wx/73,wy/95,wz/73)*.36
      if seam>.62 then
       local material=if seam>.95 then Enum.Material.Limestone else Enum.Material.Slate
       if mat[x][y][z]~=material then mat[x][y][z]=material;painted+=1;changed=true end
      end
     end
    end
   end end
   if changed then workspace.Terrain:WriteVoxels(region,4,mat,occ) end
  end
  task.wait()
 end end
 world:SetAttribute('StrataRevision',1);world:SetAttribute('StrataPaintedCells',painted)
 return {painted=painted,occupancyChanges=0}
end
return S

-- Additive geological shoulders over the preserved Sculpt07 terrain.
-- This is a separate revision: never reset or rerun Sculpt to reproduce it.
local R={}
local function key(x,y,z) return x..':'..y..':'..z end
function R.apply(world)
 assert(not game:GetService('RunService'):IsRunning(),'Edit only')
 assert(game.PlaceId==0 and world.Name=='ImpossibleMountain' and world:GetAttribute('SculptRevision')==1,'Requires isolated sculpted checkpoint')
 assert(not world:GetAttribute('ReliefRevision'),'Relief already applied')
 local protected={}
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   local e=Vector3.zero
   for _,a in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do e+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   local lo=p.Position-e-Vector3.new(16,20,16);local hi=p.Position+e+Vector3.new(16,22,16)
   for x=math.floor(lo.X/16),math.floor(hi.X/16) do for y=math.floor(lo.Y/16),math.floor(hi.Y/16) do for z=math.floor(lo.Z/16),math.floor(hi.Z/16) do protected[key(x,y,z)]=true end end end
  end
 end
 -- Soft shoulders around the exclusion cells prevent abrupt walls beside paths.
 local soft={}
 for k in pairs(protected) do
  local x,y,z=k:match('([^:]+):([^:]+):([^:]+)');x=tonumber(x);y=tonumber(y);z=tonumber(z)
  for dx=-2,2 do for dy=-2,2 do for dz=-2,2 do
   local weight=math.clamp(math.sqrt(dx*dx+dy*dy+dz*dz)/2.5,0,1)
   local n=key(x+dx,y+dy,z+dz);soft[n]=math.min(soft[n] or 1,weight)
  end end end
 end
 local stats={added=0,tiles=0,protected=0}
 for bx=-608,576,64 do for bz=-608,576,64 do
  local near=math.max(0,Vector2.new(bx+32,bz+32).Magnitude-46);local far=near+92
  local bottom=math.max(-16,math.floor(((440-far)/.4-100)/4)*4)
  local top=math.min(836,math.ceil(((585-near)/.4+40)/4)*4)
  if top>bottom and far>125 then
   local region=Region3.new(Vector3.new(bx,bottom,bz),Vector3.new(bx+64,top,bz+64))
   local mat,occ=workspace.Terrain:ReadVoxels(region,4);local changed=false
   for x=1,16 do for z=1,16 do
    local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4;local radius=Vector2.new(wx,wz).Magnitude;local a=math.atan2(wz,wx)
    for y=1,#occ[x] do
     local wy=bottom+(y-.5)*4;local cell=key(math.floor(wx/16),math.floor(wy/16),math.floor(wz/16))
     if protected[cell] then stats.protected+=1
     elseif wy>0 and radius>125 then
      -- Three broad buttresses, irregular secondary ribs and a sloping foot.
      local ridge=math.max(0,math.cos(a*3+.55+wy*.0018))^3
      local ribs=math.max(0,math.sin(a*9-wy*.005))^4
      local fade=math.clamp(wy/55,0,1)*math.clamp((836-wy)/110,0,1)
      local depth=(ridge*(58+28*math.sin(wy*.006+1)^2)+ribs*15)*fade*(soft[cell] or 1)
      local surface=477-wy*.4+depth+math.noise(wx/68,wy/79,wz/68)*9
      local value=math.clamp((surface-radius+2)/4,0,1)
      -- Only positive relief, never removes existing occupied terrain.
      if value>occ[x][y][z] and depth>4 then
       occ[x][y][z]=value;stats.added+=1;changed=true
       local altitude=wy+math.sin(a*3+.55)*85+math.sin(a*7)*25
       local material=if altitude<160 then Enum.Material.Grass elseif altitude<320 then Enum.Material.Slate elseif altitude<455 then Enum.Material.Sandstone elseif altitude<590 then Enum.Material.Rock elseif altitude<735 then Enum.Material.Basalt else Enum.Material.Snow
       -- Continuous neutral rock ribs cross the colored kingdoms.
       if ridge>.65 and altitude<590 then material=Enum.Material.Limestone end
       mat[x][y][z]=material
      end
     end
    end
   end end
   if changed then workspace.Terrain:WriteVoxels(region,4,mat,occ) end
   stats.tiles+=1
  end
  task.wait()
 end end
 world:SetAttribute('ReliefRevision',1)
 world:SetAttribute('ReliefReport',game.HttpService:JSONEncode(stats))
 return stats
end
return R

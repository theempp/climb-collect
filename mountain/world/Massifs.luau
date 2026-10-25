-- Two asymmetrical, non-route mountain shoulders rooted into the original base.
-- Additive only. This does not rerun Sculpt or Relief.
local M={}
local function key(x,y,z) return x..':'..y..':'..z end
function M.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(world.Name=='ImpossibleMountain' and world:GetAttribute('SculptRevision')==1 and not world:GetAttribute('ReliefRevision'),'Requires Review10 sculpt')
 assert(not world:GetAttribute('MassifRevision'),'Already applied')
 local protect={}
 for _,p in ipairs(world:GetDescendants()) do
  if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then
   local e=Vector3.zero
   for _,a in ipairs({p.CFrame.RightVector*p.Size.X/2,p.CFrame.UpVector*p.Size.Y/2,p.CFrame.LookVector*p.Size.Z/2}) do e+=Vector3.new(math.abs(a.X),math.abs(a.Y),math.abs(a.Z)) end
   local lo=p.Position-e-Vector3.new(16,20,16);local hi=p.Position+e+Vector3.new(16,22,16)
   for x=math.floor(lo.X/16),math.floor(hi.X/16) do for y=math.floor(lo.Y/16),math.floor(hi.Y/16) do for z=math.floor(lo.Z/16),math.floor(hi.Z/16) do protect[key(x,y,z)]=true end end end
  end
 end
 local stats={added=0,tiles=0}
 local profiles={{-325,-265,735,290,245,1.2},{165,-390,595,240,210,3.7}}
 for bx=-640,448,64 do for bz=-640,64,64 do
  local region=Region3.new(Vector3.new(bx,0,bz),Vector3.new(bx+64,744,bz+64))
  local mat,occ=workspace.Terrain:ReadVoxels(region,4);local changed=false
  for x=1,16 do for z=1,16 do
   local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4
   for y=1,186 do
    if not protect[key(math.floor(wx/16),math.floor((y-.5)/4),math.floor(wz/16))] then
     local wy=(y-.5)*4;local value=0
     for _,s in ipairs(profiles) do
      local t=wy/s[3]
      if t<1 then
       local cx=s[1]+t*37;local cz=s[2]+t*25
       local dx=(wx-cx)/s[4];local dz=(wz-cz)/s[5]
       local a=math.atan2(dz,dx)
       local width=(1-t)^.73*(1+.10*math.sin(a*5+s[6])+ .045*math.sin(a*11-t*5))
       local edge=(width-math.sqrt(dx*dx+dz*dz))*math.min(s[4],s[5])+math.noise(wx/47,wy/59,wz/47)*5
       value=math.max(value,math.clamp((edge+2)/4,0,1))
      end
     end
     if value>occ[x][y][z] then
      occ[x][y][z]=value;stats.added+=1;changed=true
      local noise=math.noise(wx/75,wy/85,wz/75)
      mat[x][y][z]=if wy<80+noise*50 then Enum.Material.Grass elseif wy>655+noise*65 then Enum.Material.Snow elseif noise>.12 then Enum.Material.Slate else Enum.Material.Limestone
     end
    end
   end
  end end
  if changed then workspace.Terrain:WriteVoxels(region,4,mat,occ) end
  stats.tiles+=1;task.wait()
 end end
 world:SetAttribute('MassifRevision',1);world:SetAttribute('MassifReport',game.HttpService:JSONEncode(stats))
 return stats
end
return M

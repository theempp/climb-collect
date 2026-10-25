-- Final irregular crown relief; preserves all expanded gameplay envelopes.
local M={}
local function key(x,y,z) return x..':'..y..':'..z end
function M.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(world:GetAttribute('NaturalRidgesRevision')==2 and not world:GetAttribute('RidgeCrownRevision'),'Requires first ridge pass')
 local clearance=require(script.Parent.ArtClearance).build(world,32)
 local stats={added=0,trimmed=0}
 for bx=-256,192,64 do for bz=-256,192,64 do
  local r=Region3.new(Vector3.new(bx,752,bz),Vector3.new(bx+64,992,bz+64));local m,o=workspace.Terrain:ReadVoxels(r,4)
  for x=1,16 do for z=1,16 do
   local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4;local radius=math.sqrt(wx*wx+wz*wz)
   local peaks=0
   for _,p in ipairs({{-82,-96,982,1.65},{88,-102,944,2.05},{-166,38,916,2.0}}) do
    local dx,dz=wx-p[1],wz-p[2];local a=math.atan2(dz,dx)
    peaks=math.max(peaks,p[3]-math.sqrt(dx*dx+dz*dz)*p[4]*(1+.13*math.sin(a*5)))
   end
   local cap=math.max(858,1010-radius*.95+12*math.sin(math.atan2(wz,wx)*3))
   for y=1,60 do
    local wy=752+(y-.5)*4
    local weight=clearance.weight(Vector3.new(wx,wy,wz))
    if weight>0 then
     local old=o[x][y][z]
     local value=math.max(math.min(old,math.clamp((cap-wy)/4+.5,0,1)),math.clamp((peaks-wy-90*(1-weight))/4+.5,0,1))
     if value~=old then
      o[x][y][z]=value
      if value>old then stats.added+=1 else stats.trimmed+=1 end
      m[x][y][z]=if value==0 then Enum.Material.Air elseif wy>peaks-13 then Enum.Material.Snow else Enum.Material.Limestone
     end
    end
   end
  end end
  workspace.Terrain:WriteVoxels(r,4,m,o);task.wait()
 end end
 world:SetAttribute('RidgeCrownRevision',1);world:SetAttribute('RidgeCrownReport',game.HttpService:JSONEncode(stats))
 return stats
end
return M

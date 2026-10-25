-- Review32 continuation: connected, asymmetric ridge relief; never rebuild routes.
local M={}
local function key(x,y,z) return x..':'..y..':'..z end
function M.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(world.Name=='ImpossibleMountain' and world:GetAttribute('FrontShoulderRevision')==1,'Requires Review32 terrain')
 assert(not world:GetAttribute('NaturalRidgesRevision'),'Already applied')
 local clearance=require(script.Parent.ArtClearance).build(world,40)
 local stats={added=0,tiles=0}
 local ridges={{.08,105,.27,770},{1.65,100,.25,660},{2.65,86,.3,880},{3.7,76,.23,720},{5.05,110,.28,820}}
 for bx=-640,576,64 do for bz=-640,576,64 do
  local region=Region3.new(Vector3.new(bx,0,bz),Vector3.new(bx+64,928,bz+64))
  local mat,occ=workspace.Terrain:ReadVoxels(region,4);local changed=false
  for x=1,16 do for z=1,16 do
   local wx=bx+(x-.5)*4;local wz=bz+(z-.5)*4
   local radius=math.sqrt(wx*wx+wz*wz);local angle=math.atan2(wz,wx)
   if radius>100 and radius<630 then
    for y=1,232 do
     local wy=(y-.5)*4
     local weight=clearance.weight(Vector3.new(wx,wy,wz))
     if weight>0 then
      local relief=0
      for _,s in ipairs(ridges) do
       local a=s[1]+.16*math.sin(wy/290+s[1])
       local d=math.atan2(math.sin(angle-a),math.cos(angle-a))
       local taper=math.clamp((s[4]-wy)/150,0,1)
       local width=s[3]*(.72+.28*math.sin(wy/170+s[1])^2)
       relief=math.max(relief,s[2]*taper*math.exp(-(d/width)^2))
      end
      local edge=476-wy*.405+relief*weight-105*(1-weight)+math.noise(wx/63,wy/87,wz/63)*18-radius
      local ceiling=math.max(838,970-radius*.85+math.sin(angle*3)*18)
      local value=math.clamp(math.min(edge,ceiling-wy)/4+.5,0,1)
      if value>occ[x][y][z] then
       occ[x][y][z]=value;stats.added+=1;changed=true
       local n=math.noise(wx/95,wy/120,wz/95)
       mat[x][y][z]=if wy>760+n*85 then Enum.Material.Snow elseif wy<150+n*70 then Enum.Material.Grass elseif n>.18 then Enum.Material.Slate else Enum.Material.Limestone
      end
     end
    end
   end
  end end
  if changed then workspace.Terrain:WriteVoxels(region,4,mat,occ) end
  stats.tiles+=1;task.wait()
 end end
 world:SetAttribute('NaturalRidgesRevision',2)
 world:SetAttribute('NaturalRidgesReport',game.HttpService:JSONEncode(stats))
 return stats
end
return M

-- Sculpt the unoccupied watershed, preserving every rounded gameplay clearance box.
local P=require(game.ReplicatedStorage.MountainShared.TerrainProfile)
local S={}
function S.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(world.Name=='ImpossibleMountain' and world:GetAttribute('NaturalRouteRevision')==51,'Expected route51 study')
 assert(not world:GetAttribute('NaturalSurfaceRevision'),'Already sculpted')
 local protection=require(script.Parent.ArtClearance).build(world,96)
 local terrain=workspace.Terrain
 local peaks={{-240,-180,755,255,235},{245,-80,675,225,210},{-310,200,580,225,205}}
 local function target(x,z)
  local original=P.height(x,z)
  if original<=0 then return original,original end
  local h=original
  for _,p in ipairs(peaks) do
   local dx,dz=(x-p[1])/p[4],(z-p[2])/p[5]
   local r=math.sqrt(dx*dx+dz*dz)
   h=math.max(h,p[3]*(1-r^1.25))
  end
  local rise=110*(1-math.exp(-math.max(0,h-original)/110))
  local relief=math.noise(x/70,z/70,51)*24+math.noise(x/27,z/27,19)*9
  local edge=math.clamp(original/80,0,1)
  edge=edge*edge*(3-2*edge)
  return original+(rise+relief)*edge,original
 end
 local changed,protected=0,0
 for bx=-704,576,64 do for bz=-704,576,64 do
  local heights={};local low,high=1000,-32
  for x=1,16 do heights[x]={};for z=1,16 do
   local h,b=target(bx+(x-.5)*4,bz+(z-.5)*4)
   heights[x][z]={h,b};low=math.min(low,b-32,h-16);high=math.max(high,b+32,h+16)
  end end
  low=math.max(-32,math.floor(low/4)*4);high=math.min(1000,math.ceil(high/4)*4)
  if high>low and high>0 then
   local region=Region3.new(Vector3.new(bx,low,bz),Vector3.new(bx+64,high,bz+64))
   local m,o=terrain:ReadVoxels(region,4);local dirty=false
   for x=1,16 do for z=1,16 do
    local h,b=unpack(heights[x][z]);local wx,wz=bx+(x-.5)*4,bz+(z-.5)*4
    local slope=math.sqrt((target(wx+4,wz)-target(wx-4,wz))^2+(target(wx,wz+4)-target(wx,wz-4))^2)/8
    for y=1,#o[x] do
     local wy=low+(y-.5)*4
     if b>0 and wy>=math.min(h,b)-28 and wy<=math.max(h,b)+16 then
      local weight=protection.weight(Vector3.new(wx,wy,wz))
      if weight==0 then protected+=1 else
       -- Blend signed heights before voxelization, never entire occupancy volumes.
       -- This moves one surface instead of filling thick shells with fractional voxels.
       local surface=b+(h-b)*weight
       local occupancy=math.clamp((surface-(wy-2))/4,0,1)
       if math.abs(occupancy-o[x][y][z])>.001 then
        o[x][y][z]=occupancy;dirty=true;changed+=1
        if occupancy<=0 then m[x][y][z]=Enum.Material.Air
        elseif m[x][y][z]==Enum.Material.Air then
         m[x][y][z]=if wy>surface-8 and surface>760 and slope<.8 then Enum.Material.Snow elseif wy>surface-8 and surface<290 and slope<1.4 then Enum.Material.Grass else Enum.Material.Rock
        end
       end
      end
     end
    end
   end end
   if dirty then terrain:WriteVoxels(region,4,m,o) end
  end
  task.wait()
 end end
 world:SetAttribute('NaturalSurfaceRevision',51)
 return {changedCells=changed,protectedCellsSkipped=protected,scope='Sculpt outside exact gameplay clearance boxes including full mover sweeps; must compare corridor fingerprints before/after.'}
end
return S

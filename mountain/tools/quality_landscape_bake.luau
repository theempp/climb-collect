-- EDIT-TIME ONLY. Additive landscape continuation on a separately saved Review04 copy.
-- Does not rebuild the mountain or touch runtime sources/anchors/parts.
-- To reproduce Review05, invoke stages 1, 2, 3 then quality_landscape_reconcile
-- with the recorded review05-recipe-correction.json (native authoring remnants).
-- Default stage 3 is the final profile; it is idempotent on the delivered terrain.
local stage=... or 3
assert(stage==1 or stage==2 or stage==3,'Landscape stage must be 1, 2 or 3')
local easternPeak=({155,240,315})[stage]
local T=workspace.Terrain
assert(not game:GetService('RunService'):IsRunning(),'Edit-time authoring only')
assert(workspace.ImpossibleMountain:GetAttribute('FreeClimbVersion')==1,'Requires baked free-climb mountain')
assert(workspace.ImpossibleMountain:GetAttribute('MountainQualityVersion')==4,'Reconcile other mountain versions before applying')
local M=Enum.Material
local function smooth(a,b,x) local t=math.clamp((x-a)/(b-a),0,1);return t*t*(3-2*t) end
local function gaussian(x,z,cx,cz,sx,sz,h) return h*math.exp(-((x-cx)/sx)^2-((z-cz)/sz)^2) end
local function height(x,z)
 local a=math.abs(x);local d=-210-z
 local section=math.clamp(math.floor(d/200),0,5)
 local route=16+section*64+64*math.clamp((d-section*200)/120,0,1)
 local side=if x<0 then -1 else 1
 local ridge=300+38*math.sin(z*.006+side)+20*math.sin(z*.013)
 local inner=smooth(176,ridge,a)
 local outer=1-smooth(ridge,700,a)
 local start=smooth(0,if stage==1 then 160 else 40,d)
 local amplitude=95+25*math.sin(z*.009+side*2)+32*math.sin(z*.004-side)
 local sideHeight=(route-12+inner*amplitude)*outer*start
 local cap=gaussian(x,z,-130,-1570,310,175,565)+gaussian(x,z,280,-1530,180,190,easternPeak)
 local peak=gaussian(x,z,-235,-1580,125,100,125)+gaussian(x,z,185,-1650,160,110,150)
 local h=math.max(sideHeight,cap+peak)
 -- Low-frequency ridges, smaller erosion furrows; no repeated ball silhouette.
 local relief=(math.noise(x*.012,z*.009,17)*19+math.noise(x*.033,z*.026,9)*5)*inner*outer*start
 return h+relief,route
end
local r={version=1,stage=stage,changed=0,added=0,chunks={},bounds={min={3392,-64,-1840},max={4800,800,-208}},protectedCorridor={minX=3920,maxX=4272,minZ=-1412},mode='additive occupancy; existing solid material preserved'}
_G.CC_LANDSCAPE_BACKUP=_G.CC_LANDSCAPE_BACKUP or {}
for z0=-1840,-240,32 do
 local region=Region3.new(Vector3.new(3392,-64,z0),Vector3.new(4800,800,z0+32))
 local mats,occ=T:ReadVoxels(region,4)
 -- Backups are in Lua only, never saved into the DataModel.
 if not _G.CC_LANDSCAPE_BACKUP[z0] then
  _G.CC_LANDSCAPE_BACKUP[z0]={region=region,mats=mats,occ=occ}
  local nm,no={},{}
  for i=1,#mats do nm[i]={};no[i]={};for j=1,#mats[i] do nm[i][j]=table.clone(mats[i][j]);no[i][j]=table.clone(occ[i][j]) end end
  mats,occ=nm,no
 end
 local changed=0
 for i=1,#mats do
  local wx=3392+(i-.5)*4;local x=wx-4096
  for k=1,8 do
   local z=z0+(k-.5)*4
   if math.abs(x)>=176 or z< -1412 then
    local h,route=height(x,z)
    for j=1,#mats[i] do
     local y=-64+(j-.5)*4
     local target=math.floor(math.clamp((h-y+2)/4,0,1)*256)/256
     if target>occ[i][j][k]+1e-6 then
      local old=occ[i][j][k];occ[i][j][k]=target
      if old==0 then
       local snow=math.max(360,route+78)+math.noise(x*.012,z*.012,5)*24
       local material=M.Rock
       if y>snow then material=M.Snow
       elseif z> -650 and y>h-12 then material=M.Grass
       elseif z> -900 and z<=-650 and y>h-9 then material=M.Sandstone
       elseif z< -1000 and z> -1270 then material=M.Basalt end
       mats[i][j][k]=material
      end
      changed+=1;r.added+=target-old
     end
    end
   end
  end
 end
 if changed>0 then T:WriteVoxels(region,4,mats,occ) end
 r.changed+=changed;table.insert(r.chunks,{z=z0,changed=changed})
 task.wait()
end
workspace.ImpossibleMountain:SetAttribute('LandscapeContinuationVersion',r.version)
workspace.ImpossibleMountain:SetAttribute('LandscapeContinuationBounds','x3392..4800 y-64..800 z-1840..-208; x3920..4272 excluded north of z-1412; additive only')
return r

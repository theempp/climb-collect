-- Apply after build-environment.luau. Correct primitive bough orientation and replace
-- preliminary wedge massifs with a reproducible smooth terrain heightfield.
local env=workspace.MountainEmpire_Step1.AlpineEnvironment_Step3
for _,m in env:GetChildren() do if m.Name:match('^AlpineMassif_') then m:Destroy() end end
-- Bough correction is performed exactly once, tracked on the environment.
if not env:GetAttribute('BoughsCorrected') then
 for _,p in env:GetDescendants() do if p.Name=='PineBough' then p.CFrame*=CFrame.Angles(0,math.pi/2,0) end end
 env:SetAttribute('BoughsCorrected',true)
end
local terrain=workspace.Terrain
terrain:SetMaterialColor(Enum.Material.Rock,Color3.fromRGB(117,132,135))
terrain:SetMaterialColor(Enum.Material.Grass,Color3.fromRGB(84,126,77))
terrain:SetMaterialColor(Enum.Material.Snow,Color3.fromRGB(229,239,237))
local peaks={{-860,-570,230,220,250},{-605,-665,345,235,270},{-350,-705,430,235,280},{-115,-610,300,190,230},{80,-790,570,245,300},{340,-710,450,235,290},{620,-640,335,230,280},{860,-570,240,200,230}}
local function height(x,z)
 local h=0
 for _,v in peaks do local dx=(x-v[1])/v[4] local dz=(z-v[2])/v[5] h=math.max(h,v[3]*math.exp(-1.65*(dx*dx+dz*dz))) end
 local fade=math.clamp((-z-232)/130,0,1)*math.clamp((1080-math.abs(x))/150,0,1)*math.clamp((z+1200)/160,0,1)
 local n=math.noise(x/155,z/155,3)*27+math.noise(x/53,z/53,9)*13+math.noise(x/19,z/19,15)*3
 return math.max(0,(h+n+24)*fade)
end
local chunks=0
for x0=-1088,1024,64 do
 for z0=-1216,-256,64 do
  local heights={} local maxH=0
  for ix=1,16 do heights[ix]={} for iz=1,16 do local h=height(x0+(ix-.5)*4,z0+(iz-.5)*4) heights[ix][iz]=h maxH=math.max(maxH,h) end end
  local ny=math.ceil((maxH+8)/4)
  local materials,occupancy={},{}
  for ix=1,16 do materials[ix]={} occupancy[ix]={}
   for iy=1,ny do materials[ix][iy]={} occupancy[ix][iy]={}
    for iz=1,16 do
     local h=heights[ix][iz] local y=-8+(iy-.5)*4 local x=x0+(ix-.5)*4 local z=z0+(iz-.5)*4
     local snowline=285+math.noise(x/90,z/90,7)*37
     local slope=math.abs(height(x+4,z)-height(x-4,z))+math.abs(height(x,z+4)-height(x,z-4))
     local mat=(y>snowline and slope<19) and Enum.Material.Snow or (y<125 and slope<7 and Enum.Material.Grass or Enum.Material.Rock)
     materials[ix][iy][iz]=mat occupancy[ix][iy][iz]=math.clamp((h-y)/4+.5,0,1)
    end
   end
  end
  terrain:WriteVoxels(Region3.new(Vector3.new(x0,-8,z0),Vector3.new(x0+64,-8+ny*4,z0+64)),4,materials,occupancy)
  chunks+=1 task.wait()
 end
end
env:SetAttribute('SculptedVista',true)
return {terrainChunks=chunks,frontLimitZ=-192,protectedGroundUntouched=true}

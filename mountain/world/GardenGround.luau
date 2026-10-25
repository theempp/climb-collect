-- Grounded planting and a worn garden path outside the combat floor.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local G={}
function G.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:FindFirstChild('GardenGround'),'Already built')
 local root=Instance.new('Folder');root.Name='GardenGround';root.Parent=world
 local q=C.route(1,.875);local center=world['Blossom Gardens'].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
 local function part(name,size,pos,color,material,shape,rot)
  return A.part(root,name,size,frame*CFrame.new(pos)*(rot or CFrame.identity),color,material,shape)
 end
 -- Staggered limestone flags lead to the arch. Uneven joints retain visible earth.
 for row=0,6 do for column=0,1 do
  local x=(column-.5)*6.1+math.sin(row*2.1)*.45;local z=56+row*4.3
  part('WornGardenFlag',Vector3.new(5.5,.18,3.8),Vector3.new(x,-.31,z),Color3.fromRGB(176+row%3*4,176+row%3*3,150),Enum.Material.Limestone,nil,CFrame.Angles(0,(row%3-1)*.035,0))
 end end
 for _,side in ipairs({-1,1}) do
  local base=Vector3.new(side*30,-.48,58)
  part('RootBed',Vector3.new(16,.4,14),base,Color3.fromRGB(77,87,62),Enum.Material.Ground,Enum.PartType.Ball)
  -- Roots emerge from each actual trunk and sink into its planting bed.
  for j=1,5 do
   local a=j*1.25+side*.4;local mid=base+Vector3.new(math.cos(a)*3,.8,math.sin(a)*3)
   local tip=base+Vector3.new(math.cos(a)*7,-.05,math.sin(a)*6)
   A.link(root,'ExposedRoot',frame:PointToWorldSpace(base+Vector3.new(0,1.6,0)),frame:PointToWorldSpace(mid),1.4,Color3.fromRGB(94,78,66),Enum.Material.Wood)
   A.link(root,'RootTip',frame:PointToWorldSpace(mid),frame:PointToWorldSpace(tip),.7,Color3.fromRGB(94,78,66),Enum.Material.Wood)
  end
  for j=1,12 do
   local a=j*2.399;local pos=base+Vector3.new(math.cos(a)*(4+j%3),.35,math.sin(a)*(4+j%2))
   local tip=pos+Vector3.new(math.sin(a)*.3,1.2+j%3*.28,0)
   A.link(root,'FlowerStem',frame:PointToWorldSpace(pos),frame:PointToWorldSpace(tip),.1,Color3.fromRGB(67,101,62),Enum.Material.Grass)
   for petal=1,5 do
    local angle=petal*math.pi*.4
    part('GroundBlossom',Vector3.new(.7,.15,.38),tip+Vector3.new(math.cos(angle)*.3,0,math.sin(angle)*.3),Color3.fromRGB(236,182+j%3*12,200),Enum.Material.SmoothPlastic,Enum.PartType.Ball,CFrame.Angles(.1,-angle,0))
   end
   part('BlossomCenter',Vector3.new(.2,.18,.2),tip+Vector3.new(0,.08,0),Color3.fromRGB(230,204,123),Enum.Material.SmoothPlastic,Enum.PartType.Ball)
  end
 end
 root:SetAttribute('Revision',1)
 local sign=world.Interactions[C.guardians[1].name]:FindFirstChild('Label')
 if sign then sign.TextLabel.Text="Sovereign's Garden" end
 return #root:GetDescendants()
end
return G

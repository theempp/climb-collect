local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local H={}
function H.dress(world)
 local A=require(script.Parent.Art)
 local root=world.HeroFalls
 assert(not root:FindFirstChild('ConnectedWaterGarden'),'Dressing already applied')
 local garden=Instance.new('Folder');garden.Name='ConnectedWaterGarden';garden.Parent=root
 local center=world['Azure Falls'].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local q=C.route(2,.875);local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
 for _,p in ipairs(world.EnvironmentFinish.azure:GetChildren()) do
  if p.Name=='FoamPool' or p.Name=='HangingFern' then
   local cf=frame:ToObjectSpace(p.CFrame);local pos=cf.Position
   p.CFrame=frame*CFrame.new(pos.X,pos.Y,if p.Name=='FoamPool' then 58 else 59.6)*cf.Rotation
  end
 end
 for _,spec in ipairs({{-19,55,12},{1,39,8},{20,29,6}}) do
  local x,h,w=table.unpack(spec)
  local backing=game.ServerStorage.MountainArtAssets.WaterfallCliff:Clone()
  backing.Name='TributaryRock';backing.Size=Vector3.new(w+14,h+6,24)
  backing.CFrame=frame*CFrame.new(x,h/2+1,72);backing.Anchored=true
  backing.CanCollide=false;backing.CanQuery=false;backing.CanTouch=false;backing.Parent=garden
  -- Every hanging row has a continuous stem attached to a wet source ledge.
  A.part(garden,'WaterSourceLedge',Vector3.new(w+8,2.4,8),frame*CFrame.new(x,h+1,62),Color3.fromRGB(109,130,131),Enum.Material.Slate)
  A.part(garden,'Headwater',Vector3.new(w,.22,6),frame*CFrame.new(x,h+2.25,61),Color3.fromRGB(153,201,204),Enum.Material.Glass)
  for _,side in ipairs({-1,1}) do
   A.link(garden,'FernStem',frame:PointToWorldSpace(Vector3.new(x+side*(w/2+2),h+1,59.6)),frame:PointToWorldSpace(Vector3.new(x+side*(w/2+2),h-19,59.6)),.3,Color3.fromRGB(65,91,64),Enum.Material.Wood)
  end
 end
 root:SetAttribute('DressingRevision',2)
end
function H.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:FindFirstChild('HeroFalls'),'Already built')
 local template=game.ServerStorage.MountainArtAssets:FindFirstChild('WaterfallCliff')
 assert(template and template:IsA('MeshPart'),'Generated cliff template missing')
 local root=Instance.new('Folder');root.Name='HeroFalls';root.Parent=world
 local archive=Instance.new('Folder');archive.Name='HeroFallsPrior';archive.Parent=game.ServerStorage
 local center=world['Azure Falls'].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local q=C.route(2,.875);local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
 local cliff=template:Clone()
 cliff.Name='CarvedWaterfallCliff';cliff.Size*=1.3;cliff.CFrame=frame*CFrame.new(0,cliff.Size.Y/2-2,84)
 cliff.Anchored=true;cliff.CanCollide=false;cliff.CanQuery=false;cliff.CanTouch=false;cliff.Color=Color3.fromRGB(176,196,203);cliff.Parent=root
 for _,p in ipairs(world.EnvironmentFinish.azure:GetChildren()) do
  if p.Name=='JointedOutcrop' then p.Parent=archive
  elseif p.Name=='SilkenWaterfall' or p.Name=='WaterThread' then
   local cf=frame:ToObjectSpace(p.CFrame);local pos=cf.Position
   p.CFrame=frame*CFrame.new(pos.X,pos.Y,if p.Name=='WaterThread' then 58.3 else 59)
   if p.Name=='SilkenWaterfall' then
    local a=Instance.new('Attachment');a.Name='FoamMist';a.Position=Vector3.new(0,-p.Size.Y/2,0);a.Parent=p
    local mist=Instance.new('ParticleEmitter');mist.Name='WaterfallMist';mist.Texture='rbxasset://textures/particles/smoke_main.dds'
    mist.Rate=5;mist.Lifetime=NumberRange.new(1.2,2);mist.Speed=NumberRange.new(.5,1.8);mist.SpreadAngle=Vector2.new(35,35)
    mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,7)})
    mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.8),NumberSequenceKeypoint.new(.35,.88),NumberSequenceKeypoint.new(1,1)})
    mist.Color=ColorSequence.new(Color3.fromRGB(218,241,240));mist.LightInfluence=.6;mist.Parent=a
   end
  end
 end
 H.dress(world)
 root:SetAttribute('Revision',2)
 return #root:GetDescendants()
end
return H

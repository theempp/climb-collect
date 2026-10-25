local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local H={}
function H.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:FindFirstChild('HeroGarden'),'Already built')
 local template=game.ServerStorage.MountainArtAssets.BlossomTreeTrunk
 local root=Instance.new('Folder');root.Name='HeroGarden';root.Parent=world
 local prior=Instance.new('Folder');prior.Name='HeroGardenPrior';prior.Parent=game.ServerStorage
 for _,p in ipairs(world.EnvironmentComposition.blossom:GetChildren()) do
  if p.Name=='LivingGardenArch' or p.Name=='BlossomCanopy' then p.Parent=prior end
 end
 local q=C.route(1,.875);local center=world['Blossom Gardens'].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
 for _,side in ipairs({-1,1}) do
  local tree=Instance.new('Model');tree.Name='SovereignBlossomTree';tree.Parent=root
  local base=frame*CFrame.new(side*30,-1,58)*CFrame.Angles(0,side*.45,0)
  local trunk=template:Clone();trunk.Name='SculptedTrunk';trunk.Size=Vector3.new(template.Size.X*.52,template.Size.Y*1.65,template.Size.Z*.52)
  trunk.CFrame=base*CFrame.new(0,trunk.Size.Y/2,0);trunk.Anchored=true;trunk.CanCollide=false;trunk.CanQuery=false;trunk.CanTouch=false;trunk.Parent=tree
  local branchEnds={Vector3.new(-8,23,-1),Vector3.new(7,28,2),Vector3.new(0,30,-7)}
  for ci,endpoint in ipairs(branchEnds) do
   local start=base:PointToWorldSpace(Vector3.new(0,18,0));local finish=base:PointToWorldSpace(endpoint)
   A.part(tree,'Branch',Vector3.new((finish-start).Magnitude,1.2-ci*.15,1.2-ci*.15),CFrame.lookAt((start+finish)/2,finish)*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(99,77,69),Enum.Material.Wood,Enum.PartType.Cylinder)
   -- Round, irregular flower clusters, with overlapping lobe sizes and depths.
   for j=0,10 do
    local a=j*2.399+ci*.4;local spread=if j==0 then 0 else 5+2*math.sin(j*1.7)
    local pos=base:PointToWorldSpace(endpoint+Vector3.new(math.cos(a)*spread,math.sin(j*1.3)*3,math.sin(a)*spread))
    local size=7.6+(j%3)*1.2
    local color=Color3.fromRGB(202,128,163):Lerp(Color3.fromRGB(250,215,221),(j%5)*.17)
    A.part(tree,'BlossomCluster',Vector3.new(size,size*.82,size*.93),CFrame.new(pos)*CFrame.Angles(.2,a,.12),color,Enum.Material.Grass,Enum.PartType.Ball)
    if j%2==0 then
     A.part(tree,'LeafCluster',Vector3.new(size*.62,2.2,size*.7),CFrame.new(pos-Vector3.new(0,3,0))*CFrame.Angles(.2,a,.15),Color3.fromRGB(92,130,91),Enum.Material.Grass,Enum.PartType.Ball)
    end
   end
  end
 end
 root:SetAttribute('Revision',1)
 return #root:GetDescendants()
end
return H

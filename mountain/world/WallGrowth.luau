-- Terrain-following ivy ribbons above the lower trails.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local G={}
function G.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(not world:FindFirstChild('WallGrowth'),'Already applied')
 local root=Instance.new('Folder');root.Name='WallGrowth';root.Parent=world
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={workspace.Terrain}
 local count=0
 for ki=1,2 do
  for j=1,16 do
   local q=C.route(ki,(j-.5)/16);local phase=j*2.399
   local out=Vector3.new(math.cos(q.angle),0,math.sin(q.angle));local tangent=Vector3.new(-out.Z,0,out.X)
   local prior
   for step=0,12 do
    local y=q.y+28+step*2.2;local drift=tangent*math.sin(step*.4+phase)*1.6
    local hit=workspace:Raycast(out*700+Vector3.new(0,y,0)+drift,-out*690,rays)
    if hit and hit.Normal.Y<.6 then
     local p=hit.Position+hit.Normal*.35
     if prior and (p-prior).Magnitude<6 then
      A.link(root,'ClingingStem',prior,p,.18,Color3.fromRGB(75,86,55),Enum.Material.Wood)
      for _,side in ipairs({-1,1}) do
       local endP=p+tangent*side*(1.8+math.sin(step*.7)*.5)+Vector3.new(0,.7,0)
       A.part(root,'IvyLeaf',Vector3.new(1.2,.20,(endP-p).Magnitude*1.6),CFrame.lookAt((p+endP)/2,endP),Color3.fromRGB(70+step%3*8,107+step%4*6,62+ki*8),Enum.Material.Grass,Enum.PartType.Ball)
      end
      count+=1
     end
     prior=p
    else prior=nil end
   end
   task.wait()
  end
 end
 root:SetAttribute('Revision',1);root:SetAttribute('RootedSegments',count);return {segments=count}
end
return G

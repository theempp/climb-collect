-- Authored planted margins; center approaches and combat boundary stay readable.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local G={}
function G.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(not world:FindFirstChild('ShelfGardens'),'Already built')
 local root=Instance.new('Folder');root.Name='ShelfGardens';root.Parent=world
 local crown=game.ServerStorage.MountainArtAssets.BlossomCanopyTemplate:FindFirstChild('crown_geom',true)
 local rng=Random.new(240922);local count=0
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={world.EnvironmentFinish}
 for ki,k in ipairs(C.kingdoms) do
  local group=Instance.new('Folder');group.Name=k.id;group.Parent=root
  local q=C.route(ki,.875);local center=world[k.name].ArenaFloor.Position+Vector3.new(0,2.5,0)
  local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
  local stone=A.color(k.rock);local leaf=A.color(k.color);local accent=A.color(k.accent)
  -- Surface treatment matches each landmark, keeping the exact support shape.
  for _,p in ipairs(world.EnvironmentFinish[k.id]:GetChildren()) do
   if p.Name=='BackdropWalkSurface' then
    p.Color=if ki==1 then Color3.fromRGB(139,157,106) elseif ki==2 then Color3.fromRGB(124,151,143) else stone:Lerp(Color3.fromRGB(202,199,178),.23)
   end
  end
  for _,spec in ipairs({{-37,49},{-33,68},{-22,77},{-13,83},{15,82},{26,74},{35,61},{39,48}}) do
   local x,z=spec[1],spec[2];local pos=frame:PointToWorldSpace(Vector3.new(x,0,z))
   local hit=workspace:Raycast(pos+Vector3.new(0,8,0),Vector3.new(0,-16,0),rays)
   if hit then
    pos=hit.Position
    -- Low soil/stone islands interrupt the straight fascia, but never project
    -- a walkable-looking cap beyond the actual support found above.
    A.part(group,'PlantingPocket',Vector3.new(7,.22,5),CFrame.new(pos-Vector3.new(0,.06,0))*CFrame.Angles(0,rng:NextNumber(0,6),0),stone:Lerp(Color3.fromRGB(55,64,47),.35),Enum.Material.Ground,Enum.PartType.Ball)
    for stem=1,5 do
     local a=stem*2.4;local base=pos+Vector3.new(math.cos(a)*1.7,0,math.sin(a)*1.4)
     if ki==1 then
      local tip=base+Vector3.new(math.cos(a)*1.2,2.5+stem%3,math.sin(a)*1.2)
      A.link(group,'ShrubStem',base,tip,.15,Color3.fromRGB(100,82,66),Enum.Material.Wood)
      local p=crown:Clone();p.Name='FloweringSpray';p.Size=Vector3.new(3.4,2.2,2.7);p.CFrame=CFrame.new(tip)*CFrame.Angles(0,a,.2);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=group
     elseif ki==2 or ki==3 then
      local h=if ki==2 then 3.5 else 2.7
      local tip=base+Vector3.new(math.cos(a)*2,h,math.sin(a)*2)
      A.link(group,'FernRachis',base,tip,.12,leaf:Lerp(Color3.fromRGB(36,74,49),.65),Enum.Material.Grass)
      for pair=1,5 do for _,side in ipairs({-1,1}) do
       local along=base:Lerp(tip,pair/6)
       local right=Vector3.new(-math.sin(a),0,math.cos(a))*side
       local endP=along+right*(1.1-pair*.12)+Vector3.new(math.cos(a)*.4,.25,math.sin(a)*.4)
       A.part(group,'Leaflet',Vector3.new(.35,.10,(endP-along).Magnitude*1.8),CFrame.lookAt((along+endP)/2,endP),leaf:Lerp(Color3.fromRGB(73,113,69),.5),Enum.Material.Grass,Enum.PartType.Ball)
      end end
     elseif ki==5 then
      local tip=base+Vector3.new(math.cos(a)*.8,2+stem%3,math.sin(a)*.8)
      A.link(group,'CharredHeather',base,tip,.22,Color3.fromRGB(64,56,58),Enum.Material.Wood)
      for twig=1,3 do A.link(group,'HeatherTwig',base:Lerp(tip,.3+twig*.15),tip+Vector3.new(math.sin(a+twig)*.8,-.5,math.cos(a+twig)*.8),.10,Color3.fromRGB(99,72,62),Enum.Material.Wood) end
     else
      local h=1.5+stem%3*.8;local p=Instance.new('WedgePart');p.Name='MineralGrowth';p.Size=Vector3.new(.6,h,.8);p.CFrame=CFrame.new(base+Vector3.new(0,h*.4,0))*CFrame.Angles(.15,a,.25);p.Color=accent:Lerp(stone,.35);p.Material=Enum.Material.Slate;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=group
     end
    end
    count+=1
   end
  end
  task.wait()
 end
 root:SetAttribute('Revision',1);root:SetAttribute('RootedPockets',count)
 return {pockets=count,parts=#root:GetDescendants()}
end
return G

-- Small composed groves on measured terrain shoulders, outside traversal envelopes.
local A=require(script.Parent.Art)
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local G={}
function G.apply(world)
 assert(game.PlaceId==0 and not game:GetService('RunService'):IsRunning(),'Local Edit only')
 assert(not world:FindFirstChild('SlopeGroves'),'Already built')
 local root=Instance.new('Folder');root.Name='SlopeGroves';root.Parent=world
 local crown=game.ServerStorage.MountainArtAssets.BlossomCanopyTemplate:FindFirstChild('crown_geom',true)
 local protected={}
 for _,p in ipairs(world:GetDescendants()) do if p:IsA('BasePart') and (p.CanCollide or p:FindFirstChildOfClass('ProximityPrompt')) then table.insert(protected,p) end end
 local function clear(pos,h,r)
  for _,p in ipairs(protected) do
   local localPos=p.CFrame:PointToObjectSpace(pos+Vector3.new(0,h/2,0));local e=p.Size/2
   if math.abs(localPos.X)<e.X+r+5 and math.abs(localPos.Z)<e.Z+r+5 and math.abs(localPos.Y)<e.Y+h/2+10 then return false end
  end
  return true
 end
 local rays=RaycastParams.new();rays.FilterType=Enum.RaycastFilterType.Include;rays.FilterDescendantsInstances={workspace.Terrain}
 local rng=Random.new(232424);local stats={trees=0,rejected=0}
 for ki=1,2 do
  local group=Instance.new('Folder');group.Name=C.kingdoms[ki].id;group.Parent=root
  for _,t in ipairs({.045,.13,.25,.38,.48,.61,.72,.81,.94}) do for j=1,4 do
   local q=C.route(ki,t+(j-2)*.008);local out=Vector3.new(math.cos(q.angle),0,math.sin(q.angle))
   local target=Vector3.new(q.x,q.y,q.z)-out*(24+j*9)
   local hit=workspace:Raycast(Vector3.new(target.X,1000,target.Z),Vector3.new(0,-1010,0),rays)
   local h=rng:NextNumber(12,25);local r=if ki==1 then 7 else 8
   if hit and hit.Normal.Y>.60 and hit.Position.Y<310 and clear(hit.Position,h+8,r) then
    local base=hit.Position-Vector3.new(0,.5,0);local tree=Instance.new('Model');tree.Name='ShoulderTree'
    local bend=Vector3.new(rng:NextNumber(-2,2),0,rng:NextNumber(-2,2));local mid=base+Vector3.new(0,h*.55,0)+bend*.4;local top=base+Vector3.new(0,h,0)+bend
    for _,s in ipairs({{base,mid,1.5},{mid,top,.85}}) do A.part(tree,'GrowingTrunk',Vector3.new((s[2]-s[1]).Magnitude,s[3],s[3]),CFrame.lookAt((s[1]+s[2])/2,s[2])*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(98,82,68),Enum.Material.Wood,Enum.PartType.Cylinder) end
    for b=1,5 do
     local a=b*2.399;local endP=top+Vector3.new(math.cos(a)*4,-2+b%3,math.sin(a)*4)
     A.link(tree,'GrowingBranch',mid:Lerp(top,.5),endP,.32,Color3.fromRGB(98,82,68),Enum.Material.Wood)
     if ki==1 then
      for spray=1,2 do
       local p=crown:Clone();p.Name='BlossomSpray';p.Size=Vector3.new(7,5.2,6)*rng:NextNumber(.8,1.1);p.CFrame=CFrame.new(endP+Vector3.new(math.cos(a+spray)*2,spray-1,math.sin(a+spray)*2))*CFrame.Angles(.2,a+spray,.3);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=tree
      end
     else
      for leaf=1,6 do
       local u=leaf/6;local pos=top:Lerp(endP,u)+Vector3.new(math.cos(a)*u*3,math.sin(u*math.pi)*1.5,math.sin(a)*u*3)
       for _,side in ipairs({-1,1}) do
        local endLeaf=pos+Vector3.new(-math.sin(a)*side*(3-u),-.4,math.cos(a)*side*(3-u))
        A.part(tree,'FernLeaf',Vector3.new(.75,.14,(endLeaf-pos).Magnitude*1.8),CFrame.lookAt((pos+endLeaf)/2,endLeaf),Color3.fromRGB(63+leaf*3,106+leaf*4,74+leaf*2),Enum.Material.Grass,Enum.PartType.Ball)
       end
      end
     end
    end
    tree.Parent=group;stats.trees+=1
   else stats.rejected+=1 end
  end end
  task.wait()
 end
 root:SetAttribute('Revision',1);root:SetAttribute('Report',game.HttpService:JSONEncode(stats));return stats
end
return G

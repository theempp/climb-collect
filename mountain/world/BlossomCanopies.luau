-- Optional baked replacement for the rounded draft crowns, using reviewed mesh assets.
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local B={}
function B.apply(world)
 assert(not game:GetService('RunService'):IsRunning() and game.PlaceId==0,'Local Edit only')
 assert(not world:FindFirstChild('BlossomCanopies'),'Already built')
 local template=game.ServerStorage.MountainArtAssets:FindFirstChild('BlossomCanopyTemplate')
 assert(template and template:IsA('Model'),'Reviewed canopy template required')
 local sources={}
 for _,p in ipairs(template:GetDescendants()) do if p:IsA('MeshPart') and p.Name=='crown_geom' then table.insert(sources,p) end end
 assert(#sources>0,'No canopy meshes')
 local sourceBox=sources[1].CFrame
 local root=Instance.new('Folder');root.Name='BlossomCanopies';root.Parent=world
 local archive=Instance.new('Folder');archive.Name='RoundedGardenCrownsPrior';archive.Parent=game.ServerStorage
 local q=C.route(1,.875);local center=world['Blossom Gardens'].ArenaFloor.Position+Vector3.new(0,2.5,0)
 local frame=CFrame.lookAt(center,center-Vector3.new(math.cos(q.angle),0,math.sin(q.angle)))
 for _,tree in ipairs(world.HeroGarden:GetChildren()) do
  for _,p in ipairs(tree:GetChildren()) do
   if p.Name=='BlossomCluster' or p.Name=='LeafCluster' then p.Parent=archive end
  end
 end
 for _,side in ipairs({-1,1}) do
  for ci,offset in ipairs({Vector3.new(-7,27,-1),Vector3.new(6,30,3),Vector3.new(0,32,-6)}) do
  for spray=0,5 do
  local a=spray*2.399+ci
  local drift=if spray==0 then Vector3.zero else Vector3.new(math.cos(a)*4,math.sin(a*1.3)*2,math.sin(a)*4)
  local target=frame*CFrame.new(Vector3.new(side*30,0,58)+offset+drift)*CFrame.Angles(.3*math.sin(a),a,side*.2)
  local scale=if side==1 then .72 else .66
  for _,source in ipairs(sources) do
   local p=source:Clone();p.Name='BlossomCrownMesh'
   local offset=sourceBox:ToObjectSpace(source.CFrame)
   p.Size*=scale;p.CFrame=target*CFrame.new(offset.Position*scale)*offset.Rotation
   p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Parent=root
  end
  end
  end
 end
 root:SetAttribute('Revision',1)
 return #root:GetChildren()
end
return B

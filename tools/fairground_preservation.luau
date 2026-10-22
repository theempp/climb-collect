return function(label)
 local H=game.HttpService;local out={}
 local paths={['Workspace.World.Routes']=workspace.World.Routes,['Workspace.World.Checkpoints']=workspace.World.Checkpoints,['ServerStorage.CC_Creatures']=game.ServerStorage.CC_Creatures,['Workspace.CC_CreatureStage1']=workspace.CC_CreatureStage1,['ReplicatedStorage.CC_Route']=game.ReplicatedStorage.CC_Route,['ReplicatedStorage.CC_Track']=game.ReplicatedStorage.CC_Track}
 local props={'Name','ClassName','CFrame','Size','Color','Material','Transparency','Reflectance','CanCollide','CanTouch','CanQuery','Anchored','Massless','CollisionGroup','MeshId','TextureID','TextureId','MeshType','Scale','Offset','Value','Source','Disabled','ColorMap','MetalnessMap','NormalMap','RoughnessMap','AnimationId','Texture','Brightness','Range','Face','Text','Visible','Attachment0','Attachment1','Part0','Part1','C0','C1'}
 for path,root in paths do
  local list={};local all={root};for _,v in root:GetDescendants() do table.insert(all,v) end
  for _,v in all do
   local row={path=v:GetFullName(),properties={},attributes={},tags=v:GetTags()};table.sort(row.tags)
   for _,k in props do local ok,value=pcall(function()return v[k]end);if ok then row.properties[k]=typeof(value)=='Instance' and value:GetFullName() or tostring(value) end end
   for k,value in v:GetAttributes() do row.attributes[k]=tostring(value) end
   table.insert(list,row)
  end
  out[path]=list
 end
 local defs={};for _,v in game.ReplicatedStorage.CC_TraversalDefs:GetChildren() do if not v.Name:match('^Practice:') then defs[v.Name]=v.Value end end;out.mountainTraversal=defs
 local was=H.HttpEnabled;H.HttpEnabled=true
 local ok,err=pcall(function()
  local manifest={};local batch=0
  for path,list in out do
   if path=='mountainTraversal' then
    batch+=1;local file=label..'-'..batch;H:PostAsync('http://127.0.0.1:8772/'..file..'.json',H:JSONEncode({[path]=list}));table.insert(manifest,file)
   else
    for first=1,#list,250 do
     local rows={};for i=first,math.min(first+249,#list) do table.insert(rows,list[i]) end
     batch+=1;local file=label..'-'..batch;H:PostAsync('http://127.0.0.1:8772/'..file..'.json',H:JSONEncode({[path]=rows}));table.insert(manifest,file)
    end
   end
  end
  H:PostAsync('http://127.0.0.1:8772/'..label..'.json',H:JSONEncode({parts=manifest}))
 end);H.HttpEnabled=was;assert(ok,err)
 local counts={};for k,list in out do local n=0;for _ in list do n+=1 end;counts[k]=n end;return counts
end

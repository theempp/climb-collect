-- One-time rigid migration of the existing course AND only its three authored sections.
return function(oldGate)
 local yard=workspace.World.TrainingYard
 assert(not yard:GetAttribute('FairgroundMigrated'),'course already migrated')
 local target=CFrame.new(-72,53,2016)*CFrame.Angles(0,math.rad(90),0)
 local transform=target*oldGate:Inverse()
 local H=game.HttpService
 local function a(v) return {v.X,v.Y,v.Z} end
 local function point(p) return a(transform*Vector3.new(table.unpack(p))) end
 for _,s in game.ReplicatedStorage.CC_TraversalDefs:GetChildren() do
  if s.Name:match('^Practice:') then
   local d=H:JSONDecode(s.Value);d.entry=point(d.entry);d.exit=point(d.exit);d.into=a(transform:VectorToWorldSpace(Vector3.new(table.unpack(d.into))))
   for _,h in d.holds do h.p=point(h.p);if h.alternative then h.alternative.p=point(h.alternative.p) end end
   s.Value=H:JSONEncode(d)
  end
 end
 yard:SetAttribute('FairgroundMigrated',true)
 return true
end

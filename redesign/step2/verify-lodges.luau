local root=workspace.MountainEmpire_Step1
local report={lodges={},unchangedLayoutParts=0,errors={},scriptCount=0,parts=0,anchored=true,placeId=game.PlaceId,maxPlayers=game.Players.MaxPlayers}
for p,b in _G.Step2Baseline do
 assert(p.Parent and p.CFrame==b[1] and p.Size==b[2] and p.Color==b[3] and p.Material==b[4] and p.CanCollide==b[5] and p.Transparency==b[6],p:GetFullName().." changed")
 report.unchangedLayoutParts+=1
end
for _,v in game:GetDescendants() do if v:IsA("LuaSourceContainer") then report.scriptCount+=1 end end
local ray=RaycastParams.new() ray.RespectCanCollide=true
local overlap=OverlapParams.new() overlap.RespectCanCollide=true
local centers={-658,-470,-282,-94,94,282,470,658}
for i,cx in centers do
 local plot=root.SanctuaryPlots:FindFirstChild(string.format("Plot_%02d",i))
 assert(plot.Plot_180x220.Size==Vector3.new(180,2,220))
 assert(plot.Plot_180x220.Position==Vector3.new(cx,-1,110))
 local m=root.EnchantedAlpineLodges:FindFirstChild(string.format("Lodge_%02d",i))
 local bounds=0
 local n=0
 for _,p in m:GetDescendants() do if p:IsA("BasePart") then
  n+=1
  for _,x in {-1,1} do for _,y in {-1,1} do for _,z in {-1,1} do
   local q=p.CFrame:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)
   assert(math.abs(q.X-cx)<=17.5+.001 and q.Z>=185-.001 and q.Z<=215+.001,p.Name.." footprint")
   bounds+=1
  end end end
 end end
 -- Avatar-sized clearance boxes cover approach, porch, doorway and interior.
 local clear=0
 for z=180,209 do
  local hits=workspace:GetPartBoundsInBox(CFrame.new(cx,4.3,z),Vector3.new(4,5.8,.7),overlap)
  assert(#hits==0,"Entrance blocked at "..i.."/"..z)
  local hit=workspace:Raycast(Vector3.new(cx,3,z),Vector3.new(0,-5,0),ray)
  assert(hit and hit.Normal.Y>.99,"Missing walk surface "..i.."/"..z)
  clear+=1
 end
 table.insert(report.lodges,{plot=i,centerX=cx,footprintCenterZ=200,parts=n,cornerChecks=bounds,entranceSamples=clear,doorWidth=5.8,doorHeight=9})
end
local samples=0
for x=-740,740,40 do for z=-58,-2,6 do
 local hit=workspace:Raycast(Vector3.new(x,5,z),Vector3.new(0,-10,0),ray)
 assert(hit and math.abs(hit.Position.Y-.16)<.01,"Front walk surface")
 samples+=1
end end
report.frontWalkSamples=samples
for _,v in root:GetDescendants() do if v:IsA("BasePart") then report.parts+=1 report.anchored=report.anchored and v.Anchored end end
assert(report.scriptCount==0)
assert(report.anchored)
assert(#report.lodges==8)
return game.HttpService:JSONEncode(report)

local root=workspace.MountainEmpire_Step1
local report={protectedParts=0,lodges=8,plotChecks=0,entranceSamples=0,frontWalkSamples=0,courtyardSamples=0,gateSamples=0,parts=0,scripts=0,anchored=true,maxPlayers=game.Players.MaxPlayers}
for p,b in _G.Step3Protected do
 assert(p.Parent,'Protected part removed')
 for k,v in b do assert(p[k]==v,p:GetFullName()..' changed '..k) end
 report.protectedParts+=1
end
local ray=RaycastParams.new() ray.RespectCanCollide=true
local overlap=OverlapParams.new() overlap.RespectCanCollide=true
for i,cx in {-658,-470,-282,-94,94,282,470,658} do
 local plot=root.SanctuaryPlots:FindFirstChild(string.format('Plot_%02d',i)).Plot_180x220
 assert(plot.Size==Vector3.new(180,2,220) and plot.Position==Vector3.new(cx,-1,110)) report.plotChecks+=1
 local n=0 for _,p in root.EnchantedAlpineLodges:FindFirstChild(string.format('Lodge_%02d',i)):GetDescendants() do if p:IsA('BasePart') then n+=1 end end assert(n==126)
 for z=180,209 do
  assert(#workspace:GetPartBoundsInBox(CFrame.new(cx,4.3,z),Vector3.new(4,5.8,.7),overlap)==0,'Entrance obstruction')
  local h=workspace:Raycast(Vector3.new(cx,3,z),Vector3.new(0,-5,0),ray) assert(h and h.Normal.Y>.99)
  report.entranceSamples+=1
 end
 for x=cx-80,cx+80,20 do for z=10,170,20 do
  assert(#workspace:GetPartBoundsInBox(CFrame.new(x,4,z),Vector3.new(4,6,4),overlap)==0,'Courtyard obstruction')
  local h=workspace:Raycast(Vector3.new(x,3,z),Vector3.new(0,-5,0),ray) assert(h and math.abs(h.Position.Y)<.3)
  report.courtyardSamples+=1
 end end
end
for x=-740,740,20 do for z=-58,-2,4 do
 local hit=workspace:Raycast(Vector3.new(x,5,z),Vector3.new(0,-10,0),ray) assert(hit and math.abs(hit.Position.Y-.16)<.01,'Front surface changed')
 assert(#workspace:GetPartBoundsInBox(CFrame.new(x,4,z),Vector3.new(4,6,3),overlap)==0,'Front obstruction') report.frontWalkSamples+=1
end end
for _,cx in {-72,0,72} do for z=-112,-204,-4 do
 assert(#workspace:GetPartBoundsInBox(CFrame.new(cx,20,z),Vector3.new(4,6,3),overlap)==0,'Gate blocked')
 local hit=workspace:Raycast(Vector3.new(cx,19,z),Vector3.new(0,-6,0),ray) assert(hit and math.abs(hit.Position.Y-16)<.1,'Gate floor') report.gateSamples+=1
end end
for _,v in game:GetDescendants() do if v:IsA('LuaSourceContainer') then report.scripts+=1 end end
for _,v in root:GetDescendants() do if v:IsA('BasePart') then report.parts+=1 report.anchored=report.anchored and v.Anchored end end
assert(report.scripts==0 and report.anchored)
return game.HttpService:JSONEncode(report)

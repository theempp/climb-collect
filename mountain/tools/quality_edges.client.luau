-- Natural outer-route approaches, summit rear-edge cross, and downhill return.
-- No position/velocity/health grants. Existing SprintRequest only.
local player=game.Players.LocalPlayer;local hum=player.Character.Humanoid;local root=hum.RootPart
local log={};local started=os.clock();local failed=false
local function publish(done) workspace:SetAttribute('MountainQA_Edges',game.HttpService:JSONEncode({done=done,passed=done and not failed,log=log,elapsed=os.clock()-started})) end
local function walk(p,label)
 local start=os.clock();local deadline=(root.Position-p).Magnitude/10+12
 repeat hum:MoveTo(p);task.wait(.12) until Vector3.new(root.Position.X-p.X,0,root.Position.Z-p.Z).Magnitude<2.4 or os.clock()-start>deadline or hum.Health<=0
 local ok=hum.Health>0 and Vector3.new(root.Position.X-p.X,0,root.Position.Z-p.Z).Magnitude<3 and math.abs(root.Position.Y-p.Y)<6
 table.insert(log,{label=label,ok=ok,position=tostring(root.Position),target=tostring(p),seconds=os.clock()-start});failed=failed or not ok;publish(not ok);return ok
end
local function point(k,x,d) return Vector3.new(x,16+(k-1)*64+64*math.min(d/120,1)+3.1,-210-(k-1)*200-d) end
task.spawn(function()
 local ok,err=pcall(function()
  game.ReplicatedStorage.MountainRemotes.SprintRequest:FireServer(true);task.wait(.3)
  if not walk(point(1,4090,2),'entry') then return end
  if not walk(point(1,3936,2),'west outer edge approach') then return end
  for k=1,6 do for _,d in {10,40,80,116,140,176,190} do if not walk(point(k,3936,d),k..':west edge:'..d) then return end end end
  for _,x in {4000,4090,4190,4256} do if not walk(point(6,x,190),'summit rear edge:'..x) then return end end
  for k=6,1,-1 do for _,d in {190,176,140,116,80,40,10,2} do if not walk(point(k,4256,d),k..':east edge return:'..d) then return end end end
  if not walk(point(1,4090,2),'return to escape') then return end
  if not walk(Vector3.new(4090,19.1,-160),'physical exit') then return end
  game.ReplicatedStorage.MountainRemotes.SprintRequest:FireServer(false);publish(true)
 end)
 if not ok then failed=true;table.insert(log,{ok=false,error=tostring(err)});publish(true) end
end)
return 'Outer-edge traversal started'

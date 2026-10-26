local w=workspace.ImpossibleMountain;local p=game.Players.LocalPlayer
local h=p.Character:WaitForChild('Humanoid');local r=h.RootPart;local scale=w:GetAttribute('CompactScale') or 1
local result={scale=scale,steps={},done=false,memoryMB=game.Stats:GetTotalMemoryUsageMb()};_G.CompactTiming=result
task.spawn(function()
 local function go(q,label)
  local t=os.clock();repeat h:MoveTo(q);task.wait(.1) until (r.Position-q).Magnitude<6 or os.clock()-t>50
  local ok=(r.Position-q).Magnitude<6;table.insert(result.steps,{label=label,ok=ok,seconds=os.clock()-t,position=tostring(r.Position)});return ok
 end
 for _,q in {Vector3.new(3438,3,-48),Vector3.new(3738,31,-108),Vector3.new(3960,31,-166),Vector3.new(3960,31,-182),Vector3.new(3960,19,-210),Vector3.new(4096,19,-210)} do if not go(q,'approach') then result.done=true;return end end
 local start=os.clock()
 for k=1,6 do for _,d in {40,80,120,196} do
  local q=Vector3.new(4096,16+((k-1)*64+64*math.min(d/120,1))*scale+3,-210-((k-1)*200+d)*scale)
  if not go(q,'section-'..k) then result.done=true;return end
 end end
 result.climbSeconds=os.clock()-start;result.done=true;result.passed=true
end)
return 'Natural timing started'

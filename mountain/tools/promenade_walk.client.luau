-- Run through Studio Client execute_luau on a fresh Play Solo (natural spawn at plot 1).
-- Ordinary Humanoid walking, no sprint/teleports: visit each home's spawn through its front opening,
-- then home -> through the grand gate -> back home. Publishes MountainQA_PromenadeWalk.
local p=game.Players.LocalPlayer;local h=p.Character:WaitForChild('Humanoid');local rr=h.RootPart
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local log={};local start=os.clock();local failed=false;local times={}
local function publish(done) workspace:SetAttribute('MountainQA_PromenadeWalk',game.HttpService:JSONEncode({done=done,passed=done and not failed,elapsed=os.clock()-start,log=log,times=times,walkSpeed=h.WalkSpeed})) end
local function walk(x,z,label)
 local q=Vector3.new(x,L.groundY+3.1,z);local begin=os.clock();local timeout=(rr.Position-q).Magnitude/8+10
 repeat h:MoveTo(q);task.wait(.1) until Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<2.3 or os.clock()-begin>timeout or h.Health<=0
 local ok=h.Health>0 and Vector3.new(rr.Position.X-q.X,0,rr.Position.Z-q.Z).Magnitude<3 and math.abs(rr.Position.Y-q.Y)<4
 table.insert(log,{label=label,ok=ok,seconds=os.clock()-begin,position=tostring(rr.Position)});failed=failed or not ok;publish(false);return ok
end
local function route(i,outbound)
 local p=L.plots[i];local sx,sz=L.spawnWorld(i);local ox,oz=L.toWorld(i,0,-L.plotDepth/2-7)
 local lane=L.axisX+p.side*(L.channelWidth/2+L.laneWidth/2)
 local pts={{sx,sz},{ox,oz},{lane,oz},{lane,L.gate.z+L.gate.towerDepth/2+3},{L.gate.x+p.side*20,L.gate.z-24}}
 if not outbound then local r={};for k=#pts,1,-1 do table.insert(r,pts[k]) end;pts=r end
 return pts
end
task.spawn(function()
 local ok,err=pcall(function()
  local current=1
  for i=1,8 do
   -- Reach home i's spawn from where we stand (inbound legs from the gate side).
   if i>1 then for k,pt in route(i,false) do if k>1 and not walk(pt[1],pt[2],'to home '..i) then return end end end
   local t0=os.clock()
   for k,pt in route(i,true) do if k>1 and not walk(pt[1],pt[2],'home '..i..' to gate') then return end end
   local out=os.clock()-t0
   local inSanctuary=L.inSanctuary(rr.Position.X,rr.Position.Z)
   table.insert(log,{label='home '..i..' beyond gate',ok=not inSanctuary and rr.Position.Z<L.gate.z-10,position=tostring(rr.Position)});failed=failed or inSanctuary
   t0=os.clock()
   for k,pt in route(i,false) do if k>1 and not walk(pt[1],pt[2],'gate to home '..i) then return end end
   times[i]={homeToGate=out,gateToHome=os.clock()-t0}
   if i<8 then for k,pt in route(i,true) do if k>1 and k<5 and not walk(pt[1],pt[2],'leave home '..i) then return end end end
  end
  publish(true)
 end)
 if not ok then failed=true;table.insert(log,{label='probe error',ok=false,error=tostring(err)});publish(true) end
end)
return 'Eight-home promenade walk started'

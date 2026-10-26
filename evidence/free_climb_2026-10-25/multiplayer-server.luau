-- Real server cache, real clients/remotes and normal Humanoid walking; memory only.
local Players=game.Players;local ST=game:GetService('StudioTestService')
local P=require(game.ServerScriptService.MountainServer.Profiles)
local command=Instance.new('RemoteFunction');command.Name='FreeClimbQACommand';command.Parent=game.ReplicatedStorage
local result={mode=P.mode,checks=0,failures={},stages={},peak=0}
local function check(ok,label) result.checks+=1;if not ok then table.insert(result.failures,label) end;return ok end
local function call(player,action,data)
 local done=false;local ok,value
 task.spawn(function() ok,value=pcall(command.InvokeClient,command,player,action,data);done=true end)
 local deadline=os.clock()+(if action=='walk' then 85 else 20)
 repeat task.wait(.05) until done or os.clock()>deadline
 if not done then return {ok=false,message='client command timeout'} end
 if not ok then return {ok=false,message=tostring(value)} end
 return value
end
local function both(a,b,fn)
 local remaining=2;local values={}
 for i,p in ipairs({a,b}) do task.spawn(function() local ok,v=pcall(fn,p,i);values[i]=if ok then v else {ok=false,message=tostring(v)};remaining-=1 end) end
 local deadline=os.clock()+160;repeat task.wait(.1) until remaining==0 or os.clock()>deadline
 assert(remaining==0,'parallel action timeout');return values
end
local function walk(player,x,y,z) local r=call(player,'walk',Vector3.new(x,y,z));assert(r.ok,player.Name..' walk '..tostring(r.reason)..' '..tostring(r.position));return r end
local function waitPlayers(n)
 local deadline=os.clock()+120
 repeat task.wait(1);result.peak=math.max(result.peak,#Players:GetPlayers()) until #Players:GetPlayers()==n or os.clock()>deadline
 assert(#Players:GetPlayers()==n,'player launch count')
 local readyDeadline=os.clock()+90
 repeat
  local ready=true;for _,p in ipairs(Players:GetPlayers()) do if not P.get(p) or not p.Character or not p.Character:FindFirstChild('HumanoidRootPart') then ready=false end end
  if ready then break end;task.wait(1)
 until os.clock()>readyDeadline
 task.wait(6)
 local ps=Players:GetPlayers();table.sort(ps,function(a,b) return a.UserId>b.UserId end);return ps
end
local ok,err=pcall(function()
 local ps=waitPlayers(3);local a,b,bystander=ps[1],ps[2],ps[3]
 check(P.mode:find('memory')~=nil,'isolated memory store')
 for _,p in ipairs(ps) do check(call(p,'audit').hud==1,p.Name..' single HUD') end
 local walks=both(a,b,function(p,i)
  local pos=p.Character:GetPivot().Position;walk(p,4096,3,pos.Z);walk(p,4096,17,-100);walk(p,4096,20,-220)
  return walk(p,if i==1 then 4038 else 4154,84,-378)
 end)
 check(walks[1].ok and walks[2].ok,'two clients natural approach different eggs')
 local strikes=both(a,b,function(p,i) return call(p,'request',{action='Strike',payload='raid:1:'..i}) end)
 check(strikes[1].ok and strikes[2].ok,'simultaneous different eggs accepted')
 local pa,pb=P.get(a),P.get(b)
 check(pa and pb and pa.run and pb.run and pa.run.id~=pb.run.id,'distinct authoritative runs')
 local g=workspace.ImpossibleMountain.Encounters.Guardian_1;task.wait(.4)
 check(g:GetAttribute('TargetUserId')==a.UserId or g:GetAttribute('TargetUserId')==b.UserId,'shared defender selects actual raider')
 check(g:GetAttribute('TargetUserId')~=bystander.UserId,'uninvolved player excluded')
 local first=call(a,'audit');local second=call(b,'audit')
 check(first.target==second.target,'clients agree shared target')
 result.stages.firstRaid={a=a.UserId,b=b.UserId,target=g:GetAttribute('TargetUserId'),aRun=pa.run and pa.run.phase,bRun=pb.run and pb.run.phase}
 -- Leave one active threat while the other completes its real remote pickup/exit.
 check(call(a,'leave').ok,'actual client departure requested')
 for i=1,2 do task.wait(.55);check(call(b,'request',{action='Strike',payload='raid:1:2'}).ok,'remaining raider strike '..i) end
 local run=P.get(b).run;check(run and run.phase=='revealed','one reveal, no early ownership')
 check(#P.get(b).creatures==3,'revealed reward still unsecured')
 check(call(b,'request',{action='Pickup',payload=run.id}).ok,'client pickup accepted')
 walk(b,4096,84,-340);walk(b,4096,19,-166);task.wait(1)
 local owned=P.get(b)
 check(owned and #owned.creatures==4 and not owned.run and #owned.securedRunIds==1,'actual physical exit owns exactly once')
 check(P.sessions[a]==nil,'departed profile released')
 result.stages.exit={roster=owned and #owned.creatures,secured=owned and #owned.securedRunIds}
 ST:AddPlayers(6);ps=waitPlayers(8)
 local plots={};for _,p in ipairs(ps) do
  local slot=p:GetAttribute('SanctuaryPlot');check(slot and not plots[slot],p.Name..' unique late-join plot');if slot then plots[slot]=true end
  local audit=call(p,'audit');check(audit.hud==1,p.Name..' eight-client HUD')
  check(P.get(p)~=nil and p.Character.Humanoid.Health>0,p.Name..' alive profile')
 end
 check(#ps==8,'eight actual simultaneous clients')
 result.stages.capacity={players=#ps,peak=result.peak}
 -- Two late joiners contest one egg using real request remotes.
 local c,d=ps[#ps-1],ps[#ps]
 walks=both(c,d,function(p,i)
  local pos=p.Character:GetPivot().Position;walk(p,4096,3,pos.Z);walk(p,4096,17,-100);walk(p,4096,20,-220)
  return walk(p,if i==1 then 4034 else 4042,84,-378)
 end)
 assert(walks[1].ok and walks[2].ok,'contention approaches')
 strikes=both(c,d,function(p) return call(p,'request',{action='Strike',payload='raid:1:1'}) end)
 local accepted=(strikes[1].ok and 1 or 0)+(strikes[2].ok and 1 or 0)
 check(accepted==1,'same egg has exactly one actual-client winner')
 result.stages.contention={accepted=accepted,replies=strikes}
end)
if not ok then table.insert(result.failures,tostring(err)) end
result.ok=#result.failures==0
ST:EndTest(result)

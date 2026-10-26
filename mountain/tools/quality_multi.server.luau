-- Two actual local clients, real cache/remotes, natural walking, memory-only ownership.
local Players=game.Players;local ST=game:GetService('StudioTestService')
local P=require(game.ServerScriptService.MountainServer.Profiles)
local command=Instance.new('RemoteFunction');command.Name='FreeClimbQACommand';command.Parent=game.ReplicatedStorage
local result={mode=P.mode,checks=0,failures={},stages={}}
local function check(ok,label,data)
 result.checks+=1;table.insert(result.stages,{label=label,ok=ok==true,data=data});if not ok then table.insert(result.failures,label) end;return ok
end
local function call(p,action,data) return command:InvokeClient(p,action,data) end
local function both(ps,fn)
 local remain=#ps;local values={}
 for i,p in ps do task.spawn(function() local ok,r=pcall(fn,p,i);values[i]=if ok then r else {ok=false,message=tostring(r)};remain-=1 end) end
 local endAt=os.clock()+140;repeat task.wait(.1) until remain==0 or os.clock()>endAt
 assert(remain==0,'client jobs timed out');return values
end
local function walk(p,x,y,z)
 local r=call(p,'walk',Vector3.new(x,y,z));assert(r.ok,p.Name..' walk failed '..tostring(r.reason)..' '..tostring(r.position));return r
end
local ok,err=pcall(function()
 local untilTime=os.clock()+120;local ps
 repeat task.wait(1);ps=Players:GetPlayers() until #ps==2 or os.clock()>untilTime
 assert(#ps==2,'two clients started')
 repeat task.wait(1) until (P.get(ps[1]) and P.get(ps[2]) and ps[1]:GetAttribute('FreeClimbClientQAReady') and ps[2]:GetAttribute('FreeClimbClientQAReady')) or os.clock()>untilTime
 table.sort(ps,function(a,b) return a.UserId>b.UserId end)
 check(P.mode:find('memory')~=nil,'isolated memory profiles')
 local counts={};for i,p in ps do counts[i]=#P.get(p).creatures;check(call(p,'audit').hud==1,p.Name..' single HUD') end
 local approaches=both(ps,function(p,i)
  local x=p.Character:GetPivot().Position.X;local side=if x<4096 then -1 else 1
  walk(p,x,3,-48);walk(p,if side<0 then 3738 else 4454,31,-108);walk(p,4096+side*136,31,-180);walk(p,4096+side*136,19,-210)
  local lane=if i==1 then 4008 else 4184
  walk(p,lane,19,-210)
  -- Use a collision query only to choose waypoint height; movement stays physical.
  for _,d in {20,40,60,80,100,124} do
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.ImpossibleMountain['Blossom Gardens']};rp.RespectCanCollide=true
   local hit=workspace:Raycast(Vector3.new(lane,500,-210-d),Vector3.new(0,-600,0),rp);assert(hit)
   walk(p,lane,hit.Position.Y+3,-210-d)
  end
  return walk(p,if i==1 then 4038 else 4154,83,-380)
 end)
 check(approaches[1].ok and approaches[2].ok,'two clients traverse new side routes',approaches)
 local strikes=both(ps,function(p,i)return call(p,'request',{action='Strike',payload='raid:1:'..i}) end)
 check(strikes[1].ok and strikes[2].ok,'simultaneous distinct eggs accepted',strikes)
 local g=workspace.ImpossibleMountain.Encounters.Guardian_1;task.wait(.3)
 check(g:GetAttribute('TargetUserId')==ps[1].UserId or g:GetAttribute('TargetUserId')==ps[2].UserId,'shared guardian selects real raider')
 local a,b=call(ps[1],'audit'),call(ps[2],'audit');check(a.target==b.target,'clients agree shared guardian target',{a=a,b=b})
 local runs=both(ps,function(p,i)
  for _=1,2 do task.wait(.55);assert(call(p,'request',{action='Strike',payload='raid:1:'..i}).ok,'strike accepted') end
  local profile=P.get(p);assert(profile.run and profile.run.phase=='revealed','reveal');assert(#profile.creatures==counts[i],'no early ownership')
  assert(call(p,'request',{action='Pickup',payload=profile.run.id}).ok,'pickup accepted')
  local x=if i==1 then 4038 else 4154
  walk(p,x,83,-336);walk(p,if i==1 then 4088 else 4104,83,-334)
  walk(p,if i==1 then 4088 else 4104,19,-160);task.wait(1)
  local saved=P.get(p);return {ok=saved and saved.run==nil and #saved.creatures==counts[i]+1 and #saved.securedRunIds==1,roster=saved and #saved.creatures,secured=saved and #saved.securedRunIds}
 end)
 check(runs[1].ok and runs[2].ok,'both natural cargo escapes own exactly once',runs)
 task.wait(2)
 local returnWalk=both(ps,function(p,i)walk(p,if i==1 then 4088 else 4104,83,-334);return walk(p,if i==1 then 4035 else 4041,83,-382) end)
 assert(returnWalk[1].ok and returnWalk[2].ok,'contention approach')
 local contest=both(ps,function(p)return call(p,'request',{action='Strike',payload='raid:1:1'}) end)
 check((contest[1].ok and 1 or 0)+(contest[2].ok and 1 or 0)==1,'same egg has one winner',contest)
end)
if not ok then table.insert(result.failures,tostring(err)) end
result.ok=#result.failures==0;ST:EndTest(result)

-- Two actual local clients, real cache/remotes, natural walking, memory-only ownership.
local Players=game.Players;local ST=game:GetService('StudioTestService')
local P=require(game.ServerScriptService.MountainServer.Profiles)
local command=Instance.new('RemoteFunction');command.Name='FreeClimbQACommand';command.Parent=game.ReplicatedStorage
local ready=Instance.new('RemoteEvent');ready.Name='FreeClimbQAReady';ready.Parent=game.ReplicatedStorage
local clients={};ready.OnServerEvent:Connect(function(p) clients[p]=true end)
local result={mode=P.mode,checks=0,failures={},stages={},done=false,setup='Controlled fixture: characters anchored and positioned in <=12-stud steps to mountain entry, then unanchored. This respects the existing movement validator. All changed-route climbing and cargo escape then use ordinary movement/remotes. No health, inventory, speed or progression writes.'}
local function publish()
 local h=game.HttpService;h:PostAsync('http://127.0.0.1:8854/multiplayer-result.json',h:JSONEncode(result),Enum.HttpContentType.ApplicationJson)
end
publish()
local function check(ok,label,data)
 result.checks+=1;table.insert(result.stages,{label=label,ok=ok==true,data=data});if not ok then table.insert(result.failures,label) end;publish();return ok
end
local function call(p,action,data) return command:InvokeClient(p,action,data) end
local function both(ps,fn)
 local remain=#ps;local values={}
 for i,p in ps do task.spawn(function() local ok,r=pcall(fn,p,i);values[i]=if ok then r else {ok=false,message=tostring(r)};remain-=1 end) end
 local endAt=os.clock()+140;repeat task.wait(.1) until remain==0 or os.clock()>endAt
 assert(remain==0,'client jobs timed out');return values
end
local function walk(p,x,y,z)
 local r=call(p,'walk',Vector3.new(x,y,z));assert(r.ok,p.Name..' walk failed toward '..tostring(Vector3.new(x,y,z))..': '..tostring(r.reason)..' '..tostring(r.position));return r
end
local ok,err=pcall(function()
 local untilTime=os.clock()+120;local ps
 repeat task.wait(1);ps=Players:GetPlayers() until #ps==2 or os.clock()>untilTime
 assert(#ps==2,'two clients started')
 repeat task.wait(1) until (P.get(ps[1]) and P.get(ps[2]) and clients[ps[1]] and clients[ps[2]]) or os.clock()>untilTime
 assert(clients[ps[1]] and clients[ps[2]],'two QA clients ready')
 table.sort(ps,function(a,b) return a.UserId>b.UserId end)
 check(P.mode:find('memory')~=nil,'isolated memory profiles')
 local counts={};for i,p in ps do counts[i]=#P.get(p).creatures;check(call(p,'audit').hud==1,p.Name..' single HUD') end
 task.wait(3) -- Let the existing CharacterAdded home placement finish before the fixture.
 local approaches=both(ps,function(p,i)
  -- Isolate multiplayer mountain interactions from unrelated home-base approach geometry.
  local lane=if i==1 then 4008 else 4184
  call(p,'stream',Vector3.new(lane,22,-214))
  local character=p.Character;local root=character.HumanoidRootPart
  local start=root.Position;local finish=Vector3.new(lane,24,-214)
  root.Anchored=true
  local steps=math.ceil((finish-start).Magnitude/12)
  for step=1,steps do character:PivotTo(CFrame.new(start:Lerp(finish,step/steps)));task.wait(.3) end
  root.Anchored=false;root.AssemblyLinearVelocity=Vector3.zero;task.wait(1)
  walk(p,lane,21,-214)
  -- Use a collision query only to choose waypoint height; movement stays physical.
  for _,d in {20,40,60,80,100,124} do
   local rp=RaycastParams.new();rp.FilterType=Enum.RaycastFilterType.Include;rp.FilterDescendantsInstances={workspace.ImpossibleMountain['Blossom Gardens']};rp.RespectCanCollide=true
   local hit=workspace:Raycast(Vector3.new(lane,500,-210-d),Vector3.new(0,-600,0),rp);assert(hit)
   walk(p,lane,hit.Position.Y+3,-210-d)
  end
  return walk(p,if i==1 then 4038 else 4154,83,-380)
 end)
 assert(check(approaches[1].ok and approaches[2].ok,'two clients traverse new side routes',approaches),'route approach failed')
 local strikes=both(ps,function(p,i)return call(p,'request',{action='Strike',payload='raid:1:'..i}) end)
 assert(check(strikes[1].ok and strikes[2].ok,'simultaneous distinct eggs accepted',strikes),'raid approach failed')
 local g=workspace.ImpossibleMountain.Encounters.Guardian_1;task.wait(.3)
 check(g:GetAttribute('TargetUserId')==ps[1].UserId or g:GetAttribute('TargetUserId')==ps[2].UserId,'shared guardian selects real raider')
 local a,b=call(ps[1],'audit'),call(ps[2],'audit');check(a.target==b.target,'clients agree shared guardian target',{a=a,b=b})
 local runs=both(ps,function(p,i)
  for _=1,2 do task.wait(.55);assert(call(p,'request',{action='Strike',payload='raid:1:'..i}).ok,'strike accepted') end
  local profile=P.get(p);assert(profile.run and profile.run.phase=='revealed','reveal');assert(#profile.creatures==counts[i],'no early ownership')
  task.wait(.16);assert(call(p,'request',{action='Pickup',payload=profile.run.id}).ok,'pickup accepted')
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
result.ok=#result.failures==0;result.done=true;publish();ST:EndTest(game.HttpService:JSONEncode(result))

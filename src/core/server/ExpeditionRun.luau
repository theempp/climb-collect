local RS=game.ReplicatedStorage
local R=require(RS.CC_Core.ExpeditionRunRules)
local C=require(RS.CC_Core.SummitConfig)
local Geometry=require(RS.CC_Core.TraversalRules)
local E={};local ctx,index;local live={};local starts={};local ready={};local beginning={};local armed={};local api
local function position(v) return {v.X,v.Y,v.Z} end
local function state(s) s.data.expedition.summit=s.data.expedition.summit or R.default();return s.data.expedition.summit end
local function sync(p)
 local s=ctx.sessions[p];local a=live[p];if not s or not a then return end
 local d=state(s)
 if a.seq<=math.max(d.completedThrough,d.retiredThrough or 0) then live[p]=nil;return end
 if not s.pending and not s.saving and not s.busy then d.active=ctx.Profile.deepCopy(a);s.dirty=true end
end
function E.begin(p,route)
 local s=ctx.sessions[p];if not s or beginning[p] or live[p] then return end
 local d=state(s)
 if d.completedThrough>d.returnedThrough or d.pendingResult then return end
 beginning[p]=true
 local seq=d.nextSeq
 local result=ctx.transaction(p,'departure:'..p.UserId..':'..seq,function(data)
  local st=data.expedition.summit or R.default();data.expedition.summit=st
  if st.active or st.completedThrough>st.returnedThrough or st.pendingResult then return {ok=false,reason='active'} end
  local a=R.begin(st.nextSeq,route,ctx.Clock.now());if not a then return {ok=false,reason='route'} end
  st.nextSeq+=1;st.active=a;return {ok=true,seq=a.seq}
 end,function()
  if ctx.sessions[p]~=s then return end
  live[p]=ctx.Profile.deepCopy(state(s).active);beginning[p]=nil
  ctx.toast(p,'Expedition underway • '..route,'good')
 end)
 if not result.pending then beginning[p]=nil end
end
function E.observe(p,e)
 local a=live[p];if not a then return end
 e.at=ctx.Clock.now();R.reduce(a,e,C);sync(p)
end
function E.onLobbyReturn(p)
 local s=ctx.sessions[p];local a=live[p];if not s or not a or s.pending or s.saving or s.busy then return end
 ctx.transaction(p,'retire:'..p.UserId..':'..a.seq,function(d)
  local st=d.expedition.summit
  if st and st.active and st.active.seq==a.seq then st.retiredThrough=math.max(st.retiredThrough or 0,a.seq);st.active=nil end
  return {ok=true}
 end,function() if ctx.sessions[p]==s then live[p]=nil end end)
end
function E.eligible(p)
 local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local r=ch and ch:FindFirstChild('HumanoidRootPart')
 local zone=workspace.World:FindFirstChild('SummitStage');zone=zone and zone:FindFirstChild('Arrival')
 local grounded=h and h.Health>0 and h.FloorMaterial~=Enum.Material.Air and (ch:GetAttribute('CC_TraversalState')==nil or ch:GetAttribute('CC_TraversalState')=='ground') and not ch:GetAttribute('CC_HomeVisit')
 if not zone or not r then return {ok=false,reason='missingArrival'} end
 local q=zone.CFrame:PointToObjectSpace(r.Position);local half=zone.Size/2
 if math.abs(q.X)>half.X or math.abs(q.Y)>half.Y or math.abs(q.Z)>half.Z then return {ok=false,reason='outsideArrival'} end
 if workspace:GetServerTimeNow()<(p:GetAttribute('CC_MovementInvalidUntil') or 0) then grounded=false end
 local result=R.eligible(live[p],{grounded=grounded,at=ctx.Clock.now()},C)
 if result.ok and not result.run.merge then return {ok=false,reason='missingMerge'} end
 return result
end
function E.recordDiscovery(p,item)
 local a=live[p];local s=ctx.sessions[p]
 if not a or not s or a.invalid or not item or (item.acquiredAt or 0)<a.startedAt then return end
 -- Successful *new acquisition* commits emit once. Recovery/swap/bank never emit these events.
 local id=item.discovery and item.discovery.id or item.uid
 if s.data.discoveryCredited[id] then return end
 a.findTotals[item.kind=='heartstone' and 'heartstones' or 'creatures']+=1;sync(p)
end
function E.init(c)
 ctx=c;ctx.ExpeditionRun=E;api=game.ServerStorage:WaitForChild('CC_CheckpointAPI')
 local paths={}
 for _,sv in RS.CC_Route:GetChildren() do
  if table.find({'Shepherd','Waterfall','SummitStair'},sv.Name) then
   local points={};for line in sv.Value:gmatch('[^;]+') do local x,y,z=line:match('([%-%d%.]+),([%-%d%.]+),([%-%d%.]+)');if x then table.insert(points,{tonumber(x),tonumber(y),tonumber(z)}) end end
   if #points>0 then table.insert(paths,{route=sv.Name,points=points});if sv.Name~='SummitStair' then starts[sv.Name]=Vector3.new(table.unpack(points[1])) end end
  end
 end
 local tracks=RS:FindFirstChild('CC_Track')
 if tracks then for _,sv in tracks:GetDescendants() do if sv:IsA('StringValue') and table.find({'Shepherd','Waterfall'},sv.Name) then
  local ok,sections=pcall(game.HttpService.JSONDecode,game.HttpService,sv.Value)
  if ok then for _,section in sections do local points={};for _,node in section.nodes or {} do table.insert(points,node.p) end;if #points>1 then table.insert(paths,{route=sv.Name,points=points}) end end end
 end end end
 -- Crown approach belongs to the common final leg, after the preserved summit terrace.
 table.insert(paths,{route='SummitStair',points={{0,3170,0},{40,3250,12}}})
 index=Geometry.routeIndex(paths,120)
 api.MovementObserved.Event:Connect(function(p,pos,valid,progress,distance)
  if not ready[p] then return end
  local s=ctx.sessions[p];if not s then return end
  local a=live[p]
  if a then
   local ch=p.Character
   if ch and not ch:GetAttribute('CC_HomeVisit') then
    local route=Geometry.nearestRoute(index,position(pos),120)
    E.observe(p,{kind='sample',y=pos.Y,distance=distance,valid=valid,nearRoute=route~=nil,progressAllowed=progress})
    if valid and progress then a.lastPos=position(pos) end
    if require(script.Parent.LobbyAnchors).contains(pos) and pos.Y<100 then E.onLobbyReturn(p) end
    if ctx.SummitFinish and E.eligible(p).ok then ctx.SummitFinish.tryFinish(p) end
   end
  elseif valid and progress and pos.Y<100 then
   if require(script.Parent.LobbyAnchors).contains(pos) then armed[p]=true end
   if not armed[p] then return end
   for route,point in starts do if (pos-point).Magnitude<24 then task.spawn(E.begin,p,route);break end end
  end
  sync(p)
 end)
 api.AuthorizedTravel.Event:Connect(function(p,kind) if kind=='test' or kind=='resume' or kind=='shuttle' or kind=='summitReturn' then armed[p]=nil end;E.observe(p,{kind='travel',travel=kind}) end)
 api.CheckpointConfirmed.Event:Connect(function(p,name)
  local i=tonumber(name:match('^Camp(%d)$'));if i then E.observe(p,{kind='camp',index=i}) elseif name=='Merge' then E.observe(p,{kind='merge'}) end
 end)
 ctx.on('traversalSection',function(p,id,route) E.observe(p,{kind='section',id=id,route=route}) end)
 for _,kind in {'claim','net','heartstone'} do ctx.on(kind,function(p,_,item) E.recordDiscovery(p,item) end) end
 ctx.on('bank',function(p,result) local a=live[p];if a and not result.dup then a.newBankedSpecies+=(result.firsts or 0);sync(p) end end)
end
function E.onLoaded(p,s)
 ready[p]=false;local d=state(s);live[p]=d.active and ctx.Profile.deepCopy(d.active)
 task.delay(1.5,function()
  if ctx.sessions[p]~=s then return end
  local a=live[p]
  if a and a.lastPos and not d.pendingResult and not s.data.expedition.homeReturn then ctx.Traversal.travel(p,Vector3.new(table.unpack(a.lastPos)),'reconnect') end
  ready[p]=true
 end)
end
function E.onLeave(p) sync(p);live[p]=nil;ready[p]=nil;beginning[p]=nil;armed[p]=nil end
function E.state(p,st) local a=live[p];if a then st.ascent={route=a.startRoute,phase=a.invalid and 'needsFreshDeparture' or 'ascending',camps=a.lastMilestone,band=a.routeEvidence.band} end end
return E

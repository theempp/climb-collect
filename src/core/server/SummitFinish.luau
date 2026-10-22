local R=require(game.ReplicatedStorage.CC_Core.ExpeditionRunRules)
local C=require(game.ReplicatedStorage.CC_Core.SummitConfig)
local S={};local ctx;local finishing={};local returning={}
local function copy(v) if type(v)~='table' then return v end;local o={};for k,x in v do o[k]=copy(x) end;return o end
-- Only called inside the Profile transaction with server-owned run evidence.
function S.completeData(d,a,c,now)
 local st=d.expedition.summit or R.default();d.expedition.summit=st
 if a.seq<=st.completedThrough then return {ok=true,alreadyCompleted=true,result=st.pendingResult} end
 if not st.active or st.active.seq~=a.seq or a.seq<=(st.retiredThrough or 0) or st.completedThrough>st.returnedThrough then return {ok=false,reason='sequence'} end
 local eligible=R.eligible(a,{grounded=true,at=now},c);if not eligible.ok then return {ok=false,reason=eligible.reason} end
 local total=0;for _,n in d.gear.summits do total+=n end
 local route=a.startRoute;local firstRoute=(d.gear.summits[route] or 0)==0
 local rewards={coins=c.coins+(total==0 and c.firstCoins or 0),points=c.points+(firstRoute and c.firstRoutePoints or 0),cosmetics={}}
 d.gear.summits[route]=(d.gear.summits[route] or 0)+1;d.coins+=rewards.coins;d.gear.points+=rewards.points
 d.expedition.earnedCosmetics=d.expedition.earnedCosmetics or {}
 local nextMilestone
 for _,m in c.milestones do
  -- Crossing a new threshold earns the cosmetic; imported historic totals never retro-grant it.
  if total<m.at and total+1>=m.at and not d.expedition.earnedCosmetics[m.id] then d.expedition.earnedCosmetics[m.id]=true;table.insert(rewards.cosmetics,{id=m.id,name=m.name}) end
  if not nextMilestone and m.at>total+1 then nextMilestone={name=m.name,at=m.at,remaining=m.at-total-1} end
 end
 local carried={};local newSpecies={};local count=0
 for _,it in d.cargo do
  table.insert(carried,{id=it.uid,kind=it.kind,species=it.species,rarity=it.rarity,tier=it.tier})
  if it.kind=='creature' then count+=1;if (d.codex[it.species] or 0)==0 then newSpecies[it.species]=true end end
 end
 local unique=0;for _ in newSpecies do unique+=1 end
 local result={id=a.id,seq=a.seq,finishedAt=now,route=route,mixedRoute=a.mixedRoute,elapsedSeconds=math.max(1,now-a.startedAt),found=copy(a.findTotals),carried=carried,carriedCreatures=count,newBankedSpecies=a.newBankedSpecies or 0,newUnbankedSpecies=unique,rewards=rewards,nextMilestone=nextMilestone,reviewEconomy=c.reviewEconomy}
 st.completedThrough=a.seq;st.active=nil;st.pendingResult=result;st.returnIntent=true
 d.expedition.successfulRuns=d.expedition.successfulRuns or {};table.insert(d.expedition.successfulRuns,{seq=a.seq,route=route,elapsedSeconds=result.elapsedSeconds,finishedAt=now})
 while #d.expedition.successfulRuns>10 do table.remove(d.expedition.successfulRuns,1) end
 return {ok=true,result=result}
end
local function unfreeze(p)
 local f=finishing[p];if f and f.root and f.root.Parent then f.root.Anchored=f.wasAnchored end
 if p.Parent then p:SetAttribute('CC_SummitSaving',false) end
 finishing[p]=nil
end
function S.tryFinish(p)
 local s=ctx.sessions[p];if not s or s.lost or s.closing or finishing[p] then return {ok=false,reason='busy'} end
 if s.pending or s.saving or s.busy or s.outcomePending then return {ok=false,reason='busy'} end
 local eligible=ctx.ExpeditionRun.eligible(p);if not eligible.ok then return eligible end
 local a=copy(eligible.run);local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');if not root then return {ok=false,reason='character'} end
 finishing[p]={root=root,wasAnchored=root.Anchored,at=os.clock()};root.Anchored=true;p:SetAttribute('CC_SummitSaving',true);ctx.push(p)
 local result=ctx.transaction(p,'summit:'..p.UserId..':'..a.seq,function(d) return S.completeData(d,a,C,ctx.Clock.now()) end,function(r)
  unfreeze(p);if ctx.sessions[p]~=s then return end
  if r.result then ctx.fx(p,{kind='summitConfirmed',id=r.result.id});ctx.push(p) end
 end)
 if not result.pending then unfreeze(p) end
 -- Persistence can be unavailable indefinitely. The player is never left anchored indefinitely.
 task.delay(8,function() if finishing[p] and finishing[p].root==root then unfreeze(p);ctx.push(p) end end)
 return result
end
local function arrive(p,s,id)
 local st=s.data.expedition.summit
 if ctx.sessions[p]~=s or not st or not st.pendingResult or st.pendingResult.id~=id then return false end
 local anchor=require(script.Parent.LobbyAnchors).resolve(workspace.World).Return
 local api=game.ServerStorage.CC_CheckpointAPI;api.SetCheckpoint:Invoke(p,nil)
 local ok=ctx.Traversal.travel(p,anchor.Position+Vector3.new(0,3,0),'summitReturn')
 if not ok then return false end
 local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
 if not r or (r.Position-anchor.Position).Magnitude>10 then return false end
 return true
end
function S.returnToCamp(p,id)
 local s=ctx.sessions[p];local st=s and s.data.expedition.summit;local result=st and st.pendingResult
 if not result or result.id~=id or returning[p] then return end
 returning[p]=true
 local response=ctx.transaction(p,'summitReturn:'..p.UserId..':'..result.seq,function(d)
  local t=d.expedition.summit;if not t.pendingResult or t.pendingResult.id~=id then return {ok=false,reason='result'} end
  t.returnedThrough=math.max(t.returnedThrough,result.seq);t.returnIntent=true;d.expedition.homeReturn=nil;return {ok=true}
 end,function()
  if arrive(p,s,id) then
   task.delay(.6,function()
    if ctx.sessions[p]==s then S.acknowledge(p,id) end
   end)
  end
  returning[p]=nil;ctx.push(p)
 end)
 if not response.pending then returning[p]=nil end
end
function S.acknowledge(p,id)
 local s=ctx.sessions[p];local st=s and s.data.expedition.summit;local result=st and st.pendingResult
 if not result or result.id~=id or st.returnedThrough<result.seq then return end
 local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local anchor=require(script.Parent.LobbyAnchors).resolve(workspace.World).Return
 if not root or (root.Position-anchor.Position).Magnitude>16 then return end
 ctx.transaction(p,'summitAck:'..p.UserId..':'..result.seq,function(d)
  local t=d.expedition.summit;if not t.pendingResult or t.pendingResult.id~=id then return {ok=false,reason='result'} end
  t.acknowledgedSeq=result.seq;t.pendingResult=nil;t.returnIntent=nil;return {ok=true}
 end,function() ctx.push(p) end)
end
function S.init(c)
 ctx=c;ctx.SummitFinish=S
 ctx.handlers.summitReturn=function(p,v) if type(v.resultId)=='string' then S.returnToCamp(p,v.resultId) end end
 ctx.handlers.summitAcknowledge=function(p,v) if type(v.resultId)=='string' then S.acknowledge(p,v.resultId) end end
 ctx.handlers.summitReplay=function(p,v) local s=ctx.sessions[p];local st=s and s.data.expedition.summit;if st and st.pendingResult and st.pendingResult.id==v.resultId then ctx.fx(p,{kind='summitReplay',id=v.resultId}) end end
 if game:GetService('RunService'):IsStudio() then
  -- ServerStorage Bindable only: no client RPC, no live server, private local-memory QA fixture.
  local probe=Instance.new('BindableFunction');probe.Name='CC_SummitReview';probe.Parent=game.ServerStorage
  probe.OnInvoke=function(action,p)
   p=p or game.Players:GetPlayers()[1];local s=ctx.sessions[p]
   if action=='eligible' then return ctx.ExpeditionRun.eligible(p) end
   if action=='profile' then return copy(s.data.expedition.summit) end
   if action=='fixture' then
    assert(s.owner.store.kind=='memory','fixture cannot access live storage')
    ctx.ExpeditionRun.onLeave(p);ctx.Traversal.travel(p,Vector3.new(40,3255,12),'test');task.wait(.7)
    local st=s.data.expedition.summit or R.default();s.data.expedition.summit=st
    assert(not st.pendingResult,'finish existing result first')
    local a=R.begin(st.nextSeq,'Shepherd',ctx.Clock.now()-600);st.nextSeq+=1
    a.routeEvidence={band=32,distance=12000,sections=20};a.lastMilestone=4;a.merge=true;a.lastPos={40,3255,12};st.active=a
    ctx.ExpeditionRun.onLoaded(p,s);return {fixture=true,seq=a.seq}
   end
  end
 end
end
function S.onLoaded(p,s)
 local st=s.data.expedition.summit
 if st and st.pendingResult then
  task.delay(2,function()
   if ctx.sessions[p]~=s then return end
   -- Recover unfinished results beside the bank, preserving their presentation until Back to Camp.
   if st.returnedThrough>=st.pendingResult.seq then S.returnToCamp(p,st.pendingResult.id)
   else arrive(p,s,st.pendingResult.id);ctx.push(p) end
  end)
 end
end
function S.state(p,st)
 local s=ctx.sessions[p];local t=s and s.data.expedition.summit
 st.summit={status=finishing[p] and 'saving' or (t and t.pendingResult and 'confirmed' or 'idle'),result=t and copy(t.pendingResult)}
end
function S.onLeave(p) unfreeze(p);returning[p]=nil end
return S

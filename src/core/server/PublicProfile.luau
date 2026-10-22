local Players=game:GetService('Players')
local R=require(game.ReplicatedStorage.CC_Core.PortfolioRules)
local A=require(game.ReplicatedStorage.CC_Core.AchievementRules)
local Earned=require(game.ReplicatedStorage.CC_Core.EarnedCosmetics)
local P={};local ctx,roster;local buckets={}
local function actor(p)
 local ch=p.Character;local h=ch and ch:FindFirstChildOfClass('Humanoid');local root=ch and ch:FindFirstChild('HumanoidRootPart')
 return root and h and h.Health>0 and root or nil
end
local function safe(p) local r=actor(p);return r and ctx.Camps.isSafe(r.Position) and (not p.Character:GetAttribute('CC_TraversalState') or p.Character:GetAttribute('CC_TraversalState')=='ground') end
local function creature(b)
 if not b then return nil end;local e=ctx.Species.get(b.species)
 return {creatureId=b.creatureId,species=e and e.id or b.species,name=e and e.name or 'Retired discovery',rarity=e and e.rarity or b.rarity,mutation=b.mutation}
end
function P.snapshot(subject)
 local session=ctx.sessions[subject];if not session or session.lost or session.closing then return nil end
 local d=session.data;local summary=R.summarize(d,roster);local unlocked=A.unlocked(summary,d.gear.summits)
 local bank={} for _,b in d.bank do bank[b.creatureId]=b end
 local showcase={} for _,id in d.portfolio.showcase do if bank[id] then table.insert(showcase,creature(bank[id])) end end
 local title=unlocked[d.portfolio.titleId] and d.portfolio.titleId or ''
 local milestones={};for id,entry in Earned do if d.expedition.earnedCosmetics and d.expedition.earnedCosmetics[id] then table.insert(milestones,entry.name) end end;table.sort(milestones)
 return {userId=subject.UserId,displayName=subject.DisplayName,username=subject.Name,level=d.level,xp=d.xp,title=A.name(title),titleId=title,summits=A.total(d.gear.summits),summitsByRoute=ctx.Profile.deepCopy(d.gear.summits),collection=summary,companion=creature(bank[d.home.companion]),showcase=showcase,cosmetics=ctx.Profile.deepCopy(d.commerce.equipped),gear=ctx.Profile.deepCopy(d.gear.equipped),milestones=milestones,earnedCosmetic=d.expedition.earnedEquipped,frameId=(Earned[d.portfolio.frameId] and d.expedition.earnedCosmetics and d.expedition.earnedCosmetics[d.portfolio.frameId]) and d.portfolio.frameId or ''}
end
function P.authorize(viewer,subject)
 if not subject or not ctx.sessions[subject] or not actor(subject) then return 'unavailable' end
 if not safe(viewer) or not safe(subject) then return 'unsafe' end
 if (actor(viewer).Position-actor(subject).Position).Magnitude>25 then return 'outOfRange' end
 return 'ok'
end
function P.init(c)
 ctx=c;roster=R.roster(ctx.Species)
 -- Read-only clones of the existing creature visuals; never alter the protected library.
 local models=Instance.new('Folder');models.Name='CC_PortfolioModels'
 for _,e in roster.entries do if e.collectible and e.obtainable then
  local model=ctx.Visuals.creature(e.id,Vector3.zero);model.Name=e.id
  for _,v in model:GetDescendants() do if v:IsA('LuaSourceContainer') or v:IsA('LayerCollector') or v:IsA('ParticleEmitter') or v:IsA('Beam') or v:IsA('Sound') then v:Destroy() elseif v:IsA('BasePart') then v.Anchored=true;v.CanCollide=false;v.CanTouch=false;v.CanQuery=false end end
  model.Parent=models
 end end
 models.Parent=game.ReplicatedStorage
 ctx.handlers.profileInspect=function(viewer,p)
  if type(p.subjectUserId)~='number' or p.subjectUserId%1~=0 or type(p.requestId)~='string' or #p.requestId>64 then return end
  local b=buckets[viewer] or {tokens=4,at=os.clock()};buckets[viewer]=b;local now=os.clock();b.tokens=math.min(4,b.tokens+now-b.at);b.at=now
  local status='rateLimited';local card
  if b.tokens>=1 then b.tokens-=1;local subject=Players:GetPlayerByUserId(p.subjectUserId);status=P.authorize(viewer,subject);if status=='ok' then card=P.snapshot(subject);if not card then status='unavailable' end end end
  ctx.fx(viewer,{kind='profileInspect',requestId=p.requestId,status=status,card=card})
 end
 local function select(plr,kind,value)
  ctx.transaction(plr,'profile:'..game.HttpService:GenerateGUID(false),function(d)
   if kind=='title' then
    if type(value)~='string' or #value>48 or (value~='' and not A.unlocked(R.summarize(d,roster),d.gear.summits)[value]) then return {ok=false,reason='locked'} end
    d.portfolio.titleId=value
   elseif kind=='showcase' then
    if type(value)~='table' or #value>3 then return {ok=false,reason='invalid'} end
    local clean=R.cleanSelections({showcase=value},d.bank);if #clean.showcase~=#value then return {ok=false,reason='ownership'} end;d.portfolio.showcase=clean.showcase
   elseif kind=='frame' then
    if value~='' and not (type(value)=='string' and Earned[value] and d.expedition.earnedCosmetics and d.expedition.earnedCosmetics[value]) then return {ok=false,reason='ownership'} end
    d.portfolio.frameId=value
   elseif kind=='earned' then
    if value~='' and not (type(value)=='string' and Earned[value] and d.expedition.earnedCosmetics and d.expedition.earnedCosmetics[value]) then return {ok=false,reason='ownership'} end
    d.expedition.earnedEquipped=value
   end
   return {ok=true}
  end,function() if kind=='earned' then ctx.CommerceCosmetics.refresh(plr) end;ctx.push(plr) end)
 end
 ctx.handlers.profileSelectTitle=function(p,v) select(p,'title',v.titleId) end
 ctx.handlers.profileSetShowcase=function(p,v) select(p,'showcase',v.creatureIds) end
 ctx.handlers.profileSetFrame=function(p,v) select(p,'frame',v.frameId) end
 ctx.handlers.profileEquipEarned=function(p,v) select(p,'earned',v.cosmeticId) end
 local f=workspace.World:FindFirstChild('Fairground')
 if f then local pr=require(script.Parent.Prompts).make(f.Anchors.Collection,{Name='CollectionPrompt',ActionText='Your portfolio',ObjectText='Field collection',HoldDuration=0,MaxActivationDistance=12});pr.Triggered:Connect(function(p) if require(script.Parent.Prompts).validate(pr,p) then ctx.fx(p,{kind='profileOwn'}) end end) end
end
function P.state(plr,st)
 local s=ctx.sessions[plr];if not s then return end
 st.profile=P.snapshot(plr)
 local d=s.data
 st.profileDetails={banked=d.stats.banked,mutationCount=st.profile.collection.mutationCount,titles=A.unlocked(st.profile.collection,d.gear.summits),selectable={},dailyPractice=d.dailyPractice,successfulRuns=d.expedition.successfulRuns or {},earnedCosmetics=d.expedition.earnedCosmetics or {}}
 for _,b in d.bank do table.insert(st.profileDetails.selectable,creature(b)) end
 st.playerTags={};local root=actor(plr)
 if root and safe(plr) then for _,other in Players:GetPlayers() do local r=actor(other);if other~=plr and r and (r.Position-root.Position).Magnitude<=60 and safe(other) then local card=P.snapshot(other);if card then table.insert(st.playerTags,{userId=card.userId,displayName=card.displayName,level=card.level,title=card.title,frameId=card.frameId}) end end end end
end
function P.onLeave(p) buckets[p]=nil end
return P

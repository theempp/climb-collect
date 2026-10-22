-- Durable drop ownership. Disconnect preserves cargo and its return location.
local Players=game:GetService("Players")
local HS=game:GetService("HttpService")
local Profile=require(script.Parent.Profile)
local DP={}
local ctx,folder,Prompts,Visuals
local packs,hist={},{}
local function vec(p) return Vector3.new(p.x or 0,p.y or 0,p.z or 0) end
local function xyz(p) return {x=p.X,y=p.Y,z=p.Z} end
function DP.describe(items)
 local out={} for _,it in ipairs(items) do local e=ctx.Species.get(it.species) table.insert(out,it.kind=="heartstone" and (it.tier.." Heartstone") or (e and e.name or it.species)) end
 return table.concat(out,", ")
end
function DP.lastGround(plr,y,above)
 local h=hist[plr] or {}
 for i=#h,1,-1 do if not y or h[i].Y>=y+(above or 10) then return h[i] end end
 return h[#h] or (plr.Character and plr.Character:GetPivot().Position) or Vector3.zero
end
local function removeVisual(id)
 local p=packs[id] if p and p.model then p.model:Destroy() end packs[id]=nil
end
function DP.recover(plr,pack,prompt)
 if plr.UserId~=pack.ownerId or packs[pack.id]~=pack or not Prompts.validate(prompt,plr) then return end
 local r=ctx.transaction(plr,"recover:"..HS:GenerateGUID(false),function(d)
  local idx,drop
  for i,x in ipairs(d.drops) do if x.id==pack.id then idx,drop=i,x break end end
  if not drop or (drop.expiresAt>0 and drop.expiresAt<=ctx.Clock.now()) then return {ok=false,reason="expired"} end
  local count=0
  for i=#drop.items,1,-1 do local it=drop.items[i]
   if ctx.Cargo.used(d.cargo)+(it.slots or 1)<=d.slots then table.insert(d.cargo,it) table.remove(drop.items,i) count+=1 end
  end
  if count==0 then return {ok=false,reason="full"} end
  d.stats.recovered+=count
  if #drop.items==0 then table.remove(d.drops,idx) end
  return {ok=true,count=count}
 end,function(done)
  DP.refresh(plr) ctx.invChanged(plr)
  ctx.toast(plr,"Recovered "..done.count.." find(s). Original discovery preserved.","good")
  ctx.fx(plr,{kind="recovered",packId=pack.id,left=packs[pack.id] and #packs[pack.id].items or 0})
 end)
 if not r.ok then ctx.toast(plr,r.reason=="full" and "Backpack full. Make room and return here." or "Recovery is waiting for a confirmed save.","warn") end
end
function DP.refresh(plr)
 local s=ctx.sessions[plr] if not s then return end
 local live={}
 for _,d in ipairs(s.data.drops) do
  if d.expiresAt==0 or d.expiresAt>ctx.Clock.now() then
   live[d.id]=true local p=packs[d.id]
   if not p then
    local pos=vec(d.pos)
    local released=d.reason=="released" and d.items[1] and d.items[1].kind=="creature"
    local m=released and Visuals.creature(d.items[1].species,pos) or Visuals.dropPack(pos)
    m.Name=released and "ReturnedCreature" or "DropPack"
    m:SetAttribute("OwnerId",plr.UserId) m:SetAttribute("PackId",d.id)
    p={id=d.id,ownerId=plr.UserId,ownerName=plr.Name,items=d.items,pos=pos,expiresAt=d.expiresAt,model=m,reason=d.reason}
    local pr=Prompts.make(m.PrimaryPart,{Name="RecoverPrompt",ActionText=released and "Reclaim" or "Recover",ObjectText=released and "Your returned find" or "Your expedition pack",HoldDuration=0.6,MaxActivationDistance=10})
    pr.Triggered:Connect(function(who) DP.recover(who,p,pr) end)
    m.Parent=folder packs[d.id]=p
   end
   p.items=d.items p.model:SetAttribute("Count",#d.items) p.model:SetAttribute("ExpiresAt",d.expiresAt)
  end
 end
 for id,p in pairs(packs) do if p.ownerId==plr.UserId and not live[id] then removeVisual(id) end end
end
-- Pure outcome transform: consumes exact preselected identities once, never substitutes later acquisitions.
function DP.applyOutcome(d,id,now,ttl)
 local index,event
 for i,e in ipairs(d.expedition.outcomes or {}) do if e.id==id then index,event=i,e break end end
 if not event then return {ok=true,outcomeId=id,items={},alreadyApplied=true} end
 local items={}
 for i=#d.cargo,1,-1 do if event.selected[d.cargo[i].uid] then table.insert(items,table.remove(d.cargo,i)) end end
 table.remove(d.expedition.outcomes,index)
 local expiry=now+ttl
 if #items>0 then table.insert(d.drops,{id=id,items=items,pos=event.pos,expiresAt=expiry,reason=event.reason}) end
 d.stats.shaken+=#items
 if event.reason=="fall" then d.stats.falls+=1 end
 return {ok=true,outcomeId=id,items=items,reason=event.reason,pos=event.pos,expiresAt=expiry}
end
function DP.processOutcomes(plr)
 local s=ctx.sessions[plr]
 if not s or s.pending or s.saving or s.busy or s.closing or s.lost then return {} end
 local event=(s.data.expedition.outcomes or {})[1]
 s.outcomePending=event~=nil
 if not event then return {} end
 local moved={}
 ctx.transaction(plr,"outcome:"..event.id,function(d) return DP.applyOutcome(d,event.id,ctx.Clock.now(),ctx.C.DROP_PACK_SECONDS) end,function(done)
  moved=done.items or {}
  s.outcomePending=#(s.data.expedition.outcomes or {})>0
  DP.refresh(plr) ctx.invChanged(plr)
  if #moved>0 then
   local visible={} for _,item in ipairs(moved) do visible[#visible+1]=ctx.Cargo.clientItem(item) end
   ctx.fx(plr,{kind="loss",reason=done.reason,lost=visible,keptCount=#s.data.cargo,packId=event.id,packPos=vec(done.pos),expiresAt=done.expiresAt})
  end
 end)
 return moved
end
function DP.shake(plr,n,pos,reason)
 local s=ctx.sessions[plr]
 local effective=s and (s.pending and s.pending.candidate or s.data)
 if not effective or effective.flags.firstBankAt==0 then
  if s and #s.data.cargo>0 then ctx.toast(plr,"Beginner protection kept your finds safe.","info") end return {}
 end
 local rareBanked=false for _,b in ipairs(effective.bank) do if b.source==ctx.C.TUTORIAL_RARE_SOURCE then rareBanked=true end end
 local queued={}
 for _,e in ipairs(effective.expedition.outcomes or {}) do for id in pairs(e.selected or {}) do queued[id]=true end end
 local candidates={}
 for _,it in ipairs(effective.cargo) do if not queued[it.uid] and (rareBanked or it.source~=ctx.C.TUTORIAL_RARE_SOURCE) then table.insert(candidates,it) end end
 local function value(it) return it.kind=="heartstone" and (ctx.C.HEARTSTONE_VALUE[it.tier] or 0) or (ctx.C.RANK[it.rarity] or 1) end
 table.sort(candidates,function(a,b) local av,bv=value(a),value(b); return av>bv or (av==bv and a.uid<b.uid) end)
 local selected={} for i=1,math.min(n,#candidates) do selected[candidates[i].uid]=true end
 if next(selected)==nil then return {} end
 Profile.queueOutcome(s,{id=HS:GenerateGUID(false),selected=selected,pos=xyz(pos or DP.lastGround(plr)),reason=reason or "fall",at=ctx.Clock.now()})
 ctx.push(plr)
 return DP.processOutcomes(plr)
end
function DP.onLoaded(plr)
 DP.refresh(plr) local s=ctx.sessions[plr]
 if s then s.outcomePending=#(s.data.expedition.outcomes or {})>0; DP.processOutcomes(plr) end
 if s and not (s.data.expedition.summit and (s.data.expedition.summit.active or s.data.expedition.summit.pendingResult)) and not s.data.expedition.homeReturn and #s.data.cargo>0 and s.data.expedition.returnPos and ctx.Traversal then
  local pos=vec(s.data.expedition.returnPos)
  task.delay(1,function() if ctx.sessions[plr]==s then ctx.Traversal.travel(plr,pos,"reconnect") end end)
 end
end
function DP.onLeave(plr,s)
 if s then
  local ch=plr.Character
  local point=(ch and ch:GetAttribute("CC_HomeVisit")) and s.data.expedition.homeReturn or nil
  point=point or xyz(DP.lastGround(plr))
  s.data.expedition.returnPos=point
	 s.departurePosition=Profile.deepCopy(point)
  if s.pending then s.pending.candidate.expedition.returnPos=Profile.deepCopy(point) end
  s.dirty=true
 end
 for id,p in pairs(packs) do if p.ownerId==plr.UserId then removeVisual(id) end end
 hist[plr]=nil Prompts.forget(plr)
end
function DP.onCharacter(plr,ch)
 local hum=ch:WaitForChild("Humanoid",10)
 if hum then hum.Died:Connect(function()
  local s=ctx.sessions[plr]
  local ret=s and ch:GetAttribute("CC_HomeVisit") and s.data.expedition.homeReturn
  DP.shake(plr,math.huge,ret and vec(ret) or DP.lastGround(plr),"reset")
 end) end
end
function DP.init(c)
 ctx=c Prompts=require(script.Parent.Prompts) Visuals=require(script.Parent.Visuals)
 folder=Instance.new("Folder") folder.Name="ExpeditionDrops" folder.Parent=workspace.World.Core
 local acc=0
 game:GetService("RunService").Heartbeat:Connect(function(dt)
  acc+=dt if acc<0.5 then return end acc=0
  for _,plr in ipairs(Players:GetPlayers()) do
   local ch=plr.Character local hrp=ch and ch:FindFirstChild("HumanoidRootPart") local hum=ch and ch:FindFirstChildOfClass("Humanoid")
   local s=ctx.sessions[plr]
   if s and s.outcomePending then DP.processOutcomes(plr) end
   if hrp and hum and hum.FloorMaterial~=Enum.Material.Air and (not ch:GetAttribute("CC_TraversalState") or ch:GetAttribute("CC_TraversalState")=="ground") and not ch:GetAttribute("CC_HomeVisit") then
    local h=hist[plr] or {} table.insert(h,hrp.Position) if #h>40 then table.remove(h,1) end hist[plr]=h
    if s and not ctx.Inv.locked(plr.UserId) then s.data.expedition.returnPos=xyz(hrp.Position) end
   end
  end
 end)
 local api=game.ServerStorage:WaitForChild("CC_CheckpointAPI",10)
 if api then api.Fell.Event:Connect(function(plr,y) DP.shake(plr,ctx.C.FALL_SHAKES,DP.lastGround(plr,y,12),"fall") end) end
 task.spawn(function()
  while true do task.wait(3)
   for plr,s in pairs(ctx.sessions) do
    local expired={} for _,d in ipairs(s.data.drops) do if d.expiresAt>0 and d.expiresAt<=ctx.Clock.now() then expired[d.id]=true end end
    if next(expired) and not ctx.Inv.locked(plr.UserId) then
     ctx.transaction(plr,"expire:"..HS:GenerateGUID(false),function(d)
      local n=0 for i=#d.drops,1,-1 do if expired[d.drops[i].id] then n+=#d.drops[i].items table.remove(d.drops,i) end end
      d.stats.lost+=n return {ok=true,count=n}
     end,function(r) DP.refresh(plr) ctx.toast(plr,"A drop pack expired: "..r.count.." unbanked find(s) were lost.","warn") end)
    end
   end
  end
 end)
end
function DP.state(plr,st)
 st.packs={} local s=ctx.sessions[plr] if not s then return end
 for _,d in ipairs(s.data.drops) do table.insert(st.packs,{id=d.id,pos=vec(d.pos),expiresAt=d.expiresAt,count=#d.items,reason=d.reason}) end
end
function DP.ownedBy(uid) local out={} for _,p in pairs(packs) do if p.ownerId==uid then table.insert(out,p) end end return out end
function DP.clearOwner(uid) for id,p in pairs(packs) do if p.ownerId==uid then removeVisual(id) end end end
DP._packs=packs
return DP

-- Glassbloom HUD state (P2 T6). Pure: profile + context + typed hud events + client observations → HUD state and
-- messages. A memory table (H.new) holds what the HUD remembers between snapshots; nothing here touches the engine.
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local H={}
H.states={rest=true,carry=true,chase=true,sanctuary=true,battle=true}
-- Message tiers (intel §4). Board text wins on timing (STOP 1, G4): XP line 1.5 s, carry pop-up 2.5 s, RUN! 1.5 s.
-- Tier 1 = toast under the coin pill, 2 = top band, 3 = centre moment. The checkpoint rail label is not a tier message.
-- knocked, lost, calm and purchase are open gaps (G5): no entry, so their legacy toasts stay tier 1 and calm is state only.
H.tiers={
 coin={tier=1,slot='toast',duration=1.5},
 xp={tier=1,slot='toast',duration=1.5},
 xpLine={tier=1,slot='xpLine',duration=1.5},
 creatureXp={tier=1,slot='toast',duration=1.5},
 pickup={tier=1,slot='toast',duration=1.5},
 toast={tier=1,slot='toast',duration=1.5},
 carry={tier=2,slot='carryPop',duration=2.5},
 regrab={tier=2,slot='carryPop',duration=2.5},
 alert={tier=2,slot='run',duration=1.5,danger=true},
 section={tier=2,slot='banner',duration=2.5},
 safe={tier=2,slot='banner',duration=2.5},
 checkpoint={slot='rail',duration=3},
 levelUp={tier=3,slot='moment',duration=2.5},
 summit={tier=3,slot='moment',duration=2.5},
 hatch={tier=3,slot='reveal',land=3.5,cta=5.7,collect=true},
}
-- Legacy toast text → kind. typed: a typed hud event drives that moment, so the host skips this toast.
-- priority keeps the current in-battle objective toasts jumping the queue. Unknown text is a tier 1 toast.
H.legacy={
 {find='heard your strike!',kind='alert',typed=true},
 {match='^Safe! ',kind='safe',typed=true},
 {find='IMPOSSIBLE MOUNTAIN CONQUERED',kind='summit'},
 {find='golden heart',kind='toast',priority=true},
 {find='constellation stones',kind='toast',priority=true},
}
local restOrder={entrance=1,recovery=2,guardian=3}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function section(k) return type(k)=='number' and k%1==0 and k>=1 and k<=#C.kingdoms end
-- In the sanctuary every tier 3 moment waits for Collect.
function H.message(kind,data,inSanctuary)
 local t=H.tiers[kind];if not t then return nil end
 local m={kind=kind,tier=t.tier,slot=t.slot,duration=t.duration,danger=t.danger,land=t.land,cta=t.cta,collect=t.collect,data=data or {}}
 if t.tier==3 and inSanctuary then m.collect=true end
 if m.collect then m.duration=nil end
 return m
end
function H.classify(text,inSanctuary)
 if type(text)~='string' or text=='' then return nil end
 for _,rule in ipairs(H.legacy) do
  if (rule.find and string.find(text,rule.find,1,true)) or (rule.match and string.match(text,rule.match)) then
   local m=H.message(rule.kind,{text=text},inSanctuary);m.typed=rule.typed;m.priority=rule.priority;m.text=text;return m
  end
 end
 local m=H.message('toast',{text=text},inSanctuary);m.text=text;return m
end
-- Client X/Z test (Controller fallback): altitude band first, then the GuardianBounds box holding the position.
-- bounds are parts (Name '1'..'6', CFrame, Size); only X and Z are tested, as in the Controller.
function H.fallbackSection(position,free,bounds)
 -- A Roblox Vector3 is a native vector: type() gives 'vector'.
 local t=type(position);if t~='table' and t~='userdata' and t~='vector' then return nil end
 local y=position.Y;if not finite(y) then return nil end
 local k=math.clamp(math.floor((y-16)/(if free then 64 else 136))+1,1,6)
 if free and type(bounds)=='table' then
  for _,b in ipairs(bounds) do
   local ok,inside=pcall(function() local q=b.CFrame:PointToObjectSpace(position);return math.abs(q.X)<=b.Size.X/2 and math.abs(q.Z)<=b.Size.Z/2 end)
   if ok and inside then k=tonumber(b.Name) or k;break end
  end
 end
 return if section(k) then k else nil
end
-- Server ui.section wins: a number is the section, false means outside every section. Only a missing (nil) or
-- malformed value falls back to the client test, and never inside the sanctuary.
function H.section(ui,fallback)
 ui=if type(ui)=='table' then ui else {}
 if ui.section==false then return nil end
 if section(ui.section) then return ui.section end
 if ui.inSanctuary==true then return nil end
 return if section(fallback) then fallback else nil
end
-- Rest point id 'k:entrance|recovery|guardian' → section and route order 1..18 (entrance, recovery, guardian).
function H.checkpoint(id)
 if type(id)~='string' then return nil end
 local k,kind=id:match('^(%d+):(%a+)$');k=tonumber(k)
 if not section(k) or not restOrder[kind] then return nil end
 return {id=id,section=k,order=(k-1)*3+restOrder[kind]}
end
-- Creature XP to reach level L is 40·(1+…+L−1) = 20L(L−1) (Rules.addXP).
local function creatureTotal(c) return 20*c.level*(c.level-1)+c.xp end
local function creatures(list)
 local out={}
 if type(list)~='table' then return out end
 for _,c in ipairs(list) do
  if type(c)=='table' and type(c.id)=='string' and finite(c.level) and finite(c.xp) then out[c.id]={id=c.id,species=c.species,level=c.level,xp=c.xp} end
 end
 return out
end
-- Gains on creatures present in both snapshots; a new creature (secure, hatch) is not an XP gain.
function H.creatureXp(before,after)
 if type(before)~='table' or type(after)~='table' then return nil end
 local was=creatures(before);local total=0;local list={}
 for id,c in pairs(creatures(after)) do
  local old=was[id]
  if old then
   local gained=creatureTotal(c)-creatureTotal(old)
   if gained>0 then total+=gained;table.insert(list,{id=id,species=c.species,amount=gained,level=c.level,levelUp=c.level>old.level}) end
  end
 end
 if total<=0 then return nil end
 table.sort(list,function(a,b) return a.id<b.id end)
 return {amount=total,creatures=list}
end
local function summary(e)
 return type(e)=='table' and finite(e.xp) and e.xp>=0 and finite(e.level) and e.level%1==0 and e.level>=1
end
-- Player XP from ui.explorer (ExplorerRules.summary). Gains only; a level rise is a level-up moment.
function H.explorerDiff(before,after)
 if not summary(before) or not summary(after) then return nil end
 local gained=after.xp-before.xp;local up=after.level>before.level
 if gained<=0 and not up then return nil end
 return {amount=math.max(0,gained),level=after.level,from=before.level,levelUp=up,into=after.into,need=after.need}
end
function H.new() return {threats={},announced={},order={},seeded=false} end
function H.chased(m) return next(m.threats)~=nil end
local function carried(run) return type(run)=='table' and run.phase=='carried' and type(run.id)=='string' end
function H.carrying(profile) return type(profile)=='table' and carried(profile.run) end
-- One carry pop-up per run id, whichever of the typed event and the profile diff arrives first.
local function announce(m,out,kind,data,inSanctuary)
 if m.announced[data.runId] then return end
 m.announced[data.runId]=true;table.insert(m.order,data.runId)
 if #m.order>32 then m.announced[table.remove(m.order,1)]=nil end
 table.insert(out,H.message(kind,data,inSanctuary))
end
-- Battle > sanctuary > chase > carry > rest. Reaching the sanctuary ends the chase look; the chase frame keeps the
-- carry portrait (H.carrying).
function H.state(m,profile,battle)
 local ui=type(profile)=='table' and type(profile.ui)=='table' and profile.ui or {}
 if battle~=nil and battle~=false then return 'battle' end
 if ui.inSanctuary==true then return 'sanctuary' end
 if H.chased(m) then return 'chase' end
 if H.carrying(profile) then return 'carry' end
 return 'rest'
end
-- Every state/context/production snapshot. The first one only records a baseline. fallback = H.fallbackSection(...).
function H.observe(m,profile,fallback)
 local out={}
 if type(profile)~='table' then return out end
 local ui=if type(profile.ui)=='table' then profile.ui else {}
 local inSanctuary=ui.inSanctuary==true;local k=H.section(ui,fallback);local run=profile.run
 local explorer=if summary(ui.explorer) then table.clone(ui.explorer) else nil
 local owned={};if type(profile.creatures)=='table' then for _,c in ipairs(profile.creatures) do if type(c)=='table' then table.insert(owned,table.clone(c)) end end end
 if m.seeded then
  if carried(run) and not (m.run and m.run.id==run.id and m.run.phase=='carried') then
   -- RunRules.receive: stolenFrom is the dropped run's id, so my own previous carry coming back is a regrab.
   local regrab=run.stolenFrom~=nil and run.stolenFrom==m.lastCarried
   announce(m,out,if regrab then 'regrab' else 'carry',{species=run.species,section=run.section,runId=run.id,stolen=if run.stolenFrom~=nil and not regrab then true else nil,trial=run.trial},inSanctuary)
  end
  if k and not inSanctuary and k~=m.lastSection then table.insert(out,H.message('section',{section=k,name=C.kingdoms[k].name},inSanctuary)) end
  if type(profile.checkpoint)=='string' and profile.checkpoint~=m.checkpoint then
   local cp=H.checkpoint(profile.checkpoint) or {id=profile.checkpoint}
   table.insert(out,H.message('checkpoint',cp,inSanctuary))
  end
  local d=H.explorerDiff(m.explorer,explorer)
  if d then
   table.insert(out,H.message('xpLine',d,inSanctuary))
   if d.levelUp then table.insert(out,H.message('levelUp',d,inSanctuary)) end
  end
  local c=H.creatureXp(m.creatures,owned);if c then table.insert(out,H.message('creatureXp',c,inSanctuary)) end
 end
 m.seeded=true
 if carried(run) then m.lastCarried=run.id end
 m.run=if type(run)=='table' then {id=run.id,phase=run.phase} else nil
 -- Gaps between section boxes don't re-banner the same section; the sanctuary resets it.
 if inSanctuary then m.lastSection=nil elseif k then m.lastSection=k end
 if type(profile.checkpoint)=='string' then m.checkpoint=profile.checkpoint end
 m.explorer=explorer;m.creatures=owned
 return out
end
-- Typed hud events (Main hud(), T3). alert/calm drive the chase; knocked and lost are gaps (their toasts stay).
function H.event(m,payload,inSanctuary)
 local out={}
 if type(payload)~='table' then return out end
 local kind=payload.kind
 if (kind=='carry' or kind=='regrab') and type(payload.runId)=='string' then
  announce(m,out,kind,{species=payload.species,section=payload.section,runId=payload.runId,stolen=payload.stolen,trial=payload.trial,auto=payload.auto},inSanctuary)
 elseif kind=='alert' and section(payload.section) then
  m.threats[payload.section]=true
  table.insert(out,H.message('alert',{guardian=payload.guardian,guardianId=payload.guardianId,section=payload.section,sectionName=payload.sectionName,eggId=payload.eggId},inSanctuary))
 elseif kind=='calm' and section(payload.section) then
  m.threats[payload.section]=nil
 elseif kind=='safe' then
  table.insert(out,H.message('safe',{species=payload.species,runId=payload.runId},inSanctuary))
 elseif kind=='xp' and finite(payload.amount) and payload.amount>0 then
  table.insert(out,H.message('xp',{amount=payload.amount,source=payload.source,level=payload.level},inSanctuary))
 end
 return out
end
return H

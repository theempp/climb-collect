-- C03 run authority: a deterministic, server-only simulation (decision record: v1-services-architecture.md).
-- Input = defender snapshot + attacker team + plan (lane per attacker, optional ability second) + seed.
-- The same input always yields the same outcome and replay events, so the server's result is final and the
-- client only plays the events back. No client-reported damage, timing or outcome is ever accepted.
local Rules=if script then require(script.Parent.OutpostRules) else require('./OutpostRules')
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local Sim={version=1,dt=.5}
local strong={Water='Fire',Fire='Nature',Nature='Earth',Earth='Crystal',Crystal='Cosmic',Cosmic='Water'}
local function element(a,b) return if strong[a]==b then 1.3 elseif strong[b]==a then .8 else 1 end
local function stats(c,variance)
 local s=C.byId[c.species];local factor=(1+(c.level-1)*.065)*variance
 return {hp=math.floor(s.health*factor*3*(if c.specialization=='Vitality' then 1.25 else 1)),attack=s.attack*factor*(if c.specialization=='Power' then 1.2 else 1),
  guard=if c.specialization=='Guard' then .15 else 0,element=s.element,legendary=s.rarity=='Legendary'}
end
local function mix(seed,i) local x=(seed+i*2654435761)%2147483647;x=(x*48271)%2147483647;x=(x*48271)%2147483647;return .95+(x%1001)/10000 end
-- plan = {lanes={1..3 per attacker}, ability={seconds|false per attacker}}; validated by the caller too.
function Sim.validPlan(plan,count)
 if type(plan)~='table' or type(plan.lanes)~='table' or #plan.lanes~=count then return false end
 for k,l in pairs(plan.lanes) do if type(k)~='number' or k%1~=0 or k<1 or k>count or type(l)~='number' or l%1~=0 or l<1 or l>3 then return false end end
 if plan.ability~=nil then
  if type(plan.ability)~='table' then return false end
  for k,t in pairs(plan.ability) do if type(k)~='number' or k%1~=0 or k<1 or k>count or (t~=false and (type(t)~='number' or t~=t or t%1~=0 or t<0 or t>Config.outpost.replaySeconds)) then return false end end
 end
 return true
end
function Sim.run(defense,attackers,plan,seed)
 assert(Rules.validSnapshot(defense),'invalid defense')
 assert(#attackers>=1 and #attackers<=3 and Sim.validPlan(plan,#attackers),'invalid plan')
 local events={};local t=0
 local function emit(kind,data) if #events<59 or (kind=='end' and #events<60) then data.t=t;data.kind=kind;table.insert(events,data) end end
 local lanes={{},{},{}}
 local total,destroyed=0,0
 for slot,pieceId in ipairs(defense.slots) do
  if pieceId then
   local piece=Rules.byId[pieceId];local lane=lanes[Rules.lanes[slot]]
   lane.structures=lane.structures or {};lane.traps=lane.traps or {}
   if piece.slot=='trap' then table.insert(lane.traps,{slot=slot,piece=piece})
   else table.insert(lane.structures,{slot=slot,id=pieceId,gate=piece.slot=='gate',hp=piece.hp,max=piece.hp});total+=piece.hp end
  end
 end
 for i,lane in ipairs(lanes) do
  lane.structures=lane.structures or {};lane.traps=lane.traps or {}
  -- gate stands behind the center walls
  table.sort(lane.structures,function(a,b) if a.gate~=b.gate then return not a.gate end return a.slot<b.slot end)
  local d=defense.defenders[i]
  if d then local st=stats(d,mix(seed,100+i));lane.defender={species=d.species,hp=st.hp,max=st.hp,st=st};total+=st.hp end
 end
 local team={}
 for i,c in ipairs(attackers) do
  local st=stats(c,mix(seed,i))
  table.insert(team,{i=i,species=c.species,lane=plan.lanes[i],hp=st.hp,max=st.hp,st=st,slowUntil=-1,burn=0,reflect=0,ability=plan.ability and plan.ability[i] or false,used=false})
  emit('enter',{a=i,lane=plan.lanes[i]})
 end
 local function laneTarget(lane)
  for _,s in ipairs(lane.structures) do if s.hp>0 then return s,'structure' end end
  if lane.defender and lane.defender.hp>0 then return lane.defender,'defender' end
  return nil
 end
 -- traps spring once on the attackers that enter their lane
 for _,a in ipairs(team) do
  for _,trap in ipairs(lanes[a.lane].traps) do
   local dmg=math.floor(trap.piece.damage*(1-a.st.guard))
   a.hp-=dmg
   if trap.piece.effect=='slow' then a.slowUntil=3 elseif trap.piece.effect=='burn' then a.burn+=math.floor(trap.piece.damage/4) elseif trap.piece.effect=='reflect' then a.reflect=.1 end
   emit('trap',{a=a.i,slot=trap.slot,amount=dmg})
  end
 end
 local gateDown=false
 local steps=math.floor(Config.outpost.replaySeconds/Sim.dt)
 for step=1,steps do
  t=step*Sim.dt
  local alive=0
  for _,a in ipairs(team) do
   if a.hp>0 then
    if a.burn>0 and step%2==0 then a.hp-=a.burn end
    local lane=lanes[a.lane];local target,kind=laneTarget(lane)
    if not target then
     -- lane cleared: help the center lane first, then any lane with targets
     for _,li in ipairs({2,1,3}) do if laneTarget(lanes[li]) then a.lane=li;emit('move',{a=a.i,lane=li});break end end
     lane=lanes[a.lane];target,kind=laneTarget(lane)
    end
    if target then
     local dps=a.st.attack*(if t<a.slowUntil then .7 else 1)
     local dmg=dps*Sim.dt
     if a.ability and not a.used and t>=a.ability then a.used=true;dmg+=a.st.attack*(if a.st.legendary then 5 else 3);emit('ability',{a=a.i,lane=a.lane}) end
     if kind=='defender' then dmg*=element(a.st.element,target.st.element) end
     dmg=math.min(target.hp,math.floor(dmg+.5))
     target.hp-=dmg;destroyed+=dmg
     if kind=='structure' and a.reflect>0 then a.hp-=math.floor(dmg*a.reflect) end
     if target.hp<=0 then
      if kind=='structure' then emit('break',{a=a.i,slot=target.slot,gate=target.gate or nil});if target.gate then gateDown=true end
      else emit('defender_down',{a=a.i,lane=a.lane,species=target.species}) end
     end
    end
    if a.hp<=0 then emit('attacker_down',{a=a.i,lane=a.lane}) else alive+=1 end
   end
  end
  -- stationed defenders strike the first living attacker in their lane (reduced while walls still stand)
  for li,lane in ipairs(lanes) do
   local d=lane.defender
   if d and d.hp>0 then
    for _,a in ipairs(team) do
     if a.hp>0 and a.lane==li then
      local walled=false;for _,s in ipairs(lane.structures) do if s.hp>0 then walled=true end end
      local dmg=math.floor(d.st.attack*Sim.dt*(if walled then .6 else 1)*element(d.st.element,a.st.element)*(1-a.st.guard)+.5)
      a.hp-=dmg
      if a.hp<=0 then emit('attacker_down',{a=a.i,lane=li});alive-=1 end
      break
     end
    end
   end
  end
  if alive<=0 or destroyed>=total then break end
 end
 local destruction=if total>0 then math.floor(destroyed*100/total) else 100
 local stars=(if destruction>=50 then 1 else 0)+(if gateDown then 1 else 0)+(if destroyed>=total then 1 else 0)
 local left=0;for _,a in ipairs(team) do if a.hp>0 then left+=1 end end
 emit('end',{stars=stars,destruction=destruction})
 return {version=Sim.version,stars=stars,destruction=destruction,gate=gateDown,duration=t,attackersLeft=left,events=events}
end
return Sim

local Config=if script then require(script.Parent.RaidConfig) else require('./RaidConfig')
local G={}
function G.new(k,now)
 return {section=k,phase='defending',threats={},restUntil=now,targetUntil=now,attackAt=now,alertVersion=0,resolvedVersion=0}
end
function G.alert(state,userId,eggId,now)
 state.threats[userId]={eggId=eggId,at=now}
 state.alertVersion+=1
 return state
end
function G.step(state,observations,now)
 local config=Config.section(state.section);local effects={}
 for id,threat in pairs(state.threats) do
  local o=observations[id]
  if not o or not o.alive or not o.inside or now-threat.at>config.threatSeconds then state.threats[id]=nil end
 end
 if now<state.restUntil then state.phase='resting';state.target=nil;return state,effects end
 local best,bestRank,bestDistance
 for id in pairs(state.threats) do
  local o=observations[id];local rank=if o.breaking then 0 else 1
  if best==nil or rank<bestRank or (rank==bestRank and (o.distance<bestDistance or (o.distance==bestDistance and id<best))) then best=id;bestRank=rank;bestDistance=o.distance end
 end
 local current=state.target and state.threats[state.target] and observations[state.target]
 if current and now<state.targetUntil and state.alertVersion==state.resolvedVersion and not (bestRank==0 and not current.breaking) then best=state.target end
 if best~=state.target then
  state.target=best;state.targetUntil=now+config.targetDwell;state.approachUntil=now+config.approachSeconds
  effects.target=best
 end
 state.resolvedVersion=state.alertVersion
 if not best then state.phase='defending';return state,effects end
 state.phase=if now<(state.approachUntil or now) then 'approaching' else 'pursuing'
 if state.phase=='pursuing' and observations[best].distance<=config.catchRange and now>=state.attackAt then
  effects.attack=best;state.attackAt=now+config.attackCooldown
 end
 return state,effects
end
function G.normalWin(state,contributors,now)
 local effects={xp={}}
 if now<state.restUntil then return state,effects end
 state.restUntil=now+Config.section(state.section).respiteSeconds;state.phase='resting';state.target=nil;state.threats={}
 local seen={};for _,id in ipairs(contributors) do if not seen[id] then seen[id]=true;table.insert(effects.xp,id) end end
 effects.respite=true
 return state,effects
end
return G

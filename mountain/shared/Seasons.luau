-- C05 weekly seasons. Week = Monday 00:00 UTC (same boundary as the weekly quest). Rank trophies live in the
-- authoritative outpost record and change only through ranked raids. Practice and friend raids never touch them.
-- Rewards for a finished season are granted once on the next join (profile.v1.seasons ring). Soft reset PROPOSED.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local S={}
function S.tier(trophies)
 local best=Config.season.tiers[1].id
 for _,t in ipairs(Config.season.tiers) do if trophies>=t.min then best=t.id end end
 return best
end
function S.reward(tier) return Config.season.rewards[tier] end
-- Rolls a record into the current season. Only seasons the player took part in earn a reward entry.
function S.rollover(rec,now)
 local week=Config.weekIndex(now)
 if rec.season>=week then return false end
 if rec.played then
  table.insert(rec.history,{season=rec.season,trophies=rec.trophies,tier=S.tier(rec.trophies)})
  while #rec.history>Config.season.historyKeep do table.remove(rec.history,1) end
 end
 rec.trophies=math.floor(rec.trophies*Config.season.softResetFactor)
 rec.season=week;rec.played=false
 return true
end
function S.pending(history,granted)
 local list={}
 for _,h in ipairs(history) do if not table.find(granted,h.season) then table.insert(list,h) end end
 return list
end
function S.view(rec,now)
 local week=Config.weekIndex(now)
 return {season=week,trophies=rec.trophies,tier=S.tier(rec.trophies),endsAt=Config.weekStart(week+1),history=rec.history,tiers=Config.season.tiers}
end
return S

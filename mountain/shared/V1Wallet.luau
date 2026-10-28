-- One reward pipeline for receipts, dailies and seasons. Rewards are coins, normal-egg tickets,
-- cosmetics/titles/badges, capped XP/production boosts and raid tokens. Nothing here grants power or creatures.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local W={}
local kinds={coins=true,eggTickets=true,cosmetic=true,title=true,badge=true,boost=true,seconds=true,raidReroll=true,shield=true}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function W.valid(reward)
 if type(reward)~='table' then return false end
 for k,v in pairs(reward) do
  if not kinds[k] then return false end
  if (k=='cosmetic' or k=='title' or k=='badge') and (type(v)~='string' or #v==0 or #v>64) then return false end
  if k=='boost' and v~='production' and v~='xp' then return false end
  if (k=='coins' or k=='eggTickets' or k=='seconds' or k=='raidReroll' or k=='shield') and (not finite(v) or v%1~=0 or v<0 or v>100000) then return false end
 end
 return (reward.boost==nil)==(reward.seconds==nil)
end
-- Mutates a profile draft. Returns what was actually granted (caps applied) or nil if invalid.
function W.grant(p,reward,now)
 if type(p)~='table' or type(p.v1)~='table' or not W.valid(reward) then return nil end
 local v=p.v1;local got={}
 if reward.coins then p.coins+=reward.coins;got.coins=reward.coins end
 if reward.eggTickets then local before=v.eggTickets;v.eggTickets=math.min(Config.wallet.maxEggTickets,before+reward.eggTickets);got.eggTickets=v.eggTickets-before end
 if reward.cosmetic then v.cosmetics[reward.cosmetic]=true;got.cosmetic=reward.cosmetic end
 if reward.title then v.titles[reward.title]=true;got.title=reward.title end
 if reward.badge then v.badges[reward.badge]=true;got.badge=reward.badge end
 for _,token in ipairs({'raidReroll','shield'}) do
  if reward[token] then local before=v.tokens[token] or 0;v.tokens[token]=math.min(Config.wallet.maxTokens,before+reward[token]);got[token]=v.tokens[token]-before end
 end
 if reward.boost then
  -- Capped stacking: remaining boost time never exceeds the cap.
  local current=math.max(now,v.boosts[reward.boost] or 0)
  v.boosts[reward.boost]=math.floor(math.min(now+Config.wallet.boostCapSeconds,current+reward.seconds))
  got.boost=reward.boost;got.seconds=v.boosts[reward.boost]-current
 end
 return got
end
function W.boostActive(p,kind,now) return type(p.v1)=='table' and (p.v1.boosts[kind] or 0)>now end
return W

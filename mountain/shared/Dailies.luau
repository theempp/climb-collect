-- C07 dailies. Pure functions over profile.v1.daily; the server is the only caller (progress comes from
-- server hooks, never from client claims). One global reset: 00:00 UTC daily, Monday 00:00 UTC weekly.
-- Login streak is HARD: a missed UTC day resets it (LOCKED). Track length 7 and the quest pool are PROPOSED.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local Schema=if script then require(script.Parent.V1Schema) else require('./V1Schema')
local D={}
-- event: the server hook name that advances it. Rewards follow the LOCKED list: coins, egg tickets,
-- cosmetics, capped boosts. No power, no rare-creature chances.
D.pool={
 mountain={
  {id='strike_eggs',event='strike',goal=6,reward={coins=80}},
  {id='secure_creature',event='secure',goal=1,reward={coins=120}},
  {id='guardian_win',event='guardian_win',goal=1,reward={eggTickets=1}},
  {id='discover',event='discover',goal=2,reward={coins=60}},
  {id='rest_points',event='checkpoint',goal=3,reward={coins=60}},
 },
 home={
  {id='hatch_one',event='hatch',goal=1,reward={coins=80}},
  {id='bank_coins',event='bank',goal=300,reward={boost='production',seconds=900}},
  {id='incubate_two',event='incubate',goal=2,reward={coins=60}},
  {id='upgrade_once',event='upgrade',goal=1,reward={coins=90}},
 },
 social={
  {id='party_climb',event='party_expedition',goal=1,reward={coins=100}},
  {id='outpost_raid',event='raid_attack',goal=2,reward={coins=100}},
  {id='friendly_raid',event='friendly_raid',goal=1,reward={cosmetic='trim_friendship'}},
  {id='practice_raid',event='practice_raid',goal=1,reward={boost='xp',seconds=900}},
 },
}
D.weekly={
 {id='w_secure_ten',event='secure',goal=10,reward={eggTickets=3}},
 {id='w_guardians',event='guardian_win',goal=4,reward={eggTickets=2,coins=300}},
 {id='w_raids',event='raid_attack',goal=10,reward={coins=600}},
 {id='w_hatch',event='hatch',goal=8,reward={eggTickets=2,boost='xp',seconds=1800}},
}
D.groups={'mountain','home','social'}
D.byId={}
for _,g in ipairs(D.groups) do for _,q in ipairs(D.pool[g]) do q.group=g;D.byId[q.id]=q end end
for _,q in ipairs(D.weekly) do q.group='weekly';D.byId[q.id]=q end
-- Deterministic across servers (no engine Random): exact integer polynomial hash of the inputs.
local function hash(...)
 local h=7
 for _,v in ipairs({...}) do local s=tostring(v)..'|';for i=1,#s do h=(h*31+string.byte(s,i))%2147483647 end end
 return h
end
D.hash=hash
local function pick(list,seed,avoid)
 local options={};for _,q in ipairs(list) do if not avoid[q.id] then table.insert(options,q) end end
 if #options==0 then return nil end
 return options[seed%#options+1]
end
local function make(def) return {id=def.id,goal=def.goal,progress=0,claimed=false} end
function D.refresh(d,userId,now)
 local day,week=Config.dayIndex(now),Config.weekIndex(now)
 local changed=false
 if d.day~=day then
  d.day=day;d.rerolls=0;d.quests={}
  for i,g in ipairs(D.groups) do table.insert(d.quests,make(pick(D.pool[g],hash(userId,day,i),{}))) end
  changed=true
 end
 if d.week~=week then
  d.week=week;d.weeklyRerolls=0;d.weekly=make(pick(D.weekly,hash(userId,'w',week),{}))
  changed=true
 end
 return changed
end
-- Called by the server at join and whenever a new UTC day is seen while online.
function D.login(d,now)
 local day=Config.dayIndex(now)
 if d.lastLogin==day then return false end
 d.streak=if d.lastLogin==day-1 then d.streak+1 else 1
 d.lastLogin=day
 return true
end
function D.loginReward(streak)
 local track=Config.daily.login
 return track[((math.max(1,streak)-1)%#track)+1]
end
function D.claimLogin(d,now)
 local day=Config.dayIndex(now)
 local id='l:'..day
 if d.lastLogin~=day then return nil,'login_first' end
 if d.loginClaimed==day or Schema.has(d.claimed,id) then return nil,'already_claimed' end
 d.loginClaimed=day;Schema.push(d.claimed,id,32)
 return D.loginReward(d.streak),id
end
function D.track(d,userId,event,amount,now)
 if type(event)~='string' or type(amount)~='number' or amount~=amount or amount<=0 or amount%1~=0 then return {} end
 D.refresh(d,userId,now)
 local advanced={}
 local function step(q)
  if q and not q.claimed and q.progress<q.goal and D.byId[q.id] and D.byId[q.id].event==event then
   q.progress=math.min(q.goal,q.progress+amount);table.insert(advanced,q.id)
  end
 end
 for _,q in ipairs(d.quests) do step(q) end
 if d.weekly then step(d.weekly) end
 return advanced
end
local function slotQuest(d,slot)
 if slot=='weekly' then return d.weekly,'w:'..d.week end
 if type(slot)=='number' and slot%1==0 and slot>=1 and slot<=#d.quests then return d.quests[slot],'q:'..d.day..':'..slot end
 return nil
end
function D.claim(d,userId,slot,now)
 D.refresh(d,userId,now)
 local q,id=slotQuest(d,slot)
 if not q then return nil,'invalid_slot' end
 if q.claimed or Schema.has(d.claimed,id) then return nil,'already_claimed' end
 if q.progress<q.goal then return nil,'not_complete' end
 q.claimed=true;Schema.push(d.claimed,id,32)
 return D.byId[q.id].reward,id
end
-- One free reroll per day (dailies) and per week (weekly). Replaces an unclaimed quest with another
-- from the same group; progress restarts.
function D.reroll(d,userId,slot,now)
 D.refresh(d,userId,now)
 local q=slotQuest(d,slot)
 if not q then return false,'invalid_slot' end
 if q.claimed then return false,'already_claimed' end
 local weekly=slot=='weekly'
 if weekly and d.weeklyRerolls>=Config.daily.rerollsPerWeek then return false,'no_rerolls' end
 if not weekly and d.rerolls>=Config.daily.rerollsPerDay then return false,'no_rerolls' end
 local avoid={}
 for _,other in ipairs(d.quests) do avoid[other.id]=true end
 if d.weekly then avoid[d.weekly.id]=true end
 local def=D.byId[q.id]
 local list=if weekly then D.weekly else D.pool[def.group]
 local nextDef=pick(list,hash(userId,'r',d.day,d.week,slot),avoid)
 if not nextDef then return false,'no_alternatives' end
 if weekly then d.weekly=make(nextDef);d.weeklyRerolls+=1 else d.quests[slot]=make(nextDef);d.rerolls+=1 end
 return true
end
-- What the HUD may read (contract: v1-services-ui-contract.md).
function D.view(d,now)
 local quests={}
 for i,q in ipairs(d.quests) do local def=D.byId[q.id];table.insert(quests,{slot=i,id=q.id,group=def.group,event=def.event,goal=q.goal,progress=q.progress,claimed=q.claimed,reward=def.reward}) end
 local w=d.weekly and D.byId[d.weekly.id]
 local today=Config.dayIndex(now)
 return {day=d.day,week=d.week,resetAt=(today+1)*86400,weeklyResetAt=Config.weekStart(Config.weekIndex(now)+1),
  streak=d.streak,trackLength=#Config.daily.login,loginClaimable=d.lastLogin==today and d.loginClaimed~=today,
  loginReward=D.loginReward(if d.lastLogin==today then d.streak else 1),quests=quests,rerollsLeft=Config.daily.rerollsPerDay-d.rerolls,
  weekly=if w then {slot='weekly',id=d.weekly.id,event=w.event,goal=d.weekly.goal,progress=d.weekly.progress,claimed=d.weekly.claimed,reward=w.reward} else nil,
  weeklyRerollsLeft=Config.daily.rerollsPerWeek-d.weeklyRerolls}
end
return D

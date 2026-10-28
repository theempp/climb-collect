-- Profile schema 3: everything v1 services own lives under profile.v1. Schema 2 profiles migrate in place;
-- the migration only adds fields, so existing creatures, eggs, coins and custody records are untouched.
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local S={schema=3}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function int(n,lo,hi) return finite(n) and n%1==0 and n>=lo and n<=hi end
local function text(v,max) return type(v)=='string' and #v>0 and #v<=(max or 64) end
local function set(t,max)
 if type(t)~='table' then return false end
 local n=0;for k,v in pairs(t) do if not text(k) or v~=true then return false end;n+=1 end
 return n<=(max or 256)
end
local function ring(t,max)
 if type(t)~='table' then return false end
 local n=0;for k,v in pairs(t) do if not int(k,1,#t) or not text(v,128) then return false end;n+=1 end
 return n==#t and n<=max
end
local function quest(q)
 return type(q)=='table' and text(q.id) and int(q.goal,1,100000) and int(q.progress,0,100000) and type(q.claimed)=='boolean'
end
function S.new()
 return {version=1,processed={},passes={},tokens={raidReroll=0,shield=0},eggTickets=0,cosmetics={},titles={},badges={},boosts={production=0,xp=0},
  daily={day=-1,streak=0,lastLogin=-1,loginClaimed=-1,quests={},rerolls=0,week=-1,weekly=false,weeklyRerolls=0,claimed={}},
  raid={day=-1,attacks=0,loot=0,rerolls=0,practice=0,revenges=0,friendly=0,friendlyWins=0,friendlyPlayed=0},
  applied={},seasons={},seasonSeen=-1}
end
function S.valid(v)
 if type(v)~='table' or v.version~=1 then return false end
 if not ring(v.processed,Config.receipts.ring) or not ring(v.applied,200) or not set(v.passes,32) or not set(v.cosmetics) or not set(v.titles) or not set(v.badges) then return false end
 if type(v.seasons)~='table' then return false end
 for k,id in pairs(v.seasons) do if not int(k,1,#v.seasons) or not int(id,0,1e7) then return false end end
 if #v.seasons>32 or not int(v.seasonSeen,-1,1e7) then return false end
 if type(v.tokens)~='table' then return false end
 for k,n in pairs(v.tokens) do if (k~='raidReroll' and k~='shield') or not int(n,0,Config.wallet.maxTokens) then return false end end
 if not int(v.eggTickets,0,Config.wallet.maxEggTickets) then return false end
 if type(v.boosts)~='table' or not int(v.boosts.production,0,1e10) or not int(v.boosts.xp,0,1e10) then return false end
 if v.title~=nil and (not text(v.title) or not v.titles[v.title]) then return false end
 local d=v.daily
 if type(d)~='table' or not int(d.day,-1,1e7) or not int(d.streak,0,1e6) or not int(d.lastLogin,-1,1e7) or not int(d.loginClaimed,-1,1e7) or not int(d.rerolls,0,10) or not int(d.week,-1,1e7) or not int(d.weeklyRerolls,0,10) or not ring(d.claimed,32) then return false end
 if type(d.quests)~='table' or #d.quests>Config.daily.questsPerDay then return false end
 for k,q in pairs(d.quests) do if not int(k,1,#d.quests) or not quest(q) then return false end end
 if d.weekly~=false and not quest(d.weekly) then return false end
 local r=v.raid
 if type(r)~='table' then return false end
 for _,key in ipairs({'day','attacks','loot','rerolls','practice','revenges','friendly','friendlyWins','friendlyPlayed'}) do if not int(r[key],-1,1e9) then return false end end
 return true
end
-- Returns the migrated profile, or nil when it cannot be migrated safely (caller must not overwrite).
function S.migrate(p)
 if type(p)~='table' then return nil end
 if p.schema==3 then return if S.valid(p.v1) then p else nil end
 if p.schema~=2 then return nil end
 if p.v1~=nil then return nil end -- unknown pre-existing field: refuse rather than clobber
 p.v1=S.new();p.schema=3
 return p
end
-- Bounded append-only id rings used for exactly-once records.
function S.push(list,id,max)
 table.insert(list,id)
 while #list>max do table.remove(list,1) end
end
function S.has(list,id) return table.find(list,id)~=nil end
return S

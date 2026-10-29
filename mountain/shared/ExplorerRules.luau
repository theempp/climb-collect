-- Player (explorer) XP (Glassbloom P2 §2). One-time XP is derived on every read from durable flags
-- (rest-point discoveries, explorer.won, the species ledger, Trial captures); only capped repeat XP is stored.
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
-- STOP 3 (owner): secures have no daily XP cap; `secures` is only today's count (bounded for storage).
local X={cap=49980,maxLevel=50,secureCountMax=1000000,repeatCap=5,restKinds={entrance=true,recovery=true,guardian=true}}
X.starters={mossbun=true,petalyn=true,fernox=true}
-- Home-base P2 (PROPOSED): a secure pays by the creature's rarity, not its section. Legendary is never an egg (Trials stay derived).
X.secureXp={Common=6,Uncommon=12,Rare=30,Epic=70,Mythic=150}
function X.secureFor(species) local s=type(species)=='string' and C.byId[species];return s and X.secureXp[s.rarity] or 0 end
local guardianSection={};for k,g in ipairs(C.guardians) do guardianSection[g.id]=k end
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function count(n,hi) return if finite(n) then math.clamp(math.floor(n),0,hi) else 0 end
-- XP from L to L+1, and the total XP at which L starts: 20(L²−1). L50 = 49,980.
function X.need(L) return 40*L+20 end
function X.start(L) return 20*(L*L-1) end
function X.level(xp)
 if not finite(xp) or xp<0 then return 1 end
 local L=math.clamp(math.floor(math.sqrt(xp/20+1)),1,X.maxLevel)
 while L<X.maxLevel and X.start(L+1)<=xp do L+=1 end
 while L>1 and X.start(L)>xp do L-=1 end
 return L
end
function X.today(t) return math.floor((if finite(t) then t else os.time())/86400) end
-- Only the 18 free-climb rest points ('k:entrance|recovery|guardian'); legacy ids are ignored.
function X.restSection(id)
 if type(id)~='string' then return nil end
 local k,kind=id:match('^([1-6]):(%a+)$')
 return if k and X.restKinds[kind] then tonumber(k) else nil
end
-- Ledger pool: non-Legendary, non-starter species (33).
function X.ledgerable(id)
 if type(id)~='string' then return false end
 local s=C.byId[id];return s~=nil and s.rarity~='Legendary' and not X.starters[id]
end
function X.derived(p)
 local xp=0;local e=p.explorer
 if type(p.discoveries)=='table' then for id,v in pairs(p.discoveries) do local k=X.restSection(id);if k and v then xp+=25*k end end end
 if type(e)=='table' and type(e.won)=='table' then for k=1,6 do if e.won[tostring(k)]==true then xp+=100*k end end end
 if type(e)=='table' and type(e.species)=='table' then for id,v in pairs(e.species) do if v==true and X.ledgerable(id) then xp+=50 end end end
 if type(p.captures)=='table' then for id,v in pairs(p.captures) do local k=guardianSection[id];if k and v then xp+=150*k end end end
 return xp
end
-- Total player XP, capped; never errors.
function X.xp(p)
 local ok,v=pcall(function()
  local e=p.explorer;local r=if type(e)=='table' then count(e.repeatXp,X.cap) else 0
  return math.min(X.cap,X.derived(p)+r)
 end)
 return if ok and finite(v) then v else 0
end
-- Fresh bounded explorer. A field that is absent (or not a table) is seeded: species from owned earned
-- creatures (origin nil, ledgerable), won from p.wins. Unknown ids and non-true values are dropped.
local function normalize(p)
 local e=if type(p.explorer)=='table' then p.explorer else {}
 local n={v=1,repeatXp=count(e.repeatXp,X.cap),day=if finite(e.day) and e.day>=0 then math.floor(e.day) else 0,secures=count(e.secures,X.secureCountMax),repeats=count(e.repeats,X.repeatCap),species={},won={}}
 if type(e.species)=='table' then for id,v in pairs(e.species) do if v==true and X.ledgerable(id) then n.species[id]=true end end
 elseif type(p.creatures)=='table' then for _,c in ipairs(p.creatures) do if type(c)=='table' and c.origin==nil and X.ledgerable(c.species) then n.species[c.species]=true end end end
 if type(e.won)=='table' then for k=1,6 do if e.won[tostring(k)]==true then n.won[tostring(k)]=true end end
 elseif type(p.wins)=='table' then for k=1,6 do if p.wins[tostring(k)] then n.won[tostring(k)]=true end end end
 n.repeatXp=math.min(n.repeatXp,math.max(0,X.cap-X.derived({discoveries=p.discoveries,captures=p.captures,explorer=n})))
 return n
end
-- Load transform (after Custody.migrate): seed absent fields and clamp a far-future day to today.
function X.ensure(p,today)
 pcall(function()
  local n=normalize(p)
  if finite(today) and n.day>today+1 then n.day=math.max(0,math.floor(today)) end
  p.explorer=n
 end)
 return p
end
-- Total: never errors, never returns false; returns the XP gained (0 when nothing is paid).
-- kind 'win' (k = section): first engaged win sets won[k] (100k, derived), later ones pay 10k up to 5/day.
-- kind 'secure' (k = run.section): X.secureXp[rarity], no daily cap; species is first-inserted into the ledger (+50, derived).
function X.award(p,kind,k,today,species)
 local ok,gained=pcall(function()
  local before=X.xp(p);local e=normalize(p);p.explorer=e
  -- The day is monotonic: counters reset only when today is later.
  if finite(today) and math.floor(today)>e.day then e.day=math.floor(today);e.secures=0;e.repeats=0 end
  local section=type(k)=='number' and k%1==0 and k>=1 and k<=6
  if section and kind=='win' then
   if not e.won[tostring(k)] then e.won[tostring(k)]=true
   elseif e.repeats<X.repeatCap then e.repeats+=1;e.repeatXp+=10*k end
  elseif section and kind=='secure' then
   e.secures=math.min(e.secures+1,X.secureCountMax);e.repeatXp+=X.secureFor(species)
   if X.ledgerable(species) then e.species[species]=true end
  end
  e.repeatXp=math.min(e.repeatXp,math.max(0,X.cap-X.derived(p)))
  return X.xp(p)-before
 end)
 if not ok then pcall(function() if type(p.explorer)~='table' then p.explorer=nil end end) end
 return if ok and finite(gained) then math.max(0,gained) else 0
end
-- The one shared read for the client: {xp, level, into, need, cap}. At L50 into and need are 0.
function X.summary(p)
 local xp=X.xp(p);local level=X.level(xp)
 local capped=level>=X.maxLevel
 return {xp=xp,level=level,into=if capped then 0 else xp-X.start(level),need=if capped then 0 else X.need(level),cap=X.cap}
end
return X

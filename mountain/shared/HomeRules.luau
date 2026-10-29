-- Home base rules (home-base P2). Pure: every write mutates only the caller's profile (a P.transact draft) and changes
-- nothing on refusal. p.home={v=1,tier=1..4,decor={['slot']={kind='creature'|'prop',id}},stock={[propId]=n}}.
-- valid() is structural and strict (load refuses a malformed or newer home, store untouched); meaning is normalized
-- on load (a creature no longer owned or also in a habitat leaves its slot), so retuned numbers never lock a profile out.
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local T=if script then require(script.Parent.HomeTiers) else require('./HomeTiers')
local X=if script then require(script.Parent.ExplorerRules) else require('./ExplorerRules')
local Config=if script then require(script.Parent.TycoonConfig) else require('./TycoonConfig')
local H={version=1,tiers=T,habitatMax=6,maxCoins=9007199254740991}
local function integer(v,lo,hi) return type(v)=='number' and v==v and v%1==0 and v>=lo and v<=hi end
local function text(v,max) return type(v)=='string' and #v>=1 and #v<=max end
local function slotKey(k) return type(k)=='string' and k:match('^[1-9]%d?$')~=nil and integer(tonumber(k),1,T.slots) end
local function owned(p,id) for _,c in ipairs(p.creatures) do if c.id==id then return c end end end
local function inHabitat(p,id)
 local t=p.tycoon;if type(t)~='table' or type(t.habitats)~='table' then return false end
 for _,h in ipairs(t.habitats) do if h.creature==id then return true end end
 return false
end
function H.valid(home)
 if type(home)~='table' or not integer(home.v,1,H.version) or not integer(home.tier,1,#T.tiers) or type(home.decor)~='table' or type(home.stock)~='table' then return false end
 for k in pairs(home) do if k~='v' and k~='tier' and k~='decor' and k~='stock' then return false end end
 for k,d in pairs(home.decor) do
  if not slotKey(k) or type(d)~='table' or (d.kind~='creature' and d.kind~='prop') or not text(d.id,80) then return false end
  for f in pairs(d) do if f~='kind' and f~='id' then return false end end
 end
 for id,n in pairs(home.stock) do if not text(id,32) or not integer(n,0,T.stockCap) then return false end end
 return true
end
function H.ensure(p)
 if p.home==nil then p.home={v=H.version,tier=1,decor={},stock={}} end
 return p.home
end
-- Load normalize: a creature shown twice keeps its lowest slot; one not owned or standing in a habitat leaves.
-- Unknown prop ids (a newer catalog) stay as inert entries, never dropped.
function H.normalize(p)
 local home=H.ensure(p);local seen={}
 for i=1,T.slots do
  local d=home.decor[tostring(i)]
  if d and d.kind=='creature' then
   if seen[d.id] or not owned(p,d.id) or inHabitat(p,d.id) then home.decor[tostring(i)]=nil else seen[d.id]=true end
  end
 end
 return home
end
-- Owner Q10: modules 7-8 leave. Their creatures are unassigned (kept in the collection), stored egg value is paid
-- out as coins (no banking bonus), and the module + comfort coins spent on them are refunded. Idempotent.
function H.capHabitats(p)
 local t=p.tycoon;local report={refund=0,eggValue=0,unassigned={}}
 if type(t)~='table' or t.slots<=H.habitatMax then return report end
 local moduleCost={750,1200} -- TycoonConfig habitats costs[5], costs[6] before P2 (slots 6->7, 7->8)
 for slot=H.habitatMax+1,t.slots do report.refund+=moduleCost[slot-H.habitatMax] end
 for i=H.habitatMax+1,#t.habitats do
  local h=t.habitats[i]
  for l=1,h.level do report.refund+=Config.paths.habitat.costs[l] end
  report.eggValue+=h.value
  if h.creature then table.insert(report.unassigned,h.creature) end
  t.habitats[i]={level=0,kingdom=h.kingdom,eggs=0,value=0,progress=0,processCarry=0,cycle=0}
 end
 t.slots=H.habitatMax
 p.coins=math.min(H.maxCoins,p.coins+report.refund+report.eggValue)
 return report
end
-- Load transform, in the same write as Profiles.load.
function H.migrate(p) H.ensure(p);local report=H.capHabitats(p);H.normalize(p);return report end
function H.tier(p) return if type(p.home)=='table' and integer(p.home.tier,1,#T.tiers) then p.home.tier else 1 end
function H.habitatCap(p) return T.tiers[H.tier(p)].habitatCap end
function H.usable(p) return T.tiers[H.tier(p)].usable end
-- Next tier: {tier,name,rank,fee,level,ready,reason}; nil at the top tier. reason 'rank' | 'coins' | nil.
function H.quote(p)
 local n=H.tier(p)+1;local def=T.tiers[n];if not def then return nil end
 local level=X.summary(p).level
 local reason=if level<def.rank then 'rank' elseif type(p.coins)~='number' or p.coins<def.fee then 'coins' else nil
 return {tier=n,name=def.name,rank=def.rank,fee=def.fee,level=level,ready=reason==nil,reason=reason}
end
-- Raise one tier. Rank comes from ExplorerRules (server XP), never from the client.
function H.raise(p)
 local q=H.quote(p);if not q then return false,'max' end
 if not q.ready then return false,q.reason end
 H.ensure(p);p.coins-=q.fee;p.home.tier=q.tier
 return true,'raised'
end
function H.displayed(p,id)
 if type(p.home)~='table' then return false end
 for _,d in pairs(p.home.decor) do if d.kind=='creature' and d.id==id then return true end end
 return false
end
-- Place into an empty usable slot. A prop comes from stock, else is bought at its price (tier and coins checked first).
-- Returns ok, reason, bought.
function H.place(p,slot,kind,id)
 local home=H.ensure(p)
 if not integer(slot,1,T.slots) then return false,'slot' end
 if slot>H.usable(p) then return false,'locked' end
 if home.decor[tostring(slot)] then return false,'occupied' end
 if kind=='creature' then
  if type(id)~='string' or not owned(p,id) then return false,'owned' end
  if inHabitat(p,id) then return false,'habitat' end
  if H.displayed(p,id) then return false,'displayed' end
  home.decor[tostring(slot)]={kind='creature',id=id};return true,'placed',false
 elseif kind=='prop' then
  local def=type(id)=='string' and T.props[id];if not def then return false,'unknown' end
  if (home.stock[id] or 0)>0 then
   home.stock[id]-=1;if home.stock[id]==0 then home.stock[id]=nil end
   home.decor[tostring(slot)]={kind='prop',id=id};return true,'placed',false
  end
  if H.tier(p)<def.tier then return false,'tier' end
  if type(p.coins)~='number' or p.coins<def.price then return false,'coins' end
  p.coins-=def.price;home.decor[tostring(slot)]={kind='prop',id=id};return true,'placed',true
 end
 return false,'kind'
end
-- Clear a slot: a creature returns to the collection (it never left), a prop returns to stock (never sold, never lost).
function H.clear(p,slot)
 local home=H.ensure(p)
 if not integer(slot,1,T.slots) then return false,'slot' end
 local d=home.decor[tostring(slot)];if not d then return false,'empty' end
 if d.kind=='prop' then
  if (home.stock[d.id] or 0)>=T.stockCap then return false,'stock' end
  home.stock[d.id]=(home.stock[d.id] or 0)+1
 end
 home.decor[tostring(slot)]=nil
 return true,'cleared'
end
-- Read-only view for the owner's client (s.ui.home).
function H.snapshot(p)
 local n=H.tier(p);local def=T.tiers[n];local decor={}
 local home=if type(p.home)=='table' then p.home else {decor={},stock={}}
 for i=1,T.slots do local d=home.decor[tostring(i)];decor[i]=if d then {kind=d.kind,id=d.id} else false end
 return {tier=n,name=def.name,habitatCap=def.habitatCap,usable=def.usable,slots=T.slots,decor=decor,stock=table.clone(home.stock),next=H.quote(p)}
end
-- Visitor Inspect: only what stands in a habitat or a display slot. Never coins, inventory or ids.
function H.inspect(p,kind,index)
 local id
 if kind=='habitat' then
  local t=p.tycoon;if type(t)~='table' or not integer(index,1,math.min(t.slots,H.habitatMax)) then return nil end
  id=t.habitats[index].creature
 elseif kind=='decor' then
  if type(p.home)~='table' or not integer(index,1,T.slots) then return nil end
  local d=p.home.decor[tostring(index)];if not d then return nil end
  if d.kind=='prop' then local def=T.props[d.id];return if def then {kind='prop',name=def.name} else nil end
  id=d.id
 else return nil end
 local c=id and owned(p,id);local s=c and C.byId[c.species];if not s then return nil end
 return {kind='creature',species=s.id,name=s.name,rarity=s.rarity,level=c.level}
end
return H

-- C03 Defense Outpost rules (pure). The home sanctuary is never attacked; only this separate outpost.
-- LOCKED: fixed slots, pieces unlocked by play (never sold), 3 stationed defenders, capped vault that fills
-- from production, stakes = trophies + capped vault coin only, ~4h shield, 24h revenge, ~5 attacks/day,
-- Robux-egg creatures never defend or attack. PROPOSED: the piece catalog and every number (V1Config).
local Config=if script then require(script.Parent.V1Config) else require('./V1Config')
local C=if script then require(script.Parent.Catalog) else require('./Catalog')
local O={version=1}
local cfg=Config.outpost
O.slots=cfg.slots
local function won(k) return function(p) return p.wins~=nil and p.wins[tostring(k)]==true end end
local function always() return true end
O.pieces={
 {id='timber_gate',slot='gate',hp=600,unlock=always,needs='starter'},
 {id='stone_gate',slot='gate',hp=900,unlock=won(3),needs='win:3'},
 {id='astral_gate',slot='gate',hp=1300,unlock=won(6),needs='win:6'},
 {id='hedge_wall',slot='wall',hp=300,unlock=always,needs='starter'},
 {id='stone_wall',slot='wall',hp=450,unlock=function(p) return #p.creatures>=8 end,needs='creatures:8'},
 {id='crystal_wall',slot='wall',hp=600,unlock=won(4),needs='win:4'},
 {id='thorn_snare',slot='trap',damage=40,effect='slow',unlock=always,needs='starter'},
 {id='tide_pool',slot='trap',damage=30,effect='slow',unlock=won(2),needs='win:2'},
 {id='sun_glare',slot='trap',damage=55,effect='burn',unlock=won(3),needs='win:3'},
 {id='prism_mirror',slot='trap',damage=45,effect='reflect',unlock=won(4),needs='win:4'},
 {id='ember_vent',slot='trap',damage=70,effect='burn',unlock=won(5),needs='win:5'},
 {id='gravity_well',slot='trap',damage=50,effect='slow',unlock=won(6),needs='win:6'},
}
O.byId={};for _,piece in ipairs(O.pieces) do O.byId[piece.id]=piece end
-- Lane layout used by the simulation: lane 2 holds the gate.
-- Slot -> lane used by the simulation. Slot 1 (gate) sits in the center lane.
O.lanes={[1]=2,[2]=1,[3]=1,[4]=2,[5]=3,[6]=3,[7]=1,[8]=2,[9]=3,[10]=2}
local function finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
local function int(n,lo,hi) return finite(n) and n%1==0 and n>=lo and n<=hi end
function O.unlocked(p)
 local set={};for _,piece in ipairs(O.pieces) do if piece.unlock(p) then set[piece.id]=true end end
 return set
end
-- Robux-egg creatures are cosmetic/tycoon-only (decision §1/§7). The shop must stamp source='robux'.
function O.eligible(c) return type(c)=='table' and c.source~='robux' and c.paid~=true and C.byId[c.species]~=nil end
function O.defender(c) return {species=c.species,level=c.level,specialization=c.specialization} end
function O.validDefender(d)
 return type(d)=='table' and C.byId[d.species]~=nil and int(d.level,1,50) and (d.specialization==nil or table.find({'Power','Guard','Vitality'},d.specialization)~=nil)
end
function O.newSnapshot(p)
 local slots={'timber_gate','hedge_wall','hedge_wall','hedge_wall','hedge_wall','hedge_wall','thorn_snare',false,false,false}
 local defenders={}
 for _,id in ipairs(p.team or {}) do
  for _,c in ipairs(p.creatures or {}) do if c.id==id and O.eligible(c) and #defenders<cfg.defenders then table.insert(defenders,O.defender(c)) end end
 end
 return {version=1,rev=1,slots=slots,defenders=defenders}
end
function O.validSnapshot(s)
 if type(s)~='table' or s.version~=1 or not int(s.rev,1,1e9) or type(s.slots)~='table' or type(s.defenders)~='table' then return false end
 for key in pairs(s.slots) do if not int(key,1,#O.slots) then return false end end
 for i,kind in ipairs(O.slots) do
  local v=s.slots[i]
  if v~=false and (type(v)~='string' or not O.byId[v] or O.byId[v].slot~=kind) then return false end
 end
 if s.slots[1]==false then return false end -- the gate slot is always filled
 if #s.defenders>cfg.defenders then return false end
 for key,d in pairs(s.defenders) do if not int(key,1,#s.defenders) or not O.validDefender(d) then return false end end
 return true
end
-- Owner edits. p = the owner's live profile (unlocks come from play only).
function O.setSlot(p,s,slot,pieceId)
 if not int(slot,1,#O.slots) then return false,'invalid_slot' end
 if pieceId==false then
  if slot==1 then return false,'gate_required' end
  s.slots[slot]=false;s.rev+=1;return true
 end
 local piece=O.byId[pieceId]
 if not piece then return false,'unknown_piece' end
 if piece.slot~=O.slots[slot] then return false,'wrong_slot_type' end
 if not piece.unlock(p) then return false,'locked' end
 s.slots[slot]=pieceId;s.rev+=1;return true
end
function O.setDefenders(p,s,ids)
 if type(ids)~='table' or #ids>cfg.defenders then return false,'invalid_defenders' end
 local list,seen={},{}
 for key,id in pairs(ids) do
  if not int(key,1,#ids) or type(id)~='string' or seen[id] then return false,'invalid_defenders' end
  seen[id]=true
  local found
  for _,c in ipairs(p.creatures) do if c.id==id then found=c end end
  if not found then return false,'not_owned' end
  if not O.eligible(found) then return false,'robux_creature_excluded' end
  table.insert(list,O.defender(found))
 end
 s.defenders=list;s.rev+=1;return true
end
-- Vault: fills at a share of production, capped by hours of that fill (PROPOSED).
function O.vaultCap(rate)
 return math.floor(math.clamp(rate*cfg.vaultShareOfProduction*cfg.vaultCapHours,cfg.vaultMinCap,cfg.vaultMaxCap))
end
function O.accrue(vault,now)
 local elapsed=math.max(0,now-(vault.updatedAt or now))
 vault.cap=O.vaultCap(vault.rate or 0)
 vault.coins=math.min(vault.cap,(vault.coins or 0)+elapsed*(vault.rate or 0)*cfg.vaultShareOfProduction/3600)
 vault.updatedAt=now
 return vault
end
function O.shielded(rec,now) return rec.shield~=nil and (rec.shield.untilTime or 0)>now end
function O.hitShield(rec,now) rec.shield.untilTime=math.max(rec.shield.untilTime or 0,now+cfg.shieldSeconds) end
-- Paid shield: at most one per UTC day, total remaining protection capped (PROPOSED 4h each, 8h cap).
function O.paidShield(rec,now)
 local day=Config.dayIndex(now)
 if rec.shield.paidDay==day and rec.shield.paidCount>=cfg.paidShieldsPerDay then return false,'daily_paid_shield_used' end
 local remaining=math.max(0,(rec.shield.untilTime or 0)-now)
 if remaining+cfg.paidShieldSeconds>cfg.shieldCapSeconds then return false,'shield_cap' end
 rec.shield.untilTime=now+remaining+cfg.paidShieldSeconds
 if rec.shield.paidDay~=day then rec.shield.paidDay=day;rec.shield.paidCount=0 end
 rec.shield.paidCount+=1
 return true
end
function O.bucket(trophies) return math.floor(math.max(0,trophies)/cfg.bucketSize) end
function O.newRecord(userId,snapshot,now)
 return {v=1,owner=userId,name='',snapshot=snapshot,trophies=0,season=Config.weekIndex(now),history={},
  vault={coins=0,cap=cfg.vaultMinCap,rate=0,updatedAt=now},shield={untilTime=0,paidDay=-1,paidCount=0},
  revenge={},lock=false,results={},log={},transfers={},paidShields={},attacks={},pending=false,lastActive=now,logSeen=0,played=false}
end
local function list(t,max) if type(t)~='table' or #t>max then return false end;for k in pairs(t) do if not int(k,1,#t) then return false end end;return true end
function O.validRecord(r)
 if type(r)~='table' or r.v~=1 or not int(r.owner,1,1e15) or not O.validSnapshot(r.snapshot) then return false end
 if not int(r.trophies,0,1e7) or not int(r.season,0,1e7) or type(r.vault)~='table' or not finite(r.vault.coins) or r.vault.coins<0 then return false end
 if type(r.shield)~='table' or not finite(r.shield.untilTime) or type(r.revenge)~='table' then return false end
 if not list(r.results,cfg.resultKeep) or not list(r.log,cfg.logKeep) or not list(r.transfers,20) or not list(r.paidShields,20) or not list(r.attacks,64) or not list(r.history,Config.season.historyKeep) then return false end
 return true
end
-- Seeded bot outposts keep matchmaking alive at low population. Deterministic per seed.
function O.bot(seed,trophies)
 local tier=math.clamp(math.floor(trophies/300)+1,1,6)
 local x=seed%2147483647
 local function nextInt(n) x=(x*48271)%2147483647;return x%n+1 end
 local gates={'timber_gate','timber_gate','stone_gate','stone_gate','stone_gate','astral_gate'}
 local walls={'hedge_wall','hedge_wall','stone_wall','stone_wall','crystal_wall','crystal_wall'}
 local traps={}
 for _,piece in ipairs(O.pieces) do if piece.slot=='trap' and (piece.needs=='starter' or tonumber(piece.needs:match('win:(%d)') or '9')<=tier) then table.insert(traps,piece.id) end end
 local slots={gates[tier]}
 for i=2,6 do slots[i]=if nextInt(6)<=3+math.floor(tier/2) then walls[tier] else false end
 for i=7,10 do slots[i]=if nextInt(6)<=2+math.floor(tier/2) then traps[nextInt(#traps)] else false end
 local defenders={}
 for i=1,cfg.defenders do
  local k=math.clamp(tier-1+nextInt(2)-1,1,6);local s=C.species[(k-1)*6+math.clamp(nextInt(4),1,5)]
  table.insert(defenders,{species=s.id,level=math.clamp(tier*7+nextInt(6)-3,1,50)})
 end
 return {version=1,rev=1,slots=slots,defenders=defenders}
end
return O

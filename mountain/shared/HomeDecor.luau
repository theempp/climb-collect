-- Decor/display rules for the home base. Owner-placed items are decor and displays ONLY; the production layout never moves.
-- Profile record p.tycoon.home={version=1,owned={[itemId]=true},decor={[slotId]=itemId},showcase={[slotId]=creatureId}}.
-- Costs are provisional (PROPOSED, coin sink, no paid advantage). Pure rules; ownership and proximity stay server-side.
local L=if script then require(script.Parent.HomeLayout) else require('./HomeLayout')
local H={version=1,maxId=80}
H.items={
 {id='lantern_post',name='Lantern Post',kind='decor',cost=40},
 {id='flower_barrel',name='Flower Barrel',kind='decor',cost=40},
 {id='pennant_banner',name='Pennant Banner',kind='decor',cost=60},
 {id='stone_bench',name='Stone Bench',kind='decor',cost=60},
 {id='garden_arch',name='Garden Arch',kind='decor',cost=90},
 {id='wind_chime',name='Wind Chime',kind='decor',cost=120},
 {id='trophy_shelf',name='Trophy Shelf',kind='display',cost=100},
 {id='creature_pedestal',name='Creature Pedestal',kind='display',cost=0},
}
H.byId={};for _,item in H.items do H.byId[item.id]=item end
local function text(v) return type(v)=='string' and #v>0 and #v<=H.maxId end
local function find(p,id) for _,c in ipairs(p.creatures) do if c.id==id then return c end end end
function H.fresh() return {version=1,owned={creature_pedestal=true},decor={},showcase={}} end
-- Structural validity only (fail closed). Creature ownership is checked when placing and when a snapshot is built.
function H.valid(h)
 if type(h)~='table' or h.version~=1 or type(h.owned)~='table' or type(h.decor)~='table' or type(h.showcase)~='table' then return false end
 for id,v in pairs(h.owned) do if v~=true or not H.byId[id] then return false end end
 for slotId,itemId in pairs(h.decor) do
  local slot=type(slotId)=='string' and L.decorSlot(slotId);local item=H.byId[itemId]
  if not slot or not item or item.kind~=slot.kind or item.id=='creature_pedestal' or not h.owned[itemId] then return false end
 end
 for slotId,creatureId in pairs(h.showcase) do
  local slot=type(slotId)=='string' and L.decorSlot(slotId)
  if not slot or slot.kind~='display' or not text(creatureId) or not h.owned.creature_pedestal then return false end
 end
 return true
end
function H.ensure(t) if not t.home then t.home=H.fresh() end return t.home end
function H.buy(p,itemId)
 local h=H.ensure(p.tycoon);local item=H.byId[itemId]
 if not item or h.owned[itemId] or item.cost<0 or p.coins<item.cost then return false end
 p.coins-=item.cost;h.owned[itemId]=true;return true
end
-- Decor item into a decor slot, or the trophy shelf into a display slot (shelf and creature showcase share the slot).
function H.place(p,slotId,itemId)
 local h=H.ensure(p.tycoon);local slot=type(slotId)=='string' and L.decorSlot(slotId);local item=H.byId[itemId]
 if not slot or not item or item.id=='creature_pedestal' or item.kind~=slot.kind or not h.owned[itemId] then return false end
 h.decor[slotId]=itemId;h.showcase[slotId]=nil;return true
end
function H.clear(p,slotId)
 local h=H.ensure(p.tycoon);if type(slotId)~='string' or not L.decorSlot(slotId) then return false end
 local had=h.decor[slotId]~=nil or h.showcase[slotId]~=nil;h.decor[slotId]=nil;h.showcase[slotId]=nil;return had
end
-- Pose an owned creature on a display slot. The same creature may stand in a habitat and on a display.
function H.showcase(p,slotId,creatureId)
 local h=H.ensure(p.tycoon);local slot=type(slotId)=='string' and L.decorSlot(slotId)
 if not slot or slot.kind~='display' or not h.owned.creature_pedestal or (creatureId~=nil and (not text(creatureId) or not find(p,creatureId))) then return false end
 for other,id in pairs(h.showcase) do if creatureId and id==creatureId and other~=slotId then h.showcase[other]=nil end end
 h.decor[slotId]=nil;h.showcase[slotId]=creatureId;return true
end
-- Minimal read-only view for visitors: species, level, rate, kingdom. No ids, coins, eggs, bag or upgrade levels.
function H.visitorView(p,Tycoon,Catalog)
 local t=p.tycoon;local view={habitats={},showcase={},decor={},trophies=p.trophies or 0,palette=t.cosmetic}
 for i=1,t.slots do
  local h=t.habitats[i];local c=h.creature and find(p,h.creature)
  if c then
   local rate=Tycoon.rate(p,i);local species=Catalog.byId[c.species]
   view.habitats[i]={species=species and species.name or '?',level=c.level,rate=math.floor(rate*10+.5)/10,kingdom=species and species.kingdom}
  end
 end
 local home=t.home
 if home then
  for slotId,creatureId in pairs(home.showcase) do
   local c=find(p,creatureId);local species=c and Catalog.byId[c.species]
   if species then view.showcase[slotId]={species=species.name,level=c.level,kingdom=species.kingdom} end
  end
  for slotId,itemId in pairs(home.decor) do view.decor[slotId]=itemId end
 end
 return view
end
function H.describe(view,kind,key)
 if kind=='habitat' then
  local row=view.habitats[key];if not row then return 'Empty habitat.' end
  return string.format('%s · level %d · %s eggs/hour',row.species,row.level,tostring(row.rate))
 elseif kind=='display' then
  local row=view.showcase[key];if row then return string.format('%s · level %d (on display)',row.species,row.level) end
  if view.decor[key]=='trophy_shelf' then return string.format('Trophy shelf · %d trophies',view.trophies) end
  return 'Empty display.'
 end
 return 'Nothing to inspect.'
end
return H

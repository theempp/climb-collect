local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local Theme=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local Hub={}
local center=Enum.TextXAlignment.Center
-- Upgrade path art (approved icon set).
local pathIcon={habitat='Heart',habitats='Heart',production='Egg',storage='Chest',bag='Gift',banking='Coin',automation='Gear'}
function Hub.render(screen,data)
 local t=data.tycoon;if not t then screen:info('Heart','Sanctuary loading','Waiting for your production profile.',64);return end
 local s=T.snapshot(data);local at=data.ui and data.ui.atHome==true;local compact=screen.compact
 local function action(card,name,label,payload,enabled,pos,size,variant)
  if not at then label='Return to your plot' end
  return screen:action(card,name,label,'Tycoon',payload,at and enabled~=false,pos,size,variant)
 end
 -- Upgrade tile (cc/05 LV4 Forge tiles): level chip, path art, effect line, price CTA; gold when maxed.
 local function upgradeTile(g,order,path,slot)
  local q=T.quote(data,path,slot);local def=T.config.paths[path]
  local card=W.card(g,'UpgradeTile_'..path..tostring(slot or ''),nil,nil,if q then Theme.alt else Theme.cta.base,def.label..(if slot then ' '..slot else ''));card.LayoutOrder=order
  local a=if compact then 40 else 56
  W.icon(card,pathIcon[path] or 'Gear',UDim2.fromOffset(a,a),UDim2.fromOffset(10,34))
  W.chip(card,if q then 'Lv '..q.level..' → '..q.next else 'Max',if q then Theme.navy else Theme.ok.base,UDim2.new(1,-a-30,0,22),UDim2.fromOffset(a+20,36))
  local effect=if q then T.upgradeEffect(data,path)..(if q.requirement~='' then ' · '..q.requirement else '') else 'Maximum level reached. No resets.'
  local e=W.label(card,effect,UDim2.new(1,-20,1,-(a+96)),UDim2.fromOffset(10,a+40),nil,12,Theme.ink,center,true);e.TextYAlignment=Enum.TextYAlignment.Top
  action(card,'Upgrade_'..path..tostring(slot or ''),if q then q.cost..' coins' else 'Maximum level',{op='upgrade',path=path,slot=slot},q~=nil and q.ready and data.coins>=q.cost,UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),'gold')
  return card
 end
 if not at then screen:info('Map','Manage from your sanctuary','You can inspect production anywhere. Return to your own plot to collect, bank, assign and upgrade.',64) end
 if screen.tab=='Habitats' then
  if screen.tycoonRoster then
   local index=screen.tycoonRoster
   local header=screen:info('Creature','Assign habitat '..index,'Choose an owned creature. Your combat team stays unchanged; each creature produces in one habitat.',72,180)
   W.button(header,'BackHabitats','Back to habitats',UDim2.fromOffset(168,44),UDim2.new(1,-180,.5,-24),function() screen.tycoonRoster=nil;screen:render(false) end)
   local assigned={};for i,h in ipairs(t.habitats) do if h.creature then assigned[h.creature]=i end end
   local page=screen.tycoonPage or 1;local pages=math.max(1,math.ceil(#data.creatures/12));page=math.min(page,pages)
   local first,last=(page-1)*12+1,math.min(page*12,#data.creatures)
   local g=screen:grid('Roster',last-first+1,170,if compact then 168 else 196)
   for i=first,last do
    local c=data.creatures[i];local species=C.byId[c.species];local where=assigned[c.id]
    local card=W.card(g,'Roster_'..c.id,nil,nil,Theme.rarity[species.rarity],species.name);card.LayoutOrder=i
    local a=if compact then 52 else 72
    W.portrait(card,species,UDim2.fromOffset(a,a),UDim2.new(.5,-a/2,0,32))
    W.chip(card,if where==index then 'Here' elseif where then 'Habitat '..where else 'Available',if where==index then Theme.ok.base elseif where then Theme.navy else Theme.cta.base,UDim2.new(1,-40,0,20),UDim2.new(0,20,0,36+a))
    W.label(card,'Lv '..c.level..' · '..species.element,UDim2.new(1,-16,0,16),UDim2.new(0,8,1,-70),Theme.display,12,Theme.ink,center)
    local payload=if where and where~=index then {op='swap',slot=index,other=where} else {op='assign',slot=index,id=c.id}
    action(card,'Assign_'..c.id,if where==index then 'Assigned here' elseif where then 'Swap '..where else 'Assign',payload,where~=index,UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),'gold')
   end
   local pageRow=screen:info('Scroll','Roster '..page..' / '..pages,'12 creatures per page',64,150)
   W.button(pageRow,'RosterNext','Next page',UDim2.fromOffset(138,44),UDim2.new(1,-150,.5,-24),function() screen.tycoonPage=page%pages+1;screen:render(false) end)
   return
  end
  screen:info('Heart','Production assignments','Two habitats to start, eight at full expansion. Matching kingdoms add +5%; shared kingdoms add up to +10%.',64)
  -- Habitat card: creature portrait, storage bar, rate/kingdom pills, one row of five actions.
  local rowW=screen.rowW;local bw=math.floor((rowW-20-4*8)/5)
  for i,h in ipairs(s.habitats) do
   if h.unlocked then
    local c=h.creature and (function() for _,v in ipairs(data.creatures) do if v.id==h.creature then return v end end end)()
    local species=c and C.byId[c.species]
    local card=W.card(screen.body,'Habitat_'..i,UDim2.new(1,-8,0,if compact then 128 else 140),nil,if c then Theme.alt else Theme.navy)
    local a=66
    W.slot(card,species,UDim2.fromOffset(a,a),UDim2.fromOffset(10,8))
    local x=a+22;local infoW=rowW-x-10
    W.label(card,string.upper('Habitat '..i..' · '..(if species then species.name else 'Empty')),UDim2.fromOffset(math.floor(infoW*.5),24),UDim2.fromOffset(x,8),Theme.label,20,Theme.ink).Name='Title'
    local bar=W.progress(card,if h.capacity>0 then h.eggs/h.capacity else 0,UDim2.fromOffset(math.floor(infoW*.5)-10,18),UDim2.fromOffset(x,44),if h.eggs>=h.capacity then Theme.bar.max else Theme.bar.ready)
    W.label(bar.Parent,h.eggs..' / '..h.capacity..' eggs',UDim2.fromScale(1,1),nil,Theme.display,12,Theme.ink,center).ZIndex=2
    local px=x+math.floor(infoW*.5);local pw=math.floor((infoW*.5-24)/3)
    W.pill(card,'Egg',string.format('%.1f/h',h.rate),pw,24,UDim2.fromOffset(px,10))
    W.pill(card,nil,C.kingdoms[h.kingdom].name:match('^%S+'),pw,24,UDim2.fromOffset(px+pw+8,10))
    W.pill(card,nil,string.format('+%.0f%%',h.bonus*100),pw,24,UDim2.fromOffset(px+2*(pw+8),10))
    W.chip(card,'Comfort Lv '..h.level,Theme.navy,UDim2.fromOffset(pw*2+8,22),UDim2.fromOffset(px,42))
    local size=UDim2.fromOffset(bw,44)
    local function at_(n) return UDim2.new(0,10+(n-1)*(bw+8),1,-52) end
    W.button(card,'Choose_'..i,'Choose',size,at_(1),function() screen.tycoonRoster=i;screen.tycoonPage=1;screen:render(false) end,'blue',at)
    action(card,'Unassign_'..i,'Unassign',{op='assign',slot=i},c~=nil,at_(2),size,'quiet')
    action(card,'Collect_'..i,if h.eggs==0 then 'Producing' elseif s.bag.eggs>=s.bagCapacity then 'Bag full' else 'Collect',{op='collect',slot=i},h.eggs>0 and s.bag.eggs<s.bagCapacity,at_(3),size,'ok')
    local q=T.quote(data,'habitat',i)
    local up=action(card,'Upgrade_habitat'..i,if q then q.cost..' coins' else 'Max level',{op='upgrade',path='habitat',slot=i},q~=nil and q.ready and data.coins>=q.cost,at_(4),size,'gold')
    up:SetAttribute('Tooltip',if q then T.upgradeEffect(data,'habitat')..(if q.requirement~='' then ' · '..q.requirement else '') else 'Maximum level reached.')
    action(card,'Attune_'..i,if data.unlocked<=1 then 'Need kingdom' else 'Attune',{op='attune',slot=i,kingdom=h.kingdom%data.unlocked+1},data.unlocked>1,at_(5),size,'tert')
   else screen:info('Padlock','Habitat '..i..' · locked','Expand habitat modules in Upgrades. Creatures and progress are never reset.',56) end
  end
 elseif screen.tab=='Upgrades' then
  local _,slot,sw=screen:banner('Chest','Linear upgrades','Buy each next level. No prestige, resets or daily streaks.',Theme.alt,{w=138,h=40})
  W.pill(slot,'Coin',tostring(data.coins),sw-4,30,UDim2.fromOffset(4,5))
  local g=screen:grid('UpgradeTiles',5,160,if compact then 176 else 200)
  for i,path in ipairs({'habitats','production','storage','bag','banking'}) do upgradeTile(g,i,path) end
 elseif screen.tab=='Automation' then
  local track=W.panel(screen.body,'AutomationTrack',UDim2.new(1,-8,0,104),nil,Theme.navy)
  W.label(track,'AUTOMATION STAGES',UDim2.new(1,-24,0,22),UDim2.fromOffset(14,6),Theme.label,19,Theme.ink).Name='Title'
  local labels,done={},{};for i,name in ipairs(T.config.automation) do labels[i]=name:match('^[^·]+'):gsub('%s+$','');done[i]=t.levels.automation>=i end
  W.track(track,labels,done,UDim2.new(1,-24,0,70),UDim2.fromOffset(12,30),Theme.tert)
  local g=screen:grid('AutomationUpgrade',2,220,if compact then 160 else 180)
  upgradeTile(g,1,'automation')
  local note=W.card(g,'OfflineProtection',nil,nil,Theme.navy,'Offline protection');note.LayoutOrder=2
  W.icon(note,'Padlock',UDim2.fromOffset(44,44),UDim2.fromOffset(10,36))
  local n=W.label(note,'Offline production stops at eight hours or full storage. Automation resumes online; stored eggs never expire.',UDim2.new(1,-74,1,-42),UDim2.fromOffset(64,36),nil,13,Theme.muted,nil,true);n.TextYAlignment=Enum.TextYAlignment.Top
 elseif screen.tab=='Cosmetics' then
  screen:banner('Gift','Sanctuary palettes','Free palettes reuse your kingdoms. They never affect production or combat.',Theme.panelPurple)
  local g=screen:grid('Palettes',#T.config.cosmetics,150,if compact then 150 else 170)
  for i,id in ipairs(T.config.cosmetics) do
   local kingdom=nil;for _,k in ipairs(C.kingdoms) do if k.element==id then kingdom=k end end
   local selected=t.cosmetic==id
   local card=W.card(g,'Palette_'..id..'_Card',nil,nil,if selected then Theme.cta.base else Theme.alt,id);card.LayoutOrder=i
   -- Swatch = the kingdom's own in-world palette (game data), shown as two discs.
   if kingdom then
    for j,col in ipairs({kingdom.color,kingdom.accent}) do local d=W.round(W.frame(card,'Swatch'..j,UDim2.fromOffset(40,40),UDim2.new(.5,(j-1)*34-37,0,34),Color3.fromRGB(table.unpack(col))),20);W.stroke(d,Theme.outline,2) end
   end
   if selected then W.chip(card,'Selected',Theme.ok.base,UDim2.new(1,-30,0,20),UDim2.new(0,15,0,80)) end
   action(card,'Palette_'..id,if selected then 'Applied' else 'Apply '..id,{op='cosmetic',id=id},not selected,UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),'gold')
  end
 elseif screen.tab=='Facilities' then
  local g=screen:grid('Facilities',2,240,if compact then 150 else 170)
  for i,v in ipairs({{'Training','Training','Creature','Train and specialize your companions.'},{'Hatchery','Eggs','Egg','Hatchable eggs stay separate from production. Three free incubators.'}}) do
   local card=W.card(g,v[1],nil,nil,Theme.alt,v[1]);card.LayoutOrder=i
   local a=if compact then 48 else 60
   W.icon(card,v[3],UDim2.fromOffset(a,a),UDim2.fromOffset(10,34))
   local d=W.label(card,v[4],UDim2.new(1,-a-30,0,a),UDim2.fromOffset(a+20,34),nil,13,Theme.ink,nil,true);d.TextYAlignment=Enum.TextYAlignment.Top
   W.button(card,'Open'..v[1],'Open '..v[1],UDim2.new(1,-20,0,44),UDim2.new(0,10,1,-52),function() screen:open(v[2]) end,'gold')
  end
 else
  -- Overview: four stat cells, then collect + bank offer cards (robloxf1-v2/07 layout).
  local row=W.frame(screen.body,'Stats',UDim2.new(1,-8,0,if compact then 52 else 62));row.BackgroundTransparency=1
  local cw=math.floor((screen.rowW-24)/4)
  for i,v in ipairs({{'Heart','Habitats',s.slots..' / 8'},{'Egg','Eggs / hour',string.format('%.1f',s.rate)},{'EggCracked','Stored',s.eggs},{'Coin','Coins',data.coins}}) do
   W.stat(row,v[1],v[2],v[3],cw,if compact then 52 else 62,UDim2.fromOffset((i-1)*(cw+8),0))
  end
  local g,gw=screen:grid('ProductionCards',2,260,if compact then 140 else 156)
  local collect=W.card(g,'Collect',nil,nil,Theme.ok.base,'Batch collection');collect.LayoutOrder=1
  local bank=W.card(g,'Bank',nil,nil,Theme.cta.base,'Bank production eggs');bank.LayoutOrder=2
  for _,v in ipairs({{collect,'Egg','Bag '..s.bag.eggs..' / '..s.bagCapacity,'Production eggs cannot hatch.'},{bank,'Coin',s.bag.value..' coins','Banking bonus '..(t.levels.banking*2.5)..'%'}}) do
   local a=if compact then 40 else 48
   W.icon(v[1],v[2],UDim2.fromOffset(a,a),UDim2.fromOffset(10,34))
   W.pill(v[1],nil,v[3],math.min(150,gw-a-34),24,UDim2.fromOffset(a+22,36))
   W.label(v[1],v[4],UDim2.new(1,-a-34,0,18),UDim2.fromOffset(a+22,64),nil,12,Theme.ink)
  end
  action(collect,'CollectProduction',if s.eggs==0 then 'No eggs ready yet' elseif s.bag.eggs>=s.bagCapacity then 'Bag full · bank eggs' else 'Collect all eggs',{op='collect',slot=0},s.eggs>0 and s.bag.eggs<s.bagCapacity,UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),'blue')
  action(bank,'BankProduction',if s.bag.eggs==0 then 'Collect eggs first' else 'Bank eggs for coins',{op='bank'},s.bag.eggs>0,UDim2.new(0,10,1,-52),UDim2.new(1,-20,0,44),'blue')
  screen:info('Scroll','How production works','Assign both starter habitats. Every tenth egg has bonus value. Full storage pauses production; collect and bank to make room.',64)
 end
end
return Hub

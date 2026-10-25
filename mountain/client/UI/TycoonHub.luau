local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local T=require(game.ReplicatedStorage.MountainShared.Tycoon)
local W=require(script.Parent.Widgets)
local Hub={}
function Hub.render(screen,data)
 local t=data.tycoon;if not t then screen:note('Sanctuary loading','Waiting for your production profile.');return end
 local s=T.snapshot(data);local at=data.ui and data.ui.atHome==true
 local function action(card,name,label,payload,enabled) return screen:action(card,name,label,'Tycoon',payload,at and enabled~=false) end
 local function upgrade(path,slot)
  local q=T.quote(data,path,slot);local def=T.config.paths[path]
  local detail=if q then 'Level '..q.level..' → '..q.next..' · '..q.cost..' coins\n'..T.upgradeEffect(data,path)..(if q.requirement~='' then '\n'..q.requirement else '') else 'Maximum level reached. No resets required.'
  local card=screen:note(def.label..(if slot then ' '..slot else ''),detail,if q and q.requirement~='' then 205 else 180)
  action(card,'Upgrade_'..path..tostring(slot or ''),if q then 'Upgrade · '..q.cost..' coins' else 'Maximum level',{op='upgrade',path=path,slot=slot},q~=nil and q.ready and data.coins>=q.cost)
 end
 if not at then screen:note('Manage from your sanctuary','You can inspect production anywhere. Return to your own plot to collect, bank, assign and upgrade.',118) end
 if screen.tab=='Habitats' then
  if screen.tycoonRoster then
   local index=screen.tycoonRoster
   local header=screen:note('Assign habitat '..index,'Choose an owned creature. Combat team stays unchanged. Each creature can produce in one habitat.',155)
   W.button(header,'BackHabitats','Back to habitats',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),function() screen.tycoonRoster=nil;screen:render(false) end)
   local assigned={};for i,h in ipairs(t.habitats) do if h.creature then assigned[h.creature]=i end end
   local page=screen.tycoonPage or 1;local pages=math.max(1,math.ceil(#data.creatures/12));page=math.min(page,pages)
   for i=(page-1)*12+1,math.min(page*12,#data.creatures) do
    local c=data.creatures[i];local species=C.byId[c.species];local where=assigned[c.id]
    local card=screen:note(species.name..' · '..species.rarity,'Level '..c.level..' · '..species.element..(if where then '\nAssigned to habitat '..where else '\nAvailable for production'),160)
    local payload=if where and where~=index then {op='swap',slot=index,other=where} else {op='assign',slot=index,id=c.id}
    action(card,'Assign_'..c.id,if where==index then 'Assigned here' elseif where then 'Swap with habitat '..where else 'Assign to habitat '..index,payload,where~=index)
   end
   local pageRow=screen:note('Roster '..page..' / '..pages,'12 creatures per page',150)
   W.button(pageRow,'RosterNext','Next page',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),function() screen.tycoonPage=page%pages+1;screen:render(false) end)
   return
  end
  screen:note('Production assignments','Two habitats to start, eight at full expansion. Match a kingdom for +5%; shared creature kingdoms add up to +10%.',130)
  for i,h in ipairs(s.habitats) do
   if h.unlocked then
    local c=h.creature and (function() for _,v in ipairs(data.creatures) do if v.id==h.creature then return v end end end)()
    local title='Habitat '..i..' · '..(if c then C.byId[c.species].name else 'Empty')
    local card=screen:note(title,string.format('%d / %d eggs · %.1f / hour\n%s · bonus %.0f%% · comfort %d',h.eggs,h.capacity,h.rate,C.kingdoms[h.kingdom].name,h.bonus*100,h.level),205)
    W.button(card,'Choose_'..i,'Choose creature',UDim2.new(.5,-21,0,44),UDim2.new(0,14,1,-56),function() screen.tycoonRoster=i;screen.tycoonPage=1;screen:render(false) end,'blue',at)
    action(card,'Unassign_'..i,'Unassign',{op='assign',slot=i},c~=nil).Position=UDim2.new(.5,7,1,-56)
    card['Unassign_'..i].Size=UDim2.new(.5,-21,0,44)
    local collect=screen:note('Habitat '..i..' storage','Stored eggs stay here when you change creatures.',145)
    action(collect,'Collect_'..i,'Collect batch',{op='collect',slot=i},h.eggs>0 and s.bag.eggs<s.bagCapacity)
    upgrade('habitat',i)
    local attune=screen:note('Habitat '..i..' kingdom',C.kingdoms[h.kingdom].name..' · cycle through your unlocked kingdoms',150)
    action(attune,'Attune_'..i,'Attune next kingdom',{op='attune',slot=i,kingdom=h.kingdom%data.unlocked+1},data.unlocked>1)
   else screen:note('Habitat '..i..' · locked','Expand habitat modules in Upgrades. Your existing creatures and progress are never reset.',100) end
  end
 elseif screen.tab=='Upgrades' then
  screen:note('Linear progression',data.coins..' coins · buy each next level. No prestige, resets or daily streaks.',105)
  for _,path in ipairs({'habitats','production','storage','bag','banking'}) do upgrade(path) end
 elseif screen.tab=='Automation' then
  for i,name in ipairs(T.config.automation) do screen:note('Stage '..i..' · '..name,if t.levels.automation>=i then 'Installed' elseif t.levels.automation+1==i then 'Next upgrade · prerequisites and price below' else 'Unlock earlier stages first',95) end
  upgrade('automation')
  screen:note('Offline storage protection','Offline production stops at eight hours or full habitat storage. Automation resumes online; stored eggs never expire.',120)
 elseif screen.tab=='Cosmetics' then
  screen:note('Sanctuary palette','Free visual palettes reuse your kingdoms. They do not affect production or combat.',105)
  for _,id in ipairs(T.config.cosmetics) do local card=screen:note(id,if t.cosmetic==id then 'Selected palette' else 'Apply to habitat trim and machines',145);action(card,'Palette_'..id,'Apply '..id,{op='cosmetic',id=id},t.cosmetic~=id) end
 elseif screen.tab=='Facilities' then
  for _,v in ipairs({{'Training','Training','Train and specialize your existing companions.'},{'Hatchery','Eggs','Hatchable creature eggs stay separate from production eggs. Three free incubators.'}}) do
   local card=screen:note(v[1],v[3],155);W.button(card,'Open'..v[1],'Open '..v[1],UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),function() screen:open(v[2]) end)
  end
 else
  screen:note('Your production sanctuary',string.format('%d / 8 habitats · %.1f eggs / hour\n%d stored eggs · %d coins',s.slots,s.rate,s.eggs,data.coins),130)
  local collect=screen:note('Batch collection','Bag '..s.bag.eggs..' / '..s.bagCapacity..' · production eggs cannot hatch. Collect from all active habitats.',165)
  action(collect,'CollectProduction','Collect all production eggs',{op='collect',slot=0},s.eggs>0 and s.bag.eggs<s.bagCapacity)
  local bank=screen:note('Bank production eggs','Bag base value: '..s.bag.value..' coins · banking bonus '..(t.levels.banking*2.5)..'%\nBank manually until advanced automation.',165)
  action(bank,'BankProduction','Bank eggs for coins',{op='bank'},s.bag.eggs>0)
  screen:note('How production works','Assign both starter habitats. Every tenth egg has bonus value. Full storage pauses production; collect and bank to make room. Upgrade storage for longer expeditions.',140)
 end
end
return Hub

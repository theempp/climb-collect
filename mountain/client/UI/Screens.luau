local Players=game:GetService('Players')
local GuiService=game:GetService('GuiService')
local UIS=game:GetService('UserInputService')
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local R=require(game.ReplicatedStorage.MountainShared.Rules)
local P=require(game.ReplicatedStorage.MountainShared.UIPresentation)
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local S={};S.__index=S
local tabs={Creatures={'Collection','Team','Training','Evolution'},Discovery={'Eggs','Field guide'},Sanctuary={'Overview','Habitats','Facilities'},Mountain={'Map','Quests','Trials'},Social={'Party','Challenges','Defense'},Profile={'Overview','Achievements','Recognition'},Shop={'Cosmetics','Convenience'},Settings={'Accessibility','Audio','Quick'}}
local aliases={Collection='Creatures',Training='Creatures',Incubator='Discovery',Eggs='Discovery',Travel='Mountain',Journal='Mountain',Competition='Social'}
local aliasTabs={Training='Training',Incubator='Eggs',Eggs='Eggs',Travel='Map',Journal='Quests',Competition='Challenges'}
function S.new(root,store,feedback,onClose)
 return setmetatable({root=root,store=store,feedback=feedback,onClose=onClose,selected={},query='',rarity='All',sort='Name',page=1,tickers={},actionButtons={}},S)
end
function S:open(name)
 if not tabs[aliases[name] or name] then return end
 self.hub=aliases[name] or name;self.tab=aliasTabs[name] or tabs[self.hub][1];self.detail=nil;self.page=1
 if self.store.profile then self.selected=table.clone(self.store.profile.team) end
 self:render(false)
end
function S:close()
 if self.shade then self.shade:Destroy();self.shade=nil end
 self.hub=nil;self.detail=nil;self.tickers={};self.actionButtons={};GuiService.SelectedObject=nil
 if self.onClose then self.onClose() end
end
function S:back() if self.detail then self.detail=nil;self:render(false) else self:close() end end
function S:send(action,payload)
 local id=self.store:request(action,payload)
 if not id then self.feedback:toast('That action is already waiting for a response. Check the status below.') end
end
function S:action(parent,name,label,action,payload,enabled,pos,size)
 if parent:FindFirstChild('Description') then parent.Description.Size=UDim2.new(1,-28,0,math.max(40,parent.Size.Y.Offset-106)) end
 local b=W.button(parent,name,label,size or UDim2.new(1,-28,0,44),pos or UDim2.new(0,14,1,-56),function() self:send(action,if type(payload)=='function' then payload() else payload) end,'blue',enabled)
 table.insert(self.actionButtons,{button=b,action=action,enabled=enabled~=false,label=label});return b
end
function S:blocked(title,description,actionLabel)
 local f=W.row(self.body,title,description,182)
 f.Description.Size=UDim2.new(1,-28,0,74)
 W.button(f,'Unavailable',actionLabel or 'Not available in this build',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),nil,'quiet',false)
 return f
end
function S:note(title,description,height) return W.row(self.body,title,description,height or 105) end
function S:pending()
 for _,v in ipairs(self.actionButtons) do
  local busy=false
  for _,p in pairs(self.store.pending) do if p.action==v.action then busy=true;break end end
  W.enable(v.button,v.enabled and not busy,if busy then 'Waiting…' else v.label)
 end
 if self.status then
  local message='Changes are confirmed by the server.';local retryId=nil
  for id,p in pairs(self.store.pending) do
   if p.status=='timeout' then message='No reply yet. Retry safely with the same request.';retryId=id;break
   else message='Waiting for '..p.action..'…' end
  end
  if not next(self.store.pending) and self.store.lastResult then message=self.store.lastResult.message or message end
  self.status.Text=message;self.retry.Visible=retryId~=nil;self.retryId=retryId
 end
end
function S:tick()
 for _,fn in ipairs(self.tickers) do fn() end
end
function S:render(preserve)
 if not self.hub or not self.store.profile then return end
 local focused=UIS:GetFocusedTextBox()
 if preserve and focused and self.shade and focused:IsDescendantOf(self.shade) then self.deferredRender=true;return end
 self.deferredRender=false
 local selected=GuiService.SelectedObject;local selectedName=if selected then selected.Name else nil;local selectedPath={}
 if preserve and selected and self.shade and selected:IsDescendantOf(self.shade) then
  local cursor=selected;while cursor and cursor~=self.shade do table.insert(selectedPath,1,cursor.Name);cursor=cursor.Parent end
 end
 local scroll=if preserve and self.body then self.body.CanvasPosition else Vector2.zero
 if self.shade then self.shade:Destroy() end
 self.tickers={};self.actionButtons={}
 local data=self.store.profile;local view=self.root.AbsoluteSize
 local width=math.min(850,view.X-20);local height=math.min(660,view.Y-16)
 self.shade=W.frame(self.root,'HubShade',UDim2.fromScale(1,1),nil,T.navy);self.shade.BackgroundTransparency=.23;self.shade.ZIndex=20;self.shade.Active=true
 local f=W.panel(self.shade,'Hub',UDim2.fromOffset(width,height),UDim2.fromScale(.5,.5));f.AnchorPoint=Vector2.new(.5,.5);f.ZIndex=21
 local title=if self.detail then 'Creature details' else self.hub
 W.text(f,title,UDim2.new(1,-140,0,44),UDim2.fromOffset(18,5),T.display,24,T.ink)
 W.button(f,'Back',if self.detail then 'Back' else 'Close',UDim2.fromOffset(86,44),UDim2.new(1,-98,0,7),function() self:back() end,'quiet')
 local tabScroll=W.new('ScrollingFrame',f,{Name='Tabs',Size=UDim2.new(1,-24,0,48),Position=UDim2.fromOffset(12,57),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.X,ScrollingDirection=Enum.ScrollingDirection.X,ScrollBarThickness=0})
 W.list(tabScroll,8,true)
 for _,name in ipairs(tabs[self.hub]) do
  W.button(tabScroll,'Tab'..name,name,UDim2.fromOffset(if #name>10 then 136 else 112,44),nil,function() self.tab=name;self.detail=nil;self.page=1;self:render(false) end,if name==self.tab then 'gold' else 'quiet')
 end
 self.body=W.scroll(f,'Content',UDim2.new(1,-24,1,-158),UDim2.fromOffset(12,108))
 self.status=W.text(f,'',UDim2.new(1,-124,0,38),UDim2.new(0,16,1,-44),nil,12,T.muted)
 self.retry=W.button(f,'Retry','Retry',UDim2.fromOffset(88,44),UDim2.new(1,-100,1,-48),function() if self.retryId then self.store:retry(self.retryId) end end,'gold');self.retry.Visible=false
 if self.hub=='Creatures' then self:creatures(data,width)
 elseif self.hub=='Discovery' then self:discovery(data)
 elseif self.hub=='Sanctuary' then self:sanctuary(data)
 elseif self.hub=='Mountain' then self:mountain(data)
 elseif self.hub=='Social' then self:social(data)
 elseif self.hub=='Profile' then self:profile(data)
 elseif self.hub=='Shop' then self:shop()
 elseif self.hub=='Settings' then self:settings(data) end
 self.body.CanvasPosition=scroll;self:pending();self:tick()
 if UIS.GamepadEnabled and UIS:GetLastInputType()==Enum.UserInputType.Gamepad1 then
  local target=if selectedName and preserve then self.shade:FindFirstChild(selectedName,true) else nil
  GuiService.SelectedObject=if target and target:IsA('GuiButton') and target.Selectable then target else f.Back
 end
end
function S:creatures(data,width)
 if self.detail then
  local c=R.find(data.creatures,self.detail);if not c then self.detail=nil;self:render(false);return end
  local info=P.creature(c);local species=C.byId[c.species]
  local hero=self:note(info.name..'  ·  Lv '..c.level,species.rarity..'  /  '..species.element..'  /  '..species.role..'\n'..species.feature,146)
  hero.Title.Size=UDim2.new(1,-130,0,28);hero.Description.Size=UDim2.new(1,-130,0,94)
  W.portrait(hero,species,UDim2.fromOffset(92,92),UDim2.new(1,-108,0,12))
  self:note('Companion statistics',string.format('Attack %d     Health %d\nXP %d / %d   ·   Evolution stage %d',math.floor(info.attack),math.floor(info.health),c.xp,info.xpRequired,R.stage(c.level)),108)
  local abilities=info.abilityNames or {species.role..' special'}
  self:note('Manual specials',table.concat(abilities,'  /  ')..'\nBasic attacks run automatically during encounters.',110)
  local evo=self:note('Evolution journey','Stage I: Lv 1   →   Stage II: Lv 15   →   Stage III: Lv 35\nEvolution happens automatically when your creature reaches the level.',122)
  W.progress(evo,math.min(c.level/35,1),UDim2.new(1,-28,0,8),UDim2.new(0,14,1,-17),T.purple)
  local at=data.ui and data.ui.atRefuge
  local train=self:note('Training session','15 coins grants 80 XP. '..(if at then 'Your creature is at the training refuge.' else 'Visit the training station at the refuge.'),150)
  self:action(train,'Train','Train · 15 coins','Train',c.id,at and data.coins>=15 and c.level<50)
  if c.specialization then self:note('Specialization',c.specialization..' is your permanent focus.',88)
  elseif c.level>=25 then
   local row=self:note('Choose a permanent focus','Power: attack +20% · Guard: 15% defense · Vitality: health +25%.',154)
   for i,choice in ipairs({'Power','Guard','Vitality'}) do
    W.button(row,'Focus'..choice,choice,UDim2.new(1/3,-14,0,44),UDim2.new((i-1)/3,10,1,-56),function()
     self.feedback:confirm('Choose '..choice..'?',species.name..' will keep this specialization permanently.',function() self:send('Specialize',{id=c.id,choice=choice}) end)
    end,'gold')
   end
  else self:note('Specialization unlocks at Lv 25','Choose Power, Guard or Vitality when this creature reaches level 25.',96) end
  return
 end
 if self.tab=='Team' then
  local team=self:note('Three companions. One expedition.','Select up to three creatures below, then save your team. '..#self.selected..' / 3 selected.',152)
  self:action(team,'Equip','Save team ('..#self.selected..'/3)','Equip',function() return table.clone(self.selected) end,#self.selected>0)
 elseif self.tab=='Training' then
  self:note('Grow your team','Train at the refuge for 15 coins / 80 XP. Open a creature to see its statistics and train.',110)
 elseif self.tab=='Evolution' then
  self:note('A journey, not a second purchase','Your creatures evolve automatically at levels 15 and 35. Specialization opens at 25. Select a creature for its timeline.',112)
 end
 local compact=self.root.AbsoluteSize.Y<390
 local filters=W.panel(self.body,'Filters',UDim2.new(1,-8,0,if compact then 54 else 110))
 local box=W.round(W.new('TextBox',filters,{Name='Search',Size=UDim2.new(1,-24,0,44),Position=UDim2.fromOffset(12,10),Text=self.query,PlaceholderText='Search your creatures',ClearTextOnFocus=false,TextColor3=T.ink,PlaceholderColor3=T.muted,BackgroundColor3=T.navy,Font=T.body,TextSize=T.size(15),BorderSizePixel=0}),8)
 box.FocusLost:Connect(function() self.query=box.Text;self.page=1;self:render(false) end)
 local rarities={'All','Common','Uncommon','Rare','Epic','Mythic','Legendary'}
 local rarityButton=W.button(filters,'Rarity','Rarity: '..self.rarity,UDim2.new(.6,-18,0,44),UDim2.fromOffset(12,62),function() self.rarity=rarities[(table.find(rarities,self.rarity) or 1)%#rarities+1];self.page=1;self:render(false) end,'quiet')
 local sortButton=W.button(filters,'Sort','Sort: '..self.sort,UDim2.new(.4,-18,0,44),UDim2.new(.6,6,0,62),function() self.sort=if self.sort=='Name' then 'Level' elseif self.sort=='Level' then 'Rarity' else 'Name';self:render(true) end,'quiet')
 if compact then
  box.Size=UDim2.new(.4,-12,0,44);box.Position=UDim2.fromOffset(6,5);box.PlaceholderText='Search'
  rarityButton.Size=UDim2.new(.3,-8,0,44);rarityButton.Position=UDim2.new(.4,0,0,5)
  sortButton.Size=UDim2.new(.3,-8,0,44);sortButton.Position=UDim2.new(.7,0,0,5)
 end
 local list=P.filterCreatures(data,self.query,self.rarity,self.sort)
 if #list==0 then self:note('No matching companions','Try another filter, or discover eggs on your next climb. Your collection stays safe.',108);return end
 local columns=if width<600 then 2 else 3
 local cardHeight=if compact then 150 else 210
 local grid=W.frame(self.body,'CreatureGrid',UDim2.new(1,-8,0,math.ceil(math.min(12,#list-(self.page-1)*12)/columns)*(cardHeight+12)));grid.BackgroundTransparency=1
 W.new('UIGridLayout',grid,{CellSize=UDim2.new(1/columns,-8,0,cardHeight),CellPadding=UDim2.fromOffset(10,12),SortOrder=Enum.SortOrder.LayoutOrder})
 for index=(self.page-1)*12+1,math.min(#list,self.page*12) do
  local c=list[index];local s=C.byId[c.species];local card=W.panel(grid,'Creature_'..c.id,nil,nil,T.card)
  W.portrait(card,s,UDim2.fromOffset(if compact then 48 else 76,if compact then 48 else 76),UDim2.new(.5,if compact then -24 else -38,0,5))
  W.text(card,s.name,UDim2.new(1,-16,0,24),UDim2.fromOffset(8,if compact then 50 else 87),T.bold,16).TextXAlignment=Enum.TextXAlignment.Center
  W.text(card,'Lv '..c.level..' · '..s.rarity,UDim2.new(1,-16,0,24),UDim2.fromOffset(8,if compact then 72 else 114),nil,12,T.rarity[s.rarity]).TextXAlignment=Enum.TextXAlignment.Center
  local selected=table.find(self.selected,c.id)
  local label=if self.tab=='Team' then (if selected then 'Selected '..selected else 'Select') else 'Details'
  W.button(card,'Details_'..c.id,label,UDim2.new(1,-20,0,44),UDim2.new(0,10,1,-56),function()
   if self.tab=='Team' then
    local n=table.find(self.selected,c.id)
    if n then table.remove(self.selected,n) elseif #self.selected<3 then table.insert(self.selected,c.id) else self.feedback:toast('Your team has three slots. Deselect one first.') end
   else self.detail=c.id end
   self:render(self.tab=='Team')
  end,if selected and self.tab=='Team' then 'gold' else 'blue')
 end
 if #list>12 then
  local pages=W.frame(self.body,'Pages',UDim2.new(1,-8,0,50));pages.BackgroundTransparency=1
  W.button(pages,'Previous','Previous',UDim2.new(.5,-8,0,44),nil,function() self.page=math.max(1,self.page-1);self:render(false) end,'quiet',self.page>1)
  W.button(pages,'Next','Next',UDim2.new(.5,-8,0,44),UDim2.fromScale(.5,0),function() self.page+=1;self:render(false) end,'quiet',self.page*12<#list)
 end
end
function S:discovery(data)
 if self.tab=='Field guide' then
  local owned={};for _,c in ipairs(data.creatures) do owned[c.species]=true end
  for k,kingdom in ipairs(C.kingdoms) do
   local found=0;for _,s in ipairs(C.species) do if s.kingdom==k and owned[s.id] then found+=1 end end
   self:note(kingdom.name,found..' / 6 regular species discovered.\nLook for nests, wild encounters, puzzles and exploration branches.',105)
  end;return
 end
 local active=0;for _,e in ipairs(data.eggs) do if e.readyAt then active+=1 end end
 self:note('Carry. Secure. Hatch.','#'..#data.cargo..' / 3 carried eggs  ·  '..#data.eggs..' secured  ·  '..active..' / 3 incubators\nExtract at a checkpoint. Incubation and hatching are free at the refuge.',116)
 if #data.cargo+#data.eggs==0 then self:note('Your next companion is out there','Follow the Blossom Gardens flags. Find a nest or win a wild encounter, then secure the egg at a checkpoint.',120) end
 for _,e in ipairs(data.cargo) do self:note(C.byId[e.species].name..' egg · unsecured','Carry to a checkpoint. A fall leaves your eggs in a recoverable pack for three minutes.',106) end
 for _,e in ipairs(data.eggs) do
  local species=C.byId[e.species];local card=self:note(species.name..' egg',species.rarity..' · secured',178)
  local timer=W.text(card,'',UDim2.new(1,-28,0,26),UDim2.fromOffset(14,78),T.bold,14,T.gold)
  local at=data.ui and data.ui.atRefuge
  local b=self:action(card,'Egg_'..e.id,if e.readyAt then 'Hatch free' else 'Incubate free',if e.readyAt then 'Hatch' else 'Incubate',e.id,at and (if e.readyAt then e.readyAt<=self.store:now() else active<3))
  table.insert(self.tickers,function()
   local remain=if e.readyAt then P.remaining(e.readyAt,self.store:now()) else nil
   timer.Text=if remain then (if remain==0 then 'Ready to hatch' else P.formatTime(remain)..' remaining') else P.formatTime(C.incubation[species.rarity])..' incubation'
   if not at then timer.Text..=' · visit refuge' end
   for _,v in ipairs(self.actionButtons) do if v.button==b then v.enabled=at and (if remain then remain==0 else active<3) end end
  end)
 end
end
function S:sanctuary(data)
 if self.tab=='Habitats' then
  self:blocked('Creature habitats','Habitat construction and creature placement are not connected to this mountain review. Your owned creatures already contribute to its income.','Habitat placement unavailable')
  self:blocked('Building upgrades','The sanctuary environment exists separately. Building levels, costs and plot ownership need its gameplay service.','Building upgrades unavailable')
 elseif self.tab=='Facilities' then
  local row=self:note('Training refuge','Open your collection to train, inspect evolution stages and select a specialization.',150)
  W.button(row,'OpenTraining','Open training',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),function() self:open('Training') end,'gold')
  local egg=self:note('Incubation','Three incubators. Free incubation. Secured eggs only. Visit the refuge to start or hatch.',150)
  W.button(egg,'OpenEggs','Open hatchery',UDim2.new(1,-28,0,44),UDim2.new(0,14,1,-56),function() self:open('Eggs') end)
  self:blocked('Facility upgrades','Facility expansion has no purchase service in this review. Existing training and incubation remain available.')
 else
  self:note('Your sanctuary collection',#data.creatures..' companions · '..data.coins..' coins\nThis review uses the expedition refuge. Personal sanctuary arrival is awaiting the sanctuary connection.',120)
  local income=self:note('Collect creature income','All owned creatures contribute. Offline accrual is capped at eight hours. Collection settles the current server balance.',160)
  self:action(income,'CollectIncome','Collect income','CollectIncome',nil,data.ui and data.ui.atRefuge)
  local at=data.ui and data.ui.atRefuge
  self:note(if at then 'At the refuge' else 'Return to the refuge',if at then 'Use the nearby training, incubation and challenge stations, or manage your collection here.' else 'Fast travel from a discovered checkpoint. The mountain menu shows available destinations.',104)
 end
end
function S:mountain(data)
 if self.tab=='Quests' then
  local q=P.quest(data);local card=self:note(q.title,q.detail,122)
  W.progress(card,q.progress/math.max(q.total,1),UDim2.new(1,-28,0,8),UDim2.new(0,14,1,-18),T.green)
  for k,kingdom in ipairs(C.kingdoms) do self:note(kingdom.name,if data.wins[tostring(k)] then 'Guardian defeated · next ascent unlocked' elseif R.canEnter(data,k) then 'Explore, strengthen your team and challenge '..C.guardians[k].name else 'Defeat '..C.guardians[k-1].name..' to unlock this kingdom.',94) end
  self:blocked('Daily missions','Daily objectives and claimable daily rewards are not connected. This journal tracks your actual mountain progression.','Daily rewards unavailable')
 elseif self.tab=='Trials' then
  for k,g in ipairs(C.guardians) do
   local owned=data.captures[g.id];local won=data.wins[tostring(k)]
   self:note(g.name..' · '..g.title,(if owned then 'CAPTURED · replay for mastery; no duplicate capture.' elseif won then 'Trial available at the kingdom altar.' else 'Defeat the normal Guardian to unlock its Trial.')..'\n3 clean dodges + 4 resolved patterns'..(if k==5 then ' + interrupt the golden heart.' elseif k==6 then ' + align three constellation stones.' else '.'),132)
  end
 else
  local f=self:note('Six kingdoms. One summit.','Travel from a checkpoint or refuge. Only discovered checkpoints are available. Travelling secures carried eggs.',146)
  self:action(f,'ReturnRefuge','Return to refuge','Travel','refuge',data.ui and (data.ui.atRefuge or data.ui.nearCheckpoint))
  for k,kingdom in ipairs(C.kingdoms) do
   local unlocked=R.canEnter(data,k);local color=Color3.fromRGB(table.unpack(kingdom.accent))
   local f=self:note(kingdom.name,(if data.wins[tostring(k)] then 'Guardian defeated' elseif unlocked then 'Explore and challenge '..C.guardians[k].name else 'Locked · defeat '..C.guardians[k-1].name)..'\n'..(data.resources[tostring(k)] or 0)..' '..kingdom.resource,174)
   W.stroke(f,color,2)
   for i,point in ipairs({'entrance','recovery','guardian'}) do
    local id=k..':'..point;local found=data.discoveries[id]==true
    self:action(f,'Travel_'..k..'_'..point,if found then point:gsub('^%l',string.upper) else 'Undiscovered','Travel',id,unlocked and found and data.ui and (data.ui.atRefuge or data.ui.nearCheckpoint),UDim2.new((i-1)/3,10,1,-58),UDim2.new(1/3,-14,0,46))
   end
  end
 end
end
function S:social(data)
 if self.tab=='Party' then
  local battle=self.store.battle
  self:note('Climb together','Friends can join the same Guardian at its altar while the encounter is open. Your teammates attack automatically and share the battle.',116)
  if battle and battle.members then
   for _,m in ipairs(battle.members) do self:note(m.name or tostring(m.userId),'In your current Guardian encounter',82) end
  else self:note('No active co-op encounter','Meet other climbers at a Guardian altar to battle together.',92) end
  self:blocked('Party finder & invitations','Persistent parties, invitations and readiness are not connected in this review. No invitations are sent from this screen.','Invitations unavailable')
 elseif self.tab=='Defense' then
  local f=self:note('Your equipped team is your defense','Register a snapshot for asynchronous challenges. Your creatures and eggs cannot be stolen. UserId: '..Players.LocalPlayer.UserId,164)
  self:action(f,'RegisterDefense','Register defense','RegisterDefense',nil,data.ui and data.ui.atRefuge)
  for i,id in ipairs(data.team) do local c=R.find(data.creatures,id);if c then self:note('Slot '..i..' · '..C.byId[c.species].name,'Level '..c.level..' · '..(c.specialization or 'No specialization'),82) end end
  self:blocked('Sanctuary defense layout','Defense placement and raid buildings need the sanctuary gameplay service. Your team snapshot challenge is available above.')
 else
  self:note('Sanctuary challenges',data.trophies..' trophies · challenge a saved defense\nA registered opponent can be offline. Practice is clearly separate from another player.',116)
  local f=self:note('Challenge a defense','Enter another player’s numeric UserId. Use 0 for the existing practice defense.',222)
  local box=W.round(W.new('TextBox',f,{Name='OpponentId',Size=UDim2.new(1,-28,0,44),Position=UDim2.fromOffset(14,106),Text=self.opponent or '',PlaceholderText='Player UserId (0 = practice)',ClearTextOnFocus=false,TextColor3=T.ink,PlaceholderColor3=T.muted,BackgroundColor3=T.navy,Font=T.body,TextSize=T.size(15),BorderSizePixel=0}),8)
  box.FocusLost:Connect(function() self.opponent=box.Text;if self.deferredRender then task.defer(function() self:render(true) end) end end)
  self:action(f,'ChallengeDefense','Challenge','ChallengeDefense',function() self.opponent=box.Text;return tonumber(box.Text) end,data.ui and data.ui.atRefuge)
  local timer=W.text(f,'',UDim2.new(1,-28,0,23),UDim2.fromOffset(14,79),nil,12,T.gold)
  table.insert(self.tickers,function() local n=P.remaining(data.competitionAt,self.store:now());timer.Text=if n>0 then 'Next challenge in '..P.formatTime(n) else 'Ready at refuge' end)
  self:blocked('Raids & friend challenges','Live raid management and friend matchmaking are not connected. Saved defense challenges use the existing server rules.','Live raids unavailable')
 end
end
function S:profile(data)
 local captures,wins=0,0;for _ in pairs(data.captures) do captures+=1 end;for _ in pairs(data.wins) do wins+=1 end
 if self.tab=='Overview' then
  self:note(Players.LocalPlayer.DisplayName,'@'..Players.LocalPlayer.Name..'\n'..#data.creatures..' companions · '..captures..' / 6 Guardians · '..data.trophies..' trophies',124)
  self:note('Expedition record',wins..' / 6 kingdom Guardians defeated\n'..(if data.discoveries.summit then 'Summit reached · Sovereign Explorer' else 'Summit journey in progress'),112)
 elseif self.tab=='Achievements' then
  for k,g in ipairs(C.guardians) do self:note(g.name..' mastery',(if data.wins[tostring(k)] then '✓ Normal victory earned' else '○ Normal victory not yet earned')..'\n'..(if data.captures[g.id] then '✓ Trial capture earned' else '○ Trial capture not yet earned'),104) end
  self:note('Sovereign Explorer',if data.discoveries.summit then '✓ Summit reached' else '○ Defeat Caeloryn and reach the summit',88)
 else
  self:note('Trophy gallery',data.trophies..' trophies earned in the existing mountain and challenge systems. Guardian captures and summit achievements appear in your profile.',108)
  self:blocked('Leaderboards & in-world rankings','A ranking service and authoritative in-world display feed are not connected. No sample players or invented ranks are shown.','Rankings unavailable')
  self:blocked('Badges & equipped titles','Badge awards and title selection need their platform/profile services. Earned mountain milestones remain visible in Achievements.','Title selection unavailable')
 end
end
function S:shop()
 if self.tab=='Cosmetics' then
  self:note('Make the mountain yours','Cosmetics and personal style belong here: appearances, decorations and visual effects. Your combat strength comes from play.',118)
  self:blocked('Cosmetic collection','No approved product catalog or entitlement service is connected to this review. Items and prices will appear when available.','Checkout unavailable')
 else
  self:note('Fair conveniences','Only noncompetitive convenience belongs here. No paid creature odds, capture advantage or power purchases.',112)
  self:blocked('Convenience catalog','No approved convenience products or receipt validation are connected. There are no purchases available.','Checkout unavailable')
 end
end
function S:settings(data)
 local prefs=(data.ui and data.ui.settings) or {}
 local function toggle(key,title,description)
  local f=self:note(title,description,148)
  self:action(f,'Setting_'..key,if prefs[key] then 'On · tap to turn off' else 'Off · tap to turn on','Settings',function() return {[key]=not prefs[key]} end,true)
 end
 if self.tab=='Audio' then
  for _,v in ipairs({{'musicVolume','Music & ambience'},{'sfxVolume','Sound effects'}}) do
   local key,title=v[1],v[2];local value=prefs[key] or 0
   local f=self:note(title,'Volume '..math.floor(value*100)..'% · visual cues always remain available.',150)
   self:action(f,'Volume_'..key,'Adjust volume','Settings',function() return {[key]=if value>=1 then 0 else math.min(1,value+.25)} end,true)
  end
 elseif self.tab=='Quick' then
  toggle('reducedMotion','Reduced motion','Keep feedback still and remove cinematic movement.')
  toggle('hints','Contextual hints','Short guidance during your expedition, never a mandatory slideshow.')
  toggle('simplifiedVFX','Simplified effects','Reduce decorative particles while retaining encounter cues.')
 else
  toggle('largeText','Larger text','Larger menu labels and descriptions. Panels remain scrollable.')
  toggle('highContrast','High contrast','Opaque panels and brighter outlines improve readability.')
  toggle('reducedMotion','Reduced motion','Reduce UI animation and camera feedback.')
  toggle('simplifiedVFX','Simplified effects','Reduce decorative effects without hiding danger.')
  toggle('hints','Contextual hints','Show short, nonblocking expedition guidance.')
 end
 self:note('Preference storage',data.saveMode or 'Preferences follow your profile save status.',88)
end
return S

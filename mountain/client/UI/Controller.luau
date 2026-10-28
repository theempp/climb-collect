local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local Feedback=require(script.Parent.Feedback)
local pg=player:WaitForChild('PlayerGui')
if pg:FindFirstChild('MountainHUD') then return {} end
local gui=W.new('ScreenGui',pg,{Name='MountainHUD',ResetOnSpawn=false,DisplayOrder=10,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=true})
gui:SetAttribute('BlueprintVersion',2);gui:SetAttribute('VisualSystem','HUDv2')
local root=W.frame(gui,'SafeRoot',UDim2.fromScale(1,1));root.BackgroundTransparency=1
local loading=W.frame(root,'Loading',UDim2.fromScale(1,1),nil,T.navy);loading.ZIndex=90
local mountain=W.mountain(loading);mountain.Size=UDim2.fromScale(.7,.8);mountain.Position=UDim2.fromScale(.15,.1)
local brand=W.text(loading,'CLIMB & COLLECT',UDim2.new(.9,0,0,58),UDim2.fromScale(.05,.26),T.title,40,T.ink);brand.TextXAlignment=Enum.TextXAlignment.Center
W.text(loading,'MOUNTAIN EMPIRE',UDim2.new(.9,0,0,30),UDim2.fromScale(.05,.44),T.bold,15,T.gold).TextXAlignment=Enum.TextXAlignment.Center
local loadStatus=W.text(loading,'Connecting to your expedition…',UDim2.new(.9,0,0,38),UDim2.fromScale(.05,.62),nil,15,T.muted);loadStatus.TextXAlignment=Enum.TextXAlignment.Center
local feedback=Feedback.new(root)
local C=require(RS:WaitForChild('MountainShared'):WaitForChild('Catalog'))
local R=require(RS.MountainShared.Rules)
local P=require(RS.MountainShared.UIPresentation)
local ClientState=require(script.Parent.ClientState)
local Screens=require(script.Parent.Screens)
local remotes=RS:WaitForChild('MountainRemotes',8)
while not remotes and gui.Parent do
 loadStatus.Text='The mountain service is taking longer to connect. Retrying…'
 remotes=RS:WaitForChild('MountainRemotes',5)
end
if not remotes then feedback:destroy();return {} end
local store=ClientState.new(remotes)
local screens
local connections={};local activeAbility=1;local expanded=false;local ready=false;local elapsed=0;local age=0;local lastSecond=-1;local saveFailed=false;local previousProfile;local memberStamp='';local wasInBattle=false
local function connect(signal,fn) local c=signal:Connect(fn);table.insert(connections,c);return c end
local click=W.new('Sound',gui,{Name='UIFeedback',SoundId='rbxasset://sounds/volume_slider.ogg',Volume=.15})
local function sound() click.Volume=.16*(T.prefs.sfxVolume or .8);click:Play() end
local function open(name) if ready then sound();screens:open(name) end end
-- Currency pill (intel §4): navy pill, coin overlapping the left end, green + tile opening the Shop.
local top=W.panel(root,'Status',UDim2.fromOffset(320,48),UDim2.fromOffset(12,8),T.navy);top.UICorner.CornerRadius=UDim.new(0,24);top.UIGradient.Enabled=false
W.icon(top,'Coin',UDim2.fromOffset(40,40),UDim2.fromOffset(-6,4))
local coins=W.text(top,'—',UDim2.new(.55,-30,1,0),UDim2.fromOffset(42,0),T.display,19,T.ink)
local plus=W.button(top,'AddCoins','+',UDim2.fromOffset(34,34),UDim2.new(1,-40,.5,-17),function() open('Shop') end,'ok');plus.Label.Font=T.display;plus.TextSize=T.size(22)
local timer=W.text(top,'00:00',UDim2.new(.45,-16,1,0),UDim2.new(.55,0,0,0),T.bold,14,T.muted);timer.TextXAlignment=Enum.TextXAlignment.Right
local progress=W.panel(root,'Journey',UDim2.fromOffset(292,80),UDim2.new(1,-304,0,8),T.navy)
local location=W.text(progress,'Blossom Gardens',UDim2.new(1,-20,0,25),UDim2.fromOffset(10,6),T.label,17)
local heightLabel=W.text(progress,'0 studs',UDim2.new(1,-20,0,21),UDim2.fromOffset(10,31),nil,12,T.muted)
local heightFill=W.progress(progress,0,UDim2.new(1,-20,0,7),UDim2.fromOffset(10,63),T.bar.fill)
local quest=W.panel(root,'QuestTracker',UDim2.fromOffset(292,76),UDim2.new(1,-304,0,96))
local questTitle=W.text(quest,'Explore the mountain',UDim2.new(1,-20,0,29),UDim2.fromOffset(10,5),T.bold,13,T.gold)
local questDetail=W.text(quest,'',UDim2.new(1,-20,0,34),UDim2.fromOffset(10,34),nil,12,T.muted)
local menu=W.tile(root,'Menu','Menu','Menu',UDim2.fromOffset(80,70),UDim2.fromOffset(12,60),function() expanded=not expanded;sound() end,T.navy)
local sidebar=W.panel(root,'Navigation',UDim2.fromOffset(172,350),UDim2.fromOffset(12,120));sidebar.Visible=false;sidebar.BackgroundTransparency=1;sidebar.UIStroke.Enabled=false
local nav=W.scroll(sidebar,'Items',UDim2.new(1,-12,1,-12),UDim2.fromOffset(6,6))
local hubNames={'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}
for i,name in ipairs(hubNames) do local b=W.tile(nav,'Nav'..name,name,name,UDim2.fromOffset(78,72),nil,function() expanded=false;open(name) end,({T.alt,T.tert,Color3.fromRGB(242,70,124),T.ok.base,T.alt,T.cta.base,T.cta.base,T.navy})[i]);b.LayoutOrder=i end
local team=W.frame(root,'Team',UDim2.fromOffset(342,60),UDim2.new(.5,-171,1,-72));team.BackgroundTransparency=1
local function selectedAbility(slot)
 local p=store.profile;local c=p and R.find(p.creatures,p.team[slot])
 return if c and C.byId[c.species].rarity=='Legendary' then activeAbility else 1
end
local slots={};local slotNames={};local slotStates={};local slotPortraits={};local slotSpecies={}
for i=1,3 do
 local index=i
 slots[i]=W.button(team,'Slot'..i,'['..i..'] Empty slot',UDim2.new(1/3,-6,1,0),UDim2.new((i-1)/3,3,0,0),function() if store.battle then store:request('Special',{slot=index,ability=selectedAbility(index)}) else open('Creatures') end end,'quiet')
 slots[i].Text=''
 slotNames[i]=W.text(slots[i],'Empty slot',UDim2.new(1,-6,0,22),UDim2.new(0,3,1,-23),T.bold,11)
 slotNames[i].TextXAlignment=Enum.TextXAlignment.Center;slotNames[i].Visible=false
 -- Mock 1: number badge circle at the bottom centre of the portrait (cooldown seconds in combat).
 slotStates[i]=W.text(slots[i],tostring(i),UDim2.fromOffset(26,22),UDim2.new(.5,-13,1,-26),T.display,13,T.ink)
 slotStates[i].TextXAlignment=Enum.TextXAlignment.Center
 slotStates[i].ZIndex=3;slotStates[i].BackgroundColor3=T.navy;slotStates[i].BackgroundTransparency=0;W.new('UICorner',slotStates[i],{CornerRadius=UDim.new(.5,0)});W.stroke(slotStates[i],T.ink,2)
 slots[i]:SetAttribute('Tooltip','Open your collection, or activate this companion’s special during combat.')
end
local actionbar=W.frame(root,'Actions',UDim2.fromOffset(342,48),UDim2.new(.5,-171,1,-128))
actionbar.BackgroundTransparency=1
local context=W.button(actionbar,'Context','Explore',UDim2.fromScale(1,1),UDim2.new(),function() local p=store.profile;local run=p and p.run;local ui=p and p.ui or {}
 if run and run.phase=='revealed' then store:request('Pickup',run.id)
 elseif ui.nearestEgg and (not run or run.phase=='breaking') then store:request('Strike',ui.nearestEgg)
 elseif ui.atHome then open('Sanctuary')
 else open('Mountain') end end,'gold')
local quickCreatures=W.tile(root,'QuickCreatures','Creatures','Creatures',UDim2.fromOffset(76,70),UDim2.fromOffset(100,60),function() open('Creatures') end,T.alt)
local quickMountain=W.tile(root,'QuickMountain','Mountain','Mountain',UDim2.fromOffset(76,70),UDim2.fromOffset(184,60),function() open('Mountain') end,T.ok.base)
local quick=W.tile(root,'Quick','Settings','Settings',UDim2.fromOffset(68,70),UDim2.fromOffset(268,60),function() open('Settings');if screens.hub then screens.tab='Quick';screens:render(false) end end,T.navy)
local dodge=W.button(root,'Dodge','Dodge [Q]',UDim2.fromOffset(122,48),UDim2.new(1,-148,1,-218),function() store:request('Dodge') end,'gold');dodge.Visible=false
local swingReadyAt=0
local function swingBat() if os.clock()<swingReadyAt then return end;swingReadyAt=os.clock()+1.5;store:request('Swing') end
local swing=W.button(root,'Swing','Bat [F]',UDim2.fromOffset(122,48),UDim2.new(1,-148,1,-218),swingBat,'blue');swing.Visible=false
 swing:SetAttribute('Tooltip','Whack a climber carrying an unsecured creature to knock it loose, then grab it.')
local ability=W.button(root,'Ability','Ability 1',UDim2.fromOffset(122,44),UDim2.new(1,-148,1,-270),function() activeAbility=activeAbility%4+1;sound() end,'quiet');ability.Visible=false
 ability:SetAttribute('Tooltip','Choose a captured Guardian’s special. Regular companions use their role special.')
 dodge:SetAttribute('Tooltip','Dodge the highlighted danger. A successful clean dodge advances Trial mastery.')
local battle=W.panel(root,'Battle',UDim2.fromOffset(410,100),UDim2.new(.5,-205,0,8));battle.Visible=false
local boss=W.text(battle,'Guardian',UDim2.new(1,-24,0,28),UDim2.fromOffset(12,6),T.label,24,T.ink)
local hp=W.progress(battle,1,UDim2.new(1,-24,0,10),UDim2.fromOffset(12,38),T.coral)
 local combatText=W.text(battle,'',UDim2.new(1,-24,0,50),UDim2.fromOffset(12,53),nil,12,T.ink)
local save=W.text(top,'Connecting…',UDim2.new(1,-16,0,14),UDim2.fromOffset(8,46),nil,10,T.ink);save.Visible=false;save.TextXAlignment=Enum.TextXAlignment.Center
coins.Size=UDim2.new(.48,-44,1,0);W.fit(coins,19,10);timer.Size=UDim2.new(.52,-60,1,0);timer.Position=UDim2.new(.48,0,0,0);W.fit(timer,14,9)
local hint=W.panel(root,'Hint',UDim2.fromOffset(320,64),UDim2.new(.5,-160,0,78));hint.Visible=false
local hintText=W.text(hint,'',UDim2.new(1,-60,1,-12),UDim2.fromOffset(12,6),nil,13,T.ink)
local dismissHint=false
W.button(hint,'DismissHint','×',UDim2.fromOffset(44,44),UDim2.new(1,-50,0,10),function() dismissHint=true;hint.Visible=false end,'quiet')
local retry=W.button(loading,'RetryLoad','Retry connection',UDim2.fromOffset(210,46),UDim2.new(.5,-105,.82,0),function()
 for id,pending in pairs(store.pending) do if pending.action=='State' then store:retry(id);return end end
 store:request('State')
end,'gold');retry.Visible=false
screens=Screens.new(root,store,feedback,function() GuiService.SelectedObject=nil end)
local defaultEffects={};local soundBases={};local settingsStamp=''
local function applyPreferences(prefs)
 T.configure(prefs);player:SetAttribute('MountainReducedMotion',prefs.reducedMotion==true)
 player:SetAttribute('MountainSimplifiedVFX',prefs.simplifiedVFX==true)
 for _,o in ipairs(root:GetDescendants()) do
  if o:IsA('UIStroke') then local base=o:GetAttribute('BaseThickness') or 1;local bt=o:GetAttribute('BaseTransparency');o.Transparency=if prefs.highContrast then math.min(bt or 0,.15) else (bt or .15);o.Thickness=if prefs.highContrast then math.max(2,base) else base
  elseif o:IsA('TextLabel') or o:IsA('TextButton') then local base=o:GetAttribute('BaseTextSize');if base then o.TextSize=T.size(base) end end
 end
 for _,o in ipairs(workspace:GetDescendants()) do
  if o:IsA('ParticleEmitter') and not o:FindFirstAncestor('Dynamics') then
   if defaultEffects[o]==nil then defaultEffects[o]=o.Enabled end;o.Enabled=defaultEffects[o] and not prefs.simplifiedVFX
  end
 end
end
connect(workspace.DescendantAdded,function(o) if o:IsA('ParticleEmitter') and not o:FindFirstAncestor('Dynamics') then defaultEffects[o]=o.Enabled;if T.prefs.simplifiedVFX then o.Enabled=false end end end)
connect(workspace.DescendantRemoving,function(o) defaultEffects[o]=nil end)
local nativeWatched=setmetatable({},{__mode='k'})
-- Roblox topbar row (GuiService.TopbarInset) in SafeRoot coordinates: X shares the root's inset space; Y is measured
-- from a full-screen (ScreenInsets.None) probe, so the row sits above the root (negative y).
local screenProbe=W.new('ScreenGui',pg,{Name='MountainHUDScreenProbe',ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.None})
local screenOrigin=W.frame(screenProbe,'Origin',UDim2.fromOffset(1,1));screenOrigin.BackgroundTransparency=1
local function topbarRect()
 local tb=GuiService.TopbarInset;if tb.Height<44 or tb.Width<=0 then return nil end
 local top=screenOrigin.AbsolutePosition.Y-root.AbsolutePosition.Y
 return {x=tb.Min.X-root.AbsolutePosition.X,y=top+tb.Min.Y,w=tb.Width,h=tb.Height}
end
local crowdedNav=false
local function layout()
 local v=root.AbsoluteSize;if v.X<=0 then return end
 local obstacles={}
 if UIS.TouchEnabled then
  local touch=pg:FindFirstChild('TouchGui')
  for _,name in ipairs({'DynamicThumbstickFrame','ThumbstickFrame','JumpButton'}) do
   local o=touch and touch:FindFirstChild(name,true)
   if o and o.Visible then
    table.insert(obstacles,{x=o.AbsolutePosition.X-root.AbsolutePosition.X,y=o.AbsolutePosition.Y-root.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y})
    if not nativeWatched[o] then nativeWatched[o]=true
     connect(o:GetPropertyChangedSignal('AbsolutePosition'),function() task.defer(layout) end)
     connect(o:GetPropertyChangedSignal('AbsoluteSize'),function() task.defer(layout) end)
    end
   end
  end
 end
 local l=P.hudLayout(v.X,v.Y,obstacles,UIS.TouchEnabled,topbarRect())
 crowdedNav=l.crowdedNavigation
 local function place(o,r) o.Size=UDim2.fromOffset(r.w,r.h);o.Position=UDim2.fromOffset(r.x,r.y) end
 place(top,l.status);place(progress,l.journey);place(menu,l.menu);place(quickCreatures,l.quickCreatures);place(quickMountain,l.quickMountain);place(team,l.team);place(actionbar,l.context);place(dodge,l.dodge);place(swing,l.dodge);place(ability,l.ability)
 place(quick,l.settings)
 -- One compact corner panel carries location, real height and the minimal objective.
 location.Size=UDim2.new(1,-20,0,22);location.Position=UDim2.fromOffset(10,3)
 heightLabel.Size=UDim2.new(1,-20,0,18);heightLabel.Position=UDim2.fromOffset(10,24)
 heightFill.Parent.Position=UDim2.new(0,10,1,-8);heightFill.Parent.Size=UDim2.new(1,-20,0,5)
 quest.BackgroundTransparency=1;quest.UIStroke.Enabled=false;quest.UIGradient.Enabled=false
 quest.Size=UDim2.new(1,-16,0,20);quest.Position=UDim2.fromOffset(8,40);quest.Parent=progress
 questTitle.Size=UDim2.fromScale(1,1);questTitle.Position=UDim2.new();questTitle.TextSize=T.size(11)
 questDetail.Visible=false
 sidebar.Size=UDim2.fromOffset(184,326);sidebar.Position=UDim2.fromOffset(12,140)
 nav.Size=UDim2.new(1,-8,1,-8);nav.Position=UDim2.fromOffset(4,4)
 local list=nav:FindFirstChildOfClass('UIListLayout');if list then list:Destroy() end
 local grid=nav:FindFirstChildOfClass('UIGridLayout') or W.new('UIGridLayout',nav,{SortOrder=Enum.SortOrder.LayoutOrder,CellPadding=UDim2.fromOffset(8,8)})
 if l.horizontalNavigation then
  place(sidebar,l.navigation)
  nav.Size=UDim2.new(1,-8,1,-4)
  nav.ScrollingDirection=Enum.ScrollingDirection.X;nav.AutomaticCanvasSize=Enum.AutomaticSize.X
  nav.UIPadding.PaddingTop=UDim.new(0,0);nav.UIPadding.PaddingBottom=UDim.new(0,0)
  grid.FillDirection=Enum.FillDirection.Vertical;grid.FillDirectionMaxCells=1;grid.CellSize=UDim2.fromOffset(78,if v.Y<550 then 44 else 70)
 else
  nav.UIPadding.PaddingTop=UDim.new(0,4);nav.UIPadding.PaddingBottom=UDim.new(0,4)
  nav.ScrollingDirection=Enum.ScrollingDirection.Y;nav.AutomaticCanvasSize=Enum.AutomaticSize.Y
  grid.FillDirection=Enum.FillDirection.Horizontal;grid.FillDirectionMaxCells=2;grid.CellSize=UDim2.fromOffset(78,70)
 end
 for _,b in ipairs(root:GetDescendants()) do
  if b:IsA('TextButton') then
   for _,o in ipairs(b:GetChildren()) do
    if o:IsA('Frame') and o.Name:sub(1,4)=='Icon' then
     local small=l.short or (b.Parent==nav and v.Y<550)
     o.Size=UDim2.fromOffset(if small then 34 else 46,if small then 34 else 46);o.Position=UDim2.new(.5,if small then -17 else -23,0,0)
     local caption=b:FindFirstChild('Text');if caption then caption.Size=UDim2.new(1,-6,0,if small then 18 else 22);caption.Position=UDim2.new(0,3,1,if small then -19 else -25) end
    end
   end
  end
 end
 -- In the topbar row the tiles are 44 px icon buttons like Roblox's own (no captions).
 for _,b in ipairs({quick,menu,quickCreatures,quickMountain}) do
  local icon=nil;for _,o in ipairs(b:GetChildren()) do if o:IsA('Frame') and o.Name:sub(1,4)=='Icon' then icon=o end end
  local caption=b:FindFirstChild('Text');if caption then caption.Visible=not l.topbar end
  if l.topbar and icon then icon.Size=UDim2.fromOffset(32,32);icon.Position=UDim2.new(.5,-16,0,3) end
 end
 for _,b in ipairs(slots) do
  local portrait=b:FindFirstChild('Portrait');if portrait then portrait.Size=UDim2.new(1,-12,1,-20);portrait.Position=UDim2.fromOffset(6,3) end
 end
 hint.Size=UDim2.fromOffset(math.min(360,v.X-380),54);hint.Position=UDim2.new(.5,-hint.Size.X.Offset/2,0,66)
 battle.Size=UDim2.fromOffset(math.min(410,v.X-230),100);battle.Position=UDim2.new(.5,-battle.Size.X.Offset/2,0,8)
 feedback.host.Size=UDim2.fromOffset(math.min(440,v.X-210),58);feedback.host.Position=UDim2.new(.5,-feedback.host.Size.X.Offset/2,0,if store.battle then 116 else 80)
 feedback.tooltip.Position=UDim2.new(.5,-140,0,if store.battle then 116 else 144)
 if screens.hub then screens:render(true) end
end
local function updateProfile()
 local data=store.profile;if not data then return end
 coins.Text=tostring(data.coins);local q=P.quest(data);questTitle.Text=q.title;questDetail.Text=if root.AbsoluteSize.Y<390 then q.progress..' / '..q.total..' objectives' else q.detail
 local prefs=data.ui and data.ui.settings or {};local stamp=game:GetService('HttpService'):JSONEncode(prefs)
 if stamp~=settingsStamp then settingsStamp=stamp;applyPreferences(prefs) end
 save.Text=if saveFailed then 'SAVING PAUSED · Progress actions unavailable' elseif tostring(data.saveMode):find('Studio') then 'STUDIO · Resets on Stop' else 'Profile synchronized'
 save.Visible=saveFailed
 if previousProfile then

  for id in pairs(data.captures) do if not previousProfile.captures[id] then feedback:reveal('Guardian captured!',C.byId[id].name..' joins your collection. This Guardian can be captured once.',C.byId[id]) end end
 end
 previousProfile={unlocked=data.unlocked,captures=table.clone(data.captures)}
 if screens.hub then screens:render(true) end
end
local disconnect=store:subscribe(function(kind,payload)
 if kind=='state' or kind=='context' or kind=='production' then updateProfile()
 elseif kind=='battle' then
  local active=payload~=nil and payload~=false;if active~=wasInBattle then wasInBattle=active;layout() end
  if payload then
   boss.Text=payload.name..(if payload.trial then ' · TRIAL' else '');hp.Size=UDim2.fromScale(math.clamp(payload.hp/math.max(1,payload.max),0,1),1)
   combatText.Text=math.ceil(payload.hp)..' HP · Phase '..math.max(1,((payload.phase or 1)-1)%4+1)..' · '..#(payload.members or {})..' climber(s)'
   if payload.trial then combatText.Text..='\n'..(payload.dodges or 0)..'/3 dodges · '..(payload.resolved or 0)..'/4 patterns · '..(if payload.captureOwned then 'Already captured' elseif payload.objective then 'Objective complete' else payload.objectiveText or 'Master the patterns') end
  end
  local stamp=game:GetService('HttpService'):JSONEncode(if payload then payload.members or {} else {})
  if stamp~=memberStamp then memberStamp=stamp;if screens.hub=='Social' and screens.tab=='Party' then screens:render(true) end end
 elseif kind=='open' then open(payload)
 elseif kind=='toast' then feedback:toast(payload,store.battle and (string.find(payload,'golden heart',1,true)~=nil or string.find(payload,'constellation stones',1,true)~=nil))
 elseif kind=='result' then
  screens:pending()
  if payload.action~='State' and payload.ok then
   sound();local d=payload.data
   if payload.action=='Hatch' and d and d.creature then feedback:reveal('A new companion!',C.byId[d.creature.species].name..' joins your collection.',C.byId[d.creature.species])
   elseif payload.action=='Train' and d and d.creature and d.stage and d.previousStage and d.stage>d.previousStage then feedback:reveal('Evolution unlocked!',C.byId[d.creature.species].name..' reached evolution stage '..d.stage..'.',C.byId[d.creature.species])
   elseif payload.action=='ChallengeDefense' and d then feedback:reveal(if d.won then 'Challenge won!' else 'Challenge complete',(if d.practice then 'Practice defense' else 'Opponent '..tostring(d.opponent))..' · '..tostring(d.rounds)..' rounds\n'..tostring(d.trophies)..' trophies awarded.')
   elseif payload.action~='Special' and payload.action~='Dodge' then feedback:toast(payload.message or 'Confirmed.') end
  elseif not payload.ok and payload.data and payload.data.confirmAbandon then
   local d=payload.data
   feedback:confirm('Abandon this creature?', 'Travel loses your unsecured attempt. Your owned creatures and coins stay safe. Cancel to keep climbing.',function() store:request('TravelAbandon',{destination=d.destination,runId=d.runId}) end)
  elseif not payload.ok then feedback:toast(payload.message or 'That action is unavailable.') end
 elseif kind=='timeout' then screens:pending();feedback:toast('Still waiting for the server. Open a menu to retry safely.')
 elseif kind=='pending' then screens:pending()
 elseif kind=='save' then saveFailed=not payload;save.Visible=saveFailed;save.Text=if not payload then 'SAVING PAUSED · Actions unavailable' elseif store.profile and tostring(store.profile.saveMode):find('Studio') then 'STUDIO · Resets on Stop' else 'Profile saved' end
end)
connect(UIS.InputBegan,function(input,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 local key=input.KeyCode
 if key==Enum.KeyCode.M or key==Enum.KeyCode.Tab or key==Enum.KeyCode.ButtonSelect then if screens.hub then screens:close() else open('Creatures') end
 elseif key==Enum.KeyCode.Escape or key==Enum.KeyCode.ButtonB then if not feedback:close() then screens:back() end
 elseif not screens.hub and not feedback.modal and ready then
  if key==Enum.KeyCode.One or key==Enum.KeyCode.Two or key==Enum.KeyCode.Three then local slot=({[Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3})[key];store:request('Special',{slot=slot,ability=selectedAbility(slot)})
  elseif (key==Enum.KeyCode.Q or key==Enum.KeyCode.ButtonY) and store.battle then store:request('Dodge')
  elseif (key==Enum.KeyCode.F or key==Enum.KeyCode.ButtonX) and not store.battle then swingBat() end
 end
end)
connect(root:GetPropertyChangedSignal('AbsoluteSize'),layout)
connect(GuiService:GetPropertyChangedSignal('TopbarInset'),function() task.defer(layout) end)
 connect(pg.DescendantAdded,function(o) if o.Name=='JumpButton' or o.Name=='DynamicThumbstickFrame' then task.defer(layout) end end)
 connect(UIS:GetPropertyChangedSignal('TouchEnabled'),layout)
local start=os.clock()
connect(Run.Heartbeat,function(dt)
 elapsed+=dt;age+=dt;if elapsed<.2 then return end;elapsed=0
 local data=store.profile;local rr=player.Character and player.Character:FindFirstChild('HumanoidRootPart');ready=data~=nil and rr~=nil
 loading.Visible=not ready;retry.Visible=not ready and os.clock()-start>8
 if not ready then loadStatus.Text=if data then 'Waiting for your character…' elseif store.status=='error' then 'Connection delayed. Retry when ready.' else 'Synchronizing your collection…' end
 sidebar.Visible=expanded and ready and not screens.hub and not store.battle;if store.battle then expanded=false end
 top.Visible=ready and not store.battle;progress.Visible=ready and not store.battle and not (expanded and P.horizontalNavigation(root.AbsoluteSize.Y,UIS.TouchEnabled));quest.Visible=ready and not store.battle and not expanded
 menu.Visible=ready and not screens.hub;quickCreatures.Visible=ready and not screens.hub and not expanded and not store.battle and not crowdedNav;quickMountain.Visible=quickCreatures.Visible;quick.Visible=ready and not screens.hub and not store.battle;team.Visible=ready and not screens.hub;actionbar.Visible=ready and not screens.hub and not store.battle and data~=nil and ((data.ui and data.ui.atHome) or (data.ui and data.ui.nearestEgg) or (data.run and data.run.phase=='revealed'))
 dodge.Visible=P.combatVisible(store.battle,ready,screens.hub~=nil);ability.Visible=dodge.Visible;battle.Visible=dodge.Visible
 swing.Visible=ready and not screens.hub and not expanded and not store.battle and data~=nil and data.ui~=nil and not data.ui.inSanctuary
 if swing.Visible then local wait=math.ceil(swingReadyAt-os.clock());W.enable(swing,wait<=0,if wait>0 then 'Bat · '..wait..'s' else (if UIS.TouchEnabled then 'Bat' else 'Bat [F]')) end
 if data then
  local clock=store:clock();local ui=data.ui or {};local cooldowns=ui.cooldowns or {}
  for i,b in ipairs(slots) do
   local c=R.find(data.creatures,data.team[i]);local remain=c and P.remaining(cooldowns[c.id..':'..selectedAbility(i)] or 0,clock) or 0
   if slotSpecies[i]~=(c and c.species) then
    if slotPortraits[i] then slotPortraits[i]:Destroy();slotPortraits[i]=nil end
    slotSpecies[i]=c and c.species
    if c then slotPortraits[i]=W.portrait(b,C.byId[c.species],UDim2.new(1,-12,1,-20),UDim2.fromOffset(6,3)) end
   end
   slotNames[i].Text=if c then C.byId[c.species].name else 'Empty slot'
   slotStates[i].Text=if c and store.battle then (if remain>0 then remain..'s' else 'GO') else tostring(i)
   slotStates[i].Size=UDim2.fromOffset(if c and store.battle and remain>0 then 34 else 26,22);slotStates[i].Position=UDim2.new(.5,-slotStates[i].Size.X.Offset/2,1,-26)
   -- HUD creature slot (intel §4): rarity-colour face, ink outline; cooling slots drop to off.base.
   W.enable(b,not store.battle or (c~=nil and remain==0))
   b.BackgroundColor3=if remain>0 then T.off elseif c then T.rarity[C.byId[c.species].rarity] else T.navy
  end
  local dr=P.remaining(ui.dodgeReadyAt or 0,clock);W.enable(dodge,dr==0,if dr>0 then 'Dodge · '..dr..'s' else 'Dodge [Q]');ability.Text='Ability '..activeAbility
  local run=data.run
  context.Text=if run and run.phase=='revealed' then 'Pick up creature' elseif run and run.phase=='carried' then 'Escape to sanctuary' elseif ui.nearestEgg then 'Strike egg' elseif ui.atHome then 'Manage sanctuary' else 'Mountain map'
  game:GetService('ProximityPromptService').Enabled=not screens.hub and not feedback.modal
  hint.Visible=ready and not expanded and not dismissHint and T.prefs.hints~=false and age<24 and not screens.hub and not store.battle and root.AbsoluteSize.Y>=550
  hintText.Text=if data.run then 'Unsecured creature: return through the sanctuary exit. Catch, serious fall or leaving loses this attempt.' elseif ui.inSanctuary then 'Choose your companions, then climb freely into any section.' else 'Find an egg. Tap each strike, pick up the creature, escape downhill.'
 end
 if math.floor(age)~=lastSecond then
  lastSecond=math.floor(age);timer.Text=P.formatTime(age);screens:tick();screens:pending()
  if data then local q=P.quest(data);questDetail.Text=if root.AbsoluteSize.Y<390 then (if T.prefs.hints~=false and age<24 then 'Break · carry · escape' else q.progress..' / '..q.total..' objectives') else q.detail end
  if rr then
   local mountain=workspace:FindFirstChild('ImpossibleMountain');local free=mountain and mountain:GetAttribute('FreeClimbVersion')
   local k=math.clamp(math.floor((rr.Position.Y-16)/(if free then 64 else 136))+1,1,6)
   if free and mountain:FindFirstChild('GuardianBounds') then
    for _,bound in ipairs(mountain.GuardianBounds:GetChildren()) do local q=bound.CFrame:PointToObjectSpace(rr.Position);if math.abs(q.X)<=bound.Size.X/2 and math.abs(q.Z)<=bound.Size.Z/2 then k=tonumber(bound.Name) or k;break end end
   end
   location.Text=if data and data.ui and data.ui.inSanctuary then 'Sanctuary · Plot '..tostring(data.ui.plot or '—') else C.kingdoms[k].name
   heightLabel.Text=math.max(0,math.floor(rr.Position.Y-16))..' studs · '..'6/6 open';heightFill.Size=UDim2.fromScale(math.clamp((rr.Position.Y-16)/(if free then 384 else 824),0,1),1)
   for name,volume in pairs({['Mountain Birds 1 (SFX)']=if k==1 then .14 elseif k==2 then .05 else 0,WaterfallLoop=if k==2 then .12 else 0,AstralWind=if k>=3 then .08 else 0,LavaLoop=if k==5 then .1 else 0}) do
    local s=game:GetService('SoundService'):FindFirstChild(name);if s then if soundBases[s]==nil then soundBases[s]=s.Volume end;s.Volume=volume*(T.prefs.musicVolume or .7);if not s.IsPlaying then s:Play() end end
   end
  end
 end
end)
layout()
connect(gui.Destroying,function()
 screenProbe:Destroy();disconnect();store:destroy();feedback:destroy();screens:destroy();for _,c in ipairs(connections) do c:Disconnect() end
 for o,value in pairs(defaultEffects) do if o.Parent then o.Enabled=value end end;for s,value in pairs(soundBases) do if s.Parent then s.Volume=value end end;GuiService.SelectedObject=nil
end)
if require(game.ReplicatedStorage.MountainShared.BuildFlags).studioAids() then
 local probe=W.new('BindableFunction',gui,{Name='UIProbe'})
 probe.OnInvoke=function(action,value)
  if action=='open' and table.find(hubNames,value) then open(value)
  elseif action=='close' then screens:close()
  elseif action=='detail' and screens.hub=='Creatures' and store.profile and store.profile.creatures[1] then screens.detail=value or store.profile.creatures[1].id;screens:render(false)
  elseif action=='tab' and screens.hub and screens.shade.Hub.Tabs:FindFirstChild('Tab'..tostring(value)) then screens.tab=value;screens.detail=nil;screens.page=1;screens:render(false) end
  return {ready=ready,hub=screens.hub,tab=screens.tab,view={root.AbsoluteSize.X,root.AbsoluteSize.Y},instances=#gui:GetDescendants(),pending=store.pending,status=store.status}
 end
end
return {}

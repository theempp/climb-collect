-- Mountain HUD wiring (Glassbloom P4). The HUD body lives in Hud.luau, messages in Feedback.luau, state logic in HudState.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local GuiService=game:GetService('GuiService')
local player=Players.LocalPlayer
local T=require(script.Parent.Theme)
local W=require(script.Parent.Widgets)
local Feedback=require(script.Parent.Feedback)
local Hud=require(script.Parent.Hud)
local Motion=require(script.Parent.Motion)
local pg=player:WaitForChild('PlayerGui')
if pg:FindFirstChild('MountainHUD') then return {} end
local gui=W.new('ScreenGui',pg,{Name='MountainHUD',ResetOnSpawn=false,DisplayOrder=10,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=false})
-- P7 R1: no safe-area clip, so the full-screen pieces (hub tint, reveal backdrop, chase vignette at l.screen) reach the device
-- edges; everything else is placed in SafeRoot coordinates (CoreUISafeInsets) and stays inside the safe area.
gui:SetAttribute('BlueprintVersion',2);gui:SetAttribute('VisualSystem','Glassbloom')
local root=W.frame(gui,'SafeRoot',UDim2.fromScale(1,1));root.BackgroundTransparency=1
-- hud-polish C: hide only Roblox's native health bar (it sat in the topbar row by TopRight; plan §0, risk R2 accepted). Retried while
-- the CoreScripts are still registering (the usual SetCoreGuiEnabled race at start).
task.spawn(function() local SG=game:GetService('StarterGui');for _=1,10 do if pcall(SG.SetCoreGuiEnabled,SG,Enum.CoreGuiType.Health,false) then return end;task.wait(.5) end end)
Motion.attach(root) -- P6: every Motion-tagged piece under SafeRoot (HUD, messages, hubs, reveal)
local loading=W.frame(root,'Loading',UDim2.fromScale(1,1),nil,T.navy);loading.ZIndex=90
local mountain=W.mountain(loading);mountain.Size=UDim2.fromScale(.7,.8);mountain.Position=UDim2.fromScale(.15,.1)
local brand=W.text(loading,'CLIMB & COLLECT',UDim2.new(.9,0,0,58),UDim2.fromScale(.05,.26),T.title,40,T.ink);brand.TextXAlignment=Enum.TextXAlignment.Center
W.text(loading,'MOUNTAIN EMPIRE',UDim2.new(.9,0,0,30),UDim2.fromScale(.05,.44),T.bold,15,T.gold).TextXAlignment=Enum.TextXAlignment.Center
local loadStatus=W.text(loading,'Connecting to your expedition…',UDim2.new(.9,0,0,38),UDim2.fromScale(.05,.62),nil,15,T.muted);loadStatus.TextXAlignment=Enum.TextXAlignment.Center
local C=require(RS:WaitForChild('MountainShared'):WaitForChild('Catalog'))
local R=require(RS.MountainShared.Rules)
local P=require(RS.MountainShared.UIPresentation)
local H=require(RS.MountainShared.HudState)
local ClientState=require(script.Parent.ClientState)
local Screens=require(script.Parent.Screens)
local screens,store,hud
local ready=false
local click=W.new('Sound',gui,{Name='UIFeedback',SoundId='rbxasset://sounds/volume_slider.ogg',Volume=.15})
local function sound() click.Volume=.16*(T.prefs.sfxVolume or .8);click:Play() end
local function open(name,tab)
 if not ready then return end
 -- `tab`: a tab name or a registered section key (Daily -> Shop 'Free gifts', P5 task D); Screens lands there.
 sound();screens:open(name,tab)
end
-- HUD (Hud.luau) before Feedback: messages render in the HUD root so they share its one UIScale.
local activeAbility=1;local swingReadyAt=0
local function selectedAbility(slot)
 local p=store and store.profile;local c=p and R.find(p.creatures,p.team[slot])
 return if c and C.byId[c.species].rarity=='Legendary' then activeAbility else 1
end
local function swingBat() if not ready or os.clock()<swingReadyAt then return end;swingReadyAt=os.clock()+1.5;store:request('Swing') end
hud=Hud.new(root,{
 open=open,sound=sound,card=function() hud:toggleCard() end,swing=swingBat,
 pickup=function() local run=store and store.profile and store.profile.run;if run and run.phase=='revealed' then store:request('Pickup',run.id) end end,
 dodge=function() store:request('Dodge') end,
 special=function(slot) if store.battle then store:request('Special',{slot=slot,ability=selectedAbility(slot)}) end end,
 ability=function() activeAbility=activeAbility%4+1;sound() end,
})
local messages=W.new('Frame',hud.layer,{Name='Messages',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=10})
local feedback=Feedback.new(root,messages)
local remotes=RS:WaitForChild('MountainRemotes',8)
while not remotes and gui.Parent do
 loadStatus.Text='The mountain service is taking longer to connect. Retrying…'
 remotes=RS:WaitForChild('MountainRemotes',5)
end
if not remotes then feedback:destroy();hud:destroy();return {} end
store=ClientState.new(remotes)
local memory=H.new()
local connections={};local saveFailed=false;local previousProfile;local wasInBattle=false;local age=0;local lastSecond=-1;local fixture=nil
local function connect(signal,fn) local c=signal:Connect(fn);table.insert(connections,c);return c end
-- Hint card (hints pref): not on the board; kept on tall screens (>= 550, where it ends above M), in the band's low row while
-- the band is free (no tier-2 message or moment).
local hint=W.panel(root,'Hint',UDim2.fromOffset(320,64),UDim2.new(.5,-160,0,78));hint.Visible=false;hint.ZIndex=25
local hintText=W.text(hint,'',UDim2.new(1,-60,1,-12),UDim2.fromOffset(12,6),nil,13,T.ink)
local dismissHint=false
W.button(hint,'DismissHint','×',UDim2.fromOffset(44,44),UDim2.new(1,-50,0,10),function() dismissHint=true;hint.Visible=false end,'quiet')
local retry=W.button(loading,'RetryLoad','Retry connection',UDim2.fromOffset(210,46),UDim2.new(.5,-105,.82,0),function()
 for id,pending in pairs(store.pending) do if pending.action=='State' then store:retry(id);return end end
 store:request('State')
end,'gold');retry.Visible=false
screens=Screens.new(root,store,feedback,function() GuiService.SelectedObject=nil end)
feedback.hooks={xpLine=function(m,hold) hud:xpLine(m,hold) end,rail=function(m,hold) hud:checkpoint(m,hold) end,
 band=function(on) hud:setBandBusy(on) end,blocking=function(on) hud:setBlocked(on) end,reveal=function(on) hud:setRevealing(on) end}
local defaultEffects={};local soundBases={};local settingsStamp=''
local layout
local function applyPreferences(prefs)
 T.configure(prefs);player:SetAttribute('MountainReducedMotion',prefs.reducedMotion==true)
 player:SetAttribute('MountainSimplifiedVFX',prefs.simplifiedVFX==true)
 Motion.refresh() -- reduced / LOW / camera shake gates follow the new prefs live
 for _,o in ipairs(root:GetDescendants()) do
  if o:IsA('UIStroke') then local base=o:GetAttribute('BaseThickness') or 1;local bt=o:GetAttribute('BaseTransparency');o.Transparency=if prefs.highContrast then math.min(bt or 0,.15) else (bt or .15);o.Thickness=if prefs.highContrast then math.max(2,base) else base
  elseif o:IsA('TextLabel') or o:IsA('TextButton') then local base=o:GetAttribute('BaseTextSize');if base then o.TextSize=T.size(base) end end
 end
 for _,o in ipairs(workspace:GetDescendants()) do
  if o:IsA('ParticleEmitter') and not o:FindFirstAncestor('Dynamics') then
   if defaultEffects[o]==nil then defaultEffects[o]=o.Enabled end;o.Enabled=defaultEffects[o] and not prefs.simplifiedVFX
  end
 end
 if layout then layout() end -- HUD scale (G2) and text-fitted widths follow the prefs
end
connect(workspace.DescendantAdded,function(o) if o:IsA('ParticleEmitter') and not o:FindFirstAncestor('Dynamics') then defaultEffects[o]=o.Enabled;if T.prefs.simplifiedVFX then o.Enabled=false end end end)
connect(workspace.DescendantRemoving,function(o) defaultEffects[o]=nil end)
local nativeWatched=setmetatable({},{__mode='k'})
-- Full-screen probe (ScreenInsets None): the §3 zones are full-screen px. Roblox's topbar row (TopbarInset) and the screen rect in
-- SafeRoot coordinates; the row sits above the root when y < 0.
local screenProbe=W.new('ScreenGui',pg,{Name='MountainHUDScreenProbe',ResetOnSpawn=false,ScreenInsets=Enum.ScreenInsets.None})
local screenOrigin=W.frame(screenProbe,'Origin',UDim2.fromOffset(1,1));screenOrigin.BackgroundTransparency=1
local function topbarRect()
 local tb=GuiService.TopbarInset;if tb.Height<44 or tb.Width<=0 then return nil end
 local top=screenOrigin.AbsolutePosition.Y-root.AbsolutePosition.Y
 return {x=tb.Min.X-root.AbsolutePosition.X,y=top+tb.Min.Y,w=tb.Width,h=tb.Height}
end
local function screenRect()
 local o=screenOrigin.AbsolutePosition-root.AbsolutePosition
 return {x=o.X,y=o.Y,w=screenProbe.AbsoluteSize.X,h=screenProbe.AbsoluteSize.Y}
end
-- QA audits resize SafeRoot to simulate a phone: the resized root is then the whole screen, with no topbar row.
local function simulated() return root.Size~=UDim2.fromScale(1,1) end
-- Menus + hatch reveal (P7 R1): board insets / tint / backdrop are measured from the screen edges, not the inset root.
local function fullScreen() local v=root.AbsoluteSize;return if simulated() then {x=0,y=0,w=v.X,h=v.Y} else screenRect() end
screens.screenRect=fullScreen;feedback.screenRect=fullScreen
local function bx(o) return {x=o.AbsolutePosition.X,y=o.AbsolutePosition.Y,w=o.AbsoluteSize.X,h=o.AbsoluteSize.Y} end
layout=function()
 local v=root.AbsoluteSize;if v.X<=0 then return end
 local obstacles={}
 if UIS.TouchEnabled then
  local touch=pg:FindFirstChild('TouchGui')
  for name,kind in pairs({JumpButton='jump',ThumbstickFrame='stick',DynamicThumbstickFrame='dynamic'}) do
   local o=touch and touch:FindFirstChild(name,true)
   if o and o.Visible then
    local r=P.nativeRect(bx(o),bx(gui),bx(root),kind=='jump');r.kind=kind;table.insert(obstacles,r)
    if not nativeWatched[o] then nativeWatched[o]=true
     connect(o:GetPropertyChangedSignal('AbsolutePosition'),function() task.defer(layout) end)
     connect(o:GetPropertyChangedSignal('AbsoluteSize'),function() task.defer(layout) end)
    end
   end
  end
 end
 local sim=simulated()
 local s=P.hudScale(T.prefs.hudScale,v.X);hud:setScale(s)
 local m=hud:measure()
 local l=P.hudLayout(v.X,v.Y,obstacles,UIS.TouchEnabled,if sim then nil else topbarRect(),{scale=s,screen=fullScreen(),coinW=m.coinW,edgeW=m.edgeW,abilityW=m.abilityW})
 hud:apply(l);feedback:layout(l) -- also re-places the hatch reveal on the screen rect
 gui:SetAttribute('HudScale',s)
 hint.Size=UDim2.fromOffset(math.min(360,v.X-380),54);hint.Position=UDim2.fromOffset(v.X/2-hint.Size.X.Offset/2,l.band.low*s) -- P7 E: the band's low row (hidden while the band is busy)
 if screens.hub then screens:render(true) end
end
local function sectionFallback(rr)
 local mtn=workspace:FindFirstChild('ImpossibleMountain');local free=mtn and mtn:GetAttribute('FreeClimbVersion')
 local bounds=if free and mtn:FindFirstChild('GuardianBounds') then mtn.GuardianBounds:GetChildren() else nil
 return H.fallbackSection(rr.Position,free,bounds)
end
local function rootPart() return player.Character and player.Character:FindFirstChild('HumanoidRootPart') end
local function inSanctuary() local p=store.profile;return p~=nil and p.ui~=nil and p.ui.inSanctuary==true end
local function deliver(list) for _,m in ipairs(list) do feedback:show(m) end end
local function updateProfile()
 local data=store.profile;if not data then return end
 local prefs=data.ui and data.ui.settings or {};local stamp=game:GetService('HttpService'):JSONEncode(prefs)
 if stamp~=settingsStamp then settingsStamp=stamp;applyPreferences(prefs) end
 local rr=rootPart();deliver(H.observe(memory,data,rr and sectionFallback(rr)))
 if previousProfile then
  for id in pairs(data.captures) do if not previousProfile.captures[id] then feedback:reveal('Guardian captured!',C.byId[id].name..' joins your collection. This Guardian can be captured once.',C.byId[id]) end end
 end
 previousProfile={unlocked=data.unlocked,captures=table.clone(data.captures)}
 if screens.hub then screens:render(true) end
end
local disconnect=store:subscribe(function(kind,payload)
 feedback.inSanctuary=inSanctuary()
 if kind=='state' or kind=='context' or kind=='production' then updateProfile()
 elseif kind=='battle' then
  local active=payload~=nil and payload~=false;if active~=wasInBattle then wasInBattle=active;layout() end
 elseif kind=='hud' then deliver(H.event(memory,payload,inSanctuary()))
 elseif kind=='open' then open(payload)
 elseif kind=='toast' then feedback:toast(payload)
 elseif kind=='result' then
  screens:pending()
  if payload.action~='State' and payload.ok then
   sound();local d=payload.data
   if payload.action=='Hatch' and d and d.creature then feedback:hatchReveal(C.byId[d.creature.species],{}) -- sanctuary reveal strip (P5 E)
   elseif payload.action=='Train' and d and d.creature and d.stage and d.previousStage and d.stage>d.previousStage then feedback:reveal('Evolution unlocked!',C.byId[d.creature.species].name..' reached evolution stage '..d.stage..'.',C.byId[d.creature.species])
   elseif payload.action~='Special' and payload.action~='Dodge' then feedback:toast(payload.message or 'Confirmed.') end
  elseif not payload.ok and payload.data and payload.data.confirmAbandon then
   local d=payload.data
   feedback:confirm('Abandon this creature?', 'Travel loses your unsecured attempt. Your owned creatures and coins stay safe. Cancel to keep climbing.',function() store:request('TravelAbandon',{destination=d.destination,runId=d.runId}) end)
  elseif not payload.ok then feedback:toast(payload.message or 'That action is unavailable.') end
 elseif kind=='timeout' then screens:pending();feedback:toast('Still waiting for the server. Open a menu to retry safely.')
 elseif kind=='pending' then screens:pending()
 elseif kind=='save' then
  local failed=not payload;if failed and not saveFailed then feedback:toast('Saving paused · Progress actions unavailable') end;saveFailed=failed
 end
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
-- P7 R1: the screen rect can move without a root resize (topbar row appearing, probe resize); one deferred layout per frame.
local layoutQueued=false
local function queueLayout() if layoutQueued then return end;layoutQueued=true;task.defer(function() layoutQueued=false;layout() end) end
connect(root:GetPropertyChangedSignal('AbsolutePosition'),queueLayout);connect(screenProbe:GetPropertyChangedSignal('AbsoluteSize'),queueLayout)
connect(pg.DescendantAdded,function(o) if o.Name=='JumpButton' or o.Name=='DynamicThumbstickFrame' or o.Name=='ThumbstickFrame' then task.defer(layout) end end)
connect(UIS:GetPropertyChangedSignal('TouchEnabled'),layout)
-- HUD view model (5 Hz). Distance/edge/beacon run in Hud's own 10 Hz carry tick.
local function liveView(data,rr)
 local ui=data.ui or {};local clock=store:clock();local cooldowns=ui.cooldowns or {}
 local ex=ui.explorer;local st=H.state(memory,data,store.battle)
 local v={ready=ready,hubOpen=screens.hub~=nil or feedback.modal~=nil,state=st,coins=data.coins,
  level=if ex then ex.level else 1,xp=if ex and ex.need and ex.need>0 then ex.into/ex.need elseif ex then 1 else 0,
  name=player.DisplayName,creatures=#(data.creatures or {}),cash=R.tycoon.coinRate(data),summit=data.discoveries and data.discoveries.summit==true,
  section=H.section(ui,rr and sectionFallback(rr)),height=if rr then math.max(0,math.floor(rr.Position.Y-16)) else 0,
  rail=T.prefs.altitudeRail~=false,daily=true,pickup=data.run~=nil and data.run.phase=='revealed'}
 local wait=math.ceil(swingReadyAt-os.clock())
 v.bat={enabled=wait<=0,text=if wait>0 then 'Bat · '..wait..'s' else (if UIS.TouchEnabled then 'Bat' else 'Bat [F]')}
 if H.carrying(data) then v.carry={species=data.run.species,runId=data.run.id,exits=ui.exits} end
 local b=store.battle
 if st=='battle' and type(b)=='table' then
  local slots={}
  for i=1,3 do
   local c=R.find(data.creatures,data.team[i]);local remain=c and P.remaining(cooldowns[c.id..':'..selectedAbility(i)] or 0,clock) or 0
   -- Badge (P7 R7): slot number when ready or empty, cooldown seconds + "s" while cooling ("GO" read as "CC" at FO 10).
   slots[i]={text=if c and remain>0 then remain..'s' else tostring(i),enabled=c~=nil and remain==0,label=if c then C.byId[c.species].name else 'Empty slot'}
  end
  local dr=P.remaining(ui.dodgeReadyAt or 0,clock)
  local n=#(b.members or {});local kicker='Phase '..math.max(1,((b.phase or 1)-1)%4+1)..' · '..n..(if n==1 then ' climber' else ' climbers') -- P7 R7
  if b.trial then kicker..=' · '..(b.dodges or 0)..'/3 dodges · '..(b.resolved or 0)..'/4 patterns · '..(if b.captureOwned then 'Already captured' elseif b.objective then 'Objective complete' else b.objectiveText or 'Master the patterns') end
  v.battle={name=tostring(b.name)..(if b.trial then ' · TRIAL' else ''),hp=b.hp,max=b.max,kicker=kicker,slots=slots,
   dodge={enabled=dr==0,text=if dr>0 then 'Dodge · '..dr..'s' else 'Dodge [Q]'},ability='Ability '..activeAbility}
 end
 return v
end
-- QA fixtures (UIProbe hudState, StudioAids only): the board frames (intel §2 HUD states) with static messages.
local function fixtureView(name,data)
 local exits=data and data.ui and data.ui.exits
 local rare;for _,s in ipairs(C.species) do if s.rarity=='Rare' then rare=s;break end end
 local v={ready=true,hubOpen=false,state=if name=='regrab' then 'carry' elseif name=='sanctuaryOpen' then 'sanctuary' else name,coins=data and data.coins or 1240,level=12,xp=.6,name=player.DisplayName,
  creatures=data and #(data.creatures or {}) or 7,cash=if data then R.tycoon.coinRate(data) else .03,summit=false,section=2,height=320,rail=true,daily=true,pickup=name=='rest',bat={enabled=true,text='Bat'}}
 if name=='carry' or name=='regrab' or name=='chase' or name=='battle' then v.carry={species=rare and rare.id,runId='fixture',exits=exits,fixed={distance=84,progress=.4,offscreen=name=='chase'}} end
 if name=='battle' then
  v.battle={name=C.guardians[1].name,hp=640,max=1000,kicker='Phase 2 · 1 climber',ability='Ability 1',dodge={enabled=true,text='Dodge [Q]'},
   slots={{text='1',enabled=true,label='Slot 1'},{text='3s',enabled=false,label='Slot 2'},{text='3',enabled=true,label='Slot 3'}}}
 end
 return v,rare
end
local function showFixture(name)
 local data=store.profile;local v,rare=fixtureView(name,data)
 feedback:clear();hud:clearTransients();hud:render(v)
 local sp=rare and rare.id
 if name=='rest' then feedback:show(H.message('coin',{text='+25 coins'}),true);hud:checkpoint(H.message('checkpoint',H.checkpoint('2:recovery')),true)
 elseif name=='carry' then feedback:show(H.message('carry',{species=sp,runId='fixture'}),true)
 elseif name=='regrab' then feedback:show(H.message('regrab',{species=sp,runId='fixture'}),true)
 elseif name=='chase' then feedback:show(H.message('alert',{guardian=C.guardians[2].name,section=2}),true)
 elseif name=='sanctuary' or name=='sanctuaryOpen' then hud:toggleCard(name=='sanctuaryOpen');feedback:show(H.message('toast',{text='Welcome home'}),true) end
end
local start=os.clock();local elapsed=0
connect(Run.Heartbeat,function(dt)
 elapsed+=dt;age+=dt;if elapsed<.2 then return end;elapsed=0
 local data=store.profile;local rr=rootPart();ready=data~=nil and rr~=nil
 loading.Visible=not ready;retry.Visible=not ready and os.clock()-start>8
 if not ready then loadStatus.Text=if data then 'Waiting for your character…' elseif store.status=='error' then 'Connection delayed. Retry when ready.' else 'Synchronizing your collection…' end
 feedback.inSanctuary=inSanctuary();feedback:setHubOpen(screens.hub~=nil)
 if data then
  if fixture then local v=fixtureView(fixture,data);v.hubOpen=screens.hub~=nil;hud:render(v) else hud:render(liveView(data,rr)) end
  game:GetService('ProximityPromptService').Enabled=not screens.hub and not feedback.modal
  local ui=data.ui or {}
  hint.Visible=ready and not dismissHint and T.prefs.hints~=false and age<24 and not screens.hub and not store.battle and not hud.bandBusy and root.AbsoluteSize.Y>=550
  hintText.Text=if data.run then 'Unsecured creature: return through the sanctuary exit. Catch, serious fall or leaving loses this attempt.' elseif ui.inSanctuary then 'Choose your companions, then climb freely into any section.' else 'Find an egg. Tap each strike, pick up the creature, escape downhill.'
 end
 if math.floor(age)~=lastSecond then
  lastSecond=math.floor(age);screens:tick();screens:pending()
  if rr then
   local k=sectionFallback(rr) or 1
   for name,volume in pairs({['Mountain Birds 1 (SFX)']=if k==1 then .14 elseif k==2 then .05 else 0,WaterfallLoop=if k==2 then .12 else 0,AstralWind=if k>=3 then .08 else 0,LavaLoop=if k==5 then .1 else 0}) do
    local s=game:GetService('SoundService'):FindFirstChild(name);if s then if soundBases[s]==nil then soundBases[s]=s.Volume end;s.Volume=volume*(T.prefs.musicVolume or .7);if not s.IsPlaying then s:Play() end end
   end
  end
 end
end)
layout()
connect(gui.Destroying,function()
 screenProbe:Destroy();disconnect();store:destroy();feedback:destroy();screens:destroy();hud:destroy();Motion.detach();for _,c in ipairs(connections) do c:Disconnect() end
 for o,value in pairs(defaultEffects) do if o.Parent then o.Enabled=value end end;for s,value in pairs(soundBases) do if s.Parent then s.Volume=value end end;GuiService.SelectedObject=nil
end)
if require(game.ReplicatedStorage.MountainShared.BuildFlags).studioAids() then
 local probe=W.new('BindableFunction',gui,{Name='UIProbe'})
 local hubNames={'Creatures','Discovery','Sanctuary','Mountain','Social','Profile','Shop','Settings'}
 probe.OnInvoke=function(action,value)
  -- P6: motion budget check; QA-only time scale for evidence capture (a speed, .1 = 10x slower; honoured while StudioAids == true).
  if action=='motionStats' then return Motion.stats() end
  if action=='motionScale' then Motion.setTimeScale(tonumber(value) or 1);return Motion.stats() end
  -- Local pref override for the Reduce effects / LOW checks (never sent to the server); nil = back to the saved prefs.
  if action=='motionPrefs' then
   local saved=store.profile and store.profile.ui and store.profile.ui.settings or {}
   local p=table.clone(saved);if type(value)=='table' then for k,v in pairs(value) do p[k]=v end end
   applyPreferences(p);return Motion.stats()
  end
  -- Evidence demos (capture_motion.py): a fixture state + one message played in full (MotionHold cleared before Motion's deferred
  -- scan, so the out part runs while the held frame stays). 'clock' = the game VM clock for frame timestamps.
  if action=='motionDemo' then
   if value=='clock' then return os.clock() end
   local states={carry='carry',run='chase',chaseTap='chase',banner='rest',toast='rest',moment='rest',card='rest',xp='rest',rail='rest'}
   feedback:clear();hud:clearTransients();hud:setChaseRestored(false);screens:close();feedback:clearMoments()
   local st=states[value];if st then fixture=st;gui:SetAttribute('HudFixture',st);local v=fixtureView(st,store.profile);hud:render(v) end
   local rare;for _,s in ipairs(C.species) do if s.rarity=='Rare' then rare=s;break end end
   local msgs={carry=H.message('carry',{species=rare and rare.id,runId='fixture'}),run=H.message('alert',{guardian=C.guardians[2].name,section=2}),
    banner=H.message('section',{section=2,name='Whispering Forest'}),toast=H.message('coin',{text='+25 coins'}),moment=H.message('summit',{})}
   local t0=os.clock()
   if msgs[value] then
    feedback:show(msgs[value],true)
    for _,slot in ipairs({'current','band','moment'}) do local r=feedback[slot];if r and r.frame then r.frame:SetAttribute('MotionHold',nil);for _,x in ipairs(r.frame:GetDescendants()) do x:SetAttribute('MotionHold',nil) end end end
   elseif value=='chaseTap' then task.delay(.6,function() hud:_dockTap(hud.e.dockButtons.Creatures) end);t0+=.6
   elseif value=='card' then hud:toggleCard(true)
   elseif value=='xp' then hud:xpLine(H.message('xpLine',{amount=60,into=300,need=500}))
   elseif value=='rail' then hud:checkpoint(H.message('checkpoint',H.checkpoint('2:recovery')))
   elseif value=='reveal' then local s;for _,x in ipairs(C.species) do if x.rarity=='Epic' then s=x;break end end;feedback:hatchReveal(s,{})
   elseif value=='shop' then open('Shop') end
   return {t0=t0}
  end
  if action=='open' and table.find(hubNames,value) then open(value)
  elseif action=='close' then screens:close();feedback:clearMoments()
  elseif action=='card' and (value=='compact' or value=='expanded') then hud:toggleCard(value=='expanded') -- hud-polish E
  elseif action=='reveal' then
   -- Hatch reveal fixture (P5 E): a species id, else the first Epic in the catalog. Replaces any moment showing.
   local s=C.byId[value];if not s then for _,x in ipairs(C.species) do if x.rarity=='Epic' then s=x;break end end end
   feedback:clearMoments();feedback:hatchReveal(s,{})
  -- hud-polish A: QA-only dialog fixtures for title-pill evidence (confirm = live Abandon copy, no-op callback; reward = Train evolution copy).
  elseif action=='dialog' and value=='confirm' then feedback:confirm('Abandon this creature?','Travel loses your unsecured attempt. Your owned creatures and coins stay safe. Cancel to keep climbing.',function() end)
  elseif action=='dialog' and value=='reward' then local s=C.species[1];feedback:reveal('Evolution unlocked!',s.name..' reached evolution stage 2.',s)
  elseif action=='detail' and screens.hub=='Creatures' and store.profile and store.profile.creatures[1] then screens.detail=value or store.profile.creatures[1].id;screens:render(false)
  elseif action=='tab' and screens.hub and screens.shade.Hub.Tabs:FindFirstChild('Tab'..tostring(value)) then screens.tab=value;screens.detail=nil;screens.page=1;screens:render(false)
  elseif action=='hudState' then
   -- Fixtures rest/carry/regrab/chase/sanctuary (compact card)/sanctuaryOpen (expanded card)/battle; 'live' returns to the live state.
   if value=='live' then fixture=nil;gui:SetAttribute('HudFixture',nil);feedback:clear();hud:clearTransients();hud:setChaseRestored(false)
   elseif H.states[value] or value=='regrab' or value=='sanctuaryOpen' then fixture=value;gui:SetAttribute('HudFixture',value);showFixture(value) end
  end
  local rv=feedback.moment and feedback.moment.trap and feedback.moment.frame
  return {ready=ready,hub=screens.hub,tab=screens.tab,hudState=fixture or (store.profile and H.state(memory,store.profile,store.battle)),view={root.AbsoluteSize.X,root.AbsoluteSize.Y},instances=#gui:GetDescendants(),reveal=rv and #rv:GetDescendants()+1 or nil,pending=store.pending,status=store.status}
 end
end
return {}

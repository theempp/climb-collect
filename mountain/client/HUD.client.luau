local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local C=require(RS:WaitForChild('MountainShared'):WaitForChild('Catalog'))
local remotes=RS:WaitForChild('MountainRemotes',120)
if not remotes then warn('Mountain is still loading.');return end
local req=remotes.Request;local event=remotes.Event
local navy=Color3.fromRGB(24,37,57);local cream=Color3.fromRGB(249,240,219);local teal=Color3.fromRGB(96,203,185);local gold=Color3.fromRGB(245,193,99)
local gui=Instance.new('ScreenGui');gui.Name='MountainHUD';gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild('PlayerGui')
local root=Instance.new('Frame');root.Size=UDim2.fromScale(1,1);root.BackgroundTransparency=1;root.Parent=gui
local function rounded(o,r) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r or 12);c.Parent=o end
local function text(parent,content,size,pos,font)
 local t=Instance.new('TextLabel');t.Size=size;t.Position=pos;t.BackgroundTransparency=1;t.Text=content;t.Font=font or Enum.Font.GothamMedium;t.TextSize=15;t.TextColor3=cream;t.TextXAlignment=Enum.TextXAlignment.Left;t.TextWrapped=true;t.Parent=parent;return t
end
local function panel(parent,size,pos)
 local f=Instance.new('Frame');f.Size=size;f.Position=pos;f.BackgroundColor3=navy;f.BackgroundTransparency=.05;f.BorderSizePixel=0;f.Parent=parent;rounded(f);return f
end
local function button(parent,label,size,pos,fn,color)
 local b=Instance.new('TextButton');b.Name=label:gsub('[^%w]','');b.Size=size;b.Position=pos;b.Text=label;b.TextSize=14;b.Font=Enum.Font.GothamBold;b.TextColor3=navy;b.BackgroundColor3=color or teal;b.BorderSizePixel=0;b.AutoButtonColor=true;b.Parent=parent;rounded(b,8);b.Activated:Connect(fn);return b
end
local header=panel(root,UDim2.fromOffset(360,87),UDim2.fromOffset(14,10))
text(header,'IMPOSSIBLE MOUNTAIN',UDim2.new(1,-24,0,25),UDim2.fromOffset(12,7),Enum.Font.GothamBold).TextColor3=gold
local location=text(header,'Blossom Gardens',UDim2.new(1,-24,0,23),UDim2.fromOffset(12,32))
local summary=text(header,'Loading expedition…',UDim2.new(1,-24,0,22),UDim2.fromOffset(12,58));summary.TextSize=12
local navigation=panel(root,UDim2.fromOffset(360,45),UDim2.fromOffset(14,103))
navigation.Name='Navigation';local navigationButtons={}
local toast=panel(root,UDim2.new(.7,0,0,66),UDim2.new(.15,0,.76,0));toast.Visible=false
local toastText=text(toast,'',UDim2.new(1,-24,1,-12),UDim2.fromOffset(12,6));toastText.TextXAlignment=Enum.TextXAlignment.Center
local notice=text(root,'LOCAL REVIEW • Studio memory resets on Stop',UDim2.new(1,-28,0,20),UDim2.new(0,14,1,-24));notice.TextSize=11;notice.TextTransparency=.2
local battle=panel(root,UDim2.fromOffset(360,80),UDim2.new(.5,-180,0,14));battle.Visible=false
local bossName=text(battle,'',UDim2.new(1,-20,0,25),UDim2.fromOffset(10,6),Enum.Font.GothamBold)
local bar=panel(battle,UDim2.new(1,-20,0,9),UDim2.fromOffset(10,36));bar.BackgroundColor3=Color3.fromRGB(66,76,91)
local fill=Instance.new('Frame');fill.Size=UDim2.fromScale(1,1);fill.BackgroundColor3=gold;fill.BorderSizePixel=0;fill.Parent=bar;rounded(fill,5)
local battleInfo=text(battle,'',UDim2.new(1,-20,0,22),UDim2.fromOffset(10,48));battleInfo.TextSize=12
local abilities=panel(root,UDim2.fromOffset(340,51),UDim2.new(.5,-170,1,-87))
local data=nil;local activeTab=nil;local selected={};local activeAbility=1;local modal=nil;local render
local function fire(action,payload) req:FireServer(action,payload) end
local toastSerial=0
local function notify(message)
 toastSerial+=1;local token=toastSerial;toast.Visible=true;toastText.Text=tostring(message)
 task.delay(5,function() if token==toastSerial then toast.Visible=false end end)
end
for i=1,3 do button(abilities,'['..i..'] Special',UDim2.fromOffset(90,37),UDim2.fromOffset(7+(i-1)*96,7),function() fire('Special',{slot=i,ability=activeAbility}) end) end
local abilityButton
abilityButton=button(abilities,'A1',UDim2.fromOffset(35,37),UDim2.fromOffset(297,7),function() activeAbility=activeAbility%4+1;abilityButton.Text='A'..activeAbility;notify('Guardian ability '..activeAbility..' selected. Regular companions use their role skill.') end,gold)
button(root,'DODGE [Q]',UDim2.fromOffset(115,44),UDim2.new(1,-137,1,-151),function() fire('Dodge') end,gold)
UIS.InputBegan:Connect(function(input,processed)
 if processed then return end
 if input.KeyCode==Enum.KeyCode.Q then fire('Dodge')
 elseif input.KeyCode==Enum.KeyCode.One then fire('Special',{slot=1,ability=activeAbility})
 elseif input.KeyCode==Enum.KeyCode.Two then fire('Special',{slot=2,ability=activeAbility})
 elseif input.KeyCode==Enum.KeyCode.Three then fire('Special',{slot=3,ability=activeAbility})
 elseif input.KeyCode==Enum.KeyCode.Tab then if modal then modal:Destroy();modal=nil;activeTab=nil else activeTab='Collection';render() end end
end)
local function row(scroll,index,title,subtitle)
 local f=panel(scroll,UDim2.new(1,-12,0,88),UDim2.fromOffset(3,(index-1)*95));f.BackgroundColor3=Color3.fromRGB(39,56,77)
 text(f,title,UDim2.new(.65,-15,0,28),UDim2.fromOffset(12,8),Enum.Font.GothamBold)
 local t=text(f,subtitle,UDim2.new(.67,-15,0,39),UDim2.fromOffset(12,39));t.TextSize=12;return f
end
local function open(tab) activeTab=tab;if data then selected=table.clone(data.team) end;render() end
for i,tab in ipairs({'Collection','Eggs','Travel','Journal'}) do navigationButtons[i]=button(navigation,tab,UDim2.fromOffset(81,32),UDim2.fromOffset(7+(i-1)*89,6),function() open(tab) end,if i==1 then gold else teal) end
render=function()
 if modal then modal:Destroy();modal=nil end
 if not activeTab or not data then return end
 local viewport=workspace.CurrentCamera.ViewportSize
 local width=math.min(660,viewport.X-24);local height=math.min(510,viewport.Y-70)
 modal=panel(root,UDim2.fromOffset(width,height),UDim2.new(.5,-width/2,.5,-height/2))
 text(modal,activeTab:upper(),UDim2.new(1,-90,0,35),UDim2.fromOffset(18,10),Enum.Font.GothamBold).TextColor3=gold
 button(modal,'×',UDim2.fromOffset(38,34),UDim2.new(1,-50,0,10),function() modal:Destroy();modal=nil;activeTab=nil end,gold)
 local scroll=Instance.new('ScrollingFrame');scroll.Size=UDim2.new(1,-24,1,-68);scroll.Position=UDim2.fromOffset(12,57);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=5;scroll.CanvasSize=UDim2.fromOffset(0,0);scroll.Parent=modal
 local index=0
 local function add(title,sub) index+=1;scroll.CanvasSize=UDim2.fromOffset(0,index*95);return row(scroll,index,title,sub) end
 if activeTab=='Collection' or activeTab=='Training' then
  local f=add('YOUR THREE-CREATURE TEAM','Select up to three companions, then equip. Training at the refuge costs 15 coins for 80 XP.')
  button(f,'Equip '..#selected,UDim2.fromOffset(115,33),UDim2.new(1,-127,0,28),function() if #selected>0 then fire('Equip',selected);notify('Team selection submitted.') end end)
  for _,c in ipairs(data.creatures) do
   local s=C.byId[c.species];local stage=if s.rarity=='Legendary' then 'Sovereign' elseif c.level>=35 then 'Stage III' elseif c.level>=15 then 'Stage II' else 'Stage I'
   local f=add(s.name..' • Lv '..c.level,s.rarity..' · '..s.role..' · '..stage..'\n'..(c.specialization or 'Specialization unlocks at Lv 25'))
   local selectedIndex=table.find(selected,c.id)
   button(f,if selectedIndex then 'Selected '..selectedIndex else 'Select',UDim2.fromOffset(112,30),UDim2.new(1,-124,0,8),function()
    local n=table.find(selected,c.id);if n then table.remove(selected,n) elseif #selected<3 then table.insert(selected,c.id) else notify('Select at most three companions.') end;render()
   end,if selectedIndex then gold else teal)
   button(f,'Train • 15',UDim2.fromOffset(112,30),UDim2.new(1,-124,0,46),function() fire('Train',c.id) end)
   if c.level>=25 and not c.specialization then
    local spec=add(s.name..' specialization','Choose a permanent focus: Power, Guard or Vitality.')
    for j,choice in ipairs({'Power','Guard','Vitality'}) do button(spec,choice,UDim2.fromOffset(72,27),UDim2.new(1,-240+(j-1)*78,0,54),function() fire('Specialize',{id=c.id,choice=choice}) end) end
   end
  end
 elseif activeTab=='Eggs' or activeTab=='Incubator' then
  add('EXPEDITION EGGS',#data.cargo..'/3 unsecured • '..#data.eggs..' secured. Extract at a checkpoint. Incubate and hatch free at the refuge.')
  for _,e in ipairs(data.cargo) do add(C.byId[e.species].name..' egg','UNSECURED • a fall leaves a recoverable pack for 3 minutes.') end
  for _,e in ipairs(data.eggs) do
   local s=C.byId[e.species];local remain=if e.readyAt then math.max(0,e.readyAt-data.serverNow) else nil
   local f=add(s.name..' egg',s.rarity..' · '..(if remain then (if remain==0 then 'Ready to hatch' else math.ceil(remain)..'s remaining') else 'Secured • '..C.incubation[s.rarity]..'s incubation'))
   button(f,if remain==0 then 'Hatch free' elseif remain then 'Incubating' else 'Incubate',UDim2.fromOffset(112,35),UDim2.new(1,-124,0,28),function() fire(if e.readyAt then 'Hatch' else 'Incubate',e.id) end,if remain==0 then gold else teal)
  end
 elseif activeTab=='Travel' then
  local f=add('Expedition Refuge','Fast travel starts at a checkpoint or the refuge. Secures your carried eggs.')
  button(f,'Return',UDim2.fromOffset(100,35),UDim2.new(1,-112,0,28),function() fire('Travel','refuge') end)
  for k,kingdom in ipairs(C.kingdoms) do
   for _,point in ipairs({'entrance','recovery','guardian'}) do
    local id=k..':'..point
    if data.discoveries[id] then
     local f=add(kingdom.name,point..' checkpoint')
     button(f,'Travel',UDim2.fromOffset(100,35),UDim2.new(1,-112,0,28),function() fire('Travel',id) end)
    end
   end
  end
 elseif activeTab=='Sanctuary' then
  add('SANCTUARY ECONOMY',data.coins..' coins • '..#data.creatures..' companions generate passive income. Offline income capped at 8 hours.')
  local f=add('Collect income','All owned creatures contribute. Rest here and prepare your next ascent.')
  button(f,'Collect',UDim2.fromOffset(110,35),UDim2.new(1,-122,0,28),function() fire('CollectIncome') end)
  local t=add('Train your collection','Develop levels, visible evolution at 15 / 35, and specialization at 25.')
  button(t,'Training',UDim2.fromOffset(110,35),UDim2.new(1,-122,0,28),function() open('Training') end)
 elseif activeTab=='Competition' then
  add('ASYNC SANCTUARY CHALLENGE',data.trophies..' trophies • challenge a saved defense even when its owner is offline. No creatures or eggs are stolen.')
  local f=add('Register your defense','Your equipped team becomes the defense snapshot. Your UserId: '..player.UserId)
  button(f,'Register',UDim2.fromOffset(112,35),UDim2.new(1,-124,0,28),function() fire('RegisterDefense') end)
  local target=add('Choose an opponent','Enter a registered player’s UserId. Use 0 for a clearly labeled practice defense.')
  local box=Instance.new('TextBox');box.Size=UDim2.fromOffset(110,30);box.Position=UDim2.new(1,-122,0,7);box.Text='0';box.PlaceholderText='UserId';box.Font=Enum.Font.Gotham;box.TextSize=14;box.TextColor3=navy;box.BackgroundColor3=cream;box.ClearTextOnFocus=true;box.Parent=target;rounded(box,5)
  button(target,'Challenge',UDim2.fromOffset(110,30),UDim2.new(1,-122,0,46),function() fire('ChallengeDefense',tonumber(box.Text));end)
 else
  add('GRAND EXPEDITION','Explore → recover eggs → extract → hatch → strengthen your team → defeat each Guardian. Auto attacks run in battle; 1 / 2 / 3 activate specials, Q dodges.')
  for k,kingdom in ipairs(C.kingdoms) do add(kingdom.name,(if data.wins[tostring(k)] then 'Guardian defeated' elseif k<=data.unlocked then 'Explore and challenge '..C.guardians[k].name else 'Locked by previous Guardian')..'\n'..(data.resources[tostring(k)] or 0)..' '..kingdom.resource) end
  add('Legendary Trials','Normal victories unlock the next kingdom. Trials require 3 clean dodges and four resolved patterns. Interrupt Pyralune’s golden heart; align Caeloryn’s three stones. Capture is guaranteed once per Guardian.')
 end
end
event.OnClientEvent:Connect(function(kind,payload)
 if kind=='state' then
  data=payload;summary.Text=payload.coins..' coins  •  Eggs '..#payload.cargo..'/3  •  Kingdom '..payload.unlocked..'/6';notice.Text=payload.saveMode
  if #selected==0 then selected=table.clone(payload.team) end
  if activeTab then render() end
 elseif kind=='toast' then notify(payload)
 elseif kind=='open' then open(payload)
 elseif kind=='battle' then
  battle.Visible=payload~=false
  if payload then bossName.Text=payload.name..(if payload.trial then ' • LEGENDARY TRIAL' else '');fill.Size=UDim2.fromScale(math.clamp(payload.hp/payload.max,0,1),1);battleInfo.Text=math.ceil(payload.hp)..' HP  •  Auto attacks active'..(if payload.trial then '  •  Dodges '..(payload.dodges or 0)..'/3' else '') end
 elseif kind=='competition' then notify((if payload.practice then 'Practice: ' else 'Defense challenge: ')..(if payload.won then 'Victory! +'..payload.trophies..' trophies' else 'Defeat • train or adjust your team')..' • '..payload.rounds..' rounds')
 elseif kind=='save' then notice.Text=if payload then data.saveMode..' • checkpoint saved' else 'SAVING PAUSED • progression locked'
 elseif kind=='dodge' then
  local h=player.Character and player.Character:FindFirstChildOfClass('Humanoid');if h then h.CameraOffset=Vector3.new(0,-.8,0);Tween:Create(h,TweenInfo.new(.6),{CameraOffset=Vector3.zero}):Play() end
 end
end)
local elapsed=0
Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<1 then return end;elapsed=0
 local rr=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if rr then
  local k=math.clamp(math.floor((rr.Position.Y-16)/136)+1,1,6);location.Text=C.kingdoms[k].name..' • '..math.max(0,math.floor(rr.Position.Y-16))..' studs'
  for name,volume in pairs({['Mountain Birds 1 (SFX)']=if k==1 then .14 elseif k==2 then .05 else 0,WaterfallLoop=if k==2 then .12 else 0,AstralWind=if k>=3 then .08 else 0,LavaLoop=if k==5 then .1 else 0}) do
   local sound=game:GetService('SoundService'):FindFirstChild(name);if sound then if not sound.IsPlaying then sound:Play() end;Tween:Create(sound,TweenInfo.new(.7),{Volume=volume}):Play() end
  end
 end
 if data then data.serverNow+=1;if activeTab=='Eggs' or activeTab=='Incubator' then render() end end
end)
local function responsive()
 local view=workspace.CurrentCamera.ViewportSize;local compact=view.X<1150
 header.Size=UDim2.fromOffset(if compact then 280 else 360,87)
 local navWidth=math.min(360,view.X-28);navigation.Size=UDim2.fromOffset(navWidth,45)
 for i,b in ipairs(navigationButtons) do b.Size=UDim2.fromOffset((navWidth-14)/4-6,32);b.Position=UDim2.fromOffset(7+(i-1)*(navWidth-14)/4,6);b.TextSize=if view.X<400 then 12 else 14 end
 battle.Position=if compact then UDim2.new(.5,-160,0,155) else UDim2.new(.5,-180,0,14);battle.Size=UDim2.fromOffset(if compact then 320 else 360,80)
 if activeTab then render() end
end
workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(responsive);responsive()
fire('State');notify('Welcome to Impossible Mountain. Follow the flags, discover eggs and rest at checkpoints. Open Journal for controls.')

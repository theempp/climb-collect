-- Visual-only production feel: creature wander/gait/idles/reactions, tag declutter, machine wheels, full-store beacons, decor sway, collect and bank moments.
-- Everything is client-local, distance culled and bounded. Reduced motion or simplified VFX leave a static, readable state.
local Players=game:GetService('Players')
local Tags=game:GetService('CollectionService')
local Run=game:GetService('RunService')
local Tween=game:GetService('TweenService')
local player=Players.LocalPlayer
local RANGE=110
local creatures,gears,beacons,banks,spines,tags,sway={},{},{},{},{},{},{}
local folder=Instance.new('Folder');folder.Name='LocalProductionFeel';folder.Parent=workspace
local function track(tag,set,onAdd)
 for _,v in ipairs(Tags:GetTagged(tag)) do set[v]=true;if onAdd then onAdd(v) end end
 local a=Tags:GetInstanceAddedSignal(tag):Connect(function(v) set[v]=true;if onAdd then onAdd(v) end end)
 local r=Tags:GetInstanceRemovedSignal(tag):Connect(function(v) set[v]=nil end)
 return a,r
end
local base={}
local brain={}
local swayBase={}
local animate
local conns={}
local function keep(a,r) table.insert(conns,a);table.insert(conns,r) end
keep(track('HabitatCreature',creatures,function(m) task.defer(function() if m.Parent then base[m]=m:GetPivot() end end) end))
keep(Tags:GetInstanceRemovedSignal('HabitatCreature'):Connect(function(m) base[m]=nil;brain[m]=nil end))
keep(Tags:GetInstanceRemovedSignal('DecorSway'):Connect(function(p) swayBase[p]=nil end))
keep(track('MachineGear',gears))
keep(track('HabitatBeacon',beacons))
keep(track('ProductionBank',banks))
keep(track('TycoonConveyor',spines))
keep(track('TycoonTag',tags))
keep(track('DecorSway',sway,function(p) swayBase[p]=p.CFrame end))
local function ring(cf,color)
 local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Shape=Enum.PartType.Cylinder
 p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(.2,2,2);p.CFrame=cf*CFrame.Angles(0,0,math.pi/2);p.Parent=folder
 local t=Tween:Create(p,TweenInfo.new(.6,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(.2,14,14),Transparency=1})
 t.Completed:Connect(function() p:Destroy() end);t:Play()
end
local function burst(cf,color,count)
 for i=1,count do
  local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Shape=Enum.PartType.Ball
  p.Material=Enum.Material.Neon;p.Color=color;p.Size=Vector3.new(.9,.9,.9);p.CFrame=cf*CFrame.new((i-count/2)*.9,2,0);p.Parent=folder
  local t=Tween:Create(p,TweenInfo.new(.7+i*.05,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=p.Position+Vector3.new(0,7+i,0),Transparency=1})
  t.Completed:Connect(function() p:Destroy() end);t:Play()
 end
end
local function quiet() return player:GetAttribute('MountainReducedMotion') or player:GetAttribute('MountainSimplifiedVFX') end
local last={}
local function pulses(part,attr,fn)
 local v=part:GetAttribute(attr)
 if v==nil then return end
 if last[part]==nil then last[part]=v;return end
 if v~=last[part] then last[part]=v;fn() end
end
-- Creature life. Habitat creatures (WanderFrame/WanderHalf set by TycoonWorld) wander their pad: pick a spot, turn, walk with a
-- gait bob, then idle (look around, sniff, hop, settle). They turn to greet a nearby player. Display creatures idle in place.
local rng=Random.new()
local IDLES={'look','sniff','hop','settle','look'}
local function yawTo(d) return math.atan2(-d.X,-d.Z) end
local function turn(a,b,rate) local d=(b-a+math.pi)%(2*math.pi)-math.pi;return a+math.clamp(d,-rate,rate),math.abs(d) end
local function think(st,now)
 if st.half and rng:NextNumber()<.6 then
  local target
  for _=1,6 do target=Vector2.new(rng:NextNumber(-st.half.X,st.half.X),rng:NextNumber(-st.half.Y,st.half.Y));if (target-st.at).Magnitude>3 then break end end
  st.mode='walk';st.target=target;st.untilT=now+8
 else
  st.mode=IDLES[rng:NextInteger(1,#IDLES)];st.untilT=now+rng:NextNumber(1.6,4);st.started=now;st.look=rng:NextNumber(-.9,.9)
 end
end
animate=function(model,b,step,now,playerPos)
 local st=brain[model]
 if not st then
  local frame=model:GetAttribute('WanderFrame');local half=model:GetAttribute('WanderHalf')
  local _,size=model:GetBoundingBox()
  st={frame=frame,half=half,at=Vector2.zero,yaw=0,phase=0,speed=0,mode='settle',untilT=now+rng:NextNumber(.5,2.5),started=now,look=0,greetAt=0,
   floating=#(function() local f={};for _,c in ipairs(model:GetChildren()) do if c.Name=='Foot' then table.insert(f,c) end end;return f end)()==0,size=size.Y}
  if frame then local l=frame:PointToObjectSpace(b.Position);st.at=Vector2.new(l.X,l.Z) end
  brain[model]=st
 end
 local here=if st.frame then st.frame*CFrame.new(st.at.X,0,st.at.Y) else b
 local world=Vector3.new(here.Position.X,b.Position.Y,here.Position.Z)
 -- Reaction: a player stepping close gets a turn-and-hop greeting, at most every 8 s.
 local toPlayer=playerPos-world;local flat=Vector3.new(toPlayer.X,0,toPlayer.Z)
 if flat.Magnitude<9 and flat.Magnitude>.5 and now>st.greetAt then st.greetAt=now+8;st.mode='greet';st.started=now;st.untilT=now+1.6;st.face=yawTo(flat) end
 if now>st.untilT then think(st,now) end
 local y,pitch,roll,yawOffset=0,0,0,0
 local wantSpeed=0
 if st.mode=='walk' then
  local delta=st.target-st.at
  if delta.Magnitude<.4 then st.mode='settle';st.untilT=now+rng:NextNumber(1,2.5);st.started=now
  else
   local dirLocal=Vector3.new(delta.X,0,delta.Y)
   local desired=if st.frame then yawTo(st.frame:VectorToWorldSpace(dirLocal)) else 0
   local diff;st.yaw,diff=turn(st.yaw,desired,3.2*step)
   wantSpeed=if diff<.6 then 2.6 else .4
   st.at+=delta.Unit*math.min(delta.Magnitude,st.speed*step)
  end
 elseif st.mode=='greet' then
  st.yaw=turn(st.yaw,st.face,5*step)
  local u=math.clamp((now-st.started-.35)/.5,0,1);y=4*.9*u*(1-u)
 elseif st.mode=='look' then yawOffset=math.sin((now-st.started)*1.4)*st.look*.6
 elseif st.mode=='sniff' then pitch=.16;y=-.08+math.abs(math.sin(now*9))*.05
 elseif st.mode=='hop' then local u=math.clamp((now-st.started)/.55,0,1);y=4*.7*u*(1-u)
 elseif st.mode=='settle' then y=-.12+math.sin(now*1.3)*.04
 end
 st.speed+=(wantSpeed-st.speed)*math.min(1,step*6)
 local gait=math.clamp(st.speed/2.6,0,1)
 st.phase+=st.speed*step*2.4
 if st.floating then y+=math.sin(now*1.6+(model:GetAttribute('IdleSeed') or 0))*.25;roll=math.sin(st.phase)*.06*gait
 else y+=math.abs(math.sin(st.phase))*.28*gait;roll=math.sin(st.phase)*.05*gait;pitch+=.05*gait end
 model:SetAttribute('Gait',gait)
 local yaw=if st.frame then st.yaw+yawOffset else math.sin(now*.5+(model:GetAttribute('IdleSeed') or 0))*.3+yawOffset
 model:PivotTo(CFrame.new(world+Vector3.new(0,y,0))*CFrame.Angles(0,yaw,0)*CFrame.Angles(-pitch,0,roll)*(b-b.Position))
end
-- Tag declutter: nearest/highest-priority tags win; any tag whose screen box overlaps an accepted one is hidden.
local function declutter(camera)
 local list={}
 for gui in pairs(tags) do
  local part=gui.Parent
  if gui.Parent and part:IsA('BasePart') then
   local world=part.Position+gui.StudsOffsetWorldSpace+part.CFrame:VectorToWorldSpace(gui.StudsOffset)
   local d=(world-camera.CFrame.Position).Magnitude
   local text=gui:FindFirstChildOfClass('TextLabel')
   if d<=gui.MaxDistance and text and text.Text~='' then
    local v,on=camera:WorldToViewportPoint(world)
    if on then table.insert(list,{gui=gui,d=d,score=d-(gui:GetAttribute('TagPriority') or 1)*6,x=v.X,y=v.Y,w=gui.Size.X.Offset,h=gui.Size.Y.Offset}) else gui.Enabled=false end
   else gui.Enabled=false end
  end
 end
 table.sort(list,function(a,b) return a.score<b.score end)
 local shown={}
 for _,e in ipairs(list) do
  local clear=true
  for _,o in ipairs(shown) do if math.abs(e.x-o.x)<(e.w+o.w)/2+4 and math.abs(e.y-o.y)<(e.h+o.h)/2+2 then clear=false;break end end
  e.gui.Enabled=clear and #shown<12
  if e.gui.Enabled then table.insert(shown,e) end
 end
end
local tagClock=0
local elapsed=0
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end
 local step=elapsed;elapsed=0
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart');if not root then return end
 local pos=root.Position;local t=workspace:GetServerTimeNow();local reduced=quiet()
 for model in pairs(creatures) do
  local b=base[model]
  if b and model.Parent then
   if (b.Position-pos).Magnitude<RANGE and not reduced then animate(model,b,step,t,pos) else model:PivotTo(b);model:SetAttribute('Gait',0) end
  end
 end
 tagClock+=step;if tagClock>=.2 then tagClock=0;declutter(workspace.CurrentCamera) end
 for part in pairs(sway) do
  local b=swayBase[part]
  if b and part.Parent and (b.Position-pos).Magnitude<RANGE and not reduced then part.CFrame=b*CFrame.new(0,part.Size.Y/2,0)*CFrame.Angles(math.sin(t*1.7+b.Position.X)*.12,0,math.sin(t*2.3+b.Position.Z)*.1)*CFrame.new(0,-part.Size.Y/2,0) end
 end
 for gear in pairs(gears) do
  local spin=gear:GetAttribute('Spin') or 0
  if spin>0 and not reduced and (gear.Position-pos).Magnitude<RANGE then gear.CFrame*=CFrame.Angles(spin*step,0,0) end
 end
 for beacon in pairs(beacons) do
  if beacon.Transparency<1 and not reduced and (beacon.Position-pos).Magnitude<RANGE then beacon.Size=Vector3.one*(1.4+math.sin(t*5)*.3) end
 end
 for bank in pairs(banks) do pulses(bank,'BankSeq',function()
  if (bank.Position-pos).Magnitude<RANGE and not reduced then ring(bank.CFrame,Color3.fromRGB(246,211,137));burst(bank.CFrame,Color3.fromRGB(246,211,137),6) end
 end) end
 for spine in pairs(spines) do pulses(spine,'CollectSeq',function()
  if (spine.Position-pos).Magnitude<RANGE and not reduced then ring(spine.CFrame,Color3.fromRGB(205,238,214)) end
 end) end
end)
script.Destroying:Connect(function() connection:Disconnect();for _,c in ipairs(conns) do c:Disconnect() end;folder:Destroy() end)

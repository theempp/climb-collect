-- Home-base ambient life, client-local only: butterflies over the gardens, ground birds that hop, peck and flee,
-- fireflies after dusk, and a soft flicker on the promenade lanterns. Runs only while the player is in the sanctuary.
-- Sound (owner-picked 2026-10-27, Pro Sound Effects via the Creator Store): wind chimes on placed Wind Chime decor, a bird take-off
-- when a ground bird flees, night crickets after dusk. Day birds stay with the HUD controller's existing loop.
-- Chimes and crickets follow the "Music & ambience" setting; the take-off follows "Sound effects".
-- Colours reuse the kingdom accents (Catalog) and the existing production palette; no new palette.
-- Budget: at most 56 anchored, non-colliding, non-queryable parts moved with one BulkMoveTo per tick at 30 Hz; sounds: 1 cricket loop, 5 one-shots, one loop per placed chime (playing only within 50 studs).
-- Reduced motion / simplified VFX hide all visuals (sound keeps its own volume settings).
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local Lighting=game:GetService('Lighting')
local Tags=game:GetService('CollectionService')
local SoundService=game:GetService('SoundService')
local C=require(game.ReplicatedStorage.MountainShared.Catalog)
local L=require(game.ReplicatedStorage.MountainShared.HomeLayout)
local player=Players.LocalPlayer
local rng=Random.new()
local folder=Instance.new('Folder');folder.Name='LocalHomeAmbience';folder.Parent=workspace
local WOOD,SLATE,GLOW=Color3.fromRGB(219,189,122),Color3.fromRGB(82,104,114),Color3.fromRGB(246,211,137)
local function part(size,color,shape,material)
 local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Size=size;p.Color=color;p.Shape=shape or Enum.PartType.Block;p.Material=material or Enum.Material.SmoothPlastic;p.Transparency=1;p.Parent=folder
 return p
end
local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
local function ground(x,z,from)
 params.FilterDescendantsInstances={folder,player.Character}
 local hit=workspace:Raycast(Vector3.new(x,(from or 60)+60,z),Vector3.new(0,-160,0),params)
 return hit and hit.Position.Y or nil
end
local function inside(x,z) return L.inSanctuary(x,z,L.northZ+12) end
local function spot(center,radius)
 for _=1,8 do
  local a=rng:NextNumber(0,math.pi*2);local r=rng:NextNumber(radius*.3,radius)
  local x,z=center.X+math.cos(a)*r,center.Z+math.sin(a)*r
  if inside(x,z) then local y=ground(x,z,center.Y);if y then return Vector3.new(x,y,z) end end
 end
 return nil
end
-- Volumes from the player's saved settings (state.ui.settings), defaults as in UIProtocol.
local volume={music=.7,sfx=.8}
local stateConnection=game.ReplicatedStorage:WaitForChild('MountainRemotes').Event.OnClientEvent:Connect(function(kind,data)
 local settings=kind=='state' and data and data.ui and data.ui.settings
 if settings then volume.music=settings.musicVolume or volume.music;volume.sfx=settings.sfxVolume or volume.sfx end
end)
local SOUNDS={chimes='rbxassetid://9120750072',takeoff='rbxassetid://9113443901',crickets='rbxassetid://9112764040'}
local function sound(parent,id,looped,maxDistance)
 local s=Instance.new('Sound');s.SoundId=id;s.Looped=looped;s.Volume=0
 if maxDistance then s.RollOffMode=Enum.RollOffMode.InverseTapered;s.RollOffMinDistance=6;s.RollOffMaxDistance=maxDistance end
 s.Parent=parent;return s
end
local crickets=sound(SoundService,SOUNDS.crickets,true);crickets.Name='HomeCrickets'
local chimes={}
local function addChime(arm) if not chimes[arm] then chimes[arm]=sound(arm,SOUNDS.chimes,true,35) end end
for _,arm in ipairs(Tags:GetTagged('WindChime')) do addChime(arm) end
local chimeAdded=Tags:GetInstanceAddedSignal('WindChime'):Connect(addChime)
local chimeRemoved=Tags:GetInstanceRemovedSignal('WindChime'):Connect(function(arm) local s=chimes[arm];chimes[arm]=nil;if s then s:Destroy() end end)
local accents={};for _,k in ipairs(C.kingdoms) do table.insert(accents,Color3.fromRGB(table.unpack(k.accent))) end
local butterflies,birds,flies={},{},{}
for i=1,10 do
 local color=accents[(i-1)%#accents+1]
 butterflies[i]={body=part(Vector3.new(.15,.15,.6),SLATE),left=part(Vector3.new(.8,.05,.7),color),right=part(Vector3.new(.8,.05,.7),color),seed=rng:NextNumber(0,100)}
end
for i=1,5 do
 local body=part(Vector3.new(.8,.7,1.1),if i%2==0 then WOOD else SLATE,Enum.PartType.Ball)
 birds[i]={body=body,beak=part(Vector3.new(.2,.2,.4),WOOD),yaw=rng:NextNumber(0,6.28),mode='hop',t=0,takeoff=sound(body,SOUNDS.takeoff,false,60)}
end
for i=1,16 do flies[i]={p=part(Vector3.new(.25,.25,.25),GLOW,Enum.PartType.Ball,Enum.Material.Neon),seed=rng:NextNumber(0,100)} end
-- Lantern flicker: promenade point lights found lazily (streaming), at most 60.
local lights={}
local function scanLights()
 if #lights>=60 then return end
 local known={};for _,l in ipairs(lights) do known[l.light]=true end
 for _,d in ipairs(workspace:GetDescendants()) do
  if d:IsA('PointLight') and not known[d] and d.Parent:IsA('BasePart') and inside(d.Parent.Position.X,d.Parent.Position.Z) then
   table.insert(lights,{light=d,base=d.Brightness,seed=rng:NextNumber(0,100)});if #lights>=60 then break end
  end
 end
end
local function silence()
 crickets.Volume=0;if crickets.IsPlaying then crickets:Stop() end
 for _,s in pairs(chimes) do if s.IsPlaying then s:Stop() end end
end
local function hideAll()
 for _,b in ipairs(butterflies) do b.body.Transparency=1;b.left.Transparency=1;b.right.Transparency=1;b.anchor=nil end
 for _,b in ipairs(birds) do b.body.Transparency=1;b.beak.Transparency=1;b.at=nil end
 for _,f in ipairs(flies) do f.p.Transparency=1;f.anchor=nil end
end
local ambience
local function quiet() return player:GetAttribute('MountainReducedMotion') or player:GetAttribute('MountainSimplifiedVFX') end
-- Night crickets fade in over dusk (18–19.5) and out over dawn (5–6.5); chimes play only within 50 studs.
local function nightAmount(clock)
 if clock>=19.5 or clock<5 then return 1 end
 if clock>=18 then return (clock-18)/1.5 end
 if clock<6.5 then return 1-(clock-5)/1.5 end
 return 0
end
ambience=function(pos,step)
 local target=.18*volume.music*nightAmount(Lighting.ClockTime)
 crickets.Volume+=(target-crickets.Volume)*math.min(1,step*2)
 if crickets.Volume>.005 then if not crickets.IsPlaying then crickets:Play() end elseif crickets.IsPlaying then crickets:Stop() end
 for arm,s in pairs(chimes) do
  if arm.Parent and (arm.Position-pos).Magnitude<50 then s.Volume=.3*volume.music;if not s.IsPlaying then s:Play() end
  elseif s.IsPlaying then s:Stop() end
 end
end
local elapsed,scanClock,active=0,0,false
local parts,frames={},{}
local connection=Run.RenderStepped:Connect(function(dt)
 elapsed+=dt;if elapsed<1/30 then return end
 local step=elapsed;elapsed=0
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local here=root and inside(root.Position.X,root.Position.Z) and not quiet()
 if not here then
  if active then active=false;hideAll();for _,l in ipairs(lights) do if l.light.Parent then l.light.Brightness=l.base end end end
  -- Sound is not motion: it keeps playing under reduced motion, but stops outside the sanctuary.
  local home=root and inside(root.Position.X,root.Position.Z)
  if not home then silence() else ambience(root.Position,step) end
  return
 end
 active=true
 local pos=root.Position;local now=os.clock()
 ambience(pos,step)
 scanClock-=step;if scanClock<=0 then scanClock=10;scanLights() end
 table.clear(parts);table.clear(frames)
 local function put(p,cf) table.insert(parts,p);table.insert(frames,cf) end
 -- Butterflies: drift between flower-height anchors near the player, flapping; re-home when left behind.
 for _,b in ipairs(butterflies) do
  if not b.anchor or (b.anchor-pos).Magnitude>70 or now>(b.retarget or 0) then
   local s=spot(pos,45);if s then b.anchor=s+Vector3.new(0,rng:NextNumber(2,5),0);b.retarget=now+rng:NextNumber(4,9);b.at=b.at or b.anchor end
  end
  if b.anchor and b.at then
   local wobble=Vector3.new(math.sin(now*1.3+b.seed)*1.5,math.sin(now*2.1+b.seed)*.6,math.cos(now*1.1+b.seed)*1.5)
   local goal=b.anchor+wobble;local delta=goal-b.at;b.at+=delta*math.min(1,step*1.2)
   local dir=Vector3.new(delta.X,0,delta.Z);local cf=CFrame.new(b.at)*(if dir.Magnitude>.05 then CFrame.lookAt(Vector3.zero,dir) else CFrame.identity)
   local flap=math.sin(now*18+b.seed)*.9
   put(b.body,cf);put(b.left,cf*CFrame.Angles(0,0,flap)*CFrame.new(-.42,0,0));put(b.right,cf*CFrame.Angles(0,0,-flap)*CFrame.new(.42,0,0))
   b.body.Transparency=0;b.left.Transparency=0;b.right.Transparency=0
  end
 end
 -- Ground birds: hop a few studs, peck, look around; take flight when the player comes within 10 studs.
 for _,b in ipairs(birds) do
  if not b.at or (b.at-pos).Magnitude>80 then b.at=spot(pos,40);b.mode='hop';b.t=now+rng:NextNumber(.5,2);b.y=0 end
  if b.at then
   local flat=Vector3.new(pos.X-b.at.X,0,pos.Z-b.at.Z)
   if b.mode~='flee' and flat.Magnitude<10 then
    b.mode='flee';b.t=now+2.5;b.vel=(-flat.Unit+Vector3.new(0,1.1,0))*16;b.yaw=math.atan2(flat.X,flat.Z)
    b.takeoff.Volume=.35*volume.sfx;b.takeoff.PlaybackSpeed=rng:NextNumber(.92,1.08);b.takeoff.TimePosition=0;b.takeoff:Play()
   end
   local pitch,lift=0,0
   if b.mode=='flee' then
    b.at+=b.vel*step;b.vel+=Vector3.new(0,2,0)*step
    if now>b.t then b.at=nil end
   elseif now>b.t then
    if rng:NextNumber()<.55 then
     b.yaw+=rng:NextNumber(-1.4,1.4);local nx,nz=b.at.X-math.sin(b.yaw)*2.5,b.at.Z-math.cos(b.yaw)*2.5
     local y=inside(nx,nz) and ground(nx,nz,b.at.Y)
     if y and math.abs(y-b.at.Y)<2 then b.from=b.at;b.to=Vector3.new(nx,y,nz);b.mode='hopping';b.start=now end
    else b.mode='peck';b.start=now end
    b.t=now+rng:NextNumber(.8,2.2)
   end
   if b.mode=='hopping' and b.from then
    local u=math.clamp((now-b.start)/.35,0,1);b.at=b.from:Lerp(b.to,u);lift=4*.6*u*(1-u)
    if u>=1 then b.mode='hop' end
   elseif b.mode=='peck' then pitch=math.max(0,math.sin((now-b.start)*12))*.5 end
   if b.at then
    local cf=CFrame.new(b.at+Vector3.new(0,.35+lift,0))*CFrame.Angles(0,b.yaw,0)*CFrame.Angles(-pitch,0,0)
    put(b.body,cf);put(b.beak,cf*CFrame.new(0,.05,-.7));b.body.Transparency=0;b.beak.Transparency=0
   else b.body.Transparency=1;b.beak.Transparency=1 end
  end
 end
 -- Fireflies after dusk only.
 local clock=Lighting.ClockTime;local night=clock<6 or clock>18.5
 for _,f in ipairs(flies) do
  if night then
   if not f.anchor or (f.anchor-pos).Magnitude>50 then local s=spot(pos,30);f.anchor=s and s+Vector3.new(0,rng:NextNumber(1,3.5),0) end
   if f.anchor then
    put(f.p,CFrame.new(f.anchor+Vector3.new(math.sin(now*.7+f.seed)*2,math.sin(now*1.1+f.seed)*.8,math.cos(now*.6+f.seed)*2)))
    f.p.Transparency=.15+.85*(math.sin(now*2+f.seed)*.5+.5)^3
   end
  else f.p.Transparency=1 end
 end
 for _,l in ipairs(lights) do
  if l.light.Parent and (l.light.Parent.Position-pos).Magnitude<90 then l.light.Brightness=l.base*(.93+.07*math.noise(now*3,l.seed)) end
 end
 if #parts>0 then workspace:BulkMoveTo(parts,frames,Enum.BulkMoveMode.FireCFrameChanged) end
end)
script.Destroying:Connect(function()
 connection:Disconnect();stateConnection:Disconnect();chimeAdded:Disconnect();chimeRemoved:Disconnect()
 crickets:Destroy();for _,s in pairs(chimes) do s:Destroy() end;folder:Destroy()
end)

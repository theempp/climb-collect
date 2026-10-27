-- Cosmetic only: renders finished offspring assets over the server's procedural placeholders
-- (nest egg, reveal, two-arm carry, companions). Custody, prompts and collision stay server-side.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local TweenService=game:GetService('TweenService')
local Assets=require(RS:WaitForChild('MountainShared'):WaitForChild('OffspringAssets'))
local Fit=require(RS.MountainShared:WaitForChild('OffspringCarryFit'))
local C=require(RS.MountainShared.Catalog)
local library=RS:WaitForChild('MountainAssets'):WaitForChild('Offspring')
local world=workspace:WaitForChild('ImpossibleMountain')
local provider=game:GetService('KeyframeSequenceProvider')
local holder=Instance.new('Folder');holder.Name='OffspringLocal';holder.Parent=workspace.CurrentCamera
local clipIds={}
local function clipId(model,name)
 local key=model.Name..'|'..name
 if clipIds[key]==nil then
  local source=library:FindFirstChild(model.Name);local seq=source and source:FindFirstChild('Rig|'..name,true)
  -- Studio sessions register local clips; a published build needs uploaded Animation assets.
  local ok,id=pcall(function() return seq and provider:RegisterKeyframeSequence(seq) end)
  clipIds[key]=ok and id or false
 end
 return clipIds[key] or nil
end
local function prepare(model)
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=true end end
 local controller=model:FindFirstChildOfClass('AnimationController') or Instance.new('AnimationController',model)
 local animator=controller:FindFirstChildOfClass('Animator') or Instance.new('Animator',controller)
 return animator
end
-- One rendered creature with a current clip.
local function newCreature(def)
 local model=library[def.creature]:Clone()
 for _,c in model:GetChildren() do if c:IsA('ObjectValue') then c:Destroy() end end
 local view={model=model,animator=prepare(model),tracks={},current=nil}
 model.Parent=holder
 function view:play(name,fade,once)
  if self.current==name and not once then return end
  local id=clipId(library[def.creature],name);if not id then return end
  local track=self.tracks[name]
  if not track then
   local a=Instance.new('Animation');a.AnimationId=id;track=self.animator:LoadAnimation(a);a:Destroy();self.tracks[name]=track
  end
  for n,t in self.tracks do if n~=name and t.IsPlaying then t:Stop(fade or .15) end end
  track.Looped=not once;track:Play(fade or .15);self.current=name
  -- Inspectable in Studio QA: the clip history of each rendered creature.
  self.model:SetAttribute('ClipHistory',((self.model:GetAttribute('ClipHistory') or '')..' '..name):sub(-120))
  if once then track.Stopped:Once(function() if self.current==name then self.current=nil end end) end
 end
 return view
end
local function hide(model,hidden)
 model:SetAttribute('OffspringHidden',hidden)
 if model:IsA('BasePart') then model.LocalTransparencyModifier=if hidden then 1 else 0 end
 for _,p in model:GetDescendants() do if p:IsA('BasePart') then p.LocalTransparencyModifier=if hidden then 1 else 0 end end
end
local groundParams=RaycastParams.new();groundParams.FilterType=Enum.RaycastFilterType.Exclude
local function ground(position)
 local ignore={holder}
 for _,pl in Players:GetPlayers() do if pl.Character then table.insert(ignore,pl.Character) end end
 for _,n in {'Encounters','RaidPresentation','Interactions'} do local f=world:FindFirstChild(n);if f then table.insert(ignore,f) end end
 groundParams.FilterDescendantsInstances=ignore
 local hit=workspace:Raycast(position+Vector3.new(0,3,0),Vector3.new(0,-12,0),groundParams)
 return hit and hit.Position
end
-- Placeholder -> rendered state, keyed by the server model.
local active={}
local function release(placeholder)
 local s=active[placeholder];if not s then return end
 active[placeholder]=nil
 if s.fit then pcall(function() s.fit:Destroy() end) end
 if s.carrier and s.carrier.Parent then s.carrier:SetAttribute('OffspringCarry',nil) end
 if s.view then s.view.model:Destroy() end
 if s.eggParts then for _,p in s.eggParts do p:Destroy() end end
end
local function speciesOf(model) return model:GetAttribute('Species') end
local function trackCreature(placeholder)
 local def=Assets.get(speciesOf(placeholder));if not def or active[placeholder] then return end
 local view=newCreature(def)
 local s={view=view,def=def,kind=if placeholder:GetAttribute('Slot') then 'companion' else 'carry',last=nil,yaw=nil}
 active[placeholder]=s;hide(placeholder,true)
 if s.kind=='companion' then view.model:ScaleTo(.01*def.companionScale);view:play('Happy',.1,true)
 else view.model:ScaleTo(.01*def.revealScale);view:play('Reveal') end
end
-- Nest eggs: real shell once the server knows the species (first strike), cracks and hatch on reveal.
local function trackEgg(shell)
 local def=Assets.get(speciesOf(shell));if not def or active[shell] then return end
 local egg=library[def.egg]:Clone();prepare(egg)
 local _,size=egg:GetBoundingBox();egg:ScaleTo(egg:GetScale()*def.eggHeight/size.Y)
 egg:PivotTo(shell.CFrame);egg.Parent=holder
 local s={egg=egg,def=def,eggParts={egg},hits=0};active[shell]=s;hide(shell,true)
end
local function crack(s,shell)
 local hits=shell:GetAttribute('Hits') or 0
 if hits==s.hits then return end
 s.hits=hits
 if hits==0 then
  -- Nest reset after a loss or timeout: restore a fresh shell.
  for i=#s.eggParts,2,-1 do s.eggParts[i]:Destroy();s.eggParts[i]=nil end
  s.egg.Parent=holder;s.hatched=false;return
 end
 local box,size=s.egg:GetBoundingBox();local cf=s.egg:GetPivot()
 local line=Instance.new('Part');line.Name='Crack';line.Anchored=true;line.CanCollide=false;line.CanQuery=false;line.CanTouch=false
 line.Material=Enum.Material.Slate;line.Color=Color3.fromRGB(107,83,65);line.Size=Vector3.new(.07,size.Y*.38,.07)
 -- Cracks open on the side facing the viewer (the striker's camera), fanning out per hit.
 local toward=(workspace.CurrentCamera.CFrame.Position-box.Position)*Vector3.new(1,0,1)
 local angle=(if toward.Magnitude>.01 then math.atan2(-toward.X,-toward.Z) else 0)+(hits-2)*.35
 line.CFrame=CFrame.new(box.Position)*CFrame.Angles(0,angle,0)*CFrame.new(0,size.Y*(.02*hits-.04),-size.X*.49)*CFrame.Angles(0,0,(hits%2*2-1)*.45)
 line.Parent=holder;table.insert(s.eggParts,line)
 -- Impact response: quick squash-and-wobble around the authored pivot.
 local base=cf;local t0=os.clock()
 local conn;conn=Run.RenderStepped:Connect(function()
  local t=os.clock()-t0;if t>.35 or not s.egg.Parent then conn:Disconnect();if s.egg.Parent then s.egg:PivotTo(base) end;return end
  local wobble=math.sin(t*40)*(1-t/.35)*.09
  s.egg:PivotTo(base*CFrame.Angles(wobble,0,wobble*.6))
 end)
end
local function hatch(s,shell)
 if s.hatched then return end
 s.hatched=true
 local opened=library[s.def.hatch]:Clone();prepare(opened)
 local _,size=opened:GetBoundingBox();opened:ScaleTo(opened:GetScale()*s.def.eggHeight/size.Y)
 opened:PivotTo(s.egg:GetPivot());opened.Parent=holder;table.insert(s.eggParts,opened)
 s.egg.Parent=nil
 for i=#s.eggParts,1,-1 do if s.eggParts[i].Name=='Crack' then s.eggParts[i]:Destroy();table.remove(s.eggParts,i) end end
 local lid=opened:FindFirstChild('Hatch_lid')
 if lid then
  local start=lid.CFrame
  TweenService:Create(lid,TweenInfo.new(.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=start*CFrame.new(.6,2.2,0)*CFrame.Angles(0,0,-.9)}):Play()
  task.delay(.9,function() if lid.Parent then TweenService:Create(lid,TweenInfo.new(.6),{Transparency=1}):Play() end end)
 end
 local burst=Instance.new('Attachment');burst.WorldPosition=s.egg:GetPivot().Position+Vector3.new(0,size.Y*.6,0);burst.Parent=workspace.Terrain
 local fx=Instance.new('ParticleEmitter');fx.Texture='rbxasset://textures/particles/sparkles_main.dds'
 local k=C.kingdoms[1].accent;fx.Color=ColorSequence.new(Color3.fromRGB(k[1],k[2],k[3]))
 fx.Lifetime=NumberRange.new(.5,.9);fx.Speed=NumberRange.new(5,9);fx.SpreadAngle=Vector2.new(180,180);fx.Size=NumberSequence.new(.35,0);fx.Rate=0;fx.Parent=burst
 fx:Emit(28);task.delay(1.5,function() burst:Destroy() end)
 -- The empty base stays briefly as a trophy of the break, then fades.
 task.delay(6,function()
  for _,p in opened:GetDescendants() do if p:IsA('BasePart') then TweenService:Create(p,TweenInfo.new(1),{Transparency=1}):Play() end end
 end)
end
local function consider(o)
 if not o:IsA('BasePart') and not o:IsA('Model') then return end
 if o:GetAttribute('RaidEgg') then trackEgg(o) elseif o:IsA('Model') and (o:GetAttribute('CarryOwner') or o:GetAttribute('Slot')) then trackCreature(o) end
end
for _,o in world:GetDescendants() do consider(o) end
world.DescendantAdded:Connect(function(o) task.defer(consider,o) end)
world.DescendantRemoving:Connect(function(o) if active[o] then release(o) end end)
-- Attributes arrive after creation (species set on first strike / at reveal).
local function watch(o)
 if o:GetAttribute('RaidEgg') or o:GetAttribute('CarryOwner') or o:GetAttribute('Slot') then
  o:GetAttributeChangedSignal('Species'):Connect(function()
   if active[o] then release(o);hide(o,false) end
   consider(o)
  end)
 end
end
for _,o in world:GetDescendants() do watch(o) end
world.DescendantAdded:Connect(function(o) task.defer(watch,o) end)
local tick=0
Run.PreRender:Connect(function(dt)
 tick+=dt;if tick<1/30 then return end;local step=tick;tick=0
 for placeholder,s in pairs(active) do
  if not placeholder.Parent then release(placeholder);continue end
  if placeholder:GetAttribute('OffspringHidden') then
   if placeholder:IsA('BasePart') then placeholder.LocalTransparencyModifier=1 end
   for _,part in placeholder:GetDescendants() do if part:IsA('BasePart') and part.LocalTransparencyModifier<1 then part.LocalTransparencyModifier=1 end end
  end
  if s.egg then
   crack(s,placeholder)
   if placeholder.Transparency>.5 and (placeholder:GetAttribute('Hits') or 0)>0 then hatch(s,placeholder) end
   continue
  end
  local view=s.view;local model=view.model
  if s.kind=='carry' then
   local inArms=placeholder:GetAttribute('InArms')
   local owner=Players:GetPlayerByUserId(placeholder:GetAttribute('CarryOwner') or 0)
   local character=owner and owner.Character
   if inArms and character and not s.fit and not s.fitFailed then
    model:SetAttribute('Species',s.def.carry)
    local ok,state=pcall(Fit.attach,model,character)
    if ok then s.fit=state;s.carrier=character;character:SetAttribute('OffspringCarry',true);view:play('Carried')
    else s.fitFailed=true;hide(placeholder,false);model.Parent=nil end
   elseif not inArms and not s.fit then
    local nest=placeholder:GetPivot().Position;local me=Players.LocalPlayer.Character and Players.LocalPlayer.Character.PrimaryPart
    local toward=if me then (me.Position-nest)*Vector3.new(1,0,1) else Vector3.new(0,0,1)
    toward=if toward.Magnitude>.01 then toward.Unit else Vector3.new(0,0,1)
    local spot=nest+toward*2.2;local floor=ground(spot)
    model:PivotTo(CFrame.lookAt(if floor then floor else spot-Vector3.new(0,1,0),(if floor then floor else spot)+toward))
   end
   if placeholder:GetAttribute('Secured') and not s.cheered then s.cheered=true;view:play('Happy',.1,true);task.delay(1.3,function() if s.fit then view:play('Carried') end end) end
  else
   -- Companion: follow the placeholder path on the ground; gait from speed, Turn from yaw rate.
   local target=placeholder:GetPivot();local floor=ground(target.Position)
   local position=if floor then floor else target.Position-Vector3.new(0,1,0)
   local velocity=if s.last then (position-s.last)/step else Vector3.zero;s.last=position
   local flat=Vector3.new(velocity.X,0,velocity.Z);local speed=flat.Magnitude
   local owner=placeholder.Parent and Players:GetPlayerByUserId(tonumber((placeholder.Parent.Name:match('Team_(%d+)')) or '') or 0)
   local look=if speed>1 then flat.Unit elseif owner and owner.Character and owner.Character.PrimaryPart then owner.Character.PrimaryPart.CFrame.LookVector*Vector3.new(1,0,1) else Vector3.new(0,0,-1)
   if look.Magnitude<.01 then look=Vector3.new(0,0,-1) end
   local yaw=math.atan2(-look.X,-look.Z);local turning=0
   if s.yaw then local d=(yaw-s.yaw+math.pi)%(2*math.pi)-math.pi;turning=math.abs(d)/step;yaw=s.yaw+d*math.min(1,step*8) end
   s.yaw=yaw
   model:PivotTo(CFrame.new(position)*CFrame.Angles(0,yaw,0))
   if view.current~='Happy' then
    view:play(if speed>s.def.runSpeed then 'Run' elseif speed>1.5 then 'Move' elseif turning>s.def.turnRate then 'Turn' else 'Idle')
   end
  end
 end
end)

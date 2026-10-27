-- Cosmetic articulation only. Authoritative roots, prompts and collision never move here.
local Run=game:GetService('RunService')
local rigs={}
local candidates={}
local function register(model)
 if not model:IsA('Model') then return end
 candidates[model]=true
 if model:GetAttribute('ArtRevision')~=2 or not model.PrimaryPart then return end
 local parts=rigs[model] or {}
 local known={};for _,joint in ipairs(parts) do known[joint.part]=true end
 for _,p in ipairs(model:GetChildren()) do
  if not known[p] and p:IsA('BasePart') and p~=model.PrimaryPart and not p.CanCollide and p:GetAttribute('RestLocal') then
   p.LocalTransparencyModifier=parts.fade or 0
   table.insert(parts,{part=p,rest=p:GetAttribute('RestLocal'),pivot=p:GetAttribute('MotionPivot') or Vector3.zero,role=p:GetAttribute('MotionRole'),phase=p:GetAttribute('MotionPhase') or 0})
  end
 end
 rigs[model]=parts
end
for _,m in ipairs(workspace:GetDescendants()) do register(m) end
workspace.DescendantAdded:Connect(register)
local elapsed=0
local discovery=0
Run:BindToRenderStep('MountainCreatureMotion',Enum.RenderPriority.Camera.Value+10,function(dt)
 discovery+=dt
 if discovery>=1 then
  discovery=0
  -- Replication can deliver the model before its root, children and pose attributes.
  for model in pairs(candidates) do
   if model:IsDescendantOf(workspace) then register(model) else candidates[model]=nil;rigs[model]=nil end
  end
 end
 elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
 local camera=workspace.CurrentCamera;if not camera then return end
 local now=workspace:GetServerTimeNow()
 for model,parts in pairs(rigs) do
  local root=model.PrimaryPart
  if not model:IsDescendantOf(workspace) or not root then rigs[model]=nil;continue end
  if model:GetAttribute('OffspringHidden') then continue end
  local distance=(root.Position-camera.CFrame.Position).Magnitude
  if model:GetAttribute('Slot') then
   -- Hide the whole companion before skipping updates; never leave frozen limbs visible.
   local fade=math.clamp((distance-150)/30,0,1)
   if parts.fade~=fade then
    parts.fade=fade;root.LocalTransparencyModifier=fade
    for _,joint in ipairs(parts) do if joint.part.Parent then joint.part.LocalTransparencyModifier=fade end end
   end
  end
  if distance>180 then continue end
  local cue=math.clamp(((model:GetAttribute('TellUntil') or 0)-now)/1.6,0,1)
  -- Gait (0..1) is a client-local walk amount set by TycoonFeel for wandering home creatures.
  local gait=model:GetAttribute('Gait') or 0
  for _,joint in ipairs(parts) do if joint.part.Parent then
   local phase=joint.phase;local role=joint.role;local swing=CFrame.identity
   if role=='Wing' then swing=CFrame.Angles(0,0,phase*(math.sin(now*3)*.18+cue*.35))
   elseif role=='Fin' then swing=CFrame.Angles(math.sin(now*2+phase)*.12,0,math.sin(now*2+phase)*.12)
   elseif role=='Mane' then swing=CFrame.Angles(math.sin(now*1.6+phase)*.06,0,math.sin(now*1.2+phase)*.045)
   elseif role=='Tail' then swing=CFrame.Angles(0,math.sin(now*(1.8+gait*3)+phase)*(.18+gait*.1),0)
   elseif role=='Ear' then swing=CFrame.Angles(math.sin(now*.8+phase)^8*.12,0,0)
   elseif role=='Foot' then swing=CFrame.Angles(math.sin(now*(1.2+gait*9)+phase+gait*joint.pivot.Z*2)*(.035+gait*.4),0,0)
   elseif role=='Fist' then swing=CFrame.new(0,math.sin(now*1.4+phase)*.2+cue*.35,0)*CFrame.Angles(cue*-.3,0,math.sin(now+phase)*.06)
   elseif role=='Orbit' then swing=CFrame.Angles(0,math.sin(now*.7+phase)*.12,math.sin(now*.9)*.08)
   end
   joint.part.CFrame=root.CFrame*CFrame.new(joint.pivot)*swing*CFrame.new(-joint.pivot)*joint.rest
  end end
 end
end)

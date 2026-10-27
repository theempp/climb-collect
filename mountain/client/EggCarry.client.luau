-- Local arm pose and short impact feedback. Custody and world models are server-owned.
local Players=game:GetService('Players')
local Run=game:GetService('RunService')
Run.PreSimulation:Connect(function()
 for _,player in ipairs(Players:GetPlayers()) do
  local c=player.Character
  if not c then continue end
  if c:GetAttribute('OffspringCarry') then continue end
  local carry=c:GetAttribute('CarryingCreature')
  local t=workspace:GetServerTimeNow()-(c:GetAttribute('PickaxeStrikeAt') or -100)
  local b=workspace:GetServerTimeNow()-(c:GetAttribute('BatSwingAt') or -100)
  for _,joint in ipairs(c:GetDescendants()) do
   if not (joint:IsA('Motor6D') or joint:IsA('AnimationConstraint')) then continue end
   local name=joint.Name
   if carry then
    if name=='RightShoulder' or name=='Right Shoulder' then joint.Transform=CFrame.Angles(1.05,0,-.42)
    elseif name=='LeftShoulder' or name=='Left Shoulder' then joint.Transform=CFrame.Angles(1.05,0,.42)
    elseif name=='RightElbow' or name=='LeftElbow' then joint.Transform=CFrame.Angles(.9,0,0) end
   elseif b>=0 and b<.35 and (name=='RightShoulder' or name=='Right Shoulder') then
    joint.Transform=CFrame.Angles(1.3,0,-1.3+b/.35*2.4)
   elseif t>=0 and t<.4 and (name=='RightShoulder' or name=='Right Shoulder') then
    joint.Transform=CFrame.Angles(.7+math.sin(t/.4*math.pi)*1.2,0,-.2)
   end
  end
 end
end)

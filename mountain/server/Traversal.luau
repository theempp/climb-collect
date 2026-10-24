local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local Rules=require(game.ReplicatedStorage.MountainShared.TraversalRules)
local T={}
function T.start(world)
 local sand,fields={},{}
 for _,part in ipairs(world.Dynamics:GetChildren()) do
  if part:GetAttribute('Kind')=='ShiftingSand' then table.insert(sand,part) end
  if part:GetAttribute('GravityField') then table.insert(fields,part) end
 end
 local forces={}
 local function clear(player)
  local data=forces[player]
  if data then data.force:Destroy();data.attachment:Destroy();forces[player]=nil end
 end
 Players.PlayerRemoving:Connect(clear)
 RunService.Heartbeat:Connect(function()
  for _,part in ipairs(sand) do
   part.AssemblyLinearVelocity=part.CFrame.LookVector*Rules.sandSpeed(workspace:GetServerTimeNow())
  end
  for _,player in ipairs(Players:GetPlayers()) do
   local char=player.Character
   local root=char and char:FindFirstChild('HumanoidRootPart')
   local h=char and char:FindFirstChildOfClass('Humanoid')
   local scale=1
   if root and h and h.Health>0 then
    for _,part in ipairs(fields) do
     local p=part.CFrame:PointToObjectSpace(root.Position)
     scale=math.min(scale,Rules.gravityScale(p.X,p.Y-part.Size.Y/2,p.Z,part.Size.X/2,part.Size.Z/2))
    end
   end
   if scale==1 then clear(player)
   else
    local data=forces[player]
    if data and data.root~=root then clear(player);data=nil end
    if not data then
     local attachment=Instance.new('Attachment');attachment.Name='MountainGravity';attachment.Parent=root
     local force=Instance.new('VectorForce');force.Name='MountainGravity';force.Attachment0=attachment
     force.ApplyAtCenterOfMass=true;force.RelativeTo=Enum.ActuatorRelativeTo.World;force.Parent=root
     data={force=force,attachment=attachment,root=root};forces[player]=data
    end
    data.force.Force=Vector3.new(0,root.AssemblyMass*workspace.Gravity*(1-scale),0)
   end
  end
 end)
end
return T

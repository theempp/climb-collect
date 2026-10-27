-- Bat knockback on the local character (it owns its physics). Custody and hit validation stay on the server.
local Players=game:GetService('Players')
local event=game:GetService('ReplicatedStorage'):WaitForChild('MountainRemotes'):WaitForChild('Event')
local player=Players.LocalPlayer
event.OnClientEvent:Connect(function(kind,payload)
 if kind~='knock' or type(payload)~='table' or typeof(payload.velocity)~='Vector3' then return end
 local c=player.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local rr=c and c:FindFirstChild('HumanoidRootPart')
 if not h or not rr or h.Health<=0 then return end
 -- A grounded Humanoid cancels velocity changes; PlatformStand lets the impulse carry the character.
 h.PlatformStand=true
 rr.AssemblyLinearVelocity=payload.velocity
 rr.AssemblyAngularVelocity=Vector3.new(math.random()-.5,0,math.random()-.5)*6
 task.delay(math.clamp(tonumber(payload.stun) or .9,.3,2),function()
  if h.Parent then h.PlatformStand=false;h:ChangeState(Enum.HumanoidStateType.GettingUp) end
 end)
end)

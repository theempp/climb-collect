local T=require(script.Parent.Parent.ExpeditionUITheme)
local H={}
function H.mount(deps)
 local self={};local ui=deps.ui
 ui.hud.BackgroundColor3=T.teal;ui.hud.BackgroundTransparency=0
 for _,v in ui.hud:GetDescendants() do if v:IsA('TextLabel') then v.TextColor3=T.ink;v.Font=Enum.Font.FredokaOne elseif v:IsA('UIStroke') then v.Color=T.cream;v.Thickness=3 end end
 ui.altitude.BackgroundColor3=T.gold;ui.altitudeText.TextColor3=T.ink
 ui.menuButton.BackgroundColor3=T.gold;ui.menuButton.TextColor3=T.ink;ui.menuButton.Font=Enum.Font.FredokaOne
 local b=T.button(deps.parent,'PROFILE',deps.profile.own,T.teal);b.Name='OpenProfile';b.AnchorPoint=Vector2.new(1,0);b.Position=UDim2.new(1,-10,0,122);b.Size=UDim2.fromOffset(116,50)
 local art=T.mountain(ui.altitude);art.Size=UDim2.fromOffset(32,32);art.Position=UDim2.new(1,-36,0,2)
 local cf,phase={},0;local scanAt=-10
 local connection=game:GetService('RunService').RenderStepped:Connect(function(dt)
  phase+=dt;local motion=not game.Players.LocalPlayer:GetAttribute('CC_ReducedMotion')
  local f=workspace.World:FindFirstChild('Fairground')
  if f and phase-scanAt>2 then scanAt=phase;for _,p in f:GetDescendants() do if p:IsA('BasePart') and p:GetAttribute('FairgroundMotion') then cf[p]=cf[p] or p.CFrame end end end
  for p,base in cf do if p.Parent then p.CFrame=base*(motion and CFrame.Angles(0,p:GetAttribute('FairgroundMotion')=='globe' and phase*.2 or math.sin(phase*1.3+p.Position.Z)*.08,0) or CFrame.new()) else cf[p]=nil end end
  b.Visible=not deps.blocked()
 end)
 function self.destroy() connection:Disconnect();b:Destroy() end
 return self
end
return H
